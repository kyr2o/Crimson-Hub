local marker = game:GetService("CoreGui"):FindFirstChild("_cr1m50n__kv_ok__7F2B1D")
if not marker then return end
local G = (getgenv and getgenv()) or _G
if not (G.CRIMSON and G.CRIMSON.ok == true) then
    return
end

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local function findGun(char)
    if not char then return nil end
    local g = char:FindFirstChild("Gun")
    if g then return g end
    return char:FindFirstChild("Gun", true)
end

local function runGunLoop(char)
    local gun = findGun(char)
    if not gun then return end
    local shoot = gun:FindFirstChild("ShootGun", true)
    if not shoot then return end

    while shoot and shoot.Parent and gun and gun.Parent and char and char.Parent do
        shoot:InvokeServer(1, 0, "AH2")
        runService.Heartbeat:Wait()
    end
end

local function getCharacter()
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    if not char:FindFirstChild("HumanoidRootPart") then
        char:WaitForChild("HumanoidRootPart", 5)
    end
    return char
end

runGunLoop(getCharacter())

localPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.25)
    if G.CRIMSON and G.CRIMSON.ok == true then
        runGunLoop(char)
    end
end)
