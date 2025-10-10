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
    enabled = false,
    rangeStabEnabled = false
}

local AllowedThrowAnimations = { "rbxassetid://1957618848" }
local MinimumAnimationTime = 0.75

local KnifeProjectileSpeed = 63/1.25

local MinTransparencyToIgnore = 0.4
local MinThicknessToIgnore = 0.4

local GroundCheckRadius = 2.5
local MaxGroundDistance = 24
local GroundHeightTolerance = 1.75

local GroundedMemoryDuration = 0.35
local TorsoHeightAboveGround = 1.0

local ExposureCheckRadius = 0.8
local MinimumExposureRatio = 0.4

local myCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRoot = myCharacter:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote

local loopConnection
local rangeStabConnection

local trackStart = setmetatable({}, { __mode = "k" })
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

local activeTargets = {}
local RangeStabRadius = 20

local function unitVector(v)
    local m = v.Magnitude
    if m == 0 or m ~= m then return Vector3.zero, 0 end
    return v/m, m
end

local function clampValue(v,a,b)
    if b<a then a,b=b,a end
    if v~=v then return a end
    return math.clamp(v,a,b)
end

local function isFinite(v)
    return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z
end

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
    activeTargets = {}
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
        for _,a in ipairs(AllowedThrowAnimations) do
            if id:find(a,1,true) then
                if not trackStart[tr] then trackStart[tr]=now end
                if now-trackStart[tr]>=MinimumAnimationTime then ok=true end
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
        if i.Transparency>=MinTransparencyToIgnore then return true end
        local s=i.Size
        if s.X<MinThicknessToIgnore or s.Y<MinThicknessToIgnore or s.Z<MinThicknessToIgnore then return true end
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
    local u,m=unitVector(t-o)
    local hit=raycastVec(o,u,clampValue(m,0,12288),ig)
    return hit,u,m
end

local LimbOrder={"LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"}

