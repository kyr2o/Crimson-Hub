local CoreGui = game:GetService("CoreGui")
local Players  = game:GetService("Players")
local RunService = game:GetService("RunService")
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"

if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local function notifyWaiting()
    local sg = CoreGui:FindFirstChild("RobloxGui") 
    local ok, fn = pcall(function() return getgenv and getgenv().sendNotification end)
    if ok and typeof(fn) == "function" then
        pcall(function() fn("Crimson Hub", "Waiting for Sheriff to Equip Gun", 2, "info") end)
    else

        local ok2, fn2 = pcall(function() return _G and _G.sendNotification end)
        if ok2 and typeof(fn2) == "function" then
            pcall(function() fn2("Crimson Hub", "Waiting for Sheriff to Equip Gun", 2, "info") end)
        end
    end
end

local function isAlive(plr)
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return false end
    if c:GetAttribute("Alive") == false then return false end
    return h.Health > 0
end

local function getSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local gunInChar = p.Character:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun", true)
            local backpack = p:FindFirstChild("Backpack")
            local gunInPack = backpack and backpack:FindFirstChild("Gun")
            if gunInChar or gunInPack then
                return p
            end
        end
    end
    return nil
end

local function waitForSheriffEquipped(sheriff)
    if not (sheriff and isAlive(sheriff)) then return nil end

    notifyWaiting()

    local diedConn
    local function died()
        if diedConn then diedConn:Disconnect() end
        diedConn = nil
    end
    local char = sheriff.Character or sheriff.CharacterAdded:Wait()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        diedConn = hum.Died:Connect(died)
    end

    while sheriff and isAlive(sheriff) do
        char = sheriff.Character
        if not char then sheriff.CharacterAdded:Wait() end
        char = sheriff.Character
        if not char then break end
        local gunEquipped = char:FindFirstChild("Gun") or char:FindFirstChild("Gun", true)
        if gunEquipped then
            if diedConn then diedConn:Disconnect() end
            return gunEquipped
        end
        RunService.Heartbeat:Wait()
    end

    if diedConn then diedConn:Disconnect() end
    return nil
end

local function run()

    local sheriff = getSheriff()
    if not sheriff then return end
    if not isAlive(sheriff) then return end

    local equippedGun = waitForSheriffEquipped(sheriff)
    if not equippedGun then return end

    local shoot = equippedGun:FindFirstChild("ShootGun", true)
    if not shoot then return end

    while shoot and shoot.Parent and sheriff and isAlive(sheriff) do
        shoot:InvokeServer(1, 0, "AH2")
        RunService.Heartbeat:Wait()
    end
end

run()
