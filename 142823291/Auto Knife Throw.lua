-- Crimson Hub Auto-Knife: FIXED pathfinding - no random openings, direct routes to exposed limbs only

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

-- Animation gate
local AllowedAnimIds = {
    "rbxassetid://1957618848",
}
local AnimGateSeconds = 0.7

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

-- CONSTRAINED pathfinding - only small adjustments toward target
local maxSideStep = 4.0        -- max distance to step sideways around obstacles
local maxVerticalStep = 3.0    -- max distance to step up/down around obstacles  
local cornerPeekDist = 2.5     -- small peek distance past corners
local maxTotalDetour = 8.0     -- total detour distance allowed

-- Exposed limb detection
local exposureCheckRadius = 0.8
local minExposureRatio = 0.4

-- State
local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConn

-- Animation tracking
local trackStart = setmetatable({}, { __mode = "k" })
-- Ground memory per target
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

-- Math helpers
local function unit(v) local m=v.Magnitude if m==0 or m~=m then return Vector3.zero,0 end return v/m,m end
local function clamp(v,a,b) if b<a then a,b=b,a end if v~=v then return a end return math.clamp(v,a,b) end
local function finite3(v) return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z end

-- Knife management  
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

-- Animation gate
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

-- Character helpers
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

-- Exposed limb detection (unchanged - this part works correctly)
local LimbPriority = {
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"
}

