local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local me = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Env = (getgenv and getgenv()) or _G
Env.CRIMSON_AUTO_KNIFE = Env.CRIMSON_AUTO_KNIFE or { enabled = true }

local AllowedAnimIds = {
    "rbxassetid://1957618848",
}
local AnimGateSeconds = 0.25

local leadAmount = 1.50
local rangeGainPerStud = 0.0025
local ignoreThinTransparency = 0.4
local ignoreMinThickness = 0.4

local groundProbeRadius = 2.5
local maxGroundSnap = 24
local sameGroundTolerance = 1.75

local groundedMemorySec = 0.35
local groundedTorsoYOffset = 1.0

local maxHorizontalSlide = 2.5
local cornerPeekDist = 2.5

local exposureCheckRadius = 0.8
local minExposureRatio = 0.4

local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConn

local trackStart = setmetatable({}, { __mode = "k" })
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

local function unit(v) local m=v.Magnitude if m==0 or m~=m then return Vector3.zero,0 end return v/m,m end
local function clamp(v,a,b) if b<a then a,b=b,a end if v~=v then return a end return math.clamp(v,a,b) end
local function finite3(v) return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z end

local function resolveKnife()
    local k = (me.Backpack and me.Backpack:FindFirstChild("Knife")) or (myChar and myChar:FindFirstChild("Knife"))
    if k ~= myKnife then
        myKnife = k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end
resolveKnife()
me.CharacterAdded:Connect(function(c)
    myChar=c; myHum=c:WaitForChild("Humanoid"); myRoot=c:WaitForChild("HumanoidRootPart")
    trackStart=setmetatable({}, { __mode = "k" }); task.defer(resolveKnife)
end)
if me:FindFirstChild("Backpack") then
    me.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)
end
myChar.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)

local function throwIsAllowedNow()
    if not myHum then return false end
    local now=os.clock(); local ok=false
    for _, tr in ipairs(myHum:GetPlayingAnimationTracks()) do
        local id = tr.Animation and tr.Animation.AnimationId or ""
        for _, allow in ipairs(AllowedAnimIds) do
            if id:find(allow,1,true) then
                if not trackStart[tr] then trackStart[tr]=now end
                if (now - trackStart[tr]) >= AnimGateSeconds then ok=true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr)~="Instance" or not tr.IsPlaying then trackStart[tr]=nil end
    end
    return ok
end

local function aimPart(char)
    return char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
end
local function worldVel(char)
    local p=aimPart(char); return p and p.AssemblyLinearVelocity or Vector3.zero
end

local function ignoreHit(hit)
    local inst=hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency>=ignoreThinTransparency then return true end
        local s=inst.Size
        if s.X<ignoreMinThickness or s.Y<ignoreMinThickness or s.Z<ignoreMinThickness then return true end
        local mat=inst.Material
        if mat==Enum.Material.Glass or mat==Enum.Material.ForceField then return true end
    end
    return false
end
local function raycastVec(origin, dir, len, ignore)
    local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances=ignore
    return Workspace:Raycast(origin, dir*len, p)
end
local function rayTowards(origin, target, ignore)
    local u,mag=unit(target-origin); local hit=raycastVec(origin,u,clamp(mag,0,12288),ignore); return hit,u,mag
end

