local CoreGui = game:GetService("CoreGui")
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"

if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local G = (getgenv and getgenv()) or _G
G.CRIMSON = G.CRIMSON or { ok = false }

local players = game:GetService("Players")
local lp = players.LocalPlayer

local function run()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and humanoid) then return end

    local knife = (lp.Backpack and lp.Backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife")
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

        for _, v in ipairs(players:GetPlayers()) do
            if v ~= lp then
                local targetChar = v.Character
                local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                if targetHum and targetHum.Health > 0 then
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    if targetRoot and myRoot then
                        targetsFound = true
                        throw:FireServer(myRoot.CFrame, targetRoot.Position)
                        task.wait()
                    end
                end
            end
        end

        if not targetsFound then
            break
        end

        task.wait(0.5)
    end
end

run()
