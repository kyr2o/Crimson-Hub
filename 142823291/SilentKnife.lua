local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local localPlayer = Players.LocalPlayer
local Environment = (getgenv and getgenv()) or _G
Environment.CRIMSON_SILENT_KNIFE = Environment.CRIMSON_SILENT_KNIFE or { enabled = false }

local AllowedAnimationIds = { "rbxassetid://1957618848" }
local AnimationGateSeconds = 0.75
local UNEQUIP_DELAY = 0.05

local myCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRoot = myCharacter:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConnection
local trackStart = setmetatable({}, { __mode = "k" })
local pendingThrows = {}

local function resolveKnife()
    local k = (localPlayer.Backpack and localPlayer.Backpack:FindFirstChild("Knife")) or (myCharacter and myCharacter:FindFirstChild("Knife"))
    if k~=myKnife then
        myKnife=k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end

resolveKnife()
localPlayer.CharacterAdded:Connect(function(c)
    myCharacter=c
    myHumanoid=c:WaitForChild("Humanoid")
    myRoot=c:WaitForChild("HumanoidRootPart")
    trackStart=setmetatable({}, { __mode="k" })
    task.defer(resolveKnife)
end)
if localPlayer:FindFirstChild("Backpack") then
    localPlayer.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    localPlayer.Backpack.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)
end
myCharacter.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
myCharacter.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)

local function throwAllowed()
    if not myHumanoid then return false end
    local now=os.clock()
    local ok=false
    for _,tr in ipairs(myHumanoid:GetPlayingAnimationTracks()) do
        local id=tr.Animation and tr.Animation.AnimationId or ""
        for _,a in ipairs(AllowedAnimationIds) do
            if id:find(a,1,true) then
                if not trackStart[tr] then trackStart[tr]=now end
                if now-trackStart[tr]>=AnimationGateSeconds then ok=true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr)~="Instance" or not tr.IsPlaying then trackStart[tr]=nil end
    end
    return ok
end

local function getAimPart(ch)
    return ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"))
end

local function raycast(origin, target, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {myCharacter}
    local direction = (target - origin).Unit * 1000
    return Workspace:Raycast(origin, direction, params)
end

local function isObstructed(origin, target, ignoreList)
    local hit = raycast(origin, target, ignoreList)
    if not hit then return false end
    local targetChar = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if (p.Character.HumanoidRootPart.Position - target).Magnitude < 10 then
                targetChar = p.Character
                break
            end
        end
    end
    if targetChar and hit.Instance:IsDescendantOf(targetChar) then
        return false
    end
    return true
end

local function findNearestTarget()
    local nearest = nil
    local minDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local root = getAimPart(p.Character)
            if h and h.Health > 0 and root then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = p
                end
            end
        end
    end
    return nearest
end

local function silentThrow(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetRoot = getAimPart(targetPlayer.Character)
    if not targetRoot then return end
    local throwPos = targetRoot.Position
    local origin = myRoot.Position
    local throwData = {
        target = targetPlayer,
        targetPos = throwPos,
        origin = origin,
        time = tick()
    }
    table.insert(pendingThrows, throwData)

    if myKnife and myKnife.Parent == myCharacter then
        myKnife.Parent = localPlayer.Backpack
    end

    task.wait(UNEQUIP_DELAY)
    resolveKnife()
    if not knifeRemote then return end
    knifeRemote:FireServer(CFrame.new(throwPos), origin)

    task.spawn(function()
        task.wait(0.5)
        if targetPlayer.Character then
            local h = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            local currentRoot = getAimPart(targetPlayer.Character)
            if h and h.Health > 0 and currentRoot then
                local currentPos = currentRoot.Position
                local distance = (currentPos - throwPos).Magnitude
                if distance > 5 then
                    if not isObstructed(origin, currentPos, {myCharacter}) then
                        if knifeRemote then
                            knifeRemote:FireServer(CFrame.new(currentPos), currentPos)
                        end
                    end
                end
            end
        end
        for i = #pendingThrows, 1, -1 do
            if tick() - pendingThrows[i].time > 2 then
                table.remove(pendingThrows, i)
            end
        end
    end)
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConnection then loopConnection:Disconnect(); loopConnection=nil end
        return
    end
    if not Environment.CRIMSON_SILENT_KNIFE.enabled then return end
    resolveKnife()
    if not myKnife or not knifeRemote then return end
    if not myCharacter or not myRoot or not myHumanoid or myHumanoid.Health<=0 then return end
    if not throwAllowed() then return end
    local target = findNearestTarget()
    if target then
        silentThrow(target)
    end
end

if loopConnection then loopConnection:Disconnect() end
loopConnection=RunService.Heartbeat:Connect(step)

Environment.CRIMSON_SILENT_KNIFE.enable=function()Environment.CRIMSON_SILENT_KNIFE.enabled=true end
Environment.CRIMSON_SILENT_KNIFE.disable=function()Environment.CRIMSON_SILENT_KNIFE.enabled=false end
