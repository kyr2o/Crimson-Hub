-- Crimson Hub Auto-Knife: exposed-limb targeting (feet-first), gap windowing, jump-aware, always-on (marker + anim gated)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SECURITY_MARKER = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(SECURITY_MARKER) then return end

local me = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Env = (getgenv and getgenv()) or _G
Env.CRIMSON_AUTO_KNIFE = Env.CRIMSON_AUTO_KNIFE or { enabled = true }

-- Throw is allowed only while one of these animations is playing long enough
local AllowedAnimIds = {
    "rbxassetid://1957618848",
}
local AnimGateSeconds = 0.25

-- Tuning
local leadAmount = 1.50
local rangeGainPerStud = 0.0025
local ignoreThinTransparency = 0.4
local ignoreMinThickness = 0.4

-- Ground/ledge logic
local groundProbeRadius = 2.5
local maxGroundSnap = 24
local sameGroundTolerance = 1.75

-- Jump memory
local groundedMemorySec = 0.35
local groundedTorsoYOffset = 1.0

-- Advanced pathing for gaps/windows
local maxPathSteps = 8
local gapProbeRadius = 4.0
local verticalClearance = 2.2
local windowSearchAngles = {-45,-30,-15,0,15,30,45}
local cornerPeekDist = 5.5
local maxDetourDistance = 16.0

-- State
local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConn

-- Animation tracking (weak table)
local trackStart = setmetatable({}, { __mode = "k" })
-- Ground memory per target
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

-- Math helpers
local function unit(v) local m=v.Magnitude if m==0 or m~=m then return Vector3.zero,0 end return v/m,m end
local function clamp(v,a,b) if b<a then a,b=b,a end if v~=v then return a end return math.clamp(v,a,b) end
local function finite3(v) return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z end
local function rotateY(v,deg) local r=math.rad(deg) local c,s=math.cos(r),math.sin(r) return Vector3.new(v.X*c - v.Z*s, v.Y, v.X*s + v.Z*c) end

-- Knife
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
    trackStart=setmetatable({}, {__mode="k"}); task.defer(resolveKnife)
end)
if me:FindFirstChild("Backpack") then
    me.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)
end
myChar.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)

-- Anim allowlist gate
local function throwIsAllowedNow()
    if not myHum then return false end
    local now=os.clock(); local ok=false
    for _,tr in ipairs(myHum:GetPlayingAnimationTracks()) do
        local id=tr.Animation and tr.Animation.AnimationId or ""
        for _,allow in ipairs(AllowedAnimIds) do
            if id:find(allow,1,true) then
                if not trackStart[tr] then trackStart[tr]=now end
                if now - trackStart[tr] >= AnimGateSeconds then ok=true end
            end
        end
    end
    for tr in pairs(trackStart) do if typeof(tr)~="Instance" or not tr.IsPlaying then trackStart[tr]=nil end end
    return ok
end

-- Char helpers
local function aimPart(char)
    return char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
end
local function worldVel(char)
    local p=aimPart(char); return p and p.AssemblyLinearVelocity or Vector3.zero
end

-- Ray helpers
local function ignoreHit(hit)
    local inst=hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency>=ignoreThinTransparency then return true end
        local s=inst.Size
        if s.X<ignoreMinThickness or s.Y<ignoreMinThickness or s.Z<ignoreMinThickness then return true end
        local mat=inst.Material
        if mat==Enum.Material.Glass or mat==Enum.Material.ForceField then return true end
        if s.X<0.8 and s.Y<0.8 and s.Z<0.8 then return true end
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

-- Exposed limb scan from origin (knife), not camera; feet-first priority
local LimbPriority = {
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","HumanoidRootPart"
}
local function getExposedLimbs(char, origin, ignore)
    local exposed = {}
    for _,name in ipairs(LimbPriority) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local hit = rayTowards(origin, part.Position, ignore)
            if not hit or hit.Instance:IsDescendantOf(char) or ignoreHit(hit) then
                table.insert(exposed, part)
            end
        end
    end
    return exposed
end

