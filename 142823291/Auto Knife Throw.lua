local coreGui      = game:GetService("CoreGui")
local players      = game:GetService("Players")
local runService   = game:GetService("RunService")
local workspace    = game:GetService("Workspace")

local markerName   = "_cr1m50n__kv_ok__7F2B1D"
if not coreGui:FindFirstChild(markerName) then return end

-- PREDICTION SETTINGS
local predLeadAmount = 5            -- base lead multiplier
local predRangeGain  = 0.005        -- distance scaling factor
local predKnifeSpeed = 64 / 0.85    -- studs per second

local env = (getgenv and getgenv()) or _G
env.CRIMSON_AUTO_KNIFE = env.CRIMSON_AUTO_KNIFE or { enabled = true }

local allowedAnimIds  = { "rbxassetid://1957618848" }
local animGateSeconds = 0.75

local me      = players.LocalPlayer
local camera  = workspace.CurrentCamera
local myChar  = me.Character or me.CharacterAdded:Wait()
local myHum   = myChar:WaitForChild("Humanoid")
local myRoot  = myChar:WaitForChild("HumanoidRootPart")

local myKnife, knifeRemote, loopConn
local trackStart = setmetatable({}, { __mode = "k" })

local function unit(v)
    local m = v.Magnitude
    if m == 0 or m ~= m then return Vector3.zero, 0 end
    return v/m, m
end

local function clamp(v, a, b)
    if b < a then a, b = b, a end
    if v ~= v then return a end
    return math.clamp(v, a, b)
end

local function finite3(v)
    return v and v.X == v.X and v.Y == v.Y and v.Z == v.Z
end

local function resolveKnife()
    local k = (me.Backpack and me.Backpack:FindFirstChild("Knife"))
           or (myChar and myChar:FindFirstChild("Knife"))
    if k ~= myKnife then
        myKnife = k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end

resolveKnife()
me.CharacterAdded:Connect(function(c)
    myChar = c
    myHum  = c:WaitForChild("Humanoid")
    myRoot = c:WaitForChild("HumanoidRootPart")
    trackStart = setmetatable({}, { __mode = "k" })
    task.defer(resolveKnife)
end)

if me:FindFirstChild("Backpack") then
    me.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)
end

myChar.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)

local function throwIsAllowedNow()
    if not myHum then return false end
    local now, ok = os.clock(), false
    for _, tr in ipairs(myHum:GetPlayingAnimationTracks()) do
        local id = tr.Animation and tr.Animation.AnimationId or ""
        for _, allow in ipairs(allowedAnimIds) do
            if id:find(allow,1,true) then
                if not trackStart[tr] then trackStart[tr]=now end
                if now - trackStart[tr] >= animGateSeconds then ok = true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr)~="Instance" or not tr.IsPlaying then trackStart[tr]=nil end
    end
    return ok
end

local function aimPart(char)
    return char and (char:FindFirstChild("UpperTorso")
                  or char:FindFirstChild("HumanoidRootPart")
                  or char:FindFirstChild("Head"))
end

local function worldVel(char)
    local p = aimPart(char)
    return p and p.AssemblyLinearVelocity or Vector3.zero
end

local function ignoreHit(hit)
    local inst = hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency >= 0.4 then return true end
        local s = inst.Size
        if s.X<0.4 or s.Y<0.4 or s.Z<0.4 then return true end
        local m = inst.Material
        if m==Enum.Material.Glass or m==Enum.Material.ForceField then return true end
    end
    return false
end

local function raycastVec(origin, dir, len, ignore)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=ignore
    return workspace:Raycast(origin, dir*len, params)
end

local function rayTowards(origin, target, ignore)
    local u, mag = unit(target-origin)
    local hit = raycastVec(origin, u, clamp(mag,0,12288), ignore)
    return hit, u, mag
end

local LimbPriority={
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"
}

