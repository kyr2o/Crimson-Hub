-- LocalScript: Crimson Hub Auto-Knife with Fixed Aiming and Distance Scaling

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Crimson Hub marker check
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:FindFirstChildOfClass("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- Crimson Hub integration
local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_KNIFE = G.CRIMSON_AUTO_KNIFE or { enabled = false }

-- Settings
local LeadBias = 1.64
local PredictStrength = 0.00
local RangeBoost = 0.0025  -- Increased for better distance scaling
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

local function hasKnife()
    return (lp.Backpack and lp.Backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
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

-- Auto-start loop when knife is detected
local function autoStartLoop()
    if hasKnife() and G.CRIMSON_AUTO_KNIFE.enabled and not loopConn then
        bindLoop()
    end
end

if lp:FindFirstChild("Backpack") then
    lp.Backpack.ChildAdded:Connect(function(it) 
        if it.Name=="Knife" then 
            resolveKnife()
            autoStartLoop()
        end 
    end)
    lp.Backpack.ChildRemoved:Connect(function(it) 
        if it==knife then 
            resolveKnife()
        end 
    end)
end
char.ChildAdded:Connect(function(it) 
    if it.Name=="Knife" then 
        resolveKnife()
        autoStartLoop()
    end 
end)
char.ChildRemoved:Connect(function(it) 
    if it==knife then 
        resolveKnife()
    end 
end)

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

-- Updated animation check - now also checks if we have a knife
local function isTargetAnimPlaying()
    if not hum then return false end
    
    -- Check if we have a knife first - if yes, allow throwing
    if hasKnife() then
        -- If we have animation playing, check duration
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            if track.Animation and track.Animation.AnimationId:find("1957618848") then
                local currentTime = os.clock()
                if lastAnimTrack ~= track then
                    animStartTime = currentTime
                    lastAnimTrack = track
                end
                return (currentTime - animStartTime) >= ANIM_DURATION
            end
        end
        
        -- Reset animation tracking if no animation found
        animStartTime = 0
        lastAnimTrack = nil
    end
    
    return false
end

-- Updated body parts with Head prioritized first
local function getExposedBodyParts(character, ignore)
    local parts = {}
    if not character then return parts end
    
    -- Priority order: Head first, then other parts
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
    local boost = 1 + math.clamp(dist * 0.0035, 0, 1.5)  -- Improved speed scaling
    return baseSpeed * boost
end
local function timeToTargetAtDist(dist)
    local s = knifeSpeedAtDist(dist)
    if s <= 0 or dist ~= dist then return 0 end
    return dist / s
end

-- Fixed vertical lead calculation to prevent floor aiming
local function verticalLead(targetChar, t, targetPart)
    local c = targetChar
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h or not targetPart then return 0 end
    
    local vy = getVel(c).Y
    local bodyVy = getBodyVelocityY(c)
    local jp = h.JumpPower or 50
    local ws = h.WalkSpeed or 16
    
    -- Only apply significant vertical lead if the target is actually moving up or down
    if math.abs(vy) < 3 then
        -- Target is mostly stationary vertically, minimal lead
        return math.clamp(vy * t * 0.2, -5, 5)
    end
    
    -- Target is jumping or falling
    local jumpImpulseVy = math.max(0, jp) * 0.6  -- Reduced multiplier
    local blendedVy = vy + bodyVy * 0.4  -- Reduced body velocity influence
    local maxRise = math.clamp(jumpImpulseVy, 0, 40)  -- Lower max rise
    local damp = 0.4  -- Reduced damping
    
    local yLead = blendedVy * t * damp - 0.5 * Workspace.Gravity * (t*t) * 0.4  -- Reduced gravity compensation
    yLead = math.clamp(yLead, -30, maxRise)  -- Tighter bounds
    
    -- Additional checks for different states
    if h:GetState() == Enum.HumanoidStateType.Freefall then
        yLead = yLead - 0.1 * Workspace.Gravity * (t*t)
    elseif h:GetState() == Enum.HumanoidStateType.Jumping then
        yLead = yLead * 0.8  -- Reduce jump prediction
    end
    
    if ws < 8 then yLead *= 0.7 end
    
    return yLead
end

-- Improved prediction with better distance scaling and horizontal focus
local function predictPoint(originPos, targetChar, targetPart)
    local anchor = targetPart or getAnchor(targetChar)
    if not anchor then return nil end
    
    local to = anchor.Position
    local toVec = to - originPos
    local distMag = toVec.Magnitude
    local t = timeToTargetAtDist(distMag)
    if t == 0 then return to end
    
    local vel = getVel(targetChar)
    local horizVel = Vector3.new(vel.X, 0, vel.Z)
    local horizSpeed = horizVel.Magnitude
    
    -- Enhanced distance-based scaling that increases with both distance and target speed
    local distanceScale = 1 + math.clamp(distMag * RangeBoost, 0, 2.0)
    local speedScale = 1 + math.clamp(horizSpeed * 0.05, 0, 0.5)
    local combinedScale = distanceScale * speedScale
    
    local horizLead = horizVel * t * LeadBias * combinedScale
    local yLead = verticalLead(targetChar, t, anchor)
    
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

-- Enhanced pathfinding with better wall avoidance and head priority
local function advancedPath(originPos, targetChar, ignore)
    local exposedParts = getExposedBodyParts(targetChar, ignore)
    if #exposedParts == 0 then return nil end
    
    -- PRIORITY: Try Head first if it's exposed
    local headPart = targetChar:FindFirstChild("Head")
    if headPart then
        for _, part in ipairs(exposedParts) do
            if part == headPart then
                -- Predict to the HEAD specifically
                local headPred = predictPoint(originPos, targetChar, headPart)
                if not headPred then break end
                
                local hit, u, _ = rayTo(originPos, headPred, ignore)
                if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
                    return headPred
                end
                
                -- Enhanced wall avoidance for head shots
                local vel = getVel(targetChar)
                local right, up = orthonormal(u)
                local lateralPref = (vel:Dot(right) >= 0) and right or -right
                
                -- Try sliding along the wall toward target movement direction
                for _, off in ipairs({2.5, 5.0, 7.5}) do
                    local slidePoint = hit.Position + lateralPref * off
                    local slidePred = slidePoint + (headPred - hit.Position) * 0.8
                    
                    local hit2, _, _ = rayTo(originPos, slidePred, ignore)
                    if not hit2 or hit2.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit2) then
                        return slidePred
                    end
                end
                
                break
            end
        end
    end
    
    -- Try direct path to main anchor
    local anchor = getAnchor(targetChar)
    if anchor then
        local desired = predictPoint(originPos, targetChar, anchor)
        if desired then
            local hit, u, _ = rayTo(originPos, desired, ignore)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
                return desired
            end
            
            -- Wall sliding for body shots
            local vel = getVel(targetChar)
            local right, _ = orthonormal(u)
            local lateralPref = (vel:Dot(right) >= 0) and right or -right
            
            for _, off in ipairs({3.0, 6.0}) do
                local slidePoint = hit.Position + lateralPref * off
                local slidePred = slidePoint + (desired - hit.Position) * 0.6
                
                local hit2, _, _ = rayTo(originPos, slidePred, ignore)
                if not hit2 or hit2.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit2) then
                    return slidePred
                end
            end
        end
    end
    
    -- Fallback to closest exposed part
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
        local pred = predictPoint(originPos, targetChar, bestPart)
        if pred then
            local hit, u, _ = rayTo(originPos, pred, ignore)
            if not hit or hit.Instance:IsDescendantOf(targetChar) or isThinOrIgnored(hit) then
                return pred
            end
            
            -- Final wall slide attempt
            local vel = getVel(targetChar)
            local right, _ = orthonormal(u)
            local lateralPref = (vel:Dot(right) >= 0) and right or -right
            
            local slidePoint = hit.Position + lateralPref * 4.0
            local slidePred = slidePoint + (pred - hit.Position) * 0.5
            
            local hit2, _, _ = rayTo(originPos, slidePred, ignore)
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

