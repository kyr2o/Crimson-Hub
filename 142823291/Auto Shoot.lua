local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or {
    enabled = false,
    prediction = 0.14,
    FALL_LEAD_MULT = 1.0,
    MIN_ABOVE_FLOOR = 1.6,
    FLOOR_RAY_RANGE = 160,
    FLOOR_RAY_RADIUS = 2.5,
    MID_AIR_FRACTION = 0.35,
    GHOST_AHEAD_BIAS = 1.0,     
}

local function __mm2_pred_from_ping(ms)
    if not ms or ms ~= ms then return 0.14 end
    if ms <= 40  then return 0.11 end
    if ms <= 60  then return 0.12 end
    if ms <= 80  then return 0.13 end
    if ms <= 100 then return 0.135 end
    if ms <= 120 then return 0.14 end
    if ms <= 150 then return 0.15 end
    if ms <= 180 then return 0.17 end
    if ms <= 220 then return 0.19 end
    return 0.21
end
local function __mm2_ping_ms()
    local net = Stats and Stats.Network
    local item = net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"]
    local v = item and item:GetValue()
    if v and v < 1 then return math.floor(v*1000 + 0.5) end
    return math.floor((v or 0) + 0.5)
end
G.CRIMSON_AUTO_SHOOT.calibrate = function()
    local ms = __mm2_ping_ms()
    local pred = __mm2_pred_from_ping(ms)
    G.CRIMSON_AUTO_SHOOT.prediction = pred
    return ms, pred
end

local LocalPlayer = Players.LocalPlayer
local shootConnection

local function raycastDown(origin, dist, ignoreList)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignoreList
    return Workspace:Raycast(origin, Vector3.new(0, -dist, 0), p)
