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

local maxPathSteps = 8
local gapProbeRadius = 4.0
local gapMinWidth = 1.8
local verticalClearance = 2.2
local windowSearchAngles = {-45, -30, -15, 0, 15, 30, 45}
local cornerPeekDist = 5.5
local intermediateWaypointSpacing = 6.0
local maxDetourDistance = 16.0

local BODY_PART_PRIORITY = {
    "Left Leg", "Right Leg",           
    "Left Foot", "Right Foot",         
    "Left Arm", "Right Arm",           
    "Left Hand", "Right Hand",         
    "LowerTorso", "UpperTorso",        
    "HumanoidRootPart",                
    "Head"                             
}

local groundedMemorySec = 0.35
local groundedTorsoYOffset = 1.0

local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConn

local trackStart = setmetatable({}, { __mode = "k" })
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

local function unit(v)
    local m = v.Magnitude
    if m == 0 or m ~= m then return Vector3.zero, 0 end
    return v / m, m
end
local function clamp(v, a, b)
    if b < a then a, b = b, a end
    if v ~= v then return a end
    return math.clamp(v, a, b)
end
local function finite3(v)
    return v and v.X == v.X and v.Y == v.Y and v.Z == v.Z
end
local function rotateVectorY(v, degrees)
    local rad = math.rad(degrees)
    local cos, sin = math.cos(rad), math.sin(rad)
    return Vector3.new(v.X * cos - v.Z * sin, v.Y, v.X * sin + v.Z * cos)
end

local function findKnife()
    local k = (me.Backpack and me.Backpack:FindFirstChild("Knife")) or (myChar and myChar:FindFirstChild("Knife"))
    if k ~= myKnife then
        myKnife = k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end
findKnife()

me.CharacterAdded:Connect(function(c)
    myChar = c
    myHum = c:WaitForChild("Humanoid")
    myRoot = c:WaitForChild("HumanoidRootPart")
    trackStart = setmetatable({}, { __mode = "k" })
    task.defer(findKnife)
end)
if me:FindFirstChild("Backpack") then
    me.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then findKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it==myKnife then findKnife() end end)
end
myChar.ChildAdded:Connect(function(it) if it.Name=="Knife" then findKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it==myKnife then findKnife() end end)

local function throwIsAllowedNow()
    if not myHum then return false end
    local now = os.clock()
    local ok = false
    for _, tr in ipairs(myHum:GetPlayingAnimationTracks()) do
        local id = tr.Animation and tr.Animation.AnimationId or ""
        for _, allow in ipairs(AllowedAnimIds) do
            if id:find(allow, 1, true) then
                if not trackStart[tr] then trackStart[tr] = now end
                if (now - trackStart[tr]) >= AnimGateSeconds then ok = true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr) ~= "Instance" or not tr.IsPlaying then
            trackStart[tr] = nil
        end
    end
    return ok
end

local function aimPart(char)
    return char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
end
local function worldVel(char)
    local p = aimPart(char)
    return p and p.AssemblyLinearVelocity or Vector3.zero
end

