
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Environment = (getgenv and getgenv()) or _G
Environment.CRIMSON_SILENT_KNIFE = Environment.CRIMSON_SILENT_KNIFE or { enabled = false }

local AllowedAnimationIds = { "rbxassetid://1957618848" }
local AnimationGateSeconds = 0.75

local KNIFE_SPEED = 63/0.85
local UNEQUIP_DELAY = 0.05

local myCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRoot = myCharacter:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConnection

local trackStart = setmetatable({}, { __mode = "k" })
local activeThrows = {}

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

local function worldVel(ch)
    local p=getAimPart(ch)
    return p and p.AssemblyLinearVelocity or Vector3.zero
end

local function ignoreHit(h)
    local i=h.Instance
    if i and i:IsA("BasePart") then
        if i.Transparency>=0.4 then return true end
        local s=i.Size
        if s.X<0.4 or s.Y<0.4 or s.Z<0.4 then return true end
        if i.Material==Enum.Material.Glass or i.Material==Enum.Material.ForceField then return true end
    end
    return false
end

local function raycastVec(o,d,l,ig)
    local p=RaycastParams.new()
    p.FilterType=Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances=ig
    return Workspace:Raycast(o,d*l,p)
end

local function rayTowards(o,t,ig)
    local dir = (t-o)
    local m = dir.Magnitude
    if m == 0 then return nil, Vector3.zero, 0 end
    local u = dir/m
    local hit=raycastVec(o,u,math.min(m,12288),ig)
    return hit,u,m
end

local function pickTarget(origin)
    local mouse=localPlayer:GetMouse()
    local bp,bl=nil,nil
    local bestScore=math.huge
    
    for _,pl in ipairs(Players:GetPlayers())do
        if pl~=localPlayer then
            local ch=pl.Character
            local h=ch and ch:FindFirstChildOfClass("Humanoid")
            if ch and h and h.Health>0 then
                local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("HumanoidRootPart")
                if torso then
                    local v,on=camera:WorldToViewportPoint(torso.Position)
                    if on then
                        local sc=(Vector2.new(v.X,v.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude
                        if sc<bestScore then
                            bp,bl,bestScore=pl,torso,sc
                        end
                    end
                end
            end
        end
    end
    return bp,bl
end

local function checkLineOfSight(from, to, targetChar)
    local ig = {myCharacter, targetChar}
    local hit, dir, dist = rayTowards(from, to, ig)
    
    if not hit then return true end
    if hit.Instance:IsDescendantOf(targetChar) then return true end
    if ignoreHit(hit) then return true end
    
    return false
end

local function monitorKnifeTravel(targetPlayer, targetPart, throwTime)
    local throwId = os.clock()
    activeThrows[throwId] = true
    
    task.spawn(function()
        local maxWaitTime = 3
        local elapsed = 0
        local checkInterval = 0.03
        
        while activeThrows[throwId] and elapsed < maxWaitTime do
            task.wait(checkInterval)
            elapsed = elapsed + checkInterval
            
            if not Environment.CRIMSON_SILENT_KNIFE.enabled then
                activeThrows[throwId] = nil
                return
            end
            
            if not targetPlayer or not targetPlayer.Parent then
                activeThrows[throwId] = nil
                return
            end
            
            local targetChar = targetPlayer.Character
            if not targetChar then
                activeThrows[throwId] = nil
                return
            end
            
            local currentTargetPart = getAimPart(targetChar)
            if not currentTargetPart then
                activeThrows[throwId] = nil
                return
            end
            
            local origin = myRoot.Position
            local targetPos = currentTargetPart.Position
            
            local hasLOS = checkLineOfSight(origin, targetPos, targetChar)
            
            if hasLOS then
                if knifeRemote then
                    knifeRemote:FireServer(CFrame.new(targetPos), origin)
                end
            end
        end
        
        activeThrows[throwId] = nil
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

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local targetPlayer, targetLimb = pickTarget(origin)
    if not targetPlayer or not targetLimb then return end

    local tc = targetPlayer.Character
    if not tc then return end
    local targetHum = tc:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health<=0 then return end

    task.spawn(function()
        if myKnife and myKnife.Parent == myCharacter then
            myHumanoid:UnequipTools()
        end
        
        task.wait(UNEQUIP_DELAY)
        
        if not Environment.CRIMSON_SILENT_KNIFE.enabled then return end
        if not knifeRemote then return end
        
        local currentTarget = getAimPart(tc)
        if not currentTarget then return end
        
        local throwPos = currentTarget.Position
        knifeRemote:FireServer(CFrame.new(throwPos), origin)
        
        monitorKnifeTravel(targetPlayer, currentTarget, os.clock())
    end)
end

if loopConnection then loopConnection:Disconnect() end
loopConnection=RunService.Heartbeat:Connect(step)

Environment.CRIMSON_SILENT_KNIFE.enable=function()
    Environment.CRIMSON_SILENT_KNIFE.enabled=true
end
Environment.CRIMSON_SILENT_KNIFE.disable=function()
    Environment.CRIMSON_SILENT_KNIFE.enabled=false
    activeThrows = {}
end
