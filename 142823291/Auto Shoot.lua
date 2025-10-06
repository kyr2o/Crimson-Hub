local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Stats       = game:GetService("Stats")
local Workspace   = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or {
    enabled          = false,
    prediction       = 0.14,
    gravity          = Workspace.Gravity or 196.2,
    jumpPower        = 50,
    fallCompensation = 1.2,
}

local function __mm2_pred_from_ping(ms)
    if not ms or ms ~= ms then return 0.14 end
    if ms <= 40  then return 0.12  end
    if ms <= 60  then return 0.125 end
    if ms <= 80  then return 0.13  end
    if ms <= 100 then return 0.135 end
    if ms <= 120 then return 0.14  end
    if ms <= 150 then return 0.145 end
    if ms <= 180 then return 0.15  end
    if ms <= 220 then return 0.155 end
    return 0.21
end

local function __mm2_ping_ms()
    local success, result = pcall(function()
        local net = Stats:FindFirstChild("Network")
        local item = net and net:FindFirstChild("ServerStatsItem")
        local data = item and item:FindFirstChild("Data Ping")
        local v = data and data:GetValue()
        if not v then return nil end
        return math.floor((v < 1 and v*1000 or v) + 0.5)
    end)
    if success and result then return result end
    local success2, res2 = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    if success2 and res2 then
        local num = tonumber(res2:match("%d+%.?%d*"))
        if num then return math.floor(num + 0.5) end
    end
    return 140
end

-- Retrieve numeric jumpPower & gravity
local function getPlayerMovementStats(player)
    local jp = G.CRIMSON_AUTO_SHOOT.jumpPower or 50
    local g  = Workspace.Gravity or G.CRIMSON_AUTO_SHOOT.gravity or 196.2
    if player and player.Character then
        local h = player.Character:FindFirstChild("Humanoid")
        if h then
            if typeof(h.JumpPower) == "number" and h.JumpPower > 0 then
                jp = h.JumpPower
            elseif typeof(h.JumpHeight) == "number" and h.JumpHeight > 0 then
                jp = h.JumpHeight * 2
            end
        end
    end
    return jp, g
end

-- Predicts future position with vertical motion
local function calculateVerticalPrediction(target, predictionTime)
    local pt  = predictionTime or G.CRIMSON_AUTO_SHOOT.prediction or 0.14
    local jp, g = getPlayerMovementStats(target)
    local root = target.Character and target.Character:FindFirstChild("UpperTorso")
    if not root then
        return Vector3.new(0,0,0)
    end

    local p0 = root.Position
    local v  = root.Velocity
    local vy = v.Y

    -- apply fall compensation safely
    if vy < -10 then
        local fc = G.CRIMSON_AUTO_SHOOT.fallCompensation or 1
        pt = pt * fc
    end

    -- kinematic vertical prediction
    local yPred = p0.Y + (vy * pt) - (0.5 * g * pt * pt)

    -- determine vertical aim offset
    local speed = math.abs(vy)
    local offsetY = 0.1

    if vy > 2 then
        if speed > jp * 0.8 then
            offsetY = 2.0
        elseif speed > jp * 0.5 then
            offsetY = 1.5
        elseif speed > jp * 0.2 then
            offsetY = 0.8
        else
            offsetY = 0.2
        end
    elseif vy < -2 then
        if speed > jp * 0.8 then
            offsetY = -2.5
        elseif speed > jp * 0.5 then
            offsetY = -2.0
        elseif speed > jp * 0.2 then
            offsetY = -1.0
        else
            offsetY = -0.3
        end
    end

    -- horizontal prediction
    local horiz = Vector3.new(v.X,0,v.Z) * pt
    local posH  = Vector3.new(p0.X, yPred, p0.Z) + horiz

    return Vector3.new(posH.X, yPred, posH.Z) + Vector3.new(0, offsetY, 0)
end

-- Calibration aliases
G.CRIMSON_AUTO_SHOOT.calibrate = function()
    local ms   = __mm2_ping_ms()
    local pred = __mm2_pred_from_ping(ms)
    G.CRIMSON_AUTO_SHOOT.prediction = pred
    return ms, pred
end
G.CalibrateAutoShoot = G.CRIMSON_AUTO_SHOOT.calibrate
G.CRIMSON_CalibrateShoot = G.CRIMSON_AUTO_SHOOT.calibrate

local LocalPlayer    = Players.LocalPlayer
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
            if murderer and murderer.Character then
                local aimPos = calculateVerticalPrediction(murderer, G.CRIMSON_AUTO_SHOOT.prediction)
                rf:InvokeServer(1, aimPos, "AH2")
            end
        end)
    end

    char.ChildAdded:Connect(function(c) if c.Name == "Gun" then tryBind() end end)
    char.ChildRemoved:Connect(function(c) if c.Name == "Gun" then disconnectShoot() end end)
    tryBind()
end

if LocalPlayer.Character then bindForCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindForCharacter)

G.CRIMSON_AUTO_SHOOT.enable  = function() G.CRIMSON_AUTO_SHOOT.enabled = true end
G.CRIMSON_AUTO_SHOOT.disable = function() G.CRIMSON_AUTO_SHOOT.enabled = false; disconnectShoot() end

-- setters
G.CRIMSON_AUTO_SHOOT.setGravity          = function(g) G.CRIMSON_AUTO_SHOOT.gravity          = g or G.CRIMSON_AUTO_SHOOT.gravity          end
G.CRIMSON_AUTO_SHOOT.setJumpPower        = function(j) G.CRIMSON_AUTO_SHOOT.jumpPower        = j or G.CRIMSON_AUTO_SHOOT.jumpPower        end
G.CRIMSON_AUTO_SHOOT.setFallCompensation = function(f) G.CRIMSON_AUTO_SHOOT.fallCompensation = f or G.CRIMSON_AUTO_SHOOT.fallCompensation end