local function isExposed(part,origin,ignore)
    if not part or not part:IsA("BasePart") then return false end
    local c=part.Position; local s=part.Size
    local pts={c,c+Vector3.new(s.X*0.3,0,0),c+Vector3.new(-s.X*0.3,0,0),
        c+Vector3.new(0,s.Y*0.3,0),c+Vector3.new(0,-s.Y*0.3,0),
        c+Vector3.new(0,0,s.Z*0.3),c+Vector3.new(0,0,-s.Z*0.3)}
    if part.Name:find("Foot") or part.Name:find("Hand") or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(pts,c+Vector3.new(s.X*0.4,s.Y*0.4,0))
        table.insert(pts,c+Vector3.new(-s.X*0.4,s.Y*0.4,0))
        table.insert(pts,c+Vector3.new(s.X*0.4,-s.Y*0.4,0))
        table.insert(pts,c+Vector3.new(-s.X*0.4,-s.Y*0.4,0))
    end
    local clear=0
    local fullIgnore={myCharacter,part.Parent}
    for _,v in ipairs(ignore)do table.insert(fullIgnore,v) end
    for _,p in ipairs(pts)do
        local h=rayTowards(origin,p,fullIgnore)
        if not h or h.Instance:IsDescendantOf(part.Parent) or ignoreHit(h) then clear=clear+1 end
    end
    return (clear/#pts)>=MinimumExposureRatio
end

local function pickTarget(origin)
    local mouse=localPlayer:GetMouse()
    local bp,bl,bs=nil,nil,math.huge
    for _,pl in ipairs(Players:GetPlayers())do
        if pl~=localPlayer then
            local ch=pl.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid")
            if ch and h and h.Health>0 then
                local ig={myCharacter}
                for _,part in ipairs((function()
                    local ex={}
                    for _,nm in ipairs(LimbOrder)do
                        local p=ch:FindFirstChild(nm)
                        if p and isExposed(p,origin,ig) then table.insert(ex,p) end
                    end
                    return ex
                end)())do
                    local v,on=camera:WorldToViewportPoint(part.Position)
                    local sc=on and (Vector2.new(v.X,v.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude or 9999
                    local ws=(part.Position-origin).Magnitude*0.1
                    local bias= part.Name:find("Foot") and -100
                        or part.Name:find("LowerLeg") and -80
                        or part.Name:find("Leg") and -60
                        or part.Name:find("Hand") and -40
                        or part.Name:find("LowerArm") and -30
                        or part.Name:find("Arm") and -20
                        or part.Name=="Head" and -10
                        or 10
                    local score=sc+ws+bias
                    if score<bs then bp,bl,bs=pl,part,score end
                end
            end
        end
    end
    return bp,bl
end

local function rememberGroundTorso(ch,same,gp)
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local t=ch and ch:FindFirstChild("UpperTorso")
    if not h or not t then return end
    local id=ch:GetDebugId()
    if same and gp then
        local p=t.Position
        lastGroundedTorso[id]=Vector3.new(p.X,gp.Y+TorsoHeightAboveGround,p.Z)
        lastGroundedTime[id]=os.clock()
    end
end

local function findGround(ch,ignore)
    local ap=getAimPart(ch)
    if not ap then return nil,false end
    local from=ap.Position+Vector3.new(0,2,0)
    local hit=raycastVec(from,Vector3.new(0,-1,0),MaxGroundDistance,ignore)
    local gp=hit and hit.Position or nil
    if not gp then
        local vel=worldVel(ch)
        local f=Vector3.new(vel.X,0,vel.Z)
        f=f.Magnitude>0 and f.Unit or Vector3.new(0,0,1)
        local r=f:Cross(Vector3.new(0,1,0)).Unit
        for _,off in ipairs({Vector3.new(),r*GroundCheckRadius,-r*GroundCheckRadius,f*GroundCheckRadius,-f*GroundCheckRadius})do
            local h2=raycastVec(from+off,Vector3.new(0,-1,0),MaxGroundDistance,ignore)
            if h2 then gp=h2.Position break end
        end
    end
    local id=ch:GetDebugId(); local same=false
    if gp then
        local last=lastGroundY[id]
        if last then same=math.abs(gp.Y-last)<=GroundHeightTolerance end
        lastGroundY[id]=gp.Y
    end
    return gp,same
end

local function hasNormalJump(h) local jp=h and h.JumpPower or 50 return jp>=40 and jp<=75 end

local function predictPoint(origin,ch,focus,same,gp)
    local p=focus or getAimPart(ch)
    if not p then return nil end
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local id,chtime=ch:GetDebugId(),os.clock()
    local useStick=false
    if h and hasNormalJump(h) and lastGroundedTorso[id] and lastGroundedTime[id] and (chtime-lastGroundedTime[id]<=GroundedMemoryDuration) then
        local st=h:GetState()
        if (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and (not same) then useStick=true end
    end
    local base=useStick and lastGroundedTorso[id] or p.Position
    if not useStick and gp then base=Vector3.new(base.X,gp.Y+(p.Name=="Head" and 1 or 0.9),base.Z) end
    local dist=(base-origin).Magnitude
    if dist==0 then return base end
    local t=dist/KnifeProjectileSpeed; if t<=0 then t=0 end
    local vel=worldVel(ch)
    local horiz=Vector3.new(vel.X,0,vel.Z)
    local speed=horiz.Magnitude
    local lead=(speed>0) and (horiz*t) or Vector3.zero
    local predicted = Vector3.new(base.X, p.Position.Y, base.Z) + lead
    return predicted
end

local function directAim(o,tp,ch,ig)
    local h,dir=rayTowards(o,tp,ig)
    if not h or ignoreHit(h) then return tp end
    local right=dir:Cross(Vector3.new(0,1,0)).Unit
    local slide=right
    if ch then
        local vel=worldVel(ch)
        local hor=Vector3.new(vel.X,0,vel.Z)
        if hor.Magnitude>0.5 then slide = (hor:Dot(right)>=0) and right or -right end
    end
    for _,off in ipairs({1.5,2.5})do
        for _,d in ipairs({slide,-slide})do
            local sp = h.Position + d*off
            sp=Vector3.new(sp.X,tp.Y,sp.Z)
            local h1=rayTowards(o,sp,ig)
            if h1 and not ignoreHit(h1) then continue end
            local h2=rayTowards(sp,tp,ig)
            if not h2 or ignoreHit(h2) then return sp end
        end
    end
    return h.Position - dir*0.5
end

local function isPlayerPart(part)
    if not part or not part:IsA("BasePart") then return false end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            return true
        end
    end

    local model = part.Parent
    if model and model:IsA("Model") then
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return true
        end
    end

    return false
end

local function setupRangeStab()
    local function monitorThrowingKnife()
        local throwingKnifeAdded
        throwingKnifeAdded = Workspace.ChildAdded:Connect(function(child)
            if child.Name == "ThrowingKnife" and Environment.CRIMSON_AUTO_KNIFE.rangeStabEnabled then
                task.spawn(function()
                    resolveKnife()

                    local origin = (myKnife and myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
                    local targetPlayer, targetLimb = pickTarget(origin)

                    if targetPlayer and targetLimb then
                        local targetCharacter = targetPlayer.Character
                        local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

                        if targetRoot then
                            local targetId = targetPlayer.UserId
                            activeTargets[targetId] = {
                                player = targetPlayer,
                                character = targetCharacter,
                                root = targetRoot,
                                startTime = tick()
                            }
                        end
                    end

                    for _, part in ipairs(myCharacter:GetDescendants()) do
                        if part:IsA("BasePart") and not isPlayerPart(part) then
                            part.CanCollide = false
                        end
                    end

                    while child and child.Parent == Workspace and Environment.CRIMSON_AUTO_KNIFE.rangeStabEnabled do
                        local knifePos = child:IsA("Model") and child:GetPivot().Position or (child:IsA("BasePart") and child.Position or nil)
                        if not knifePos then break end

                        for uid, data in pairs(activeTargets) do
                            local tChar = data.character
                            local tRoot = data.root

                            if tChar and tChar.Parent and tRoot and tRoot.Parent then
                                local distance = (tRoot.Position - knifePos).Magnitude

                                if distance <= RangeStabRadius then
                                    local HitboxSize = 5000
                                    local ExpandedSize = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                                    local Root = tRoot

                                    if Root:IsA("BasePart") then
                                        Root.CanCollide = false
                                        Root.Size = ExpandedSize
                                        Root.Transparency = 1

                                        task.wait(0.05)

                                        local stabRemote = myKnife and myKnife:FindFirstChild("Stab")
                                        if stabRemote then
                                            stabRemote:FireServer("Slash")
                                        end

                                        task.wait(0.1)

                                        if Root and Root.Parent then
                                            Root.Size = Vector3.new(2, 1, 1)
                                            Root.Transparency = 1
                                        end
                                    end

                                    activeTargets[uid] = nil
                                end
                            else
                                activeTargets[uid] = nil
                            end
                        end

                        task.wait()
                    end

                    task.wait(0.5)
                    for _, part in ipairs(myCharacter:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not isPlayerPart(part) then
                            part.CanCollide = true
                        end
                    end

                    activeTargets = {}
                end)
            end
        end)

        return throwingKnifeAdded
    end

    return monitorThrowingKnife()
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConnection then loopConnection:Disconnect(); loopConnection=nil end
        return
    end

    if not Environment.CRIMSON_AUTO_KNIFE.enabled then return end

    resolveKnife()
    if not myKnife or not myCharacter or not myRoot or not myHumanoid or myHumanoid.Health<=0 then
        return
    end

    if not throwAllowed() then return end

    if not knifeRemote then return end
    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local targetPlayer, targetLimb = pickTarget(origin)
    if not targetPlayer or not targetLimb then return end

    local tc,targetHum,anchor = targetPlayer.Character, nil, nil
    if tc then targetHum=tc:FindFirstChildOfClass("Humanoid"); anchor=getAimPart(tc) end
    if not targetHum or targetHum.Health<=0 or not anchor then return end
    if not (os.clock()-(_G.__stair_hold or 0)>=0) then return end

    local ig={myCharacter}
    local gp,same = findGround(tc,ig)
    rememberGroundTorso(tc,same,gp)

    local pred = predictPoint(origin,tc,targetLimb,same,gp)
    if not pred then return end

    local aim = directAim(origin,pred,tc,ig)
    if not isFinite(aim) then return end

    if math.abs((pred-origin).Y)>0.5 then
        _G.__stair_hold=os.clock()
    end

    knifeRemote:FireServer(CFrame.new(aim),origin)
end

if loopConnection then loopConnection:Disconnect() end
loopConnection=RunService.Heartbeat:Connect(step)

Environment.CRIMSON_AUTO_KNIFE.enable = function() Environment.CRIMSON_AUTO_KNIFE.enabled = true end
Environment.CRIMSON_AUTO_KNIFE.disable = function() Environment.CRIMSON_AUTO_KNIFE.enabled = false end

Environment.CRIMSON_AUTO_KNIFE.enableRangeStab = function() 
    Environment.CRIMSON_AUTO_KNIFE.rangeStabEnabled = true 
    if rangeStabConnection then rangeStabConnection:Disconnect() end
    rangeStabConnection = setupRangeStab()
end

Environment.CRIMSON_AUTO_KNIFE.disableRangeStab = function() 
    Environment.CRIMSON_AUTO_KNIFE.rangeStabEnabled = false 
    if rangeStabConnection then rangeStabConnection:Disconnect() rangeStabConnection = nil end
    activeTargets = {}
end
