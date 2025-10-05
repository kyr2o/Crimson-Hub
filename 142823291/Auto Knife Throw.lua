local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local markerName = "_cr1m50n__kv_ok__7F2B1D"
if not coreGui:FindFirstChild(markerName) then return end

local predLeadAmount = 5
local predRangeGain = 0.005
local predKnifeSpeed = 64/0.85

local env = (getgenv and getgenv()) or _G
env.CRIMSON_AUTO_KNIFE = env.CRIMSON_AUTO_KNIFE or { enabled = true }

local allowedAnimIds = { "rbxassetid://1957618848" }
local animGateSeconds = 0.75

local me = players.LocalPlayer
local camera = workspace.CurrentCamera
local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")

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
    local k = (me.Backpack and me.Backpack:FindFirstChild("Knife")) or (myChar and myChar:FindFirstChild("Knife"))
    if k ~= myKnife then
        myKnife = k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end

resolveKnife()
me.CharacterAdded:Connect(function(c)
    myChar = c
    myHum = c:WaitForChild("Humanoid")
    myRoot = c:WaitForChild("HumanoidRootPart")
    trackStart = setmetatable({}, { __mode = "k" })
    task.defer(resolveKnife)
end)
if me:FindFirstChild("Backpack") then
    me.Backpack.ChildAdded:Connect(function(it) if it.Name == "Knife" then resolveKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it == myKnife then resolveKnife() end end)
end
myChar.ChildAdded:Connect(function(it) if it.Name == "Knife" then resolveKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it == myKnife then resolveKnife() end end)

local function throwIsAllowedNow()
    if not myHum then return false end
    local now = os.clock()
    local ok = false
    for _, tr in ipairs(myHum:GetPlayingAnimationTracks()) do
        local id = tr.Animation and tr.Animation.AnimationId or ""
        for _, allow in ipairs(allowedAnimIds) do
            if id:find(allow, 1, true) then
                if not trackStart[tr] then trackStart[tr] = now end
                if (now - trackStart[tr]) >= animGateSeconds then ok = true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr) ~= "Instance" or not tr.IsPlaying then trackStart[tr] = nil end
    end
    return ok
end

local function aimPart(char)
    return char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
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
        if s.X < 0.4 or s.Y < 0.4 or s.Z < 0.4 then return true end
        local m = inst.Material
        if m == Enum.Material.Glass or m == Enum.Material.ForceField then return true end
    end
    return false
end

