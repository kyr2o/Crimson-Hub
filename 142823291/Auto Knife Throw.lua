local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local lp = Players.LocalPlayer
local cam = Workspace.CurrentCamera

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_KNIFE = G.CRIMSON_AUTO_KNIFE or { enabled = true } 

local LeadBias = 1.50
local RangeBoost = 0.0025
local MaxBounces = 4
local LateralOffsets = {3.0, 6.0, 9.0}
local VerticalOffsets = {2.0, -2.0}
local CornerPeek = 6.0
local ThinAlpha = 0.4
local MinThickness = 0.4

local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local knife, throwRemote
local loopConn

local function safeNormalize(v)
    local m = v.Magnitude
    if m == 0 or m ~= m then return Vector3.new(0,0,0), 0 end
    return v/m, m
end
local function mclamp(val, lo, hi)
    if hi < lo then lo,hi = hi,lo end
    if val ~= val then return lo end
    return math.clamp(val, lo, hi)
end
local function isFiniteVec3(v)
    return v and v.X == v.X and v.Y == v.Y and v.Z == v.Z
end

local function resolveKnife()
    local k = (lp.Backpack and lp.Backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
    if k ~= knife then
        knife = k
        throwRemote = knife and knife:FindFirstChild("Throw") or nil
    end
end
resolveKnife()

lp.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    task.defer(resolveKnife)
end)

if lp:FindFirstChild("Backpack") then
    lp.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    lp.Backpack.ChildRemoved:Connect(function(it) if it==knife then resolveKnife() end end)
end
char.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
char.ChildRemoved:Connect(function(it) if it==knife then resolveKnife() end end)

