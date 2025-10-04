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

local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConn

local trackStart = setmetatable({}, { __mode = "k" })

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
    me.Backpack.ChildAdded:Connect(function(it) if it.Name == "Knife" then findKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it == myKnife then findKnife() end end)
end
myChar.ChildAdded:Connect(function(it) if it.Name == "Knife" then findKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it == myKnife then findKnife() end end)

local function throwIsAllowedNow()
    if not myHum then return false end
    local now = os.clock()

    local allowed = false
    for _, track in ipairs(myHum:GetPlayingAnimationTracks()) do
        local animId = track.Animation and track.Animation.AnimationId or ""
        for _, allow in ipairs(AllowedAnimIds) do
            if animId:find(allow, 1, true) then
                if not trackStart[track] then
                    trackStart[track] = now
                end
                if (now - trackStart[track]) >= AnimGateSeconds then
                    allowed = true
                end
            end
        end
    end

    for tr, _ in pairs(trackStart) do
        if typeof(tr) ~= "Instance" or not tr.IsPlaying then
            trackStart[tr] = nil
        end
    end

    return allowed
end

local function aimPart(char)
    return char and (char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"))
end
local function worldVel(char)
    local a = aimPart(char)
    return a and a.AssemblyLinearVelocity or Vector3.zero
end

local function chooseTarget()
    local mouse = me:GetMouse()
    local onScreen, offScreen = {}, {}

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= me then
            local c = pl.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local a = c and aimPart(c)
            if h and h.Health > 0 and a then
                local v, on = camera:WorldToViewportPoint(a.Position)
                local worldDist = (a.Position - myRoot.Position).Magnitude
                if on then
                    local cursorDist = (Vector2.new(v.X, v.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    table.insert(onScreen, { player = pl, cursor = cursorDist, dist = worldDist })
                else
                    table.insert(offScreen, { player = pl, dist = worldDist })
                end
            end
        end
    end

    table.sort(onScreen, function(a, b)
        if math.abs(a.cursor - b.cursor) < 12 then
            return a.dist < b.dist
        end
        return a.cursor < b.cursor
    end)
    if #onScreen > 0 then return onScreen[1].player end

    table.sort(offScreen, function(a, b) return a.dist < b.dist end)
    if #offScreen > 0 then return offScreen[1].player end

    return nil
end

local function groundAhead(pos, dirUnit, len, ignore)
    local probeFrom = pos + dirUnit * len
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    local hit = Workspace:Raycast(probeFrom + Vector3.new(0, 3, 0), Vector3.new(0, -50, 0), p)
    return hit ~= nil, hit and hit.Position or nil
end

local baseKnifeSpeed = 205
local function knifeSpeedAt(dist)
    local boost = 1 + math.clamp(dist * 0.0035, 0, 1.5)
    return baseKnifeSpeed * boost
end
local function timeTo(dist)
    local s = knifeSpeedAt(dist)
    if s <= 0 or dist ~= dist then return 0 end
    return dist / s
end

local function verticalOffset(targetChar, t, focusPart)
    local h = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not h or not focusPart then return 0 end

    local vy = worldVel(targetChar).Y
    local bodyVy = 0
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, obj in ipairs(hrp:GetChildren()) do
            if obj:IsA("BodyVelocity") then bodyVy += obj.Velocity.Y end
        end
    end

    if math.abs(vy) < 3 then
        return clamp(vy * t * 0.2, -5, 5)
    end

    local jp = h.JumpPower or 50
    local ws = h.WalkSpeed or 16
    local blended = vy + bodyVy * 0.4
    local riseCap = clamp(jp * 0.6, 0, 40)
    local y = blended * t * 0.4 - 0.5 * Workspace.Gravity * (t * t) * 0.4
    y = clamp(y, -30, riseCap)

    local st = h:GetState()
    if st == Enum.HumanoidStateType.Freefall then
        y = y - 0.1 * Workspace.Gravity * (t * t)
    elseif st == Enum.HumanoidStateType.Jumping then
        y = y * 0.8
    end
    if ws < 8 then y = y * 0.7 end

    return y
end

local function predictPoint(origin, targetChar, focusPart)
    local p = focusPart or aimPart(targetChar)
    if not p then return nil end

    local to = p.Position
    local dist = (to - origin).Magnitude
    local t = timeTo(dist); if t == 0 then return to end

    local vel = worldVel(targetChar)
    local horiz = Vector3.new(vel.X, 0, vel.Z)
    local speed = horiz.Magnitude

    local distScale = 1 + math.clamp(dist * rangeGainPerStud, 0, 2.0)
    local speedScale = 1 + math.clamp(speed * 0.05, 0, 0.5)
    local leadScale = distScale * speedScale

    local leadVec = horiz * t * leadAmount * leadScale
    local y = verticalOffset(targetChar, t, p)

    local pred = to + leadVec + Vector3.new(0, y, 0)
    return finite3(pred) and pred or to
end

local function axes(v)
    local u,_m = unit(v)
    if u.Magnitude == 0 then return Vector3.new(1,0,0), Vector3.new(0,1,0) end
    local up = Vector3.new(0,1,0)
    if math.abs(u:Dot(up)) > 0.95 then up = Vector3.new(1,0,0) end
    local right = (u:Cross(up)).Unit
    local newUp = (right:Cross(u)).Unit
    return right, newUp
end

local function shouldIgnore(hit)
    local inst = hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency >= ignoreThinTransparency then return true end
        local s = inst.Size
        if s.X < ignoreMinThickness or s.Y < ignoreMinThickness or s.Z < ignoreMinThickness then
            return true
        end
        local mat = inst.Material
        if mat == Enum.Material.Glass or mat == Enum.Material.ForceField then return true end
    end
    return false
end

local function raycastTo(origin, target, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    local u, mag = unit(target - origin)
    local hit = Workspace:Raycast(origin, u * clamp(mag, 0, 12288), p)
    return hit, u, mag
end

local function solvePath(origin, targetChar, ignoreList)
    local seen = {}
    local function exposedParts()
        local list = {}
        local candidates = {"Head","UpperTorso","LowerTorso","HumanoidRootPart","Left Arm","Right Arm","Left Leg","Right Leg"}
        local eye = camera.CFrame.Position
        for _,name in ipairs(candidates) do
            local part = targetChar:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                local p = RaycastParams.new()
                p.FilterType = Enum.RaycastFilterType.Exclude
                p.FilterDescendantsInstances = ignoreList
                local u,mag = unit(part.Position - eye)
                local hit = Workspace:Raycast(eye, u * clamp(mag, 0, 12288), p)
                if not hit or hit.Instance:IsDescendantOf(targetChar) then
                    table.insert(list, part)
                end
            end
        end
        return list
    end

    local vis = exposedParts()
    if #vis == 0 then return nil end

    local head = targetChar:FindFirstChild("Head")
    if head then
        for _,part in ipairs(vis) do
            if part == head then
                local headPred = predictPoint(origin, targetChar, head)
                if headPred then
                    local hit, u = raycastTo(origin, headPred, ignoreList)
                    if not hit or hit.Instance:IsDescendantOf(targetChar) or shouldIgnore(hit) then
                        return headPred
                    end
                    local v = worldVel(targetChar)
                    local right,_up = axes(u)
                    local lateral = (v:Dot(right) >= 0) and right or -right
                    for _,off in ipairs({2.5, 5.0, 7.5}) do
                        local side = hit.Position + lateral * off
                        local slide = side + (headPred - hit.Position) * 0.8
                        local h2 = select(1, raycastTo(origin, slide, ignoreList))
                        if not h2 or h2.Instance:IsDescendantOf(targetChar) or shouldIgnore(h2) then
                            return slide
                        end
                    end
                end
                break
            end
        end
    end

    local a = aimPart(targetChar)
    local bodyPred = predictPoint(origin, targetChar, a)
    if bodyPred then
        local hit, u = raycastTo(origin, bodyPred, ignoreList)
        if not hit or hit.Instance:IsDescendantOf(targetChar) or shouldIgnore(hit) then
            return bodyPred
        end
        local v = worldVel(targetChar)
        local right,_up = axes(u)
        local lateral = (v:Dot(right) >= 0) and right or -right
        for _,off in ipairs({3.0, 6.0}) do
            local side = hit.Position + lateral * off
            local slide = side + (bodyPred - hit.Position) * 0.6
            local h2 = select(1, raycastTo(origin, slide, ignoreList))
            if not h2 or h2.Instance:IsDescendantOf(targetChar) or shouldIgnore(h2) then
                return slide
            end
        end
    end

    local best, bestScore = nil, math.huge
    for _,part in ipairs(vis) do
        local v, on = camera:WorldToViewportPoint(part.Position)
        local d = on and (Vector2.new(v.X, v.Y) - Vector2.new(camera.ViewportSize.X*0.5, camera.ViewportSize.Y*0.5)).Magnitude or 9999
        if d < bestScore then best, bestScore = part, d end
    end
    if best then
        local pred = predictPoint(origin, targetChar, best)
        if pred then
            local hit, u = raycastTo(origin, pred, ignoreList)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or shouldIgnore(hit) then
                return pred
            end
            local v = worldVel(targetChar)
            local right,_up = axes(u)
            local lateral = (v:Dot(right) >= 0) and right or -right
            local side = hit.Position + lateral * 4.0
            local slide = side + (pred - hit.Position) * 0.5
            local h2 = select(1, raycastTo(origin, slide, ignoreList))
            if not h2 or h2.Instance:IsDescendantOf(targetChar) or shouldIgnore(h2) then
                return slide
            end
        end
    end

    return nil
end

local function clampToFloor(aim, targetAnchor, ignore)
    local dir = (aim - targetAnchor.Position)
    local u,mag = unit(dir)
    if mag < 1 then return aim end
    local has, floorY = groundAhead(targetAnchor.Position, u, 11, ignore)
    if has then return aim end
    if floorY then return Vector3.new(aim.X, floorY + 0.75, aim.Z) end
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
        if loopConn then loopConn:Disconnect(); loopConn = nil end
        return
    end
    if not Env.CRIMSON_AUTO_KNIFE.enabled then return end
    findKnife()
    if not myKnife or not knifeRemote then return end
    if not myChar or not myRoot or not myHum or myHum.Health <= 0 then return end

    if not throwIsAllowedNow() then return end

    local target = chooseTarget()
    if not target then return end
    local tc = target.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local tAnchor = tc and aimPart(tc)
    if not th or th.Health <= 0 or not tAnchor then return end

    if not readyToThrow() then return end

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local ignore = { myChar }

    local aimPos = solvePath(origin, tc, ignore)
    if not aimPos or not finite3(aimPos) then return end

    aimPos = clampToFloor(aimPos, tAnchor, ignore)
    if not finite3(aimPos) then return end

    knifeRemote:FireServer(CFrame.new(aimPos), origin)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable = function()
    Env.CRIMSON_AUTO_KNIFE.enabled = true
end
Env.CRIMSON_AUTO_KNIFE.disable = function()
    Env.CRIMSON_AUTO_KNIFE.enabled = false
end
