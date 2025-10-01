local g = (getgenv and getgenv()) or _G
g.CRIMSON = g.CRIMSON or { ok = false }

local function start()
    local players = game:GetService("Players")
    local runService = game:GetService("RunService")
    local gun = nil

    for _, p in ipairs(players:GetPlayers()) do
        if p.Character then
            local g = p.Character:FindFirstChild("Gun")
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
end

if g.CRIMSON.ok == true then
    start()
else

    if g.CRIMSON.Event and g.CRIMSON.Event.Event then
        local conn
        conn = g.CRIMSON.Event.Event:Connect(function(ok)
            if ok == true then
                if conn then conn:Disconnect() end
                start()
            end
        end)
    end
    return
end
