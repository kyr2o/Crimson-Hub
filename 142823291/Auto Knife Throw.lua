local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { 
    enabled = false, 
    prediction = 0.14,
    autoCalibrate = true,
    lastCalibrationTime = 0,
    calibrationInterval = 0.5 -- Update every 0.5 seconds
}

-- Known optimal prediction values (ping -> prediction mapping)
local PING_PREDICTION_MAP = {
    {ping = 10, pred = 0.110},
    {ping = 20, pred = 0.115},
    {ping = 30, pred = 0.118},
    {ping = 40, pred = 0.12},
    {ping = 50, pred = 0.122},
    {ping = 60, pred = 0.124},
    {ping = 70, pred = 0.126},
    {ping = 80, pred = 0.128},
    {ping = 90, pred = 0.132},
    {ping = 100, pred = 0.137},
    {ping = 110, pred = 0.142},
    {ping = 120, pred = 0.147},
    {ping = 130, pred = 0.150},
    {ping = 140, pred = 0.152},
    {ping = 150, pred = 0.154},
    {ping = 160, pred = 0.156},
    {ping = 170, pred = 0.158},
    {ping = 180, pred = 0.159},
    {ping = 190, pred = 0.162},
    {ping = 200, pred = 0.165},
    {ping = 210, pred = 0.168},
    {ping = 220, pred = 0.171},
    {ping = 250, pred = 0.180},
    {ping = 300, pred = 0.195},
}

-- Linear interpolation helper
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Calculate prediction from ping using interpolation
local function __mm2_pred_from_ping(ms)
    if not ms or ms ~= ms then return 0.14 end
    
    -- Clamp to reasonable range
    ms = math.clamp(ms, 10, 350)
    
    -- Find the two closest ping values
    local lower, upper
    for i = 1, #PING_PREDICTION_MAP do
        local entry = PING_PREDICTION_MAP[i]
        if ms <= entry.ping then
            if i == 1 then
                return entry.pred
            end
            lower = PING_PREDICTION_MAP[i - 1]
            upper = entry
            break
        end
    end
    
    -- If ping is higher than max mapped value, use the last one
    if not lower then
        return PING_PREDICTION_MAP[#PING_PREDICTION_MAP].pred
    end
    
    -- Interpolate between the two closest values
    local t = (ms - lower.ping) / (upper.ping - lower.ping)
    local interpolatedPred = lerp(lower.pred, upper.pred, t)
    
    -- Round to 7 decimal places for precision (like 0.1444086)
    return math.floor(interpolatedPred * 10000000 + 0.5) / 10000000
end

-- Get current ping in milliseconds
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

-- Manual calibration function (still available)
G.CRIMSON_AUTO_SHOOT.calibrate = function()
    local ms = __mm2_ping_ms()
    local pred = __mm2_pred_from_ping(ms)
    G.CRIMSON_AUTO_SHOOT.prediction = pred
    return ms, pred
end

-- Auto-calibration loop
local autoCalibrationConnection
local function startAutoCalibration()
    if autoCalibrationConnection then
        autoCalibrationConnection:Disconnect()
    end
    
    autoCalibrationConnection = RunService.Heartbeat:Connect(function()
        if not G.CRIMSON_AUTO_SHOOT.autoCalibrate then return end
        
        local currentTime = tick()
        if currentTime - G.CRIMSON_AUTO_SHOOT.lastCalibrationTime >= G.CRIMSON_AUTO_SHOOT.calibrationInterval then
            local ms = __mm2_ping_ms()
            local pred = __mm2_pred_from_ping(ms)
            G.CRIMSON_AUTO_SHOOT.prediction = pred
            G.CRIMSON_AUTO_SHOOT.lastCalibrationTime = currentTime
        end
    end)
end

-- Compatibility aliases
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

-- Start auto-calibration
startAutoCalibration()

G.CRIMSON_AUTO_SHOOT.enable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = true
end

G.CRIMSON_AUTO_SHOOT.disable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = false
    disconnectShoot()
end

G.CRIMSON_AUTO_SHOOT.toggleAutoCalibrate = function(state)
    if state ~= nil then
        G.CRIMSON_AUTO_SHOOT.autoCalibrate = state
    else
        G.CRIMSON_AUTO_SHOOT.autoCalibrate = not G.CRIMSON_AUTO_SHOOT.autoCalibrate
    end
    return G.CRIMSON_AUTO_SHOOT.autoCalibrate
end

G.CRIMSON_AUTO_SHOOT.setCalibrationInterval = function(seconds)
    G.CRIMSON_AUTO_SHOOT.calibrationInterval = math.max(0.1, seconds)
end

-- Debug function to see current stats
G.CRIMSON_AUTO_SHOOT.getStats = function()
    local ping = __mm2_ping_ms()
    return {
        ping = ping,
        prediction = G.CRIMSON_AUTO_SHOOT.prediction,
        autoCalibrate = G.CRIMSON_AUTO_SHOOT.autoCalibrate,
        enabled = G.CRIMSON_AUTO_SHOOT.enabled
    }
end
