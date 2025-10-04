local players = game:GetService("Players")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local localPlayer = players.LocalPlayer

local G = (getgenv and getgenv()) or _G
G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.15 }

local shootConnection

-- Safe raycast with full nil checking
local function raycastDown(origin, distance, ignoreList)
    if not origin or not distance or distance <= 0 then return nil end
    
    local success, result = pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignoreList or {}
        return workspace:Raycast(origin, Vector3.new(0, -distance, 0), rayParams)
    end)
    
    return success and result or nil
end

-- Simplified floor detection with nil safety
local function getFloorY(position, ignoreList)
    if not position then return nil end
    
    local maxDistance = 100
    local rayOrigin = position + Vector3.new(0, 2, 0)
    
    -- Try single raycast first
    local result = raycastDown(rayOrigin, maxDistance, ignoreList or {})
    if result and result.Position then
        return result.Position.Y
    end
    
    -- If that fails, try a few offset positions
    local offsets = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1)
    }
    
    for _, offset in ipairs(offsets) do
        local offsetOrigin = rayOrigin + offset
        local offsetResult = raycastDown(offsetOrigin, maxDistance, ignoreList or {})
        if offsetResult and offsetResult.Position then
            return offsetResult.Position.Y
        end
    end
    
    return nil
end

-- Safe prediction with extensive nil checking
local function predictFallPosition(root, prediction)
    if not root or not root.Position or not root.Velocity then
        return nil
    end
    
    local velocity = root.Velocity
    local position = root.Position
    local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    
    -- Ensure prediction is a valid number
    prediction = tonumber(prediction) or 0.15
    if prediction <= 0 then prediction = 0.15 end
    
    -- Base horizontal prediction with nil checks
    local basePos = Vector3.new(
        position.X + (velocity.X * prediction),
        position.Y + (velocity.Y * prediction),
        position.Z + (velocity.Z * prediction)
    )
    
    -- Check if target is falling (with nil safety)
    local isFalling = false
    if velocity.Y and velocity.Y < -2 then
        isFalling = true
    elseif humanoid then
        local success, state = pcall(function() return humanoid:GetState() end)
        if success and state == Enum.HumanoidStateType.Freefall then
            isFalling = true
        end
    end
    
    if not isFalling then
        return basePos
    end
    
    -- Fall-specific prediction with gravity
    local gravity = 196.2
    if workspace.Gravity then
        gravity = workspace.Gravity
    end
    
    local fallTime = prediction
    
    -- Enhanced vertical prediction with gravity
    local verticalOffset = (velocity.Y * fallTime) - (0.5 * gravity * (fallTime * fallTime))
    
    -- Horizontal prediction with air resistance simulation
    local airDrag = 1.0
    if velocity.Y then
        local fallSpeed = math.abs(velocity.Y)
        airDrag = math.max(0.6, 1 - (fallSpeed * 0.008))
    end
    
    local predictedPos = Vector3.new(
        position.X + (velocity.X * prediction * airDrag),
        position.Y + verticalOffset,
        position.Z + (velocity.Z * prediction * airDrag)
    )
    
    -- Floor safety check with nil protection
    local ignoreList = {}
    if localPlayer.Character then
        table.insert(ignoreList, localPlayer.Character)
    end
    if root.Parent then
        table.insert(ignoreList, root.Parent)
    end
    
    local floorY = getFloorY(Vector3.new(predictedPos.X, position.Y, predictedPos.Z), ignoreList)
    
    if floorY then
        local minHeightAboveFloor = 2.5
        
        if isFalling then
            local distanceToFloor = position.Y - floorY
            local fallSpeed = velocity.Y and math.abs(velocity.Y) or 0
            local fallProgress = math.min(math.max((fallSpeed - 5) / 30, 0), 1)
            
            local dynamicHeight = minHeightAboveFloor + (math.max(distanceToFloor, 0) * (0.4 - 0.2 * fallProgress))
            local safeFloorY = floorY + math.max(dynamicHeight, minHeightAboveFloor)
            
            if predictedPos.Y < safeFloorY then
                predictedPos = Vector3.new(predictedPos.X, safeFloorY, predictedPos.Z)
            end
        else
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
                
                -- Use enhanced prediction with full error handling
                local success, aimPos = pcall(function()
                    return predictFallPosition(root, pred)
                end)
                
                if success and aimPos then
                    rf:InvokeServer(1, aimPos, "AH2")
                else
                    -- Fallback to simple prediction if enhanced fails
                    local fallbackPos = root.Position + (root.Velocity * pred)
                    rf:InvokeServer(1, fallbackPos, "AH2")
                end
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
