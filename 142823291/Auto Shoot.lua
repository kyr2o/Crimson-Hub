local players = game:GetService("Players")
local runService = game:GetService("RunService")
local stats = game:GetService("Stats")
local localPlayer = players.LocalPlayer

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or {
    enabled = false,
    prediction = 0.14,
    auto_ping = false
}

local shootConnection

local function readPingMs()
    local ok, val = pcall(function()
        local item = stats.Network.ServerStatsItem["Data Ping"]
        return item and item:GetValue() or nil
    end)
    if ok and type(val) == "number" then return val end

    ok, val = pcall(function()
        local item = stats.Network.ServerStatsItem["Ping"]
        return item and item:GetValue() or nil
    end)
    if ok and type(val) == "number" then return val end

    return 120 
end

local function pingToPrediction(ms)

    ms = math.clamp(ms, 20, 300)

    if ms <= 40 then
        return 0.05 + (ms-20) * (0.02/20)
    elseif ms <= 70 then
        return 0.07 + (ms-40) * (0.03/30)
    elseif ms <= 100 then
        return 0.10 + (ms-70) * (0.03/30)
    elseif ms <= 120 then
        return 0.13 + (ms-100) * (0.01/20)
    elseif ms <= 150 then
        return 0.14 + (ms-120) * (0.01/30)
    elseif ms <= 200 then
        return 0.15 + (ms-150) * (0.03/50)
    else
        return 0.18 + (ms-200) * (0.05/100)
    end
end

local function findMurderer()
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local bp = player:FindFirstChild("Backpack")
            if bp and bp:FindFirstChild("Knife") then
                return player
            end
            if player.Character:FindFirstChild("Knife") then
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

    local backpack = localPlayer:WaitForChild("Backpack", 5)
    if not backpack then return end

    local function tryBindGun()
        local gun = character:FindFirstChild("Gun") or backpack:FindFirstChild("Gun")
        if not gun then return end

        local rf = gun:FindFirstChild("KnifeLocal") and gun.KnifeLocal:FindFirstChild("CreateBeam") and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
        if not rf then return end

        if shootConnection then shootConnection:Disconnect() end
        shootConnection = runService.Heartbeat:Connect(function()
            if not G.CRIMSON_AUTO_SHOOT.enabled then return end
            if not character:FindFirstChild("Gun") then return end

            if G.CRIMSON_AUTO_SHOOT.auto_ping then
                local ping = readPingMs()
                G.CRIMSON_AUTO_SHOOT.prediction = pingToPrediction(ping)
            end

            local murderer = findMurderer()
            local root = murderer and murderer.Character and (murderer.Character:FindFirstChild("UpperTorso") or murderer.Character:FindFirstChild("HumanoidRootPart"))
            if root then
                local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0.12
                local vel = root.AssemblyLinearVelocity or root.Velocity
                local aimPos = root.Position + (vel * pred)
                rf:InvokeServer(1, aimPos, "AH2")
            end
        end)
    end

    character.ChildAdded:Connect(function(child)
        if child.Name == "Gun" then
            tryBindGun()
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Gun" then
            disconnectShoot()
        end
    end)

    tryBindGun()
end

if localPlayer.Character then
    onCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacter)

G.CRIMSON_AUTO_SHOOT.enable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = true
end
G.CRIMSON_AUTO_SHOOT.disable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = false
    disconnectShoot()
end

G.CRIMSON_AUTO_SHOOT.set_auto_ping = function(state)
    G.CRIMSON_AUTO_SHOOT.auto_ping = state and true or false
end

G.CRIMSON_AUTO_SHOOT.snap_prediction_from_ping = function()
    local ping = readPingMs()
    local pred = pingToPrediction(ping)
    G.CRIMSON_AUTO_SHOOT.prediction = pred
    return ping, pred
end
