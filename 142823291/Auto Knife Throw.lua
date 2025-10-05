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

local KNIFE_SPEED = 63/0.85
local IGNORE_TRANSPARENCY = 0.4
local IGNORE_SIZE = 0.4
local GROUND_CHECK_DISTANCE = 24
local GROUND_MEMORY_DURATION = 0.35
local GROUND_TORSO_OFFSET = 1.0
local MIN_EXPOSURE_RATIO = 0.4
local THROW_COOLDOWN = 0.27
local MAX_TOKENS = 4
local TOKEN_REFILL_RATE = 1.5

local myCharacter = me.Character or me.CharacterAdded:Wait()
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRootPart = myCharacter:WaitForChild("HumanoidRootPart")

local currentKnife, throwEvent
local lastThrowTime = 0
local tokenCount = MAX_TOKENS
local lastRefillTime = os.clock()

local groundHeights = {}
local lastGroundedPositions = {}
local lastGroundedTimes = {}

local function normalize(vec)
    local mag = vec.Magnitude
    if mag == 0 or mag ~= mag then
        return Vector3.zero, 0
    end
    return vec/mag, mag
end

local function clampValue(value, min, max)
    if max < min then min, max = max, min end
    if value ~= value then return min end
    return math.clamp(value, min, max)
end

local function isPartIgnored(part)
    if part.Transparency >= IGNORE_TRANSPARENCY then
        return true
    end
    local size = part.Size
    if size.X < IGNORE_SIZE or size.Y < IGNORE_SIZE or size.Z < IGNORE_SIZE then
        return true
    end
    local mat = part.Material
    if mat == Enum.Material.Glass or mat == Enum.Material.ForceField then
        return true
    end
    return false
end

local function raycast(origin, direction, distance, blacklist)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = blacklist
    return Workspace:Raycast(origin, direction*distance, params)
end

local function rayTo(origin, target, blacklist)
    local dir, dist = normalize(target-origin)
    local hit = raycast(origin, dir, clampValue(dist, 0, 12288), blacklist)
    return hit, dir, dist
end

local limbOrder = {
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"
}

local function getVelocity(model)
    local part = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
    return part and part.AssemblyLinearVelocity or Vector3.zero
end

