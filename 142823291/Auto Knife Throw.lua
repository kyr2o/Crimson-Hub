local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Environment = (getgenv and getgenv()) or _G
Environment.CRIMSON_AUTO_KNIFE = Environment.CRIMSON_AUTO_KNIFE or {
    enabled = true,
    silentKnifeEnabled = true 
}

local AllowedAnimationIds = { "rbxassetid://1957618848" }
local AnimationGateSeconds = 0.75

local KNIFE_SPEED = 63/0.85

local myCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRoot = myCharacter:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConnection

local trackStart = setmetatable({}, { __mode = "k" })

local function resolveKnife()
    local k = (localPlayer.Backpack and localPlayer.Backpack:FindFirstChild("Knife")) or (myCharacter and myCharacter:FindFirstChild("Knife"))
    if k ~= myKnife then
        myKnife = k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end

resolveKnife()
localPlayer.CharacterAdded:Connect(function(c)
    myCharacter = c
    myHumanoid = c:WaitForChild("Humanoid")
    myRoot = c:WaitForChild("HumanoidRootPart")
    trackStart = setmetatable({}, { __mode = "k" })
    task.defer(resolveKnife)
end)
if localPlayer:FindFirstChild("Backpack") then
    localPlayer.Backpack.ChildAdded:Connect(function(it) if it.Name == "Knife" then resolveKnife() end end)
    localPlayer.Backpack.ChildRemoved:Connect(function(it) if it == myKnife then resolveKnife() end end)
end
myCharacter.ChildAdded:Connect(function(it) if it.Name == "Knife" then resolveKnife() end end)
myCharacter.ChildRemoved:Connect(function(it) if it == myKnife then resolveKnife() end end)

local function throwAllowed()
    if not myHumanoid then return false end
    local now = os.clock()
    local ok = false
    for _, tr in ipairs(myHumanoid:GetPlayingAnimationTracks()) do
        local id = tr.Animation and tr.Animation.AnimationId or ""
        for _, a in ipairs(AllowedAnimationIds) do
            if id:find(a, 1, true) then
                if not trackStart[tr] then trackStart[tr] = now end
                if now - trackStart[tr] >= AnimationGateSeconds then ok = true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr) ~= "Instance" or not tr.IsPlaying then trackStart[tr] = nil end
    end
    return ok
end

local LimbOrder = {
    "HumanoidRootPart","UpperTorso","Head",
    "LeftArm","RightArm","LeftLowerArm","RightLowerArm","LeftHand","RightHand",
    "LeftLeg","RightLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"
}

local function getAimPart(ch)
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Head"))
end

local function isAlive(plr)
    local ch = plr and plr.Character
    if not ch then return false end
    local h = ch:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function pickTarget()
    local bestPlr, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and isAlive(p) then
            local ch = p.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if hrp then
                local v2, on = camera:WorldToViewportPoint(hrp.Position)
                local mx, my = localPlayer:GetMouse().X, localPlayer:GetMouse().Y
                local dist = on and (Vector2.new(v2.X, v2.Y) - Vector2.new(mx, my)).Magnitude or 9999
                local score = dist + (hrp.Position - myRoot.Position).Magnitude * 0.05
                if not bestScore or score < bestScore then
                    bestScore = score
                    bestPlr = p
                end
            end
        end
    end
    return bestPlr
end

local function ensureKnifeEquipped()
    resolveKnife()
    if not myKnife then return false end
    if myKnife.Parent ~= myCharacter then
        myHumanoid:EquipTool(myKnife)
        myKnife = myCharacter:WaitForChild("Knife", 1)
        if not myKnife then return false end
    end
    knifeRemote = myKnife:FindFirstChild("Throw")
    return knifeRemote ~= nil
end

local function silentThrowInstant()
    if not ensureKnifeEquipped() then return end

    local targetPlr = pickTarget()
    if not targetPlr or not isAlive(targetPlr) then return end

    local tch = targetPlr.Character
    local targetRoot = tch and tch:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local originCF = targetRoot.CFrame
    local targetPos = targetRoot.Position

    local handle = myKnife:FindFirstChild("Handle")
    if handle then
        handle.CFrame = originCF
    end

    knifeRemote:FireServer(originCF, targetPos)
    task.wait(0.03)
    knifeRemote:FireServer(originCF, targetPos)
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConnection then loopConnection:Disconnect(); loopConnection = nil end
        return
    end

    if Environment.CRIMSON_AUTO_KNIFE.silentKnifeEnabled then

        silentThrowInstant()
        return
    end
end

if loopConnection then loopConnection:Disconnect() end
loopConnection = RunService.Heartbeat:Connect(step)

Environment.CRIMSON_AUTO_KNIFE.enableSilentKnife = function() Environment.CRIMSON_AUTO_KNIFE.silentKnifeEnabled = true end
Environment.CRIMSON_AUTO_KNIFE.disableSilentKnife = function() Environment.CRIMSON_AUTO_KNIFE.silentKnifeEnabled = false end