local function getAnchor(character)
    return character and (character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart"))
end
local function getVel(character)
    local part = getAnchor(character)
    return part and part.AssemblyLinearVelocity or Vector3.zero
end

local function pickTarget()
    local mouse = lp:GetMouse()
    local onScreen, offScreen = {}, {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local a = c and getAnchor(c)
            if h and h.Health>0 and a then
                local v, on = cam:WorldToViewportPoint(a.Position)
                local distWorld = (a.Position - root.Position).Magnitude
                if on then
                    local dMouse = (Vector2.new(v.X, v.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    table.insert(onScreen, {player=p, screenDist=dMouse, worldDist=distWorld})
                else
                    table.insert(offScreen, {player=p, worldDist=distWorld})
                end
            end
        end
    end

    table.sort(onScreen, function(a,b)
        if math.abs(a.screenDist-b.screenDist) < 12 then
            return a.worldDist < b.worldDist
        end
        return a.screenDist < b.screenDist
    end)
    if #onScreen>0 then return onScreen[1].player end

    table.sort(offScreen, function(a,b) return a.worldDist < b.worldDist end)
    if #offScreen>0 then return offScreen[1].player end

    return nil
end

local function groundAhead(pos, dirUnit, len, ignore)
    local ahead = pos + dirUnit*len
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    local down = Workspace:Raycast(ahead + Vector3.new(0,3,0), Vector3.new(0,-50,0), p)
    return down ~= nil, down and down.Position or nil
end

local baseSpeed = 205
local function knifeSpeedAtDist(dist)
    local boost = 1 + math.clamp(dist * 0.0035, 0, 1.5)
    return baseSpeed * boost
end
local function timeToTargetAtDist(dist)
    local s = knifeSpeedAtDist(dist)
    if s <= 0 or dist ~= dist then return 0 end
    return dist / s
end

local function verticalLead(targetChar, t, targetPart)
    local c = targetChar
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h or not targetPart then return 0 end

    local vy = getVel(c).Y
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local bodyVy = 0
    if hrp then
        for _,obj in ipairs(hrp:GetChildren()) do
            if obj:IsA("BodyVelocity") then bodyVy += obj.Velocity.Y end
        end
    end
    local jp = h.JumpPower or 50
    local ws = h.WalkSpeed or 16

    if math.abs(vy) < 3 then
        return math.clamp(vy * t * 0.2, -5, 5)
    end

    local jumpImpulseVy = math.max(0, jp) * 0.6
    local blendedVy = vy + bodyVy * 0.4
    local maxRise = math.clamp(jumpImpulseVy, 0, 40)
    local yLead = blendedVy * t * 0.4 - 0.5 * Workspace.Gravity * (t*t) * 0.4
    yLead = math.clamp(yLead, -30, maxRise)

    local st = h:GetState()
    if st == Enum.HumanoidStateType.Freefall then
        yLead = yLead - 0.1 * Workspace.Gravity * (t*t)
    elseif st == Enum.HumanoidStateType.Jumping then
        yLead = yLead * 0.8
    end
    if ws < 8 then yLead *= 0.7 end

    return yLead
end

local function predictPoint(originPos, targetChar, targetPart)
    local a = targetPart or getAnchor(targetChar)
    if not a then return nil end
    local to = a.Position
    local distMag = (to - originPos).Magnitude
    local t = timeToTargetAtDist(distMag); if t==0 then return to end
    local vel = getVel(targetChar)
    local horizVel = Vector3.new(vel.X,0,vel.Z)
    local horizSpeed = horizVel.Magnitude
    local distanceScale = 1 + math.clamp(distMag * RangeBoost, 0, 2.0)
    local speedScale = 1 + math.clamp(horizSpeed * 0.05, 0, 0.5)
    local combinedScale = distanceScale * speedScale
    local horizLead = horizVel * t * LeadBias * combinedScale
    local yLead = verticalLead(targetChar, t, a)
    local pred = to + horizLead + Vector3.new(0, yLead, 0)
    return isFiniteVec3(pred) and pred or to
end

local function orthonormal(v)
    local u,_ = safeNormalize(v)
    if u.Magnitude==0 then return Vector3.new(1,0,0), Vector3.new(0,1,0) end
    local up = Vector3.new(0,1,0)
    if math.abs(u:Dot(up))>0.95 then up = Vector3.new(1,0,0) end
    local right = (u:Cross(up)).Unit
    local newUp = (right:Cross(u)).Unit
    return right, newUp
end

local function isThinOrIgnored(hit)
    local inst = hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency >= ThinAlpha then return true end
        local s = inst.Size
        if s.X < MinThickness or s.Y < MinThickness or s.Z < MinThickness then return true end
        local mat = inst.Material
        if mat == Enum.Material.Glass or mat == Enum.Material.ForceField then return true end
    end
    return false
end

local function rayTo(originPos, targetPos, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    local u, mag = safeNormalize(targetPos - originPos)
    local hit = Workspace:Raycast(originPos, u * mclamp(mag, 0, 12288), p)
    return hit, u, mag
end

local function getExposedBodyParts(character, ignore)
    local parts = {}
    local names = {"Head","UpperTorso","LowerTorso","HumanoidRootPart","Left Arm","Right Arm","Left Leg","Right Leg"}
    local origin = cam.CFrame.Position
    for _,n in ipairs(names) do
        local part = character:FindFirstChild(n)
        if part and part:IsA("BasePart") then
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = ignore
            local u, mag = safeNormalize(part.Position - origin)
            local hit = Workspace:Raycast(origin, u*mclamp(mag,0,12288), p)
            if not hit or hit.Instance:IsDescendantOf(character) then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

local function advancedPath(originPos, targetChar, ignore)
    local exposed = getExposedBodyParts(targetChar, ignore)
    if #exposed==0 then return nil end

    local head = targetChar:FindFirstChild("Head")
    if head then
        for _,part in ipairs(exposed) do
            if part==head then
                local headPred = predictPoint(originPos, targetChar, head)
                if not headPred then break end
                local hit, u = rayTo(originPos, headPred, ignore)
                if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
                    return headPred
                end
                local vel = getVel(targetChar)
                local right,_ = orthonormal(u)
                local lateral = (vel:Dot(right)>=0) and right or -right
                for _,off in ipairs({2.5,5.0,7.5}) do
                    local slidePoint = hit.Position + lateral*off
                    local slidePred = slidePoint + (headPred - hit.Position) * 0.8
                    local hit2 = select(1, rayTo(originPos, slidePred, ignore))
                    if not hit2 or hit2.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit2) then
                        return slidePred
                    end
                end
                break
            end
        end
    end

    local anchor = getAnchor(targetChar)
    local desired = predictPoint(originPos, targetChar, anchor)
    if desired then
        local hit, u = rayTo(originPos, desired, ignore)
        if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
            return desired
        end
        local vel = getVel(targetChar)
        local right,_ = orthonormal(u)
        local lateral = (vel:Dot(right)>=0) and right or -right
        for _,off in ipairs({3.0,6.0}) do
            local slidePoint = hit.Position + lateral*off
            local slidePred = slidePoint + (desired - hit.Position) * 0.6
            local hit2 = select(1, rayTo(originPos, slidePred, ignore))
            if not hit2 or hit2.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit2) then
                return slidePred
            end
        end
    end

    local bestPart, bestDist = nil, math.huge
    for _,part in ipairs(exposed) do
        local v,on = cam:WorldToViewportPoint(part.Position)
        local d = on and (Vector2.new(v.X,v.Y) - Vector2.new(cam.ViewportSize.X*0.5, cam.ViewportSize.Y*0.5)).Magnitude or 9999
        if d < bestDist then bestPart=part; bestDist=d end
    end
    if bestPart then
        local pred = predictPoint(originPos, targetChar, bestPart)
        if pred then
            local hit,u = rayTo(originPos, pred, ignore)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
                return pred
            end
            local vel = getVel(targetChar)
            local right,_ = orthonormal(u)
            local lateral = (vel:Dot(right)>=0) and right or -right
            local slidePoint = hit.Position + lateral*4.0
            local slidePred = slidePoint + (pred - hit.Position) * 0.5
            local hit2 = select(1, rayTo(originPos, slidePred, ignore))
            if not hit2 or hit2.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit2) then
                return slidePred
            end
        end
    end

    return nil
end

local function clampToPlatform(aim, targetAnchor, ignore)
    local dir = (aim - targetAnchor.Position)
    local u,mag = safeNormalize(dir)
    if mag < 1 then return aim end
    local hasGround, groundPos = groundAhead(targetAnchor.Position, u, 11, ignore)
    if hasGround then return aim end
    if groundPos then return Vector3.new(aim.X, groundPos.Y+0.75, aim.Z) end
    return aim
end

local lastThrow, throwCd = 0, 0.25
local tokens,maxTokens,refillRate = 4,4,1.5
local lastRefill = os.clock()
local function canFire()
    local now = os.clock()
    local dt = now - lastRefill
    if dt>0 then tokens = math.min(maxTokens, tokens + dt*refillRate); lastRefill = now end
    if now - lastThrow < throwCd then return false end
    if tokens < 1 then return false end
    tokens = tokens - 1; lastThrow = now; return true
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConn then loopConn:Disconnect(); loopConn=nil end
        return
    end
    if not G.CRIMSON_AUTO_KNIFE.enabled then return end
    resolveKnife()
    if not knife or not throwRemote then return end
    if not char or not root or not hum or hum.Health<=0 then return end

    local tgt = pickTarget()
    if not tgt then return end
    local tc = tgt.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor = tc and getAnchor(tc)
    if not th or th.Health<=0 or not anchor then return end

    if not canFire() then return end

    local originPos = (knife:FindFirstChild("Handle") and knife.Handle.Position) or root.Position
    local ignore = {char}

    local finalPos = advancedPath(originPos, tc, ignore)
    if not finalPos or not isFiniteVec3(finalPos) then return end
    finalPos = clampToPlatform(finalPos, anchor, ignore)
    if not isFiniteVec3(finalPos) then return end

    throwRemote:FireServer(CFrame.new(finalPos), originPos)
end

if loopConn then loopConn:Disconnect() end
loopConn = RunService.Heartbeat:Connect(step)

G.CRIMSON_AUTO_KNIFE.enable = function()
    G.CRIMSON_AUTO_KNIFE.enabled = true
end
G.CRIMSON_AUTO_KNIFE.disable = function()
    G.CRIMSON_AUTO_KNIFE.enabled = false
end