local lastThrow, throwCd = 0, 0.25  -- Reduced cooldown for better responsiveness
local tokens,maxTokens,refillRate = 4,4,1.5  -- Increased tokens and refill rate
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
    -- Check marker still exists
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConn then loopConn:Disconnect(); loopConn = nil end
        return
    end
    
    if not G.CRIMSON_AUTO_KNIFE.enabled then return end
    
    -- Auto-resolve knife each frame
    resolveKnife()
    if not knife or not throwRemote then return end
    if not char or not root or not hum or hum.Health<=0 then return end
    
    -- Check if we have knife and animation is playing
    if not hasKnife() or not isTargetAnimPlaying() then return end

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

function bindLoop()
    if loopConn then loopConn:Disconnect(); loopConn=nil end
    loopConn = RunService.Heartbeat:Connect(stepThrow)
end

local function unbindLoop()
    if loopConn then loopConn:Disconnect(); loopConn=nil end
end

-- Start the loop immediately if enabled and has knife
if G.CRIMSON_AUTO_KNIFE.enabled and hasKnife() then
    bindLoop()
end

-- Crimson Hub interface
G.CRIMSON_AUTO_KNIFE.enable = function()
    G.CRIMSON_AUTO_KNIFE.enabled = true
    -- Auto-start if we have a knife
    if hasKnife() then
        bindLoop()
    end
end

G.CRIMSON_AUTO_KNIFE.disable = function()
    G.CRIMSON_AUTO_KNIFE.enabled = false
    unbindLoop()
end
