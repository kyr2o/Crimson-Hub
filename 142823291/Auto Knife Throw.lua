local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:FindFirstChildOfClass("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_KNIFE = G.CRIMSON_AUTO_KNIFE or { enabled = false }

local LeadBias = 1.50
local PredictStrength = 0.00
local RangeBoost = 0.0016
local MaxBounces = 3
local LateralOffsets = {3.0, 6.0, 9.0}
local VerticalOffsets = {2.0, -2.0}
local CornerPeek = 6.0
local ThinAlpha = 0.4
local MinThickness = 0.4
local ANIM_ID = "rbxassetid://1957618848"
local ANIM_DURATION = 0.3

local knife, throwRemote
local loopConn
local animStartTime = 0
local lastAnimTrack = nil

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
    animStartTime = 0
    lastAnimTrack = nil
    task.defer(resolveKnife)
end)

if lp:FindFirstChild("Backpack") then
    lp.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    lp.Backpack.ChildRemoved:Connect(function(it) if it==knife then resolveKnife() end end)
end
char.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
char.ChildRemoved:Connect(function(it) if it==knife then resolveKnife() end end)

local cam = Workspace.CurrentCamera

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

local function getAnchor(character)
    return character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart"))
end
local function getVel(character)
    local part = getAnchor(character)
    return part and part.AssemblyLinearVelocity or Vector3.zero
end
local function getBodyVelocityY(character)
    if not character then return 0 end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local sum = 0
    for _,obj in ipairs(hrp:GetChildren()) do
        if obj:IsA("BodyVelocity") then
            sum += obj.Velocity.Y
        end
    end
    return sum
end

local function isTargetAnimPlaying()
    if not hum then return false end
    local currentTime = os.clock()

    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId:find("1957618848") then
            if lastAnimTrack ~= track then
                animStartTime = currentTime
                lastAnimTrack = track
            end
            return (currentTime - animStartTime) >= ANIM_DURATION
        end
    end

    animStartTime = 0
    lastAnimTrack = nil
    return false
end

