local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or {
    enabled = false,
    prediction = 0.14,
    gravity = Workspace.Gravity or 196.2,
    jumpPower = 50,
    fallCompensation = 1.2
}

local function __mm2_pred_from_ping(ms)
    if not ms or ms ~= ms then return 0.14 end
    if ms <= 40  then return 0.12 end
    if ms <= 60  then return 0.125 end
    if ms <= 80  then return 0.13 end
    if ms <= 100 then return 0.135 end
    if ms <= 120 then return 0.14 end
    if ms <= 150 then return 0.145 end
    if ms <= 180 then return 0.15 end
    if ms <= 220 then return 0.155 end
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
    if success and result then return result end
    local success2, result2 = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    if success2 and result2 then
        local num = tonumber(result2:match("%d+%.?%d*"))
        if num then return math.floor(num + 0.5) end
    end
    return 140
end

local function getPlayerMovementStats(player)
    local jumpPower = G.CRIMSON_AUTO_SHOOT.jumpPower
    local gravity = Workspace.Gravity or G.CRIMSON_AUTO_SHOOT.gravity
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            if typeof(humanoid.JumpPower) == "number" and humanoid.JumpPower > 0 then
                jumpPower = humanoid.JumpPower
            elseif typeof(humanoid.JumpHeight) == "number" and humanoid.JumpHeight > 0 then
                jumpPower = humanoid.JumpHeight * 2
            end
        end
    end
    return jumpPower, gravity
end

local function calculateVerticalPrediction(target, predictionTime)
    local predTime = predictionTime or G.CRIMSON_AUTO_SHOOT.prediction or 0.14
    local jumpPower, gravity = getPlayerMovementStats(target)
    local root = target.Character and target.Character:FindFirstChild("UpperTorso")
    if not root then
        return Vector3.new(0, 0, 0)
    end

    local pos0 = root.Position
    local vel = root.Velocity
    local vy = vel.Y

    if vy < -10 then
        predTime = predTime * (G.CRIMSON_AUTO_SHOOT.fallCompensation or 1)
    end

    local yPred = pos0.Y + (vy * predTime) - (0.5 * gravity * predTime * predTime)

    local speed = math.abs(vy)
    local offsetY = 0.1  

    if vy > 2 then
        if speed > jumpPower * 0.8 then
            offsetY = 2.0
        elseif speed > jumpPower * 0.5 then
            offsetY = 1.5
        elseif speed > jumpPower * 0.2 then
            offsetY = 0.8
        else
            offsetY = 0.2
        end
    elseif vy < -2 then
        if speed > jumpPower * 0.8 then
            offsetY = -2.5
        elseif speed > jumpPower * 0.5 then
            offsetY = -2.0
        elseif speed > jumpPower * 0.2 then
            offsetY = -1.0
        else
            offsetY = -0.3
        end
    end

    local horizVel = Vector3.new(vel.X, 0, vel.Z)
    local xyPred = Vector3.new(pos0.X, yPred, pos0.Z) + (horizVel * predTime)
    return Vector3.new(xyPred.X, yPred, xyPred.Z) + Vector3.new(0, offsetY, 0)
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

local function findMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local bp = p:FindFirstChild("Backpack")
            if (bp and bp:FindFirstChild("Knife")) or p.Character:FindFirstChild("Knife") then
                return p
            end
        end
    end
end

local function disconnectShoot()
    if shootConnection then
        shootConnection:Disconnect()
        shootConnection = nil
    end
end

local function bindForCharacter(char)
    disconnectShoot()
    local backpack = LocalPlayer:WaitForChild("Backpack", 5)
    if not backpack then return end

    local function tryBind()
        local gun = char:FindFirstChild("Gun") or backpack:FindFirstChild("Gun")
        if not gun then return end
        local rf = gun:FindFirstChild("KnifeLocal")
            and gun.KnifeLocal:FindFirstChild("CreateBeam")
            and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
        if not rf then return end

        shootConnection = RunService.Heartbeat:Connect(function()
            if not G.CRIMSON_AUTO_SHOOT.enabled then return end
            if not char:FindFirstChild("Gun") then return end
            local murderer = findMurderer()
            if not murderer or not murderer.Character then return end
            local aimPos = calculateVerticalPrediction(murderer, G.CRIMSON_AUTO_SHOOT.prediction)
            rf:InvokeServer(1, aimPos, "AH2")
        end)
    end

    char.ChildAdded:Connect(function(c) if c.Name == "Gun" then tryBind() end end)
    char.ChildRemoved:Connect(function(c) if c.Name == "Gun" then disconnectShoot() end end)
    tryBind()
end

if LocalPlayer.Character then bindForCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindForCharacter)

G.CRIMSON_AUTO_SHOOT.enable = function() G.CRIMSON_AUTO_SHOOT.enabled = true end
G.CRIMSON_AUTO_SHOOT.disable = function() G.CRIMSON_AUTO_SHOOT.enabled = false; disconnectShoot() end

G.CRIMSON_AUTO_SHOOT.setGravity         = function(g) G.CRIMSON_AUTO_SHOOT.gravity = g or G.CRIMSON_AUTO_SHOOT.gravity end
G.CRIMSON_AUTO_SHOOT.setJumpPower       = function(j) G.CRIMSON_AUTO_SHOOT.jumpPower = j or G.CRIMSON_AUTO_SHOOT.jumpPower end
G.CRIMSON_AUTO_SHOOT.setFallCompensation = function(f) G.CRIMSON_AUTO_SHOOT.fallCompensation = f or G.CRIMSON_AUTO_SHOOT.fallCompensation end
