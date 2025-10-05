local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Environment = (getgenv and getgenv()) or _G
Environment.CRIMSON_AUTO_KNIFE = Environment.CRIMSON_AUTO_KNIFE or { enabled = true }

local AllowedAnimationIds = {
    "rbxassetid://1957618848",
}
local AnimationGateSeconds = 0.75

local KNIFE_SPEED = 63/0.85

local ignoreThinTransparency = 0.4
local ignoreMinThickness = 0.4

local groundProbeRadius = 2.5
local maxGroundSnap = 24
local sameGroundTolerance = 1.75

local groundedMemorySec = 0.35
local groundedTorsoYOffset = 1.0

local maxHorizontalSlide = 2.5
local cornerPeekDist = 2.5

local exposureCheckRadius = 0.8
local minExposureRatio = 0.4

local myCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRoot = myCharacter:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConnection

local trackStart = setmetatable({}, { __mode = "k" })
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

local function unitVector(vector)
    local magnitude = vector.Magnitude
    if magnitude == 0 or magnitude ~= magnitude then
        return Vector3.zero, 0
    end
    return vector / magnitude, magnitude
end

local function clampValue(value, minimum, maximum)
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    if value ~= value then
        return minimum
    end
    return math.clamp(value, minimum, maximum)
end

local function isFiniteVector3(vector)
    return vector and vector.X == vector.X and vector.Y == vector.Y and vector.Z == vector.Z
end

local function resolveKnife()
    local knife = (localPlayer.Backpack and localPlayer.Backpack:FindFirstChild("Knife")) or (myCharacter and myCharacter:FindFirstChild("Knife"))
    if knife ~= myKnife then
        myKnife = knife
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end

resolveKnife()

localPlayer.CharacterAdded:Connect(function(character)
    myCharacter = character
    myHumanoid = character:WaitForChild("Humanoid")
    myRoot = character:WaitForChild("HumanoidRootPart")
    trackStart = setmetatable({}, { __mode = "k" })
    task.defer(resolveKnife)
end)

if localPlayer:FindFirstChild("Backpack") then
    localPlayer.Backpack.ChildAdded:Connect(function(item)
        if item.Name == "Knife" then
            resolveKnife()
        end
    end)
    localPlayer.Backpack.ChildRemoved:Connect(function(item)
        if item == myKnife then
            resolveKnife()
        end
    end)
end

myCharacter.ChildAdded:Connect(function(item)
    if item.Name == "Knife" then
        resolveKnife()
    end
end)

myCharacter.ChildRemoved:Connect(function(item)
    if item == myKnife then
        resolveKnife()
    end
end)

local function throwIsAllowedNow()
    if not myHumanoid then
        return false
    end
    local currentTime = os.clock()
    local allowed = false
    for _, track in ipairs(myHumanoid:GetPlayingAnimationTracks()) do
        local animationId = track.Animation and track.Animation.AnimationId or ""
        for _, allowedId in ipairs(AllowedAnimationIds) do
            if animationId:find(allowedId, 1, true) then
                if not trackStart[track] then
                    trackStart[track] = currentTime
                end
                if (currentTime - trackStart[track]) >= AnimationGateSeconds then
                    allowed = true
                end
            end
        end
    end
    for track in pairs(trackStart) do
        if typeof(track) ~= "Instance" or not track.IsPlaying then
            trackStart[track] = nil
        end
    end
    return allowed
end

local function getAimPart(character)
    return character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
end

local function getWorldVelocity(character)
    local part = getAimPart(character)
    return part and part.AssemblyLinearVelocity or Vector3.zero
end

local function shouldIgnoreHit(raycastResult)
    local instance = raycastResult.Instance
    if instance and instance:IsA("BasePart") then
        if instance.Transparency >= ignoreThinTransparency then
            return true
        end
        local size = instance.Size
        if size.X < ignoreMinThickness or size.Y < ignoreMinThickness or size.Z < ignoreMinThickness then
            return true
        end
        local material = instance.Material
        if material == Enum.Material.Glass or material == Enum.Material.ForceField then
            return true
        end
    end
    return false
end