local function getExposedBodyParts(character, ignore)
    local parts = {}
    if not character then return parts end

    local bodyParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    local origin = cam.CFrame.Position

    for _, partName in ipairs(bodyParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = ignore
            local u, mag = safeNormalize(part.Position - origin)
            local hit = Workspace:Raycast(origin, u * mclamp(mag, 0, 12288), p)
            if not hit or hit.Instance:IsDescendantOf(character) then
                table.insert(parts, part)
            end
        end
    end

    return parts
end

local function mouseClosestTarget(selfChar)
    local ignore = {selfChar}
    local best, bestDist = nil, math.huge
    local mousePos = Vector2.new(mouse.X, mouse.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and c then
                local exposedParts = getExposedBodyParts(c, ignore)
                if #exposedParts > 0 then
                    local anchor = getAnchor(c)
                    if anchor then
                        local screenPos, onScreen = cam:WorldToViewportPoint(anchor.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if dist < bestDist then
                                best = p
                                bestDist = dist
                            end
                        end
                    end
                end
            end
        end
    end

    return best
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
    local boost = 1 + math.clamp(dist * 0.0022, 0, 1.0)
    return baseSpeed * boost
end
local function timeToTargetAtDist(dist)
    local s = knifeSpeedAtDist(dist)
    if s <= 0 or dist ~= dist then return 0 end
    return dist / s
end

local function verticalLead(targetChar, t)
    local c = targetChar
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local anchor = getAnchor(c)
    if not h or not anchor then return 0 end
    local vy = getVel(c).Y
    local bodyVy = getBodyVelocityY(c)
    local jp = h.JumpPower or 50
    local ws = h.WalkSpeed or 16
    local jumpImpulseVy = math.max(0, jp) * 0.85
    local blendedVy = vy + bodyVy*0.6
    local maxRise = math.clamp(jumpImpulseVy, 0, 70)
    local damp = 0.65
    local yLead = blendedVy * t * damp - 0.5 * Workspace.Gravity * (t*t) * 0.85
    yLead = math.clamp(yLead, -60, maxRise)
    if h:GetState() == Enum.HumanoidStateType.Freefall then
        yLead = yLead - 0.15 * Workspace.Gravity * (t*t)
    end
    if ws < 8 then yLead *= 0.9 end
    return yLead
end

local function predictPoint(originPos, targetChar)
    local anchor = getAnchor(targetChar); if not anchor then return nil end
    local to = anchor.Position
    local toVec = to - originPos
    local distMag = toVec.Magnitude
    local t = timeToTargetAtDist(distMag); if t == 0 then return to end
    local vel = getVel(targetChar)
    local horizVel = Vector3.new(vel.X, 0, vel.Z)
    local distGain = 1 + math.clamp(distMag * RangeBoost, 0, 1.2)
    local horizLead = horizVel * t * LeadBias * distGain
    local yLead = verticalLead(targetChar, t)
    local pred = to + horizLead + Vector3.new(0, yLead, 0)
    return isFiniteVec3(pred) and pred or to
end

local function orthonormal(v)
    local u,_ = safeNormalize(v)
    if u.Magnitude == 0 then return Vector3.new(1,0,0), Vector3.new(0,1,0) end
    local up = Vector3.new(0,1,0)
    if math.abs(u:Dot(up)) > 0.95 then up = Vector3.new(1,0,0) end
    local right = (u:Cross(up)).Unit
    local newUp = (right:Cross(u)).Unit
    return right, newUp
end

local function isThinOrIgnored(hit)
    local inst = hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency >= ThinAlpha then return true end
        local s = inst.Size
        if s.X < MinThickness or s.Y < MinThickness or s.Z < MinThickness then
            return true
        end
        local mat = inst.Material
        if mat == Enum.Material.Glass or mat == Enum.Material.ForceField then
            return true
        end
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

local function advancedPath(originPos, targetChar, ignore)
    local exposedParts = getExposedBodyParts(targetChar, ignore)
    if #exposedParts == 0 then return nil end

    local anchor = getAnchor(targetChar)
    if anchor then
        local desired = predictPoint(originPos, targetChar)
        if desired then
            local hit, u, _ = rayTo(originPos, desired, ignore)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
                return desired
            end
        end
    end

    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local bestPart, bestDist = nil, math.huge

    for _, part in ipairs(exposedParts) do
        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist < bestDist then
                bestPart = part
                bestDist = dist
            end
        end
    end

    if bestPart then

        local vel = getVel(targetChar)
        local t = timeToTargetAtDist((bestPart.Position - originPos).Magnitude)
        local horizVel = Vector3.new(vel.X, 0, vel.Z)
        local horizLead = horizVel * t * LeadBias
        local yLead = verticalLead(targetChar, t)
        local pred = bestPart.Position + horizLead + Vector3.new(0, yLead, 0)

        local hit, u, _ = rayTo(originPos, pred, ignore)
        if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
            return pred
        end

        local current = originPos
        local aim = pred
        local steps = 0

        while steps < MaxBounces do
            local hit2, u2, _ = rayTo(current, aim, ignore)
            if not hit2 or hit2.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit2) then
                return aim
            end

            local tVel = getVel(targetChar)
            local right, up = orthonormal(u2)
            local lateralPref = (tVel:Dot(right) >= 0) and right or -right

            local tried = false
            for _, off in ipairs(LateralOffsets) do
                for _, vOff in ipairs(VerticalOffsets) do
                    local side = hit2.Position + lateralPref * off + up * vOff
                    local peek = side + u2 * CornerPeek
                    local hit3 = select(1, rayTo(current, peek, ignore))
                    if not hit3 or hit3.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit3) then
                        current = current + (side - current) * 0.001
                        aim = peek
                        tried = true
                        break
                    end
                end
                if tried then break end
            end

            if not tried then
                aim = hit2.Position - u2 * 2.25
                break
            end

            steps += 1
        end

        return aim
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

local lastThrow, throwCd = 0, 0.33
local tokens,maxTokens,refillRate = 3,3,1.2
local lastRefill = os.clock()
local function canFire()
    local now = os.clock()
    local dt = now - lastRefill
    if dt>0 then tokens = math.min(maxTokens, tokens + dt*refillRate); lastRefill = now end
    if now - lastThrow < throwCd then return false end
    if tokens < 1 then return false end
    tokens = tokens - 1; lastThrow = now; return true
end

local function stepThrow()

    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConn then loopConn:Disconnect(); loopConn = nil end
        return
    end

    if not G.CRIMSON_AUTO_KNIFE.enabled then return end
    if not knife or not throwRemote then return end
    if not char or not root or not hum or hum.Health<=0 then return end
    if knife.Parent ~= char then return end
    if not isTargetAnimPlaying() then return end

    local tgt = mouseClosestTarget(char)
    if not tgt then return end
    local tc = tgt.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    local anchor = tc and getAnchor(tc)
    if not anchor or not th or th.Health<=0 then return end

    if not canFire() then return end

    local originPos = (knife:FindFirstChild("Handle") and knife.Handle.Position) or root.Position
    local ignore = {char}

    local finalPos = advancedPath(originPos, tc, ignore)
    if not finalPos or not isFiniteVec3(finalPos) then return end

    finalPos = clampToPlatform(finalPos, anchor, ignore)
    if not isFiniteVec3(finalPos) then return end

    throwRemote:FireServer(CFrame.new(finalPos), originPos)
end

local function bindLoop()
    if loopConn then loopConn:Disconnect(); loopConn=nil end
    loopConn = RunService.Heartbeat:Connect(stepThrow)
end

local function unbindLoop()
    if loopConn then loopConn:Disconnect(); loopConn=nil end
end

local function attachToolSignals(tool)
    if tool and tool.Name=="Knife" then
        tool.Equipped:Connect(bindLoop)
        tool.Unequipped:Connect(unbindLoop)
    end
end

if knife then attachToolSignals(knife) end
char.ChildAdded:Connect(attachToolSignals)
if knife and knife.Parent==char then bindLoop() end

G.CRIMSON_AUTO_KNIFE.enable = function()
    G.CRIMSON_AUTO_KNIFE.enabled = true
end

G.CRIMSON_AUTO_KNIFE.disable = function()
    G.CRIMSON_AUTO_KNIFE.enabled = false
    unbindLoop()
end
