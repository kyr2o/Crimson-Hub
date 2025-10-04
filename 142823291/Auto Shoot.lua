local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }

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
G.CalibrateAutoShoot = G.CRIMSON_AUTO_SHOOT.calibrate
G.CRIMSON_CalibrateShoot = G.CRIMSON_AUTO_SHOOT.calibrate

local LocalPlayer = Players.LocalPlayer
local shootConnection

local function raycastDown(fromPos, maxDist, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    return Workspace:Raycast(fromPos, Vector3.new(0, -maxDist, 0), params)
end

local function humanoidAndRoot(char)
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    return hum, root
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
    if shootConnection then
        shootConnection:Disconnect()
        shootConnection = nil
    end
end

local function verticalNudgeForAir(rootPos, vel, hum, ignore)
    if not hum then return 0 end

    local gravity = Workspace.Gravity or 196.2
    local jp = hum.JumpPower or 50
    local state = hum:GetState()
    local vy = vel.Y

    local falling = (state == Enum.HumanoidStateType.Freefall) or (vy < -1.0)
    local jumping = (state == Enum.HumanoidStateType.Jumping)

    local downHit = raycastDown(rootPos + Vector3.new(0, 1.5, 0), 80, ignore)
    local floorY = downHit and downHit.Position.Y or nil
    local distToFloor = floorY and (rootPos.Y - floorY) or nil

    if falling then

        local baseDown = 0
        if distToFloor then

            baseDown = math.clamp(0.3 + (distToFloor * 0.11), 0.4, 2.4)
        else

            baseDown = 0.8
        end

        local speedFactor = math.clamp(math.abs(vy) / 40, 0.0, 1.0) 
        local nudgeDown = baseDown * (1.0 + 0.6 * speedFactor)

        if floorY then
            local minAbove = 1.2
            local targetY = rootPos.Y - nudgeDown
            if targetY < (floorY + minAbove) then
                nudgeDown = (rootPos.Y - (floorY + minAbove))
                nudgeDown = math.max(nudgeDown, 0.4) 
            end
        end

        return -math.abs(nudgeDown) 
    elseif jumping then

        local up = math.clamp(vy * 0.03 * math.clamp(jp/50, 0.6, 1.4), 0, 1.2)
        return up
    else

        return math.clamp(vy * 0.02, -0.8, 0.8)
    end
end

local function onCharacter(character)
    disconnectShoot()
    local backpack = LocalPlayer:WaitForChild("Backpack", 5)
    if not backpack then return end

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

            local murderer = findMurderer()
            local tChar = murderer and murderer.Character
            if not tChar then return end

            local hum, root = humanoidAndRoot(tChar)
            if not hum or not root then return end

            local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0
            local vel = root.Velocity
            local baseAim = root.Position + (vel * pred)

            local ignore = {character, LocalPlayer.Character}
            local nudgeY = verticalNudgeForAir(root.Position, vel, hum, ignore)

            if hum:GetState() == Enum.HumanoidStateType.Freefall or vel.Y < -1.0 then
                nudgeY = math.min(nudgeY, 0) 
            end

            local aimPos = baseAim + Vector3.new(0, nudgeY, 0)

            rf:InvokeServer(1, aimPos, "AH2")
        end)
    end

    character.ChildAdded:Connect(function(child)
        if child.Name == "Gun" then tryBindGun() end
    end)
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Gun" then disconnectShoot() end
    end)

    tryBindGun()
end

if LocalPlayer.Character then onCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacter)

G.CRIMSON_AUTO_SHOOT.enable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = true
end
G.CRIMSON_AUTO_SHOOT.disable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = false
    disconnectShoot()
end
