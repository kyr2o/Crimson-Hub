local CoreGui = game:GetService("CoreGui")
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"

if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local players = game:GetService("Players")
local runService = game:GetService("RunService")

local gun = nil
for _, p in ipairs(players:GetPlayers()) do
    if p.Character then
        local g = p.Character:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun", true)
        if g then
            gun = g
            break
        end
    end
end

if gun then
    local shoot = gun:FindFirstChild("ShootGun", true)
    if shoot then
        while shoot and shoot.Parent do
            shoot:InvokeServer(1, 0, "AH2")
            runService.Heartbeat:Wait()
        end
    end
end
