local G = (getgenv and getgenv()) or _G
G.CRIMSON = G.CRIMSON or { ok = false }

local players = game:GetService("Players")
local lp = players.LocalPlayer

local function run()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
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
        for _, v in ipairs(players:GetPlayers()) do
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
end

if G.CRIMSON.ok == true then
    run()
else

    if G.CRIMSON.Event and G.CRIMSON.Event.Event then
        local conn
        conn = G.CRIMSON.Event.Event:Connect(function(ok)
            if ok == true then
                if conn then conn:Disconnect() end
                run()
            end
        end)
    end
    return
end
