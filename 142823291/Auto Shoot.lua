local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.15 }

local shootConnection

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
            local murderer = findMurderer()
            local root = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0
                local aimPos = root.Position + (root.Velocity * pred)
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