local LimbPriority = {
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"
}
local function isPartExposed(part, origin, ignore)
    if not part or not part:IsA("BasePart") then return false end
    local c=part.Position; local s=part.Size
    local pts = {
        c, c+Vector3.new(s.X*0.3,0,0), c+Vector3.new(-s.X*0.3,0,0),
        c+Vector3.new(0,s.Y*0.3,0), c+Vector3.new(0,-s.Y*0.3,0),
        c+Vector3.new(0,0,s.Z*0.3), c+Vector3.new(0,0,-s.Z*0.3),
    }
    if part.Name:find("Foot") or part.Name:find("Hand") or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(pts, c+Vector3.new(s.X*0.4, s.Y*0.4, 0))
        table.insert(pts, c+Vector3.new(-s.X*0.4, s.Y*0.4, 0))
        table.insert(pts, c+Vector3.new(s.X*0.4, -s.Y*0.4, 0))
        table.insert(pts, c+Vector3.new(-s.X*0.4, -s.Y*0.4, 0))
    end
    local clear=0
    local fullIgnore={myChar, part.Parent}
    for _,i in ipairs(ignore) do table.insert(fullIgnore, i) end
    for _,p in ipairs(pts) do
        local hit=rayTowards(origin,p,fullIgnore)
        if not hit or hit.Instance:IsDescendantOf(part.Parent) or ignoreHit(hit) then
            clear=clear+1
        end
    end
    return (clear/#pts) >= minExposureRatio
end
local function getExposedLimbs(char, origin, ignore)
    local exposed={}
    if not char then return exposed end
    for _,name in ipairs(LimbPriority) do
        local part=char:FindFirstChild(name)
        if part and isPartExposed(part, origin, ignore) then
            table.insert(exposed, part)
        end
    end
    return exposed
end
local function pickExposedTarget(origin)
    local mouse=me:GetMouse(); local bestPlr,bestPart,bestScore=nil,nil,math.huge
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= me then
            local c=pl.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
            if c and h and h.Health>0 then
                local ignore={myChar}
                for _,part in ipairs(getExposedLimbs(c, origin, ignore)) do
                    local v,on=camera:WorldToViewportPoint(part.Position)
                    local screenScore = on and (Vector2.new(v.X,v.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude or 9999
                    local worldScore = (part.Position - origin).Magnitude * 0.1
                    local limbBias = 0
                    if part.Name:find("Foot") then limbBias=-100
                    elseif part.Name:find("LowerLeg") then limbBias=-80
                    elseif part.Name:find("Leg") then limbBias=-60
                    elseif part.Name:find("Hand") then limbBias=-40
                    elseif part.Name:find("LowerArm") then limbBias=-30
                    elseif part.Name:find("Arm") then limbBias=-20
                    elseif part.Name=="Head" then limbBias=-10
                    else limbBias=10 end
                    local score = screenScore + worldScore + limbBias
                    if score < bestScore then bestPlr,bestPart,bestScore=pl,part,score end
                end
            end
        end
    end
    return bestPlr,bestPart
end

local function rememberGroundedTorso(targetChar, sameGround, groundPos)
    local hum=targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local torso=targetChar and targetChar:FindFirstChild("UpperTorso")
    if not hum or not torso then return end
    local id=targetChar:GetDebugId()
    if sameGround and groundPos then
        local p=torso.Position
        lastGroundedTorso[id]=Vector3.new(p.X, groundPos.Y + groundedTorsoYOffset, p.Z)
        lastGroundedTime[id]=os.clock()
    end
end
local function groundGhost(targetChar, ignore)
    local a=aimPart(targetChar); if not a then return nil,false end
    local from=a.Position + Vector3.new(0,2,0)
    local hit=raycastVec(from, Vector3.new(0,-1,0), maxGroundSnap, ignore)
    local gpos=hit and hit.Position or nil
    if not gpos then
        local vel=worldVel(targetChar)
        local f=Vector3.new(vel.X,0,vel.Z); f=f.Magnitude>0 and f.Unit or Vector3.new(0,0,1)
        local r=f:Cross(Vector3.new(0,1,0)).Unit
        for _,off in ipairs({Vector3.new(0,0,0), r*groundProbeRadius, -r*groundProbeRadius, f*groundProbeRadius, -f*groundProbeRadius}) do
            local h2=raycastVec(from+off, Vector3.new(0,-1,0), maxGroundSnap, ignore)
            if h2 then gpos=h2.Position break end
        end
    end
    local id=targetChar:GetDebugId(); local same=false
    if gpos then
        local last=lastGroundY[id]
        if last then same = math.abs(gpos.Y - last) <= sameGroundTolerance end
        lastGroundY[id]=gpos.Y
    end
    return gpos,same
end

local baseKnifeSpeed=205
local function knifeSpeedAt(dist) return baseKnifeSpeed * (1 + math.clamp(dist*0.0035,0,1.5)) end
local function timeTo(dist) local s=knifeSpeedAt(dist) if s<=0 or dist~=dist then return 0 end return dist/s end
local function hasNormalJP(h) local jp=h and h.JumpPower or 50 return jp>=40 and jp<=75 end

local function predictPoint(origin, targetChar, focusPart, sameGround, groundPos)
    local p=focusPart or aimPart(targetChar); if not p then return nil end

    local hum=targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local id=targetChar:GetDebugId(); local now=os.clock()
    local useStick=false
    if hum and hasNormalJP(hum) and lastGroundedTorso[id] and lastGroundedTime[id] and (now-lastGroundedTime[id]<=groundedMemorySec) then
        local st=hum:GetState()
        if (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and (not sameGround) then
            useStick=true
        end
    end

    local basePos = useStick and lastGroundedTorso[id] or p.Position
    if not useStick and groundPos then
        basePos = Vector3.new(basePos.X, groundPos.Y + (p.Name=="Head" and 1.5 or 0.9), basePos.Z)
    end

    local dist=(basePos - origin).Magnitude
    local t=timeTo(dist); if t==0 then return basePos end

    local vel=worldVel(targetChar)
    local horiz=Vector3.new(vel.X,0,vel.Z)
    local speed=horiz.Magnitude
    local STILL_SPEED=1.25
    local doLead = speed > STILL_SPEED

    local distScale = 1 + math.clamp(dist * rangeGainPerStud, 0, 2.0)
    local speedScale = doLead and (1 + math.clamp(speed * 0.05, 0, 0.5)) or 1
    local leadScale = doLead and (distScale * speedScale) or 0
    local leadVec = doLead and (horiz * t * leadAmount * leadScale) or Vector3.zero

    local vy=vel.Y; local extra=0
    local hrp=targetChar:FindFirstChild("HumanoidRootPart")
    if hrp then for _,o in ipairs(hrp:GetChildren()) do if o:IsA("BodyVelocity") then extra+=o.Velocity.Y end end end
    local normal=hum and hasNormalJP(hum)
    local st=hum and hum:GetState() or Enum.HumanoidStateType.Running
    local recent=lastGroundedTime[id] and (now-lastGroundedTime[id]<=groundedMemorySec)

    local y
    if useStick then
        y = clamp(vy * t * 0.12, -3, 3)
    else
        local blended=vy + extra*0.35
        y = blended * t * 0.38 - 0.5 * Workspace.Gravity * (t*t) * 0.35
        y = (normal and clamp(y,-28,36) or clamp(y,-22,28))
        if st==Enum.HumanoidStateType.Freefall then
            y = y - 0.08 * Workspace.Gravity * (t*t)
        elseif st==Enum.HumanoidStateType.Jumping and normal then
            y = y * 0.75
        end
        if hum and (hum.WalkSpeed or 16) < 8 then y = y * 0.7 end
    end

    local targetDY = (p.Position.Y - origin.Y)
    if not doLead and math.abs(vy) < 1.0 then
        y = math.clamp(y, -4, targetDY > 0 and 6 or 4)
    elseif targetDY > 0 and y > 0 then
        y = math.min(y, 8)
    end

    local pred = basePos + leadVec + Vector3.new(0,y,0)
    return finite3(pred) and pred or basePos
end

local function directAim(origin, targetPos, targetChar, ignore)
    local hit,toDir = rayTowards(origin, targetPos, ignore)
    if not hit or ignoreHit(hit) then
        return targetPos
    end
    local right = toDir:Cross(Vector3.new(0,1,0)).Unit
    local slideDir = right
    if targetChar then
        local vel=worldVel(targetChar); local horiz=Vector3.new(vel.X,0,vel.Z)
        if horiz.Magnitude>0.5 then slideDir = (horiz:Dot(right) >= 0) and right or -right end
    end
    for _,off in ipairs({1.5, 2.5}) do
        for _,dir in ipairs({slideDir, -slideDir}) do
            local slidePos = hit.Position + dir * off
            slidePos = Vector3.new(slidePos.X, targetPos.Y, slidePos.Z)
            local h1 = rayTowards(origin, slidePos, ignore)
            if h1 and not ignoreHit(h1) then continue end
            local h2 = rayTowards(slidePos, targetPos, ignore)
            if not h2 or ignoreHit(h2) then
                return slidePos
            end
        end
    end
    return hit.Position - toDir * 0.5
end

local function clampToStairPlane(originAim, limbPred, ignore)
    local down = raycastVec(limbPred + Vector3.new(0,3,0), Vector3.new(0,-1,0), 8, ignore)
    if not down then return originAim end
    local floorY = down.Position.Y + 0.6
    if math.abs(limbPred.Y - floorY) <= 1.25 then
        return Vector3.new(originAim.X, floorY, originAim.Z)
    end
    return originAim
end

local lastThrow, gapSec = 0, 0.27
local tokens, maxTokens, refill = 4,4,1.5
local lastRefill=os.clock()
local function readyToThrow()
    local now=os.clock(); local dt=now-lastRefill
    if dt>0 then tokens=math.min(maxTokens, tokens + dt*refill); lastRefill=now end
    if (now-lastThrow)<gapSec or tokens<1 then return false end
    tokens=tokens-1; lastThrow=now; return true
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConn then loopConn:Disconnect(); loopConn=nil end
        return
    end
    if not Env.CRIMSON_AUTO_KNIFE.enabled then return end
    resolveKnife(); if not myKnife or not knifeRemote then return end
    if not myChar or not myRoot or not myHum or myHum.Health<=0 then return end
    if not throwIsAllowedNow() then return end

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local targetPlr, targetLimb = (function()
        return (function(o) return pickExposedTarget(o) end)(origin)
    end)()
    if not targetPlr or not targetLimb then return end

    local tc = targetPlr.Character; local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor = tc and aimPart(tc)
    if not th or th.Health<=0 or not anchor then return end
    if not readyToThrow() then return end

    local ignore={myChar}
    local gpos, sameGround = groundGhost(tc, ignore)
    rememberGroundedTorso(tc, sameGround, gpos)

    local limbPred = predictPoint(origin, tc, targetLimb, sameGround, gpos)
    if not limbPred then return end

    local aimPos = directAim(origin, limbPred, tc, ignore)
    if not aimPos or not finite3(aimPos) then return end

    aimPos = clampToStairPlane(aimPos, limbPred, ignore)
    if not finite3(aimPos) then return end

    local dY = math.abs((limbPred - origin).Y)
    if dY > 0.5 then
        if (os.clock() - (_G.__stair_hold or 0)) < 0.05 then return end
        _G.__stair_hold = os.clock()
    end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable  = function() Env.CRIMSON_AUTO_KNIFE.enabled = true  end
Env.CRIMSON_AUTO_KNIFE.disable = function() Env.CRIMSON_AUTO_KNIFE.enabled = false end
