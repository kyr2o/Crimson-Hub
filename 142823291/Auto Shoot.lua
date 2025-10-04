local players = game:GetService("Players")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local localPlayer = players.LocalPlayer

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.15 }

local shootConnection

-- Raycast helpers
local function raycastDown(origin, distance, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList or {}
    return workspace:Raycast(origin, Vector3.new(0, -distance, 0), rayParams)
end

-- Multiple raycast floor detection (5-point sampling)
local function getFloorY(position, ignoreList)
    local sampleRadius = 2.0
    local maxDistance = 100
    local samples = {
        Vector3.new(0, 0, 0),
        Vector3.new(sampleRadius, 0, 0),
        Vector3.new(-sampleRadius, 0, 0),
        Vector3.new(0, 0, sampleRadius),
        Vector3.new(0, 0, -sampleRadius)
    }
    
    local floorYs = {}
    for _, offset in ipairs(samples) do
        local rayOrigin = position + offset + Vector3.new(0, 2, 0)
        local result = raycastDown(rayOrigin, maxDistance, ignoreList)
        if result then
            table.insert(floorYs, result.Position.Y)
        end
    end
    
    if #floorYs == 0 then return nil end
    
    -- Return median Y to avoid outliers from gaps/holes
    table.sort(floorYs)
    return floorYs[math.ceil(#floorYs / 2)]
end

-- Enhanced prediction for falling targets
local function predictFallPosition(root, prediction)
    local velocity = root.Velocity
    local position = root.Position
    local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
    
    -- Base horizontal prediction
    local basePos = position + (velocity * prediction)
    
    -- Check if target is falling
    local isFalling = velocity.Y < -2 or (humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall)
    
    if not isFalling then
        return basePos
    end
    
    -- Fall-specific prediction with gravity
    local gravity = workspace.Gravity or 196.2
    local fallTime = prediction
    
    -- Enhanced vertical prediction with gravity
    local verticalOffset = velocity.Y * fallTime - 0.5 * gravity * (fallTime * fallTime)
    
    -- Horizontal prediction with air resistance simulation
    local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
    local airDrag = math.clamp(1 - (math.abs(velocity.Y) * 0.008), 0.6, 1.0) -- Reduce horizontal movement while falling
    local horizontalOffset = horizontalVel * (prediction * airDrag)
    
    local predictedPos = Vector3.new(
        position.X + horizontalOffset.X,
        position.Y + verticalOffset,
        position.Z + horizontalOffset.Z
    )
    
    -- Floor safety check with multiple raycasts
    local ignoreList = {localPlayer.Character, root.Parent}
    local floorY = getFloorY(Vector3.new(predictedPos.X, position.Y, predictedPos.Z), ignoreList)
    
    if floorY then
        local minHeightAboveFloor = 2.5 -- Keep aim at least this high above floor
        
        -- If falling, keep aim in midair but not at ground level
        if isFalling then
            local distanceToFloor = position.Y - floorY
            local fallProgress = math.clamp((math.abs(velocity.Y) - 5) / 30, 0, 1) -- 0 = slow fall, 1 = fast fall
            
            -- Dynamic height: higher for slow falls, lower for fast falls but never at ground
            local dynamicHeight = minHeightAboveFloor + (distanceToFloor * (0.4 - 0.2 * fallProgress))
            local safeFloorY = floorY + math.max(dynamicHeight, minHeightAboveFloor)
            
            if predictedPos.Y < safeFloorY then
                predictedPos = Vector3.new(predictedPos.X, safeFloorY, predictedPos.Z)
            end
        else
            -- Non-falling safety
            if predictedPos.Y < (floorY + minHeightAboveFloor) then
                predictedPos = Vector3.new(predictedPos.X, floorY + minHeightAboveFloor, predictedPos.Z)
            end
        end
    end
    
    return predictedPos
end

local function findMurderer()
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local bp = player:FindFirstChild("Backpack")
            if bp and bp:FindFirstChild("Knife") then
                return player
            end
            if player.Character:FindFirstChild("Knife") then
                return player
            end
        end
    end
    return nil
end

local function disconnectShoot()
    if shootConnection then
        shootConnection:Disconnect()
        shootConnection = nil
    end
end

local function onCharacter(character)
    disconnectShoot()

    local backpack = localPlayer:WaitForChild("Backpack", 5)
    if not backpack then return end

    local function tryBindGun()
        local gun = character:FindFirstChild("Gun") or backpack:FindFirstChild("Gun")
        if not gun then return end

        local rf = gun:FindFirstChild("KnifeLocal") and gun.KnifeLocal:FindFirstChild("CreateBeam") and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
        if not rf then return end

        if shootConnection then shootConnection:Disconnect() end
        shootConnection = runService.Heartbeat:Connect(function()
            if not G.CRIMSON_AUTO_SHOOT.enabled then return end
            if not character:FindFirstChild("Gun") then return end
            
            local murderer = findMurderer()
            local root = murderer and murderer.Character and murderer.Character:FindFirstChild("UpperTorso")
            if root then
                local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0.15
                
                -- Use enhanced prediction for falling targets
                local aimPos = predictFallPosition(root, pred)
                
                rf:InvokeServer(1, aimPos, "AH2")
            end
        end)
    end

    character.ChildAdded:Connect(function(child)
        if child.Name == "Gun" then
            tryBindGun()
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Gun" then
            disconnectShoot()
        end
    end)

    tryBindGun()
end

if localPlayer.Character then
    onCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacter)

G.CRIMSON_AUTO_SHOOT.enable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = true
end
G.CRIMSON_AUTO_SHOOT.disable = function()
    G.CRIMSON_AUTO_SHOOT.enabled = false
    disconnectShoot()
end
