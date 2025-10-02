-- Break Gun (strictly gated by Crimson Hub verification + session)

local players = game:GetService("Players")
local runService = game:GetService("RunService")

local function run()
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

-- strict gate
local G = (getgenv and getgenv()) or _G
G.CRIMSON = G.CRIMSON or {}

-- generate a per-execution module session token
local mySession = tostring(math.random()) .. tostring(os.clock())

-- require hub to set CRIMSON.session to the same token before proceed
local function allowed()
    return (G.CRIMSON and G.CRIMSON.ok == true and G.CRIMSON.session == mySession) or false
end

-- if hub already verified this session, go
if allowed() then
    run()
else
    -- wait for hub and then check session match
    if G.CRIMSON and G.CRIMSON.Event and G.CRIMSON.Event.Event then
        local conn
        conn = G.CRIMSON.Event.Event:Connect(function(ok)
            if ok == true and allowed() then
                if conn then conn:Disconnect() end
                run()
            end
        end)
    end
end