local function getExposedBodyPartsInPriority(character, ignore)
    if not character then return {} end

    local exposed = {}
    local origin = camera.CFrame.Position

    for _, partName in ipairs(BODY_PART_PRIORITY) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = ignore
            local u, mag = unit(part.Position - origin)
            local hit = Workspace:Raycast(origin, u * clamp(mag, 0, 12288), p)

            if not hit or hit.Instance:IsDescendantOf(character) or ignoreHit(hit) then
                table.insert(exposed, {part = part, name = partName, priority = #exposed + 1})
            end
        end
    end

    return exposed
end

local function chooseTarget()
    local mouse = me:GetMouse()
    local front, rest = {}, {}

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= me then
            local c = pl.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local a = c and aimPart(c)
            if h and h.Health > 0 and a then
                local v, on = camera:WorldToViewportPoint(a.Position)
                local dw = (a.Position - myRoot.Position).Magnitude
                if on then
                    local dm = (Vector2.new(v.X, v.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    table.insert(front, { player = pl, m = dm, d = dw })
                else
                    table.insert(rest, { player = pl, d = dw })
                end
            end
        end
    end

    table.sort(front, function(a,b)
        if math.abs(a.m - b.m) < 12 then
            return a.d < b.d
        end
        return a.m < b.m
    end)
    if #front > 0 then return front[1].player end

    table.sort(rest, function(a,b) return a.d < b.d end)
    if #rest > 0 then return rest[1].player end
    return nil
end

local function ignoreHit(hit)
    local inst = hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency >= ignoreThinTransparency then return true end
        local s = inst.Size
        if s.X < ignoreMinThickness or s.Y < ignoreMinThickness or s.Z < ignoreMinThickness then return true end
        local mat = inst.Material
        if mat == Enum.Material.Glass or mat == Enum.Material.ForceField then return true end

        if s.X < 0.8 and s.Y < 0.8 and s.Z < 0.8 then return true end
    end
    return false
end

local function rayTo(origin, dir, length, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    return Workspace:Raycast(origin, dir * length, p)
end

local function rayTowards(origin, target, ignore)
    local u, mag = unit(target - origin)
    local hit = rayTo(origin, u, clamp(mag, 0, 12288), ignore)
    return hit, u, mag
end

local function hasVerticalClearance(position, ignore)
    local up = rayTo(position, Vector3.new(0, 1, 0), verticalClearance, ignore)
    local down = rayTo(position, Vector3.new(0, -1, 0), verticalClearance, ignore)
    return not up and not down
end

local function findGapInDirection(from, toTarget, ignore)
    local baseDir = unit(toTarget - from)
    local bestGap = nil
    local bestScore = math.huge

    for _, angle in ipairs(windowSearchAngles) do
        local probeDir = rotateVectorY(baseDir, angle)
        local probePoint = from + probeDir * gapProbeRadius

        local hit = rayTowards(from, probePoint, ignore)
        if not hit then
            if hasVerticalClearance(probePoint, ignore) then
                local score = math.abs(angle) + (probePoint - toTarget).Magnitude * 0.1
                if score < bestScore then
                    bestGap = probePoint
                    bestScore = score
                end
            end
        end
    end

    return bestGap
end

local function findAdvancedPath(origin, targetPos, ignore)
    local waypoints = {origin}
    local current = origin
    local totalDetour = 0

    for step = 1, maxPathSteps do
        local toTarget = targetPos - current
        local dist = toTarget.Magnitude
        if dist < 2.0 then
            table.insert(waypoints, targetPos)
            break
        end

        local hit = rayTowards(current, targetPos, ignore)
        if not hit or ignoreHit(hit) then
            table.insert(waypoints, targetPos)
            break
        end

        local gap = findGapInDirection(current, targetPos, ignore)
        if gap then
            local gapDist = (gap - current).Magnitude
            if totalDetour + gapDist <= maxDetourDistance then
                table.insert(waypoints, gap)
                current = gap
                totalDetour = totalDetour + gapDist
                continue
            end
        end

        local u = unit(toTarget)
        local right = u:Cross(Vector3.new(0, 1, 0)).Unit

        local targetChar = nil
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= me and pl.Character then
                local anchor = aimPart(pl.Character)
                if anchor and (anchor.Position - targetPos).Magnitude < 5 then
                    targetChar = pl.Character
                    break
                end
            end
        end

        local slideDir = right
        if targetChar then
            local vel = worldVel(targetChar)
            local velRight = Vector3.new(vel.X, 0, vel.Z):Dot(right)
            slideDir = velRight >= 0 and right or -right
        end

        local foundSlide = false
        for _, offset in ipairs({3.0, 6.0, 9.0, 12.0}) do
            local slidePoint = hit.Position + slideDir * offset
            local peek = slidePoint + u * cornerPeekDist

            local slideHit = rayTowards(current, slidePoint, ignore)
            local peekHit = rayTowards(slidePoint, peek, ignore)

            if (not slideHit or ignoreHit(slideHit)) and 
               (not peekHit or ignoreHit(peekHit)) and 
               hasVerticalClearance(slidePoint, ignore) then

                local slideDist = (slidePoint - current).Magnitude
                if totalDetour + slideDist <= maxDetourDistance then
                    table.insert(waypoints, slidePoint)
                    current = slidePoint
                    totalDetour = totalDetour + slideDist
                    foundSlide = true
                    break
                end
            end
        end

        if not foundSlide then
            for _, yOffset in ipairs({2.5, -2.5, 5.0}) do
                local altPoint = hit.Position + slideDir * 4.0 + Vector3.new(0, yOffset, 0)
                local altHit = rayTowards(current, altPoint, ignore)

                if not altHit or ignoreHit(altHit) then
                    local altDist = (altPoint - current).Magnitude
                    if totalDetour + altDist <= maxDetourDistance then
                        table.insert(waypoints, altPoint)
                        current = altPoint
                        totalDetour = totalDetour + altDist
                        foundSlide = true
                        break
                    end
                end
            end
        end

        if not foundSlide then
            table.insert(waypoints, hit.Position - u * 1.0)
            break
        end
    end

    return #waypoints > 1 and waypoints[#waypoints] or nil
end

local function rememberGroundedTorso(targetChar, sameGround, groundPos)
    local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local torso = targetChar and targetChar:FindFirstChild("UpperTorso")
    if not hum or not torso then return end
    local id = targetChar:GetDebugId()
    if sameGround and groundPos then
        local p = torso.Position
        lastGroundedTorso[id] = Vector3.new(p.X, groundPos.Y + groundedTorsoYOffset, p.Z)
        lastGroundedTime[id] = os.clock()
    end
end

local function groundGhost(targetChar, ignore)
    local a = aimPart(targetChar); if not a then return nil, false end
    local from = a.Position + Vector3.new(0, 2.0, 0)
    local hit = rayTo(from, Vector3.new(0, -1, 0), maxGroundSnap, ignore)
    local groundPos = hit and hit.Position or nil

    if not groundPos then
        local vel = worldVel(targetChar)
        local f = Vector3.new(vel.X, 0, vel.Z)
        f = (f.Magnitude > 0) and f.Unit or Vector3.new(0,0,1)
        local r = f:Cross(Vector3.new(0,1,0)).Unit
        local samples = {
            Vector3.new(0,0,0), r * groundProbeRadius, -r * groundProbeRadius,
            f * groundProbeRadius, -f * groundProbeRadius,
        }
        for _,off in ipairs(samples) do
            local h2 = rayTo(from + off, Vector3.new(0,-1,0), maxGroundSnap, ignore)
            if h2 then groundPos = h2.Position break end
        end
    end

    local id = targetChar:GetDebugId()
    local same = false
    if groundPos then
        local lastY = lastGroundY[id]
        if lastY then same = math.abs(groundPos.Y - lastY) <= sameGroundTolerance end
        lastGroundY[id] = groundPos.Y
    end
    return groundPos, same
end

local baseKnifeSpeed = 205
local function knifeSpeedAt(dist)
    local gain = 1 + math.clamp(dist * 0.0035, 0, 1.5)
    return baseKnifeSpeed * gain
end
local function timeTo(dist)
    local s = knifeSpeedAt(dist)
    if s <= 0 or dist ~= dist then return 0 end
    return dist / s
end

local function hasNormalJumpPower(hum)
    local jp = hum and hum.JumpPower or 50
    return jp >= 40 and jp <= 75
end

local function verticalOffset(targetChar, t, focusPart, sameGround, groundPos)
    local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not hum or not focusPart then return 0 end

    local vy = worldVel(targetChar).Y
    local extraVy = 0
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _,o in ipairs(hrp:GetChildren()) do
            if o:IsA("BodyVelocity") then extraVy += o.Velocity.Y end
        end
    end

    local normalJP = hasNormalJumpPower(hum)
    local state = hum:GetState()
    local id = targetChar:GetDebugId()
    local now = os.clock()
    local recentlyGrounded = lastGroundedTime[id] and (now - lastGroundedTime[id] <= groundedMemorySec)

    if normalJP and (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall) and recentlyGrounded and (not sameGround) then
        return clamp(vy * t * 0.12, -3, 3)
    end

    local blended = vy + extraVy * 0.35
    local y = blended * t * 0.38 - 0.5 * Workspace.Gravity * (t*t) * 0.35
    if normalJP then y = clamp(y, -28, 36) else y = clamp(y, -22, 28) end

    if state == Enum.HumanoidStateType.Freefall then
        y = y - 0.08 * Workspace.Gravity * (t*t)
    elseif state == Enum.HumanoidStateType.Jumping and normalJP then
        y = y * 0.75
    end
    if (hum.WalkSpeed or 16) < 8 then y = y * 0.7 end
    return y
end

local function predictPoint(origin, targetChar, focusPart, sameGround, groundPos)
    local p = focusPart or aimPart(targetChar)
    if not p then return nil end

    local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local id = targetChar:GetDebugId()
    local basePos

    local now = os.clock()
    local useTorsoStick = false
    if hum and hasNormalJumpPower(hum) and lastGroundedTorso[id] and lastGroundedTime[id] and (now - lastGroundedTime[id] <= groundedMemorySec) then
        local state = hum:GetState()
        if (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall) and (not sameGround) then
            basePos = lastGroundedTorso[id]
            useTorsoStick = true
        end
    end

    if not basePos then
        basePos = p.Position
        if groundPos then

            local yOffset = 1.0
            if p.Name:find("Leg") or p.Name:find("Foot") then
                yOffset = 0.5  
            elseif p.Name == "Head" then
                yOffset = 1.5
            end
            basePos = Vector3.new(basePos.X, groundPos.Y + yOffset, basePos.Z)
        end
    end

    local dist = (basePos - origin).Magnitude
    local t = timeTo(dist); if t == 0 then return basePos end

    local vel = worldVel(targetChar)
    local horiz = Vector3.new(vel.X, 0, vel.Z)
    local speed = horiz.Magnitude

    local distScale = 1 + math.clamp(dist * rangeGainPerStud, 0, 2.0)
    local speedScale = 1 + math.clamp(speed * 0.05, 0, 0.5)
    local leadScale = distScale * speedScale

    local leadVec = horiz * t * leadAmount * leadScale
    local y = 0
    if not useTorsoStick then
        y = verticalOffset(targetChar, t, p, sameGround, groundPos)
    else
        y = clamp(worldVel(targetChar).Y * t * 0.12, -3, 3)
    end

    local pred = basePos + leadVec + Vector3.new(0, y, 0)
    return finite3(pred) and pred or basePos
end

local function advancedPathfinding(origin, targetChar, ignoreList, sameGround, groundPos)

    local exposedParts = getExposedBodyPartsInPriority(targetChar, ignoreList)

    for _, partInfo in ipairs(exposedParts) do
        local part = partInfo.part
        local pred = predictPoint(origin, targetChar, part, sameGround, groundPos)
        if pred then
            local advancedAim = findAdvancedPath(origin, pred, ignoreList)
            if advancedAim then 
                return advancedAim, part  
            end
        end
    end

    local a = aimPart(targetChar)
    if a then
        local bodyPred = predictPoint(origin, targetChar, a, sameGround, groundPos)
        if bodyPred then
            local advancedAim = findAdvancedPath(origin, bodyPred, ignoreList)
            if advancedAim then return advancedAim, a end
        end
    end

    return nil, nil
end

local function clampToFloor(aim, targetAnchor, ignore)
    local dir = (aim - targetAnchor.Position)
    local u,mag = unit(dir)
    if mag < 1 then return aim end
    local ahead = targetAnchor.Position + u * 11
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    local hit = Workspace:Raycast(ahead + Vector3.new(0,3,0), Vector3.new(0,-50,0), p)
    if hit then return aim end
    if hit and hit.Position then
        return Vector3.new(aim.X, hit.Position.Y + 0.75, aim.Z)
    end
    return aim
end

local lastThrow, minThrowGap = 0, 0.25
local tokens, maxTokens, refillPerSec = 4, 4, 1.5
local lastRefill = os.clock()
local function readyToThrow()
    local now = os.clock()
    local dt = now - lastRefill
    if dt > 0 then
        tokens = math.min(maxTokens, tokens + dt * refillPerSec)
        lastRefill = now
    end
    if (now - lastThrow) < minThrowGap then return false end
    if tokens < 1 then return false end
    tokens = tokens - 1
    lastThrow = now
    return true
end

local function step()
    if not CoreGui:FindFirstChild(SECURITY_MARKER) then
        if loopConn then loopConn:Disconnect(); loopConn=nil end
        return
    end
    if not Env.CRIMSON_AUTO_KNIFE.enabled then return end

    findKnife()
    if not myKnife or not knifeRemote then return end
    if not myChar or not myRoot or not myHum or myHum.Health <= 0 then return end
    if not throwIsAllowedNow() then return end

    local targetPlr = chooseTarget()
    if not targetPlr then return end
    local tc = targetPlr.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local tAnchor = tc and aimPart(tc)
    if not th or th.Health <= 0 or not tAnchor then return end

    if not readyToThrow() then return end

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local ignore = { myChar }

    local groundPos, sameGround = groundGhost(tc, ignore)
    rememberGroundedTorso(tc, sameGround, groundPos)

    local aimPos, targetedPart = advancedPathfinding(origin, tc, ignore, sameGround, groundPos)
    if not aimPos or not finite3(aimPos) then return end
    aimPos = clampToFloor(aimPos, tAnchor, ignore)
    if not finite3(aimPos) then return end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable  = function() Env.CRIMSON_AUTO_KNIFE.enabled = true  end
Env.CRIMSON_AUTO_KNIFE.disable = function() Env.CRIMSON_AUTO_KNIFE.enabled = false end
