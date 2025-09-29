local players = game:GetService("Players")
local lp = players.LocalPlayer
local char = lp.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")

if not (char and humanoid) then return end

local knife = lp.Backpack:FindFirstChild("Knife") or char:FindFirstChild("Knife")

if not knife then return end

if knife.Parent == lp.Backpack then
    humanoid:EquipTool(knife)
    knife = char:WaitForChild("Knife", 2)
    if not knife then return end
end

local throw = knife:FindFirstChild("Throw")
if not throw then return end

while knife and knife.Parent == char do
    local targetsFound = false
    for i, v in ipairs(players:GetPlayers()) do
        local targetChar = v.Character
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        
        if v ~= lp and targetHum and targetHum.Health > 0 then
            targetsFound = true
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local args = {
                    char.HumanoidRootPart.CFrame,
                    targetRoot.Position
                }
                throw:FireServer(unpack(args))
                task.wait()
            end
        end
    end
    
    if not targetsFound then
        break
    end
    
    task.wait(0.5)
end
