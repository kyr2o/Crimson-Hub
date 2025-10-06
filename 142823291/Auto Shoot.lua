local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }

local GRAVITY = workspace.Gravity or 196.2

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

local function findMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local bp = player:FindFirstChild("Backpack")
            if (bp and bp:FindFirstChild("Knife")) or player.Character:FindFirstChild("Knife") then
                return player
            end
        end
    end
    return nil
end

-- Calculate vertical aim offset based on movement
local function calculateVerticalAimOffset(targetRoot, targetHumanoid, predTime)
    local velocity = targetRoot.Velocity
    local verticalVel = velocity.Y
    
    -- Get jump power (default to 50 if not accessible)
    local jumpPower = 50
    if targetHumanoid and targetHumanoid:FindFirstChild("JumpPower") then
        jumpPower = targetHumanoid.JumpPower
    elseif targetHumanoid and targetHumanoid:FindFirstChild("JumpHeight") then
        -- Convert JumpHeight to JumpPower equivalent
        jumpPower = math.sqrt(2 * GRAVITY * targetHumanoid.JumpHeight)
    end
    
    -- Calculate predicted vertical position change
    -- Using kinematic equation: y = v*t - 0.5*g*t^2
    local verticalDisplacement = (verticalVel * predTime) - (0.5 * GRAVITY * predTime * predTime)
    
    -- Determine aim adjustment based on vertical movement
    local aimOffset = Vector3.new(0, 0, 0)
    local absVerticalVel = math.abs(verticalVel)
    
    -- Ascending (moving upward)
    if verticalVel > 2 then
        -- Calculate how much of jump they've completed
        local jumpProgress = verticalVel / jumpPower
        
        if jumpProgress > 0.5 then
            -- Early ascent - aim higher (head region)
            aimOffset = Vector3.new(0, 1.5, 0)
        elseif jumpProgress > 0.2 then
            -- Mid ascent - aim for upper torso
            aimOffset = Vector3.new(0, 0.8, 0)
        else
            -- Late ascent (slowing down) - aim for torso
            aimOffset = Vector3.new(0, 0.3, 0)
        end
        
    -- Descending (falling down)
    elseif verticalVel < -2 then
        local descendSpeed = math.abs(verticalVel)
        
        if descendSpeed > 40 then
            -- Fast descent - aim much lower (legs/feet)
            aimOffset = Vector3.new(0, -1.8, 0)
        elseif descendSpeed > 20 then
            -- Moderate descent - aim for legs
            aimOffset = Vector3.new(0, -1.2, 0)
        else
            -- Slow descent - aim for lower torso
            aimOffset = Vector3.new(0, -0.5, 0)
        end
        
    -- On ground or minimal vertical movement
    else
        aimOffset = Vector3.new(0, 0, 0)
    end
    
    return aimOffset
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
            if not murderer or not murderer.Character then return end
            
            local root = murderer.Character:FindFirstChild("UpperTorso") or murderer.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = murderer.Character:FindFirstChild("Humanoid")

            if root then
                local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0.14
                
                -- Calculate vertical aim adjustment
                local verticalOffset = Vector3.new(0, 0, 0)
                if humanoid then
                    verticalOffset = calculateVerticalAimOffset(root, humanoid, pred)
                end
                
                -- Predict horizontal movement
                local horizontalPrediction = root.Velocity * pred
                
                -- Combine base position, horizontal prediction, and vertical aim offset
                local aimPos = root.Position + horizontalPrediction + verticalOffset
                
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
