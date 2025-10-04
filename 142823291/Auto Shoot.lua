-- Auto Shoot Script (Logic and Hub Hooks)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Register calibrators early and on both globals the hub may check
local Stats = game:GetService("Stats")
local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }

local function __mm2_pred_from_ping(ms)
    if not ms or ms ~= ms then return 0.14 end
    if ms <= 40  then return 0.06 end
    if ms <= 60  then return 0.08 end
    if ms <= 80  then return 0.10 end
    if ms <= 100 then return 0.12 end
    if ms <= 120 then return 0.135 end
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

-- Primary API the hub should call
G.CRIMSON_AUTO_SHOOT.calibrate = function()
    local ms = __mm2_ping_ms()
    local pred = __mm2_pred_from_ping(ms)
    G.CRIMSON_AUTO_SHOOT.prediction = pred
    return ms, pred
end

-- Alias some common names hubs use
G.CalibrateAutoShoot = G.CRIMSON_AUTO_SHOOT.calibrate
G.CRIMSON_CalibrateShoot = G.CRIMSON_AUTO_SHOOT.calibrate

-- Auto Shoot Core Logic
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
            local root = murderer and murderer.Character and murderer.Character:FindFirstChild("UpperTorso")
            
            if root then
                local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0
                local aimPos = root.Position + (root.Velocity * pred)
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
