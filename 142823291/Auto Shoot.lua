local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }

local function __mm2_pred_from_ping(ms)
    if not ms or ms ~= ms then return 0.14 end
    if ms <= 40  then return 0.12 end
    if ms <= 60  then return 0.124 end
    if ms <= 80  then return 0.128 end
    if ms <= 100 then return 0.137 end
    if ms <= 120 then return 0.147 end
    if ms <= 150 then return 0.154 end
    if ms <= 180 then return 0.159 end
    if ms <= 220 then return 0.166 end
    return 0.21
end

local function __mm2_ping_ms()
    local success, result = pcall(function()
        local net = Stats:FindFirstChild("Network")
        if not net then return nil end

        local serverStats = net:FindFirstChild("ServerStatsItem")
        if not serverStats then return nil end

        local dataPing = serverStats:FindFirstChild("Data Ping")
        if not dataPing then return nil end

        local value = dataPing:GetValue()
        if not value then return nil end

        if value < 1 then
            return math.floor(value * 1000 + 0.5)
        else
            return math.floor(value + 0.5)
        end
    end)

    if success and result then
        return result
    end

    local success2, result2 = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)

    if success2 and result2 then
        local num = tonumber(result2:match("%d+%.?%d*"))
        if num then
            return math.floor(num + 0.5)
        end
    end

    return 140
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

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function getVel(part)
    if not part then return Vector3.zero end

    local ok, v = pcall(function() return part.AssemblyLinearVelocity end)
    if ok and v then return v end
    return part.Velocity
end

local function isInAir(humanoid)
    if not humanoid then return false end
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
end

local function getJumpV0(humanoid)

    local g = Workspace.Gravity
    if humanoid and humanoid.UseJumpPower then
        local jp = humanoid.JumpPower or 50
        return math.max(jp, 1)
    else
        local jh = (humanoid and humanoid.JumpHeight) or 7.2
        return math.sqrt(math.max(2 * g * math.max(jh, 0.1), 1))
    end
end

local function findPart(character, names)
    for _, n in ipairs(names) do
        local p = character:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            return p
        end
    end
    return nil
end

local function pickAimPart(character, vy, v0, groundedDefaultToHead)

    local head = findPart(character, {"Head"})
    local lowerTorso = findPart(character, {"LowerTorso", "Torso"})
    local upperTorso = findPart(character, {"UpperTorso", "Torso"})
    local leftLowerLeg = findPart(character, {"LeftLowerLeg", "Left Leg"})
    local rightLowerLeg = findPart(character, {"RightLowerLeg", "Right Leg"})
    local root = findPart(character, {"HumanoidRootPart"})

    local fast = 0.6 * v0
    local slow = 0.2 * v0

    if vy > fast then
        return head or upperTorso or lowerTorso or root
    elseif vy > slow then
        return lowerTorso or upperTorso or head or root
    elseif vy < -slow then

        return leftLowerLeg or rightLowerLeg or lowerTorso or upperTorso or head or root
    else

        return lowerTorso or upperTorso or head or root
    end
end

local function computePredictedAimPos(part, t, doVerticalBallistics)
    if not part then return nil end
    local pos0 = part.Position
    local v = getVel(part)

    local x = pos0.X + v.X * t
    local z = pos0.Z + v.Z * t

    local y
    if doVerticalBallistics then
        local g = Workspace.Gravity
        y = pos0.Y + v.Y * t - 0.5 * g * t * t
    else
        y = pos0.Y
    end

    return Vector3.new(x, y, z)
end

local function findMurderer()
    local lp = LocalPlayer
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local bp = player:FindFirstChild("Backpack")
            if (bp and bp:FindFirstChild("Knife")) or player.Character:FindFirstChild("Knife") then
                return player
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
            local mchar = murderer and murderer.Character
            if not mchar then return end

            local hum = getHumanoid(mchar)
            local inAir = isInAir(hum)
            local v0 = getJumpV0(hum)

            local head = mchar:FindFirstChild("Head")
            local baseAimPart
            if inAir then

                local torsoRef = findPart(mchar, {"UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}) or head
                local vy = torsoRef and getVel(torsoRef).Y or 0
                baseAimPart = pickAimPart(mchar, vy, v0, false)
            else
                baseAimPart = head or findPart(mchar, {"UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"})
            end
            if not baseAimPart then return end

            local t = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0.14

            local aimPos = computePredictedAimPos(baseAimPart, t, inAir)

            if aimPos then

                rf:InvokeServer(1, aimPos, "AH2")
            end
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