-- Pick best exposed limb per player; cursor-first if on-screen; else nearest by world distance
local function pickExposedTarget(origin)
    local mouse = me:GetMouse()
    local bestPlr, bestPart, bestScore = nil, nil, math.huge
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= me then
            local c=pl.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
            if c and h and h.Health>0 then
                local ignore={myChar}
                local parts = getExposedLimbs(c, origin, ignore)
                for _,part in ipairs(parts) do
                    local v,on = camera:WorldToViewportPoint(part.Position)
                    local screenScore = on and (Vector2.new(v.X,v.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude or 9999
                    local worldScore = (part.Position - origin).Magnitude * 0.25
                    local limbBias = 0
                    if part.Name:find("Foot") or part.Name:find("LowerLeg") or part.Name:find("Leg") then limbBias = -40 end
                    if part.Name:find("Hand") or part.Name:find("LowerArm") or part.Name:find("Arm") then limbBias = limbBias - 10 end
                    if part.Name=="Head" then limbBias = limbBias + 5 end
                    local score = screenScore + worldScore + limbBias
                    if score < bestScore then bestPlr, bestPart, bestScore = pl, part, score end
                end
            end
        end
    end
    return bestPlr, bestPart
end

-- Ground ghost + last grounded torso
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
    local gpos = hit and hit.Position or nil
    if not gpos then
        local vel=worldVel(targetChar)
        local f=Vector3.new(vel.X,0,vel.Z); f = f.Magnitude>0 and f.Unit or Vector3.new(0,0,1)
        local r=f:Cross(Vector3.new(0,1,0)).Unit
        for _,off in ipairs({Vector3.new(0,0,0), r*groundProbeRadius, -r*groundProbeRadius, f*groundProbeRadius, -f*groundProbeRadius}) do
            local h2=raycastVec(from+off, Vector3.new(0,-1,0), maxGroundSnap, ignore)
            if h2 then gpos=h2.Position break end
        end
    end
    local id=targetChar:GetDebugId()
    local same=false
    if gpos then
        local last=lastGroundY[id]
        if last then same = math.abs(gpos.Y - last) <= sameGroundTolerance end
        lastGroundY[id]=gpos.Y
    end
    return gpos, same
end

-- Travel model
local baseKnifeSpeed=205
local function knifeSpeedAt(dist) return 1 + math.clamp(dist*0.0035,0,1.5) end
local function timeTo(dist) local s=baseKnifeSpeed*knifeSpeedAt(dist) if s<=0 or dist~=dist then return 0 end return dist/s end
local function hasNormalJP(h) local jp=h and h.JumpPower or 50 return jp>=40 and jp<=75 end

local function verticalOffset(targetChar, t, focusPart, sameGround, groundPos)
    local hum=targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not hum or not focusPart then return 0 end
    local vy=worldVel(targetChar).Y
    local extra=0
    local hrp=targetChar:FindFirstChild("HumanoidRootPart")
    if hrp then for _,o in ipairs(hrp:GetChildren()) do if o:IsA("BodyVelocity") then extra+=o.Velocity.Y end end end
    local normal=hasNormalJP(hum)
    local st=hum:GetState()
    local id=targetChar:GetDebugId()
    local now=os.clock()
    local recent=lastGroundedTime[id] and (now-lastGroundedTime[id]<=groundedMemorySec)

    if normal and (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and recent and (not sameGround) then
        return clamp(vy * t * 0.12, -3, 3)
    end

    local blended=vy + extra*0.35
    local y = blended * t * 0.38 - 0.5 * Workspace.Gravity * (t*t) * 0.35
    y = normal and clamp(y,-28,36) or clamp(y,-22,28)
    if st==Enum.HumanoidStateType.Freefall then y = y - 0.08 * Workspace.Gravity * (t*t)
    elseif st==Enum.HumanoidStateType.Jumping and normal then y = y * 0.75 end
    if (hum.WalkSpeed or 16) < 8 then y = y * 0.7 end
    return y
end

local function predictPoint(origin, targetChar, focusPart, sameGround, groundPos)
    local p=focusPart or aimPart(targetChar); if not p then return nil end
    local hum=targetChar:FindFirstChildOfClass("Humanoid")
    local id=targetChar:GetDebugId()
    local now=os.clock()
    local useStick=false
    if hum and hasNormalJP(hum) and lastGroundedTorso[id] and lastGroundedTime[id] and (now-lastGroundedTime[id]<=groundedMemorySec) then
        local st=hum:GetState()
        if (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and (not sameGround) then
            useStick=true
        end
    end

    local basePos
    if useStick then
        basePos = lastGroundedTorso[id]
    else
        basePos = p.Position
        if groundPos then
            basePos = Vector3.new(basePos.X, groundPos.Y + (p.Name=="Head" and 1.5 or 0.9), basePos.Z)
        end
    end

    local dist=(basePos - origin).Magnitude
    local t=timeTo(dist); if t==0 then return basePos end

    local vel=worldVel(targetChar)
    local horiz=Vector3.new(vel.X,0,vel.Z)
    local speed=horiz.Magnitude

    local distScale = 1 + math.clamp(dist*rangeGainPerStud, 0, 2.0)
    local speedScale = 1 + math.clamp(speed*0.05, 0, 0.5)
    local leadScale = distScale * speedScale

    local leadVec = horiz * t * leadAmount * leadScale
    local y = useStick and clamp(vel.Y * t * 0.12, -3, 3) or verticalOffset(targetChar, t, p, sameGround, groundPos)

    local pred = basePos + leadVec + Vector3.new(0,y,0)
    return finite3(pred) and pred or basePos
end

-- Gap/window helpers
local function hasVerticalClearance(pos, ignore)
    local up = raycastVec(pos, Vector3.new(0,1,0), verticalClearance, ignore)
    local down = raycastVec(pos, Vector3.new(0,-1,0), verticalClearance, ignore)
    return not up and not down
end
local function findGapInDirection(from, toTarget, ignore)
    local dir = unit(toTarget - from)
    local best, bestScore = nil, math.huge
    for _,ang in ipairs(windowSearchAngles) do
        local probeDir = rotateY(dir, ang)
        local probePos = from + probeDir * gapProbeRadius
        local hit = rayTowards(from, probePos, ignore)
        if not hit then
            if hasVerticalClearance(probePos, ignore) then
                local score = math.abs(ang) + (probePos - toTarget).Magnitude * 0.1
                if score < bestScore then best, bestScore = probePos, score end
            end
        end
    end
    return best
end

local function advancedPath(origin, targetPos, targetChar, ignore)
    local waypoints = {origin}
    local current = origin
    local detour = 0

    for _=1,maxPathSteps do
        local toT = targetPos - current
        local dist = toT.Magnitude
        if dist < 2.0 then table.insert(waypoints, targetPos) break end

        local hit,u = rayTowards(current, targetPos, ignore)
        if not hit or ignoreHit(hit) then
            table.insert(waypoints, targetPos); break
        end

        -- Try gaps first
        local gap = findGapInDirection(current, targetPos, ignore)
        if gap then
            local gdist=(gap-current).Magnitude
            if detour + gdist <= maxDetourDistance then
                table.insert(waypoints, gap); current=gap; detour+=gdist; continue
            end
        end

        -- Slide along wall toward target lateral motion if known
        local right = u:Cross(Vector3.new(0,1,0)).Unit
        local slideDir = right
        if targetChar then
            local vel=worldVel(targetChar)
            slideDir = (Vector3.new(vel.X,0,vel.Z):Dot(right) >= 0) and right or -right
        end

        local found=false
        for _,off in ipairs({3.0,6.0,9.0,12.0}) do
            local side = hit.Position + slideDir*off
            local peek = side + u * cornerPeekDist
            local h1 = rayTowards(current, side, ignore)
            local h2 = rayTowards(side, peek, ignore)
            if (not h1 or ignoreHit(h1)) and (not h2 or ignoreHit(h2)) and hasVerticalClearance(side, ignore) then
                local sdist=(side-current).Magnitude
                if detour+sdist <= maxDetourDistance then
                    table.insert(waypoints, side); current=side; detour+=sdist; found=true; break
                end
            end
        end
        if not found then
            -- small nudge and stop
            table.insert(waypoints, hit.Position - u*1.0)
            break
        end
    end

    return waypoints[#waypoints]
end

local function clampToFloor(aim, targetAnchor, ignore)
    local dir = (aim - targetAnchor.Position)
    local u,mag = unit(dir)
    if mag < 1 then return aim end
    local ahead = targetAnchor.Position + u*11
    local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances=ignore
    local hit = Workspace:Raycast(ahead + Vector3.new(0,3,0), Vector3.new(0,-50,0), p)
    if hit then return aim end
    if hit and hit.Position then return Vector3.new(aim.X, hit.Position.Y + 0.75, aim.Z) end
    return aim
end

-- Rate limit
local lastThrow, gapSec = 0, 0.25
local tokens, maxTokens, refill = 4,4,1.5
local lastRefill=os.clock()
local function readyToThrow()
    local now=os.clock(); local dt=now-lastRefill
    if dt>0 then tokens=math.min(maxTokens, tokens + dt*refill); lastRefill=now end
    if (now-lastThrow)<gapSec then return false end
    if tokens<1 then return false end
    tokens=tokens-1; lastThrow=now; return true
end

-- Main loop
local function step()
    if not CoreGui:FindFirstChild(SECURITY_MARKER) then if loopConn then loopConn:Disconnect(); loopConn=nil end return end
    if not Env.CRIMSON_AUTO_KNIFE.enabled then return end
    resolveKnife(); if not myKnife or not knifeRemote then return end
    if not myChar or not myRoot or not myHum or myHum.Health<=0 then return end
    if not throwIsAllowedNow() then return end

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local targetPlr, targetLimb = pickExposedTarget(origin)
    if not targetPlr or not targetLimb then return end

    local tc = targetPlr.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor = tc and aimPart(tc)
    if not th or th.Health<=0 or not anchor then return end
    if not readyToThrow() then return end

    local ignore={myChar}
    local gpos, sameGround = groundGhost(tc, ignore)
    rememberGroundedTorso(tc, sameGround, gpos)

    -- Predict to the chosen exposed limb
    local limbPred = predictPoint(origin, tc, targetLimb, sameGround, gpos)
    if not limbPred then return end

    -- Advanced pathing to the predicted limb position
    local aimPos = advancedPath(origin, limbPred, tc, ignore)
    if not aimPos or not finite3(aimPos) then return end

    aimPos = clampToFloor(aimPos, anchor, ignore)
    if not finite3(aimPos) then return end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable  = function() Env.CRIMSON_AUTO_KNIFE.enabled = true  end
Env.CRIMSON_AUTO_KNIFE.disable = function() Env.CRIMSON_AUTO_KNIFE.enabled = false end