local function isPartExposed(part, origin, ignore)
    if not part or not part:IsA("BasePart") then return false end
    local center = part.Position; local size = part.Size
    local checkPoints = {
        center, center + Vector3.new(size.X*0.3, 0, 0), center + Vector3.new(-size.X*0.3, 0, 0),
        center + Vector3.new(0, size.Y*0.3, 0), center + Vector3.new(0, -size.Y*0.3, 0),
        center + Vector3.new(0, 0, size.Z*0.3), center + Vector3.new(0, 0, -size.Z*0.3),
    }
    if part.Name:find("Foot") or part.Name:find("Hand") or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(checkPoints, center + Vector3.new(size.X*0.4, size.Y*0.4, 0))
        table.insert(checkPoints, center + Vector3.new(-size.X*0.4, size.Y*0.4, 0))
        table.insert(checkPoints, center + Vector3.new(size.X*0.4, -size.Y*0.4, 0))
        table.insert(checkPoints, center + Vector3.new(-size.X*0.4, -size.Y*0.4, 0))
    end
    
    local clearCount = 0
    for _, point in ipairs(checkPoints) do
        local hit = rayTowards(origin, point, ignore)
        if not hit or hit.Instance:IsDescendantOf(part.Parent) or ignoreHit(hit) then
            clearCount = clearCount + 1
        end
    end
    return (clearCount / #checkPoints) >= minExposureRatio
end

local function getExposedLimbs(char, origin, ignore)
    local exposed = {}; if not char then return exposed end
    local fullIgnore = {table.unpack(ignore)}; table.insert(fullIgnore, char)
    for _,name in ipairs(LimbPriority) do
        local part = char:FindFirstChild(name)
        if part and isPartExposed(part, origin, fullIgnore) then
            table.insert(exposed, part)
        end
    end
    return exposed
end

local function pickExposedTarget(origin)
    local mouse = me:GetMouse(); local candidates = {}
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= me then
            local c=pl.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
            if c and h and h.Health>0 then
                local ignore={myChar}; local parts = getExposedLimbs(c, origin, ignore)
                for _,part in ipairs(parts) do
                    table.insert(candidates, {player=pl, part=part})
                end
            end
        end
    end
    if #candidates == 0 then return nil, nil end

    local best, bestScore = nil, math.huge
    for _, candidate in ipairs(candidates) do
        local part = candidate.part; local v, on = camera:WorldToViewportPoint(part.Position)
        local screenScore = on and (Vector2.new(v.X,v.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude or 9999
        local worldScore = (part.Position - origin).Magnitude * 0.1
        local limbBias = 0
        if part.Name:find("Foot") then limbBias = -100
        elseif part.Name:find("LowerLeg") then limbBias = -80
        elseif part.Name:find("Leg") then limbBias = -60
        elseif part.Name:find("Hand") then limbBias = -40
        elseif part.Name:find("LowerArm") then limbBias = -30
        elseif part.Name:find("Arm") then limbBias = -20
        elseif part.Name=="Head" then limbBias = -10
        else limbBias = 10 end
        local totalScore = screenScore + worldScore + limbBias
        if totalScore < bestScore then best, bestScore = candidate, totalScore end
    end
    return best and best.player or nil, best and best.part or nil
end

-- Ground ghost tracking (unchanged)
local function rememberGroundedTorso(targetChar, sameGround, groundPos)
    local hum=targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local torso=targetChar and targetChar:FindFirstChild("UpperTorso")
    if not hum or not torso then return end; local id=targetChar:GetDebugId()
    if sameGround and groundPos then
        local p=torso.Position; lastGroundedTorso[id]=Vector3.new(p.X, groundPos.Y + groundedTorsoYOffset, p.Z)
        lastGroundedTime[id]=os.clock()
    end
end

local function groundGhost(targetChar, ignore)
    local a=aimPart(targetChar); if not a then return nil,false end
    local from=a.Position + Vector3.new(0,2,0); local hit=raycastVec(from, Vector3.new(0,-1,0), maxGroundSnap, ignore)
    local gpos = hit and hit.Position or nil
    if not gpos then
        local vel=worldVel(targetChar); local f=Vector3.new(vel.X,0,vel.Z); f = f.Magnitude>0 and f.Unit or Vector3.new(0,0,1)
        local r=f:Cross(Vector3.new(0,1,0)).Unit
        for _,off in ipairs({Vector3.new(0,0,0), r*groundProbeRadius, -r*groundProbeRadius, f*groundProbeRadius, -f*groundProbeRadius}) do
            local h2=raycastVec(from+off, Vector3.new(0,-1,0), maxGroundSnap, ignore)
            if h2 then gpos=h2.Position break end
        end
    end
    local id=targetChar:GetDebugId(); local same=false
    if gpos then local last=lastGroundY[id]
        if last then same = math.abs(gpos.Y - last) <= sameGroundTolerance end; lastGroundY[id]=gpos.Y
    end
    return gpos, same
end

-- Travel and prediction (unchanged)
local baseKnifeSpeed=205
local function knifeSpeedAt(dist) return baseKnifeSpeed * (1 + math.clamp(dist*0.0035,0,1.5)) end
local function timeTo(dist) local s=knifeSpeedAt(dist) if s<=0 or dist~=dist then return 0 end return dist/s end
local function hasNormalJP(h) local jp=h and h.JumpPower or 50 return jp>=40 and jp<=75 end

local function verticalOffset(targetChar, t, focusPart, sameGround, groundPos)
    local hum=targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not hum or not focusPart then return 0 end
    local vy=worldVel(targetChar).Y; local extra=0; local hrp=targetChar:FindFirstChild("HumanoidRootPart")
    if hrp then for _,o in ipairs(hrp:GetChildren()) do if o:IsA("BodyVelocity") then extra+=o.Velocity.Y end end end
    local normal=hasNormalJP(hum); local st=hum:GetState(); local id=targetChar:GetDebugId()
    local now=os.clock(); local recent=lastGroundedTime[id] and (now-lastGroundedTime[id]<=groundedMemorySec)

    if normal and (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and recent and (not sameGround) then
        return clamp(vy * t * 0.12, -3, 3)
    end

    local blended=vy + extra*0.35; local y = blended * t * 0.38 - 0.5 * Workspace.Gravity * (t*t) * 0.35
    y = normal and clamp(y,-28,36) or clamp(y,-22,28)
    if st==Enum.HumanoidStateType.Freefall then y = y - 0.08 * Workspace.Gravity * (t*t)
    elseif st==Enum.HumanoidStateType.Jumping and normal then y = y * 0.75 end
    if (hum.WalkSpeed or 16) < 8 then y = y * 0.7 end
    return y
end

local function predictPoint(origin, targetChar, focusPart, sameGround, groundPos)
    local p=focusPart or aimPart(targetChar); if not p then return nil end
    local hum=targetChar:FindFirstChildOfClass("Humanoid"); local id=targetChar:GetDebugId(); local now=os.clock(); local useStick=false
    if hum and hasNormalJP(hum) and lastGroundedTorso[id] and lastGroundedTime[id] and (now-lastGroundedTime[id]<=groundedMemorySec) then
        local st=hum:GetState()
        if (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and (not sameGround) then useStick=true end
    end

    local basePos = useStick and lastGroundedTorso[id] or p.Position
    if not useStick and groundPos then
        basePos = Vector3.new(basePos.X, groundPos.Y + (p.Name=="Head" and 1.5 or 0.9), basePos.Z)
    end

    local dist=(basePos - origin).Magnitude; local t=timeTo(dist); if t==0 then return basePos end
    local vel=worldVel(targetChar); local horiz=Vector3.new(vel.X,0,vel.Z); local speed=horiz.Magnitude
    local distScale = 1 + math.clamp(dist*rangeGainPerStud, 0, 2.0); local speedScale = 1 + math.clamp(speed*0.05, 0, 0.5)
    local leadScale = distScale * speedScale; local leadVec = horiz * t * leadAmount * leadScale
    local y = useStick and clamp(vel.Y * t * 0.12, -3, 3) or verticalOffset(targetChar, t, p, sameGround, groundPos)
    local pred = basePos + leadVec + Vector3.new(0,y,0)
    return finite3(pred) and pred or basePos
end

-- FIXED: Constrained pathfinding that only makes small adjustments toward the target
local function constrainedPath(origin, targetPos, targetChar, ignore)
    -- First check direct path
    local hit, dirToTarget = rayTowards(origin, targetPos, ignore)
    if not hit or ignoreHit(hit) then
        return targetPos  -- Direct path is clear
    end

    -- Path is blocked, try SMALL adjustments only
    local hitPos = hit.Position
    local toTarget = unit(targetPos - origin)
    local right = toTarget:Cross(Vector3.new(0,1,0)).Unit
    
    -- Prefer sliding toward target's movement if known
    local slideDir = right
    if targetChar then
        local vel = worldVel(targetChar)
        local velHorizontal = Vector3.new(vel.X, 0, vel.Z)
        if velHorizontal.Magnitude > 1 then
            slideDir = (velHorizontal:Dot(right) >= 0) and right or -right
        end
    end

    -- Try small side steps around the obstacle
    local bestPath = nil
    local bestScore = math.huge
    
    for _, offset in ipairs({2.0, 3.5}) do  -- Only small offsets
        for _, direction in ipairs({slideDir, -slideDir}) do
            local sideStep = hitPos + direction * offset
            
            -- Make sure side step doesn't go too far from original path
            local distanceFromPath = (sideStep - (origin + toTarget * (sideStep - origin):Dot(toTarget))).Magnitude
            if distanceFromPath > maxSideStep then continue end
            
            -- Check if we can reach the side step
            local reachHit = rayTowards(origin, sideStep, ignore)
            if reachHit and not ignoreHit(reachHit) then continue end
            
            -- Check if we can see target from side step  
            local seeHit = rayTowards(sideStep, targetPos, ignore)
            if seeHit and not ignoreHit(seeHit) then
                -- Try small peek past the side step
                local peek = sideStep + toTarget * cornerPeekDist
                seeHit = rayTowards(sideStep, peek, ignore)
                if seeHit and not ignoreHit(seeHit) then continue end
                sideStep = peek
            end
            
            -- Score this path (prefer shorter detours)
            local detourDistance = (sideStep - origin).Magnitude + (targetPos - sideStep).Magnitude
            local directDistance = (targetPos - origin).Magnitude
            local score = detourDistance - directDistance
            
            if score < bestScore and score < maxTotalDetour then
                bestPath = sideStep
                bestScore = score
            end
        end
    end

    -- Try small vertical adjustments if horizontal failed
    if not bestPath then
        for _, yOffset in ipairs({maxVerticalStep, -maxVerticalStep}) do
            local vertStep = hitPos + Vector3.new(0, yOffset, 0) + slideDir * 2.0
            
            local reachHit = rayTowards(origin, vertStep, ignore)
            if not reachHit or ignoreHit(reachHit) then
                local seeHit = rayTowards(vertStep, targetPos, ignore)
                if not seeHit or ignoreHit(seeHit) then
                    local detourDist = (vertStep - origin).Magnitude + (targetPos - vertStep).Magnitude
                    local directDist = (targetPos - origin).Magnitude
                    if (detourDist - directDist) < maxTotalDetour then
                        bestPath = vertStep
                        break
                    end
                end
            end
        end
    end

    -- Return best path found, or fall back to hitting the obstacle
    return bestPath or (hitPos - dirToTarget * 1.0)
end

local function clampToFloor(aim, targetAnchor, ignore)
    local dir = (aim - targetAnchor.Position); local u,mag = unit(dir); if mag < 1 then return aim end
    local ahead = targetAnchor.Position + u*11
    local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances=ignore
    local hit = Workspace:Raycast(ahead + Vector3.new(0,3,0), Vector3.new(0,-50,0), p)
    return hit and Vector3.new(aim.X, hit.Position.Y + 0.75, aim.Z) or aim
end

-- Rate limiting
local lastThrow, gapSec = 0, 0.25; local tokens, maxTokens, refill = 4,4,1.5; local lastRefill=os.clock()
local function readyToThrow()
    local now=os.clock(); local dt=now-lastRefill
    if dt>0 then tokens=math.min(maxTokens, tokens + dt*refill); lastRefill=now end
    if (now-lastThrow)<gapSec or tokens<1 then return false end
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

    local tc = targetPlr.Character; local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor = tc and aimPart(tc)
    if not th or th.Health<=0 or not anchor then return end
    if not readyToThrow() then return end

    local ignore={myChar}; local gpos, sameGround = groundGhost(tc, ignore)
    rememberGroundedTorso(tc, sameGround, gpos)

    local limbPred = predictPoint(origin, tc, targetLimb, sameGround, gpos)
    if not limbPred then return end

    -- Use constrained pathfinding instead of the old advanced pathfinding
    local aimPos = constrainedPath(origin, limbPred, tc, ignore)
    if not aimPos or not finite3(aimPos) then return end
    aimPos = clampToFloor(aimPos, anchor, ignore)
    if not finite3(aimPos) then return end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable  = function() Env.CRIMSON_AUTO_KNIFE.enabled = true  end
Env.CRIMSON_AUTO_KNIFE.disable = function() Env.CRIMSON_AUTO_KNIFE.enabled = false end
