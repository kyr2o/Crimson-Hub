local CoreGui = game:GetService("CoreGui")
local Players  = game:GetService("Players")
local RunService = game:GetService("RunService")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local Shared = (getgenv and getgenv()) or _G
local notify = Shared.CRIMSON_NOTIFY 

local function isAlive(plr)
    local ch = plr.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if ch:GetAttribute("Alive") == false then return false end
    return hum.Health > 0
end

local function findSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer and p.Character and isAlive(p) then
            local ch = p.Character
            local backpack = p:FindFirstChild("Backpack")
            if ch:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
                return p
            end
        end
    end
    return nil
end

local function waitForSheriffGunEquipped(sheriff)
    local ch = sheriff.Character
    if not (ch and isAlive(sheriff)) then return false end

    if ch:FindFirstChild("Gun") then return true end

    if notify then pcall(function() notify("Break Gun", "Waiting for sheriff to equip gun…", 2, "info") end) end

    local hum = ch:FindFirstChildOfClass("Humanoid")
    local equipped = false
    local died = false
    local connAdded, connDied

    connAdded = ch.ChildAdded:Connect(function(inst)
        if inst and inst:IsA("Tool") and inst.Name == "Gun" then
            equipped = true
        end
    end)

    if hum then
        connDied = hum.Died:Connect(function() died = true end)
    end

    while not equipped and not died and isAlive(sheriff) do
        RunService.Heartbeat:Wait()
    end

    if connAdded then connAdded:Disconnect() end
    if connDied then connDied:Disconnect() end
    return equipped and isAlive(sheriff)
end

local function breakGunLoop(gun)
    local shoot = gun and gun:FindFirstChild("ShootGun", true)
    while shoot and shoot.Parent do

        shoot:InvokeServer(1, 0, "AH2")
        RunService.Heartbeat:Wait()
    end
end

local sheriff = findSheriff()
if not sheriff then return end
if not isAlive(sheriff) then return end

if not waitForSheriffGunEquipped(sheriff) then

    return
end

local ch = sheriff.Character
local gun = ch and (ch:FindFirstChild("Gun") or ch:FindFirstChild("Gun", true))
if gun then
    breakGunLoop(gun)
end
