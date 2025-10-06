local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Stats       = game:GetService("Stats")
local Workspace   = game:GetService("Workspace")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or {
    enabled          = false,
    prediction       = 0.14,
    gravity          = 196.2,
    jumpPower        = 50,
    fallCompensation = 1.35,
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

-- Completely recoded vertical prediction with nil safety
local function calculateVerticalPrediction(target, predictionTime)
    -- Validate inputs
    if not target or not target.Character then
        return nil
    end
    
    local root = target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end
    
    -- Safe defaults
    local pred = tonumber(predictionTime) or tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0.14
    local grav = tonumber(Workspace.Gravity) or tonumber(G.CRIMSON_AUTO_SHOOT.gravity) or 196.2
    
    -- Get humanoid for jump power
    local humanoid = target.Character:FindFirstChild("Humanoid")
    local jumpPow = tonumber(G.CRIMSON_AUTO_SHOOT.jumpPower) or 50
    
    if humanoid then
        local jp = tonumber(humanoid.JumpPower)
        local jh = tonumber(humanoid.JumpHeight)
        if jp and jp > 0 then
            jumpPow = jp
        elseif jh and jh > 0 then
            jumpPow = jh * 2
        end
    end
    
    -- Get current position and velocity safely
    local pos = root.Position or Vector3.new(0,0,0)
    local vel = root.Velocity or Vector3.new(0,0,0)
    
    local vx = tonumber(vel.X) or 0
    local vy = tonumber(vel.Y) or 0
    local vz = tonumber(vel.Z) or 0
    
    -- Adjust prediction time for falling
    local adjustedPred = pred
    if vy < -10 then
        local comp = tonumber(G.CRIMSON_AUTO_SHOOT.fallCompensation) or 1.35
        adjustedPred = pred * comp
    end
    
    -- Predict horizontal position
    local futureX = pos.X + (vx * adjustedPred)
    local futureZ = pos.Z + (vz * adjustedPred)
    
    -- Predict vertical position with gravity
    -- Formula: y = y0 + vy*t - 0.5*g*t^2
    local futureY = pos.Y + (vy * adjustedPred) - (0.5 * grav * adjustedPred * adjustedPred)
    
    -- Calculate aim offset based on vertical movement
    local offsetY = 0
    local speed = math.abs(vy)
    
    -- Ascending (jumping up)
    if vy > 2 then
        if speed > jumpPow * 0.8 then
            offsetY = 2.0
        elseif speed > jumpPow * 0.5 then
            offsetY = 1.5
        elseif speed > jumpPow * 0.2 then
            offsetY = 0.8
        else
            offsetY = 0.2
        end
    -- Descending (falling down)
    elseif vy < -2 then
        if speed > jumpPow * 0.8 then
            offsetY = -2.5
        elseif speed > jumpPow * 0.5 then
            offsetY = -2.0
        elseif speed > jumpPow * 0.2 then
            offsetY = -1.0
        else
            offsetY = -0.5
        end
    else
        offsetY = 0.1
    end
    
    -- Return final predicted position
    return Vector3.new(futureX, futureY + offsetY, futureZ)
end

-- Calibration
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
    return nil
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

        if shootConnection then shootConnection:Disconnect() end
        
        shootConnection = RunService.Heartbeat:Connect(function()
            if not G.CRIMSON_AUTO_SHOOT.enabled then return end
            if not char:FindFirstChild("Gun") then return end
            
            local murderer = findMurderer()
            if not murderer then return end
            
            local aimPos = calculateVerticalPrediction(murderer, G.CRIMSON_AUTO_SHOOT.prediction)
            if aimPos then
                pcall(function()
                    rf:InvokeServer(1, aimPos, "AH2")
                end)
            end
        end)
    end

    char.ChildAdded:Connect(function(c)
        if c.Name == "Gun" then
            tryBind()
        end
    end)
    
    char.ChildRemoved:Connect(function(c)
        if c.Name == "Gun" then
            disconnectShoot()
        end
    end)
    
    tryBind()
end

if LocalPlayer.Character then
    bindForCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(bindForCharacter)

-- Control functions
G.CRIMSON_AUTO_SHOOT.enable  = function()
    G.CRIMSON_AUTO_SHOOT.enabled = true
end

G.CRIMSON_AUTO_SHOOT.disable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = false
    disconnectShoot()
end

-- Configuration setters
G.CRIMSON_AUTO_SHOOT.setGravity = function(g)
    G.CRIMSON_AUTO_SHOOT.gravity = tonumber(g) or 196.2
end

G.CRIMSON_AUTO_SHOOT.setJumpPower = function(j)
    G.CRIMSON_AUTO_SHOOT.jumpPower = tonumber(j) or 50
end

G.CRIMSON_AUTO_SHOOT.setFallCompensation = function(f)
    G.CRIMSON_AUTO_SHOOT.fallCompensation = tonumber(f) or 1.35
end