end
local function sampleFloorMedianXZ(centerXZ, maxDist, radius, ignore)
    local cx, cz = centerXZ.X, centerXZ.Z
    local offsets = {
        Vector3.new(0,0,0),
        Vector3.new(radius,0,0), Vector3.new(-radius,0,0),
        Vector3.new(0,0,radius), Vector3.new(0,0,-radius),
        Vector3.new(radius,0,radius), Vector3.new(-radius,0,radius),
        Vector3.new(radius,0,-radius), Vector3.new(-radius,0,-radius),
    }
    local ys = {}
    for _, off in ipairs(offsets) do
        local start = Vector3.new(cx + off.X, centerXZ.Y + 2.0, cz + off.Z)
        local hit = raycastDown(start, maxDist, ignore)
        if hit then ys[#ys+1] = hit.Position.Y end
    end
    if #ys == 0 then return nil end
    table.sort(ys)
    return ys[math.ceil(#ys*0.5)]
end

local function humanoidAndRoot(char)
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    return hum, root
end
local function partSafe(char, name)
    local p = char and char:FindFirstChild(name)
    return (p and p:IsA("BasePart")) and p or nil
end
local function findMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local bp = p:FindFirstChild("Backpack")
            if (bp and bp:FindFirstChild("Knife")) or p.Character:FindFirstChild("Knife") then
                return p
            end
        end
    end
    return nil
end
local function disconnectShoot()
    if shootConnection then shootConnection:Disconnect(); shootConnection=nil end
end
local function networkTimeBudget()
    local ms = __mm2_ping_ms() or 140
    local oneWay = (ms/1000)*0.5
    local frameCushion = 1/90
    local extra = 0.006
    return math.clamp(oneWay + frameCushion + extra, 0.035, 0.40)
end

local function ghostProbePosition(rootPos, vel, basePred, ignore)

    local aheadBias = tonumber(G.CRIMSON_AUTO_SHOOT.GHOST_AHEAD_BIAS) or 1.0
    local leadT = math.max(basePred * aheadBias, 0.06)
    local projXZ = Vector3.new(rootPos.X + vel.X * leadT, rootPos.Y, rootPos.Z + vel.Z * leadT)
    local floorY = sampleFloorMedianXZ(projXZ, G.CRIMSON_AUTO_SHOOT.FLOOR_RAY_RANGE, G.CRIMSON_AUTO_SHOOT.FLOOR_RAY_RADIUS, ignore)
    if not floorY then return nil end
    local minAbove = tonumber(G.CRIMSON_AUTO_SHOOT.MIN_ABOVE_FLOOR) or 1.6
    return Vector3.new(projXZ.X, floorY + minAbove, projXZ.Z)
end

local function phaseTargetPart(char, velY)

    if velY > 7 then
        return partSafe(char, "Head") or partSafe(char, "UpperTorso") or partSafe(char, "HumanoidRootPart")
    end

    if velY > 1 then
        return partSafe(char, "LowerTorso") or partSafe(char, "UpperTorso") or partSafe(char, "HumanoidRootPart")
    end

    if velY <= -1 then
        return partSafe(char, "LeftUpperLeg") or partSafe(char, "RightUpperLeg")
            or partSafe(char, "LeftLowerLeg") or partSafe(char, "RightLowerLeg")
            or partSafe(char, "LowerTorso") or partSafe(char, "HumanoidRootPart")
    end

    return partSafe(char, "UpperTorso") or partSafe(char, "HumanoidRootPart")
end

local function computeAim(char, hum, root, basePred, ignore)
    local gravity = Workspace.Gravity or 196.2
    local state = hum:GetState()
    local vel = root.Velocity
    local vy = vel.Y
    local falling = (state == Enum.HumanoidStateType.Freefall) or (vy < -1.0)
    local jumping = (state == Enum.HumanoidStateType.Jumping)

    local t_net = networkTimeBudget()

    local anchor = phaseTargetPart(char, vy)
    local anchorPos = anchor and anchor.Position or root.Position

    local airHoriz = Vector3.new(vel.X, 0, vel.Z)
    local airDragScale = 1.0
    if falling then
        airDragScale = math.clamp(0.9 - (math.abs(vy) * 0.012), 0.35, 0.9)
        local maxAir = 28
        local sp = airHoriz.Magnitude
        if sp > maxAir then airHoriz = airHoriz.Unit * maxAir end
    end
    local userMult = math.max(0.2, tonumber(G.CRIMSON_AUTO_SHOOT.FALL_LEAD_MULT) or 1.0)
    local horizLead = airHoriz * (basePred * (falling and (0.9 * airDragScale * userMult) or 1.0))

    local ballY = vy * t_net - 0.5 * gravity * (t_net * t_net)
    if jumping and ballY < 0 then ballY = ballY * 0.4 end

    local rawAim = anchorPos + horizLead + Vector3.new(0, ballY, 0)

    if falling or jumping then
        local ghost = ghostProbePosition(root.Position, vel, basePred, ignore)
        if ghost then

            local minAbove = tonumber(G.CRIMSON_AUTO_SHOOT.MIN_ABOVE_FLOOR) or 1.6
            local remain = math.max((anchorPos.Y - ghost.Y + minAbove), 0)
            local frac = math.clamp(tonumber(G.CRIMSON_AUTO_SHOOT.MID_AIR_FRACTION) or 0.35, 0.15, 0.6)
            local clampY = ghost.Y + remain * frac
            if rawAim.Y < clampY then
                rawAim = Vector3.new(rawAim.X, clampY, rawAim.Z)
            end
        end
    end

    return rawAim
end

local function onCharacter(character)
    if shootConnection then shootConnection:Disconnect(); shootConnection=nil end
    local backpack = LocalPlayer:WaitForChild("Backpack", 5); if not backpack then return end

    local function tryBindGun()
        local gun = character:FindFirstChild("Gun") or backpack:FindFirstChild("Gun")
        if not gun then return end
        local rf = gun:FindFirstChild("KnifeLocal")
            and gun.KnifeLocal:FindFirstChild("CreateBeam")
            and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
        if not rf then return end

        if shootConnection then shootConnection:Disconnect() end
        shootConnection = RunService.Heartbeat:Connect(function()
            if not G.CRIMSON_AUTO_SHOOT.enabled then return end
            if not character:FindFirstChild("Gun") then return end

            local murderer = (function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local bp = p:FindFirstChild("Backpack")
                        if (bp and bp:FindFirstChild("Knife")) or p.Character:FindFirstChild("Knife") then
                            return p
                        end
                    end
                end
                return nil
            end)()
            if not murderer then return end
            local tChar = murderer.Character; if not tChar then return end
            local hum, root = humanoidAndRoot(tChar); if not hum or not root then return end

            local basePred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0.14
            local ignore = {character, LocalPlayer.Character, tChar}

            local aimPos = computeAim(tChar, hum, root, basePred, ignore)
            local gunLocal = gun and gun:FindFirstChild("KnifeLocal")
            local beam = gunLocal and gunLocal:FindFirstChild("CreateBeam")
            local rf2 = beam and beam:FindFirstChild("RemoteFunction")
            if rf2 then rf2:InvokeServer(1, aimPos, "AH2") end
        end)
    end

    character.ChildAdded:Connect(function(child) if child.Name == "Gun" then tryBindGun() end end)
    character.ChildRemoved:Connect(function(child) if child.Name == "Gun" then if shootConnection then shootConnection:Disconnect(); shootConnection=nil end end end)
    tryBindGun()
end

local function start()
    if LocalPlayer.Character then onCharacter(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(onCharacter)
end
start()

G.CRIMSON_AUTO_SHOOT.enable = function() G.CRIMSON_AUTO_SHOOT.enabled = true end
G.CRIMSON_AUTO_SHOOT.disable = function() G.CRIMSON_AUTO_SHOOT.enabled = false if shootConnection then shootConnection:Disconnect(); shootConnection=nil end end