local function isPartExposed(part, origin, ignore)
    if not part or not part:IsA("BasePart") then return false end
    local c, s = part.Position, part.Size
    local pts={
        c, c+Vector3.new(s.X*0.3,0,0), c-Vector3.new(s.X*0.3,0,0),
        c+Vector3.new(0,s.Y*0.3,0), c-Vector3.new(0,s.Y*0.3,0),
        c+Vector3.new(0,0,s.Z*0.3), c-Vector3.new(0,0,s.Z*0.3),
    }
    if part.Name:find("Foot") or part.Name:find("Hand")
    or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(pts, c+Vector3.new(s.X*0.4,s.Y*0.4,0))
        table.insert(pts, c-Vector3.new(s.X*0.4,-s.Y*0.4,0))
        table.insert(pts, c+Vector3.new(-s.X*0.4,s.Y*0.4,0))
        table.insert(pts, c-Vector3.new(-s.X*0.4,-s.Y*0.4,0))
    end
    local clear, fullIgnore = 0, {myChar, part.Parent}
    for _,i in ipairs(ignore) do table.insert(fullIgnore,i) end
    for _,p in ipairs(pts) do
        local h = rayTowards(origin,p,fullIgnore)
        if not h or h.Instance:IsDescendantOf(part.Parent) or ignoreHit(h) then
            clear += 1
        end
    end
    return (clear/#pts) >= 0.4
end

local function getExposedLimbs(char, origin, ignore)
    local out={}
    if not char then return out end
    for _,name in ipairs(LimbPriority) do
        local part=char:FindFirstChild(name)
        if part and isPartExposed(part, origin, ignore) then
            table.insert(out, part)
        end
    end
    return out
end

local function pickExposedTarget(origin)
    local m=me:GetMouse()
    local bestPl,bestPart,bestScore=nil,nil,math.huge
    for _,pl in ipairs(players:GetPlayers()) do
        if pl~=me then
            local c=pl.Character
            local h=c and c:FindFirstChildOfClass("Humanoid")
            if c and h and h.Health>0 then
                local ignore={myChar}
                for _,pt in ipairs(getExposedLimbs(c,origin,ignore)) do
                    local v,on=camera:WorldToViewportPoint(pt.Position)
                    local screen=(on and (Vector2.new(v.X,v.Y)-Vector2.new(m.X,m.Y)).Magnitude) or 9999
                    local world=(pt.Position-origin).Magnitude*0.1
                    local bias=10
                    if pt.Name:find("Foot") then bias=-100
                    elseif pt.Name:find("LowerLeg") then bias=-80
                    elseif pt.Name:find("Leg") then bias=-60
                    elseif pt.Name:find("Hand") then bias=-40
                    elseif pt.Name:find("LowerArm") then bias=-30
                    elseif pt.Name:find("Arm") then bias=-20
                    elseif pt.Name=="Head" then bias=-10 end
                    local score=screen+world+bias
                    if score<bestScore then
                        bestPl,bestPart,bestScore=pl,pt,score
                    end
                end
            end
        end
    end
    return bestPl,bestPart
end

local lastGroundY, lastTorso, lastTime = {},{},{}

local function rememberGroundedTorso(tc,same,gp)
    local h=tc and tc:FindFirstChildOfClass("Humanoid")
    local t=tc and tc:FindFirstChild("UpperTorso")
    if not h or not t then return end
    local id=tc:GetDebugId()
    if same and gp then
        local p=t.Position
        lastTorso[id]=Vector3.new(p.X,gp.Y+1,p.Z)
        lastTime[id]=os.clock()
    end
end

local function groundGhost(tc,ignore)
    local a=aimPart(tc)
    if not a then return nil,false end
    local from=a.Position+Vector3.new(0,2,0)
    local hit=raycastVec(from,Vector3.new(0,-1,0),24,ignore)
    local gp=hit and hit.Position or nil
    local id=tc:GetDebugId()
    local same=false
    if gp then
        same = lastGroundY[id] and math.abs(gp.Y-lastGroundY[id])<=1.75
        lastGroundY[id]=gp.Y
    end
    return gp,same
end

local function knifeSpeedAt(dist)
    return predKnifeSpeed
end

local function timeTo(dist)
    return dist>0 and dist/knifeSpeedAt(dist) or 0
end

local function hasNormalJP(h)
    return h and h.JumpPower>=40 and h.JumpPower<=75
end

local function predictPoint(origin,tc,focus,same,gp)
    local p=focus or aimPart(tc)
    if not p then return nil end
    local h=tc and tc:FindFirstChildOfClass("Humanoid")
    local id=tc:GetDebugId()
    local now, useStick=os.clock(),false
    if h and hasNormalJP(h) and lastTorso[id] and lastTime[id]
       and now-lastTime[id]<=0.35 then
        local st=h:GetState()
        if (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall)
           and not same then useStick=true end
    end
    local base=useStick and lastTorso[id] or p.Position
    if not useStick and gp then
        base=Vector3.new(base.X,gp.Y+(p.Name=="Head" and 1 or 0.9),base.Z)
    end
    local dist=(base-origin).Magnitude
    local t=timeTo(dist)
    if t==0 then return base end
    local vel=worldVel(tc)
    local horiz=Vector3.new(vel.X,0,vel.Z)
    local speed=horiz.Magnitude
    local doLead=speed>4.25
    local ds=1+clamp(dist*predRangeGain,0,2)
    local ss=doLead and (1+clamp(speed*0.05,0,0.5)) or 1
    local ls=doLead and (ds*ss) or 0
    local lead=doLead and horiz*t*predLeadAmount*ls or Vector3.zero

    local vy=vel.Y
    local extra=0
    local hrp=tc:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _,o in ipairs(hrp:GetChildren()) do
            if o:IsA("BodyVelocity") then extra+=o.Velocity.Y end
        end
    end

    local st=h and h:GetState() or Enum.HumanoidStateType.Running
    local y
    if useStick then
        y=clamp(vy*t*0.12,-3,3)
    else
        local blend=vy+extra*0.35
        y=blend*t*0.38-0.5*workspace.Gravity*(t*t)*0.35
        if hasNormalJP(h) then y=clamp(y,-28,36) else y=clamp(y,-22,28) end
        if st==Enum.HumanoidStateType.Freefall then y=y-0.08*workspace.Gravity*(t*t)
        elseif st==Enum.HumanoidStateType.Jumping and hasNormalJP(h) then y=y*0.75 end
        if h and h.WalkSpeed<8 then y=y*0.7 end
    end

    local targetDY=p.Position.Y-origin.Y
    if not doLead and math.abs(vy)<1 then
        y=clamp(y,-4,targetDY>0 and 6 or 4)
    elseif targetDY>0 and y>0 then
        y=math.min(y,8)
    end

    local pred=base+lead+Vector3.new(0,y,0)
    return finite3(pred) and pred or base
end

local function directAim(origin,target,tc,ignore)
    local hit,dir=rayTowards(origin,target,ignore)
    if not hit or ignoreHit(hit) then return target end
    local right=dir:Cross(Vector3.new(0,1,0)).Unit
    local slide=right
    local vel=worldVel(tc)
    local horiz=Vector3.new(vel.X,0,vel.Z)
    if horiz.Magnitude>0.5 then
        slide=(horiz:Dot(right)>=0) and right or -right
    end
    for _,off in ipairs({1.5,2.5}) do
        for _,d in ipairs({slide,-slide}) do
            local sp=hit.Position+d*off
            sp=Vector3.new(sp.X,target.Y,sp.Z)
            local h1=rayTowards(origin,sp,ignore)
            if h1 and not ignoreHit(h1) then continue end
            local h2=rayTowards(sp,target,ignore)
            if not h2 or ignoreHit(h2) then return sp end
        end
    end
    return hit.Position-dir*0.5
end

local function clampToStair(originAim,limb,ignore)
    local down=raycastVec(limb+Vector3.new(0,3,0),Vector3.new(0,-1,0),8,ignore)
    if not down then return originAim end
    local y=down.Position.Y+0.6
    if math.abs(limb.Y-y)<=1.25 then
        return Vector3.new(originAim.X,y,originAim.Z)
    end
    return originAim
end

local lastThrow, gap, tokens, maxT, refill, lastRefill = 0,0.27,4,4,1.5,os.clock()
local function readyToThrow()
    local now=os.clock()
    local dt=now-lastRefill
    if dt>0 then tokens=math.min(maxT,tokens+dt*refill); lastRefill=now end
    if now-lastThrow<gap or tokens<1 then return false end
    tokens-=1; lastThrow=now; return true
end

local function step()
    if not coreGui:FindFirstChild(markerName) then
        if loopConn then loopConn:Disconnect() end
        return
    end
    if not env.CRIMSON_AUTO_KNIFE.enabled then return end
    resolveKnife()
    if not myKnife or not knifeRemote then return end
    if not myChar or not myRoot or not myHum or myHum.Health<=0 then return end
    if not throwIsAllowedNow() then return end

    local origin = (myKnife.Handle and myKnife.Handle.Position) or myRoot.Position
    local targetPl, targetLimb = pickExposedTarget(origin)
    if not targetPl or not targetLimb then return end

    local tc = targetPl.Character
    local th=tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor=tc and aimPart(tc)
    if not th or th.Health<=0 or not anchor then return end
    if not readyToThrow() then return end

    local ignore={myChar}
    local gp, same = groundGhost(tc, ignore)
    rememberGroundedTorso(tc, same, gp)

    local limbPred = predictPoint(origin, tc, targetLimb, same, gp)
    if not limbPred then return end

    local aimPos = directAim(origin, limbPred, tc, ignore)
    if not aimPos or not finite3(aimPos) then return end

    aimPos = clampToStair(aimPos, limbPred, ignore)
    if not finite3(aimPos) then return end

    local dist = (limbPred-origin).Magnitude
    local hitTime = dist/predKnifeSpeed
    env.CRIMSON_AUTO_KNIFE.lastTargetDistance     = dist
    env.CRIMSON_AUTO_KNIFE.lastEstimatedHitTime = hitTime

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = runService.Heartbeat:Connect(step)

env.CRIMSON_AUTO_KNIFE.enable  = function() env.CRIMSON_AUTO_KNIFE.enabled = true end
env.CRIMSON_AUTO_KNIFE.disable = function() env.CRIMSON_AUTO_KNIFE.enabled = false end