local function raycastVector(origin, direction, length, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    return Workspace:Raycast(origin, direction * length, params)
end

local function rayTowards(origin, target, ignoreList)
    local direction, magnitude = unitVector(target - origin)
    local hit = raycastVector(origin, direction, clampValue(magnitude, 0, 12288), ignoreList)
    return hit, direction, magnitude
end

local LimbPriority = {
    "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftLeg", "RightLeg",
    "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftArm", "RightArm",
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
}

local function isPartExposed(part, origin, ignoreList)
    if not part or not part:IsA("BasePart") then
        return false
    end
    local center = part.Position
    local size = part.Size
    local points = {
        center,
        center + Vector3.new(size.X * 0.3, 0, 0),
        center + Vector3.new(-size.X * 0.3, 0, 0),
        center + Vector3.new(0, size.Y * 0.3, 0),
        center + Vector3.new(0, -size.Y * 0.3, 0),
        center + Vector3.new(0, 0, size.Z * 0.3),
        center + Vector3.new(0, 0, -size.Z * 0.3),
    }
    if part.Name:find("Foot") or part.Name:find("Hand") or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(points, center + Vector3.new(size.X * 0.4, size.Y * 0.4, 0))
        table.insert(points, center + Vector3.new(-size.X * 0.4, size.Y * 0.4, 0))
        table.insert(points, center + Vector3.new(size.X * 0.4, -size.Y * 0.4, 0))
        table.insert(points, center + Vector3.new(-size.X * 0.4, -size.Y * 0.4, 0))
    end
    local clearCount = 0
    local fullIgnore = {myCharacter, part.Parent}
    for _, ignoredItem in ipairs(ignoreList) do
        table.insert(fullIgnore, ignoredItem)
    end
    for _, point in ipairs(points) do
        local hit = rayTowards(origin, point, fullIgnore)
        if not hit or hit.Instance:IsDescendantOf(part.Parent) or shouldIgnoreHit(hit) then
            clearCount = clearCount + 1
        end
    end
    return (clearCount / #points) >= minExposureRatio
end

local function getExposedLimbs(character, origin, ignoreList)
    local exposed = {}
    if not character then
        return exposed
    end
    for _, limbName in ipairs(LimbPriority) do
        local part = character:FindFirstChild(limbName)
        if part and isPartExposed(part, origin, ignoreList) then
            table.insert(exposed, part)
        end
    end
    return exposed
end

local function pickExposedTarget(origin)
    local mouse = localPlayer:GetMouse()
    local bestPlayer, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if character and humanoid and humanoid.Health > 0 then
                local ignoreList = {myCharacter}
                for _, part in ipairs(getExposedLimbs(character, origin, ignoreList)) do
                    local viewportPosition, onScreen = camera:WorldToViewportPoint(part.Position)
                    local screenScore = onScreen and (Vector2.new(viewportPosition.X, viewportPosition.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude or 9999
                    local worldScore = (part.Position - origin).Magnitude * 0.1
                    local limbBias = 0
                    if part.Name:find("Foot") then
                        limbBias = -100
                    elseif part.Name:find("LowerLeg") then
                        limbBias = -80
                    elseif part.Name:find("Leg") then
                        limbBias = -60
                    elseif part.Name:find("Hand") then
                        limbBias = -40
                    elseif part.Name:find("LowerArm") then
                        limbBias = -30
                    elseif part.Name:find("Arm") then
                        limbBias = -20
                    elseif part.Name == "Head" then
                        limbBias = -10
                    else
                        limbBias = 10
                    end
                    local score = screenScore + worldScore + limbBias
                    if score < bestScore then
                        bestPlayer, bestPart, bestScore = player, part, score
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

local function rememberGroundedTorso(targetCharacter, sameGround, groundPosition)
    local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local torso = targetCharacter and targetCharacter:FindFirstChild("UpperTorso")
    if not humanoid or not torso then
        return
    end
    local characterId = targetCharacter:GetDebugId()
    if sameGround and groundPosition then
        local position = torso.Position
        lastGroundedTorso[characterId] = Vector3.new(position.X, groundPosition.Y + groundedTorsoYOffset, position.Z)
        lastGroundedTime[characterId] = os.clock()
    end
end

local function findGroundGhost(targetCharacter, ignoreList)
    local aimingPart = getAimPart(targetCharacter)
    if not aimingPart then
        return nil, false
    end
    local fromPosition = aimingPart.Position + Vector3.new(0, 2, 0)
    local hit = raycastVector(fromPosition, Vector3.new(0, -1, 0), maxGroundSnap, ignoreList)
    local groundPosition = hit and hit.Position or nil
    if not groundPosition then
        local velocity = getWorldVelocity(targetCharacter)
        local forward = Vector3.new(velocity.X, 0, velocity.Z)
        forward = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, 1)
        local rightVector = forward:Cross(Vector3.new(0, 1, 0)).Unit
        for _, offset in ipairs({Vector3.new(0, 0, 0), rightVector * groundProbeRadius, -rightVector * groundProbeRadius, forward * groundProbeRadius, -forward * groundProbeRadius}) do
            local secondHit = raycastVector(fromPosition + offset, Vector3.new(0, -1, 0), maxGroundSnap, ignoreList)
            if secondHit then
                groundPosition = secondHit.Position
                break
            end
        end
    end
    local characterId = targetCharacter:GetDebugId()
    local sameGround = false
    if groundPosition then
        local lastY = lastGroundY[characterId]
        if lastY then
            sameGround = math.abs(groundPosition.Y - lastY) <= sameGroundTolerance
        end
        lastGroundY[characterId] = groundPosition.Y
    end
    return groundPosition, sameGround
end

local function hasNormalJumpPower(humanoid)
    local jumpPower = humanoid and humanoid.JumpPower or 50
    return jumpPower >= 40 and jumpPower <= 75
end

local function predictPoint(origin, targetCharacter, focusPart, sameGround, groundPosition)
    local part = focusPart or getAimPart(targetCharacter)
    if not part then
        return nil
    end

    local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local characterId = targetCharacter:GetDebugId()
    local currentTime = os.clock()
    local useStick = false
    if humanoid and hasNormalJumpPower(humanoid) and lastGroundedTorso[characterId] and lastGroundedTime[characterId] and (currentTime - lastGroundedTime[characterId] <= groundedMemorySec) then
        local state = humanoid:GetState()
        if (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall) and (not sameGround) then
            useStick = true
        end
    end

    local basePosition = useStick and lastGroundedTorso[characterId] or part.Position
    if not useStick and groundPosition then
        basePosition = Vector3.new(basePosition.X, groundPosition.Y + (part.Name == "Head" and 1 or 0.9), basePosition.Z)
    end

    local distance = (basePosition - origin).Magnitude
    if distance == 0 then
        return basePosition
    end

    local travelTime = distance / KNIFE_SPEED
    if travelTime <= 0 then
        travelTime = 0
    end

    local velocity = getWorldVelocity(targetCharacter)
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = horizontalVelocity.Magnitude

    local leadVector = (speed > 0) and (horizontalVelocity * travelTime) or Vector3.zero

    local verticalVelocity = velocity.Y
    local extraVertical = 0
    local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if rootPart then
        for _, object in ipairs(rootPart:GetChildren()) do
            if object:IsA("BodyVelocity") then
                extraVertical = extraVertical + object.Velocity.Y
            end
        end
    end
    local normal = humanoid and hasNormalJumpPower(humanoid)
    local state = humanoid and humanoid:GetState() or Enum.HumanoidStateType.Running
    local recentGrounded = lastGroundedTime[characterId] and (currentTime - lastGroundedTime[characterId] <= groundedMemorySec)

    local yOffset
    if useStick then
        yOffset = clampValue(verticalVelocity * travelTime * 0.12, -3, 3)
    else
        local blended = verticalVelocity + extraVertical * 0.35
        yOffset = blended * travelTime * 0.38 - 0.5 * Workspace.Gravity * (travelTime * travelTime) * 0.35
        yOffset = (normal and clampValue(yOffset, -28, 36) or clampValue(yOffset, -22, 28))
        if state == Enum.HumanoidStateType.Freefall then
            yOffset = yOffset - 0.08 * Workspace.Gravity * (travelTime * travelTime)
        elseif state == Enum.HumanoidStateType.Jumping and normal then
            yOffset = yOffset * 0.75
        end
        if humanoid and (humanoid.WalkSpeed or 16) < 8 then
            yOffset = yOffset * 0.7
        end
    end

    local targetDeltaY = (part.Position.Y - origin.Y)
    if speed == 0 and math.abs(verticalVelocity) < 1.0 then
        yOffset = math.clamp(yOffset, -4, targetDeltaY > 0 and 6 or 4)
    elseif targetDeltaY > 0 and yOffset > 0 then
        yOffset = math.min(yOffset, 8)
    end

    local predicted = basePosition + leadVector + Vector3.new(0, yOffset, 0)
    return isFiniteVector3(predicted) and predicted or basePosition
end

local function directAim(origin, targetPosition, targetCharacter, ignoreList)
    local hit, toDirection = rayTowards(origin, targetPosition, ignoreList)
    if not hit or shouldIgnoreHit(hit) then
        return targetPosition
    end
    local rightVector = toDirection:Cross(Vector3.new(0, 1, 0)).Unit
    local slideDirection = rightVector
    if targetCharacter then
        local velocity = getWorldVelocity(targetCharacter)
        local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
        if horizontal.Magnitude > 0.5 then
            slideDirection = (horizontal:Dot(rightVector) >= 0) and rightVector or -rightVector
        end
    end
    for _, offset in ipairs({1.5, 2.5}) do
        for _, direction in ipairs({slideDirection, -slideDirection}) do
            local slidePosition = hit.Position + direction * offset
            slidePosition = Vector3.new(slidePosition.X, targetPosition.Y, slidePosition.Z)
            local firstHit = rayTowards(origin, slidePosition, ignoreList)
            if firstHit and not shouldIgnoreHit(firstHit) then
                continue
            end
            local secondHit = rayTowards(slidePosition, targetPosition, ignoreList)
            if not secondHit or shouldIgnoreHit(secondHit) then
                return slidePosition
            end
        end
    end
    return hit.Position - toDirection * 0.5
end

local function clampToStairPlane(originAim, limbPrediction, ignoreList)
    local downHit = raycastVector(limbPrediction + Vector3.new(0, 3, 0), Vector3.new(0, -1, 0), 8, ignoreList)
    if not downHit then
        return originAim
    end
    local floorY = downHit.Position.Y + 0.6
    if math.abs(limbPrediction.Y - floorY) <= 1.25 then
        return Vector3.new(originAim.X, floorY, originAim.Z)
    end
    return originAim
end

local lastThrow, gapSeconds = 0, 0.27
local tokens, maxTokens, refillRate = 4, 4, 1.5
local lastRefill = os.clock()

local function readyToThrow()
    local currentTime = os.clock()
    local deltaTime = currentTime - lastRefill
    if deltaTime > 0 then
        tokens = math.min(maxTokens, tokens + deltaTime * refillRate)
        lastRefill = currentTime
    end
    if (currentTime - lastThrow) < gapSeconds or tokens < 1 then
        return false
    end
    tokens = tokens - 1
    lastThrow = currentTime
    return true
end

local function step()
    if not CoreGui:FindFirstChild(MARKER_NAME) then
        if loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
        return
    end
    if not Environment.CRIMSON_AUTO_KNIFE.enabled then
        return
    end
    resolveKnife()
    if not myKnife or not knifeRemote then
        return
    end
    if not myCharacter or not myRoot or not myHumanoid or myHumanoid.Health <= 0 then
        return
    end
    if not throwIsAllowedNow() then
        return
    end

    local origin = (myKnife:FindFirstChild("Handle") and myKnife.Handle.Position) or myRoot.Position
    local targetPlayer, targetLimb = (function()
        return (function(originPosition)
            return pickExposedTarget(originPosition)
        end)(origin)
    end)()
    if not targetPlayer or not targetLimb then
        return
    end

    local targetCharacter = targetPlayer.Character
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local anchor = targetCharacter and getAimPart(targetCharacter)
    if not targetHumanoid or targetHumanoid.Health <= 0 or not anchor then
        return
    end
    if not readyToThrow() then
        return
    end

    local ignoreList = {myCharacter}
    local groundPosition, sameGround = findGroundGhost(targetCharacter, ignoreList)
    rememberGroundedTorso(targetCharacter, sameGround, groundPosition)

    local limbPrediction = predictPoint(origin, targetCharacter, targetLimb, sameGround, groundPosition)
    if not limbPrediction then
        return
    end

    local aimPosition = directAim(origin, limbPrediction, targetCharacter, ignoreList)
    if not aimPosition or not isFiniteVector3(aimPosition) then
        return
    end

    aimPosition = clampToStairPlane(aimPosition, limbPrediction, ignoreList)
    if not isFiniteVector3(aimPosition) then
        return
    end

    local deltaY = math.abs((limbPrediction - origin).Y)
    if deltaY > 0.5 then
        if (os.clock() - (_G.__stair_hold or 0)) < 0.05 then
            return
        end
        _G.__stair_hold = os.clock()
    end

    knifeRemote:FireServer(CFrame.new(aimPosition), origin)
end

if loopConnection then
    loopConnection:Disconnect()
end
loopConnection = RunService.Heartbeat:Connect(step)

Environment.CRIMSON_AUTO_KNIFE.enable = function()
    Environment.CRIMSON_AUTO_KNIFE.enabled = true
end
Environment.CRIMSON_AUTO_KNIFE.disable = function()
    Environment.CRIMSON_AUTO_KNIFE.enabled = false
end