local function raycastVec(origin, dir, len, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    return workspace:Raycast(origin, dir*len, p)
end

local function rayTowards(origin, target, ignore)
    local u, mag = unit(target-origin)
    local hit = raycastVec(origin, u, clamp(mag, 0, 12288), ignore)
    return hit, u, mag
end

local LimbPriority = {
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"
}

local function isPartExposed(part, origin, ignore)
    if not part or not part:IsA("BasePart") then return false end
    local c = part.Position
    local s = part.Size
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
    local clear = 0
    local fullIgnore = {myChar, part.Parent}
    for _, i in ipairs(ignore) do table.insert(fullIgnore, i) end
    for _, p in ipairs(pts) do
        local h = rayTowards(origin, p, fullIgnore)
        if not h or h.Instance:IsDescendantOf(part.Parent) or ignoreHit(h) then
            clear = clear + 1
        end
    end
    return (clear/#pts) >= 0.4
end

local function getExposedLimbs(char, origin, ignore)
    local exposed = {}
    if not char then return exposed end
    for _, name in ipairs(LimbPriority) do
        local part = char:FindFirstChild(name)
        if part and isPartExposed(part, origin, ignore) then
            table.insert(exposed, part)
        end
    end
    return exposed
end

local function pickExposedTarget(origin)
    local mouse = me:GetMouse()
    local bestPlr, bestPart, bestScore = nil, nil, math.huge
    for _, pl in ipairs(players:GetPlayers()) do
        if pl ~= me then
            local c = pl.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if c and h and h.Health > 0 then
                local ignore = {myChar}
                for _, part in ipairs(getExposedLimbs(c, origin, ignore)) do
                    local v, on = camera:WorldToViewportPoint(part.Position)
                    local screenScore = on and (Vector2.new(v.X, v.Y)-Vector2.new(mouse.X, mouse.Y)).Magnitude or 9999
                    local worldScore = (part.Position-origin).Magnitude*0.1
                    local limbBias = 10
                    if part.Name:find("Foot") then limbBias = -100
                    elseif part.Name:find("LowerLeg") then limbBias = -80
                    elseif part.Name:find("Leg") then limbBias = -60
                    elseif part.Name:find("Hand") then limbBias = -40
                    elseif part.Name:find("LowerArm") then limbBias = -30
                    elseif part.Name:find("Arm") then limbBias = -20
                    elseif part.Name == "Head" then limbBias = -10 end
                    local score = screenScore + worldScore + limbBias
                    if score < bestScore then
                        bestPlr, bestPart, bestScore = pl, part, score
                    end
                end
            end
        end
    end
    return bestPlr, bestPart
end

local lastGroundY, lastGroundedTorso, lastGroundedTime = {}, {}, {}

local function rememberGroundedTorso(tc, same, gp)
    local hum = tc and tc:FindFirstChildOfClass("Humanoid")
    local torso = tc and tc:FindFirstChild("UpperTorso")
    if not hum or not torso then return end
    local id = tc:GetDebugId()
    if same and gp then
        local p = torso.Position
        lastGroundedTorso[id] = Vector3.new(p.X, gp.Y+1, p.Z)
        lastGroundedTime[id] = os.clock()
    end
end

local function groundGhost(tc, ignore)
    local a = aimPart(tc)
    if not a then return nil, false end
    local from = a.Position+Vector3.new(0,2,0)
    local hit = raycastVec(from, Vector3.new(0,-1,0), 24, ignore)
    local gp = hit and hit.Position or nil
    local id = tc:GetDebugId()
    local same = false
    if gp then
        local last = lastGroundY[id]
        same = last and math.abs(gp.Y-last)<=1.75
        lastGroundY[id] = gp.Y
    end
    return gp, same
end

local function knifeSpeedAt(dist)
    return predKnifeSpeed
end

local function timeTo(dist)
    if dist <= 0 then return 0 end
    return dist/knifeSpeedAt(dist)
end

local function hasNormalJP(h)
    return h and h.JumpPower and h.JumpPower>=40 and h.JumpPower<=75
end

local function predictPoint(origin, tc, focusPart, same, gp)
    local p = focusPart or aimPart(tc)
    if not p then return nil end
    local hum = tc and tc:FindFirstChildOfClass("Humanoid")
    local id = tc:GetDebugId()
    local now = os.clock()
    local useStick = false
    if hum and hasNormalJP(hum) and lastGroundedTorso[id] and lastGroundedTime[id]
       and now-lastGroundedTime[id]<=0.35 then
        local st = hum:GetState()
        if (st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall) and not same then
            useStick = true
        end
    end
    local basePos = useStick and lastGroundedTorso[id] or p.Position
    if not useStick and gp then
        basePos = Vector3.new(basePos.X, gp.Y + (p.Name=="Head" and 1 or 0.9), basePos.Z)
    end
    local dist = (basePos-origin).Magnitude
    local t = timeTo(dist)
    if t == 0 then return basePos end
    local vel = worldVel(tc)
    local horiz = Vector3.new(vel.X, 0, vel.Z)
    local speed = horiz.Magnitude
    local doLead = speed > 4.25
    local distScale = 1 + clamp(dist * predRangeGain, 0, 2.0)
    local speedScale = doLead and (1 + clamp(speed * 0.05, 0, 0.5)) or 1
    local leadScale = doLead and (distScale * speedScale) or 0
    local leadVec = doLead and (horiz * t * predLeadAmount * leadScale) or Vector3.zero
    local vy = vel.Y
    local extra = 0
    local hrp = tc:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, o in ipairs(hrp:GetChildren()) do
            if o:IsA("BodyVelocity") then extra = extra + o.Velocity.Y end
        end
    end
    local st = hum and hum:GetState() or Enum.HumanoidStateType.Running
    local y
    if useStick then
        y = clamp(vy * t * 0.12, -3, 3)
    else
        local blended = vy + extra * 0.35
        y = blended * t * 0.38 - 0.5 * workspace.Gravity * (t*t) * 0.35
        if hasNormalJP(hum) then y = clamp(y, -28, 36) else y = clamp(y, -22, 28) end
        if st==Enum.HumanoidStateType.Freefall then y = y - 0.08 * workspace.Gravity * (t*t)
        elseif st==Enum.HumanoidStateType.Jumping and hasNormalJP(hum) then y = y * 0.75 end
        if hum and hum.WalkSpeed < 8 then y = y * 0.7 end
    end
    local targetDY = p.Position.Y - origin.Y
    if not doLead and math.abs(vy) < 1 then
        y = clamp(y, -4, targetDY>0 and 6 or 4)
    elseif targetDY>0 and y>0 then
        y = math.min(y, 8)
    end
    local pred = basePos + leadVec + Vector3.new(0, y, 0)
    return finite3(pred) and pred or basePos
end

local function directAim(origin, targetPos, tc, ignore)
    local hit, toDir = rayTowards(origin, targetPos, ignore)
    if not hit or ignoreHit(hit) then return targetPos end
    local right = toDir:Cross(Vector3.new(0,1,0)).Unit
    local slideDir = right
    local vel = worldVel(tc)
    local horiz = Vector3.new(vel.X,0,vel.Z)
    if horiz.Magnitude > 0.5 then
        slideDir = (horiz:Dot(right) >= 0) and right or -right
    end
    for _, off in ipairs({1.5,2.5}) do
        for _, dir in ipairs({slideDir, -slideDir}) do
            local slidePos = hit.Position + dir*off
            slidePos = Vector3.new(slidePos.X, targetPos.Y, slidePos.Z)
            local h1 = rayTowards(origin, slidePos, ignore)
            if h1 and not ignoreHit(h1) then continue end
            local h2 = rayTowards(slidePos, targetPos, ignore)
            if not h2 or ignoreHit(h2) then return slidePos end
        end
    end
    return hit.Position - toDir*0.5
end

local function clampToStairPlane(originAim, limbPred, ignore)
    local down = raycastVec(limbPred+Vector3.new(0,3,0), Vector3.new(0,-1,0), 8, ignore)
    if not down then return originAim end
    local floorY = down.Position.Y + 0.6
    if math.abs(limbPred.Y - floorY) <= 1.25 then
        return Vector3.new(originAim.X, floorY, originAim.Z)
    end
    return originAim
end

local lastThrow, gapSec, tokens, maxTokens, refill, lastRefill = 0, 0.27, 4, 4, 1.5, os.clock()

local function readyToThrow()
    local now = os.clock()
    local dt = now - lastRefill
    if dt > 0 then
        tokens = math.min(maxTokens, tokens + dt*refill)
        lastRefill = now
    end
    if now - lastThrow < gapSec or tokens < 1 then return false end
    tokens = tokens - 1
    lastThrow = now
    return true
end

local function step()
    if not coreGui:FindFirstChild(markerName) then
        if loopConn then loopConn:Disconnect() end
        return
    end
    if not env.CRIMSON_AUTO_KNIFE.enabled then return end
    resolveKnife()
    if not myKnife or not knifeRemote then return end
    if not myChar or not myRoot or not myHum or myHum.Health <= 0 then return end
    if not throwIsAllowedNow() then return end

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local targetPlr, targetLimb = pickExposedTarget(origin)
    if not targetPlr or not targetLimb then return end

    local tc = targetPlr.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor = tc and aimPart(tc)
    if not th or th.Health <= 0 or not anchor then return end
    if not readyToThrow() then return end

    local ignore = {myChar}
    local gp, same = groundGhost(tc, ignore)
    rememberGroundedTorso(tc, same, gp)

    local limbPred = predictPoint(origin, tc, targetLimb, same, gp)
    if not limbPred then return end

    local aimPos = directAim(origin, limbPred, tc, ignore)
    if not aimPos or not finite3(aimPos) then return end

    aimPos = clampToStairPlane(aimPos, limbPred, ignore)
    if not finite3(aimPos) then return end

    local dY = math.abs((limbPred - origin).Y)
    if dY > 0.5 then
        if os.clock() - (_G.__stair_hold or 0) < 0.05 then return end
        _G.__stair_hold = os.clock()
    end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = runService.Heartbeat:Connect(step)

env.CRIMSON_AUTO_KNIFE.enable = function() env.CRIMSON_AUTO_KNIFE.enabled = true end
env.CRIMSON_AUTO_KNIFE.disable = function() env.CRIMSON_AUTO_KNIFE.enabled = false end