local function isVisible(part, origin, ignoreList)
    if not part then return false end
    local center = part.Position
    local size = part.Size
    local points = {
        center,
        center + Vector3.new(size.X*0.3,0,0),
        center + Vector3.new(-size.X*0.3,0,0),
        center + Vector3.new(0,size.Y*0.3,0),
        center + Vector3.new(0,-size.Y*0.3,0),
        center + Vector3.new(0,0,size.Z*0.3),
        center + Vector3.new(0,0,-size.Z*0.3),
    }
    if part.Name:find("Foot") or part.Name:find("Hand") or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(points, center + Vector3.new(size.X*0.4, size.Y*0.4, 0))
        table.insert(points, center + Vector3.new(-size.X*0.4, size.Y*0.4, 0))
        table.insert(points, center + Vector3.new(size.X*0.4, -size.Y*0.4, 0))
        table.insert(points, center + Vector3.new(-size.X*0.4, -size.Y*0.4, 0))
    end
    local visibleCount = 0
    local blacklist = {myCharacter, part.Parent}
    for _, inst in ipairs(ignoreList) do
        table.insert(blacklist, inst)
    end
    for _, point in ipairs(points) do
        local hit = rayTo(origin, point, blacklist)
        if not hit or hit.Instance:IsDescendantOf(part.Parent) or isPartIgnored(hit.Instance) then
            visibleCount = visibleCount + 1
        end
    end
    return (visibleCount / #points) >= MIN_EXPOSURE_RATIO
end

local function findExposedLimbs(target, origin, ignoreList)
    local limbs = {}
    for _, name in ipairs(limbOrder) do
        local part = target:FindFirstChild(name)
        if part and isVisible(part, origin, ignoreList) then
            table.insert(limbs, part)
        end
    end
    return limbs
end

local function pickTarget(origin)
    local mouse = me:GetMouse()
    local bestPlayer, bestPart, bestScore = nil, nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= me then
            local char = pl.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if char and humanoid and humanoid.Health > 0 then
                local ignoreList = {myCharacter}
                for _, part in ipairs(findExposedLimbs(char, origin, ignoreList)) do
                    local onScreen, screenPos = camera:WorldToViewportPoint(part.Position)
                    local screenDist = onScreen and (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude or 9999
                    local worldDist = (part.Position - origin).Magnitude * 0.1
                    local bias = 10
                    if part.Name:find("Foot") then bias = -100
                    elseif part.Name:find("LowerLeg") then bias = -80
                    elseif part.Name:find("Leg") then bias = -60
                    elseif part.Name:find("Hand") then bias = -40
                    elseif part.Name:find("LowerArm") then bias = -30
                    elseif part.Name:find("Arm") then bias = -20
                    elseif part.Name == "Head" then bias = -10 end
                    local score = screenDist + worldDist + bias
                    if score < bestScore then
                        bestPlayer, bestPart, bestScore = pl, part, score
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

local function updateKnife()
    local found = (me.Backpack:FindFirstChild("Knife")) or (myCharacter:FindFirstChild("Knife"))
    if found ~= currentKnife then
        currentKnife = found
        throwEvent = currentKnife and currentKnife:FindFirstChild("Throw") or nil
    end
end

me.CharacterAdded:Connect(function(char)
    myCharacter = char
    myHumanoid = char:WaitForChild("Humanoid")
    myRootPart = char:WaitForChild("HumanoidRootPart")
    updateKnife()
end)
me.Backpack.ChildAdded:Connect(function(item) if item.Name == "Knife" then updateKnife() end end)
me.Backpack.ChildRemoved:Connect(function(item) if item == currentKnife then updateKnife() end end)
myCharacter.ChildAdded:Connect(function(item) if item.Name == "Knife" then updateKnife() end end)
myCharacter.ChildRemoved:Connect(function(item) if item == currentKnife then updateKnife() end end)
updateKnife()

local function refillTokens()
    local now = os.clock()
    local dt = now - lastRefillTime
    if dt > 0 then
        tokenCount = math.min(MAX_TOKENS, tokenCount + dt * TOKEN_REFILL_RATE)
        lastRefillTime = now
    end
end

local function canThrow()
    refillTokens()
    local now = os.clock()
    if (now - lastThrowTime) < THROW_COOLDOWN or tokenCount < 1 then
        return false
    end
    tokenCount = tokenCount - 1
    lastThrowTime = now
    return true
end

local function rememberGround(target, same, groundPos)
    local torso = target:FindFirstChild("UpperTorso")
    if not torso then return end
    local id = target:GetDebugId()
    if same and groundPos then
        local pos = torso.Position
        lastGroundedPositions[id] = Vector3.new(pos.X, groundPos.Y + GROUND_TORSO_OFFSET, pos.Z)
        lastGroundedTimes[id] = os.clock()
    end
end

local function getGroundPosition(target, ignoreList)
    local part = target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart")
    if not part then return nil, false end
    local origin = part.Position + Vector3.new(0,2,0)
    local hit = raycast(origin, Vector3.new(0,-1,0), GROUND_CHECK_DISTANCE, ignoreList)
    local groundPos = hit and hit.Position or nil
    local id = target:GetDebugId()
    local same = false
    if groundPos then
        local lastY = groundHeights[id]
        if lastY and math.abs(groundPos.Y - lastY) <= 1.75 then
            same = true
        end
        groundHeights[id] = groundPos.Y
    end
    return groundPos, same
end

local function calculateAim(origin, target, focusPart, sameGround, groundPos)
    local part = focusPart or target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
    if not part then return nil end
    local id = target:GetDebugId()
    local now = os.clock()

    local basePosition
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local lastTime = lastGroundedTimes[id]
    if humanoid and lastGroundedPositions[id] and lastTime and (now - lastTime) <= GROUND_MEMORY_DURATION then
        local state = humanoid:GetState()
        if (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall) and not sameGround then
            basePosition = lastGroundedPositions[id]
        end
    end

    if not basePosition then
        basePosition = part.Position
        if groundPos then
            basePosition = Vector3.new(basePosition.X, groundPos.Y + (part.Name=="Head" and 1 or 0.9), basePosition.Z)
        end
    end

    local distance = (basePosition - origin).Magnitude
    if distance == 0 then return basePosition end

    local travelTime = distance / KNIFE_SPEED

    local velocity = getVelocity(target)
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = horizontalVelocity.Magnitude

    rememberGround(target, sameGround, groundPos)

    local lead = (speed > 0) and (horizontalVelocity * travelTime) or Vector3.zero

    local verticalVelocity = velocity.Y
    local yDrop = verticalVelocity * travelTime * 0.38 - 0.5 * Workspace.Gravity * (travelTime^2) * 0.35
    yDrop = clampValue(yDrop, -28, 36)
    if humanoid and (humanoid.WalkSpeed or 16) < 8 then
        yDrop = yDrop * 0.7
    end

    return Vector3.new(basePosition.X, basePosition.Y, basePosition.Z) + lead + Vector3.new(0, yDrop, 0)
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then return end
    if not Env.CRIMSON_AUTO_KNIFE.enabled then return end
    updateKnife()
    if not currentKnife or not throwEvent then return end
    if not myCharacter or not myHumanoid or myHumanoid.Health <= 0 then return end
    local origin = (currentKnife:FindFirstChild("Handle") and currentKnife.Handle.Position) or myRootPart.Position
    local player, limb = pickTarget(origin)
    if not player or not limb then return end
    local targetChar = player.Character
    local targetHumanoid = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then return end
    if not canThrow() then return end

    local ignoreList = {myCharacter}
    local groundPos, sameGround = getGroundPosition(targetChar, ignoreList)
    local aimPos = calculateAim(origin, targetChar, limb, sameGround, groundPos)
    if not aimPos then return end

    throwEvent:FireServer(CFrame.new(aimPos), origin)
end

RunService.Heartbeat:Connect(step)

Env.CRIMSON_AUTO_KNIFE.enable  = function() Env.CRIMSON_AUTO_KNIFE.enabled = true  end
Env.CRIMSON_AUTO_KNIFE.disable = function() Env.CRIMSON_AUTO_KNIFE.enabled = false end
