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
local maxWallSteps = 4
local sideProbe = {3.0, 6.0, 9.0}
local heightProbe = {2.0, -2.0}
local peekForward = 6.0
local ignoreThinTransparency = 0.4
local ignoreMinThickness = 0.4
local groundProbeRadius = 2.5
local maxGroundSnap = 24
local sameGroundTolerance = 1.75

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

local function rememberGroundedTorso(targetChar, sameGround, groundPos)
    local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local torso = targetChar and targetChar:FindFirstChild("UpperTorso")
    if not hum or not torso then return end
    local id = targetChar:GetDebugId()
    if sameGround and groundPos then
        local p = torso.Position
        lastGroundedTorso[id] = Vector3.new(p.X, groundPos.Y + groundedTorsoYOffset, p.Z)
        lastGroundedTime[id]  = os.clock()
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
            Vector3.new(0,0,0),
            r * groundProbeRadius,
            -r * groundProbeRadius,
            f * groundProbeRadius,
            -f * groundProbeRadius,
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
        if lastY then
            same = math.abs(groundPos.Y - lastY) <= sameGroundTolerance
        end
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
            basePos = Vector3.new(basePos.X, groundPos.Y + (p.Name == "Head" and 1.5 or 1.0), basePos.Z)
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

local function axes(v)
    local u,_ = unit(v)
    if u.Magnitude == 0 then return Vector3.new(1,0,0), Vector3.new(0,1,0) end
    local up = Vector3.new(0,1,0)
    if math.abs(u:Dot(up)) > 0.95 then up = Vector3.new(1,0,0) end
    local right = (u:Cross(up)).Unit
    local newUp = (right:Cross(u)).Unit
    return right, newUp
end

local function advancedPath(origin, targetChar, ignoreList, sameGround, groundPos)
    local head = targetChar:FindFirstChild("Head")
    if head then
        local headPred = predictPoint(origin, targetChar, head, sameGround, groundPos)
        if headPred then
            local hit, u = rayTowards(origin, headPred, ignoreList)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or ignoreHit(hit) then
                return headPred
            end
            local v = worldVel(targetChar)
            local right,_ = axes(u)
            local lateral = (v:Dot(right) >= 0) and right or -right
            for _,off in ipairs({2.5, 5.0, 7.5}) do
                local side = hit.Position + lateral * off
                local slide = side + (headPred - hit.Position) * 0.8
                local h2 = select(1, rayTowards(origin, slide, ignoreList))
                if not h2 or h2.Instance:IsDescendantOf(targetChar) or ignoreHit(h2) then
                    return slide
                end
            end
        end
    end

    local a = aimPart(targetChar)
    if a then
        local bodyPred = predictPoint(origin, targetChar, a, sameGround, groundPos)
        if bodyPred then
            local hit, u = rayTowards(origin, bodyPred, ignoreList)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or ignoreHit(hit) then
                return bodyPred
            end
            local v = worldVel(targetChar)
            local right,_ = axes(u)
            local lateral = (v:Dot(right) >= 0) and right or -right
            for _,off in ipairs({3.0, 6.0}) do
                local side = hit.Position + lateral * off
                local slide = side + (bodyPred - hit.Position) * 0.6
                local h2 = select(1, rayTowards(origin, slide, ignoreList))
                if not h2 or h2.Instance:IsDescendantOf(targetChar) or ignoreHit(h2) then
                    return slide
                end
            end
        end
    end

    return nil
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

    local aimPos = advancedPath(origin, tc, ignore, sameGround, groundPos)
    if not aimPos or not finite3(aimPos) then return end
    aimPos = clampToFloor(aimPos, tAnchor, ignore)
    if not finite3(aimPos) then return end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable  = function() Env.CRIMSON_AUTO_KNIFE.enabled = true  end
Env.CRIMSON_AUTO_KNIFE.disable = function() Env.CRIMSON_AUTO_KNIFE.enabled = false end
