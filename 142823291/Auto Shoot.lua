local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local GlobalEnv = (getgenv and getgenv()) or _G
GlobalEnv.CRIMSON_AUTO_SHOOT = GlobalEnv.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }

local PredictionReferenceData = {
    {ping = 40, prediction = 0.12},    
    {ping = 60, prediction = 0.124},   
    {ping = 80, prediction = 0.128},   
    {ping = 100, prediction = 0.137},  
    {ping = 120, prediction = 0.147},  
    {ping = 150, prediction = 0.154},  
    {ping = 170, prediction = 0.158},  
    {ping = 180, prediction = 0.159},  
    {ping = 200, prediction = 0.15},   
    {ping = 220, prediction = 0.166}   
}

local function CalculatePredictionFromPing(milliseconds)
    if not milliseconds or milliseconds ~= milliseconds then return 0.14 end

    local firstReference = PredictionReferenceData[1]
    local lastReference = PredictionReferenceData[#PredictionReferenceData]

    if milliseconds <= firstReference.ping then
        return firstReference.prediction
    end

    if milliseconds >= lastReference.ping then
        local secondLastReference = PredictionReferenceData[#PredictionReferenceData 
        local slopeRate = (lastReference.prediction 
        local extrapolatedValue = lastReference.prediction + slopeRate * (milliseconds 
        return math.max(extrapolatedValue, lastReference.prediction)
    end

    for referenceIndex = 1, #PredictionReferenceData 
        local lowerBound = PredictionReferenceData[referenceIndex]
        local upperBound = PredictionReferenceData[referenceIndex + 1]

        if milliseconds >= lowerBound.ping and milliseconds <= upperBound.ping then

            local interpolationRatio = (milliseconds 
            local interpolatedPrediction = lowerBound.prediction + (upperBound.prediction 
            return interpolatedPrediction
        end
    end

    return 0.14
end

local function GetCurrentPingInMilliseconds()
    local success, pingValue = pcall(function()
        local networkStats = Stats:FindFirstChild("Network")
        if not networkStats then return nil end

        local serverStatsItem = networkStats:FindFirstChild("ServerStatsItem")
        if not serverStatsItem then return nil end

        local dataPingObject = serverStatsItem:FindFirstChild("Data Ping")
        if not dataPingObject then return nil end

        local rawPingValue = dataPingObject:GetValue()
        if not rawPingValue then return nil end

        return rawPingValue
    end)

    if success and pingValue then
        return pingValue
    end

    local successString, pingString = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)

    if successString and pingString then
        local parsedNumber = tonumber(pingString:match("%d+%.?%d*"))
        if parsedNumber then
            return parsedNumber  
        end
    end

    return 140  
end

GlobalEnv.CRIMSON_AUTO_SHOOT.calibrate = function()
    local currentPingMs = GetCurrentPingInMilliseconds()
    local calculatedPrediction = CalculatePredictionFromPing(currentPingMs)
    GlobalEnv.CRIMSON_AUTO_SHOOT.prediction = calculatedPrediction
    return currentPingMs, calculatedPrediction
end

GlobalEnv.CalibrateAutoShoot = GlobalEnv.CRIMSON_AUTO_SHOOT.calibrate
GlobalEnv.CRIMSON_CalibrateShoot = GlobalEnv.CRIMSON_AUTO_SHOOT.calibrate

local LocalPlayer = Players.LocalPlayer
local currentShootConnection

local function GetCharacterHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function GetPartVelocity(part)
    if not part then return Vector3.zero end

    local success, velocity = pcall(function() return part.AssemblyLinearVelocity end)
    if success and velocity then return velocity end
    return part.Velocity
end

local function IsCharacterInAir(humanoid)
    if not humanoid then return false end
    local currentState = humanoid:GetState()
    return currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping
end

local function GetJumpInitialVelocity(humanoid)
    local gravityForce = Workspace.Gravity
    if humanoid and humanoid.UseJumpPower then
        local jumpPower = humanoid.JumpPower or 50
        return math.max(jumpPower, 1)
    else
        local jumpHeight = (humanoid and humanoid.JumpHeight) or 7.2
        return math.sqrt(math.max(2 * gravityForce * math.max(jumpHeight, 0.1), 1))
    end
end

local function FindBodyPart(character, partNames)
    for _, partName in ipairs(partNames) do
        local foundPart = character:FindFirstChild(partName)
        if foundPart and foundPart:IsA("BasePart") then
            return foundPart
        end
    end
    return nil
end

local function SelectBestAimTarget(character, verticalVelocity, jumpVelocity, groundedDefaultToHead)
    local headPart = FindBodyPart(character, {"Head"})
    local lowerTorsoPart = FindBodyPart(character, {"LowerTorso", "Torso"})
    local upperTorsoPart = FindBodyPart(character, {"UpperTorso", "Torso"})
    local leftLowerLegPart = FindBodyPart(character, {"LeftLowerLeg", "Left Leg"})
    local rightLowerLegPart = FindBodyPart(character, {"RightLowerLeg", "Right Leg"})
    local rootPart = FindBodyPart(character, {"HumanoidRootPart"})

    local fastThreshold = 0.6 * jumpVelocity
    local slowThreshold = 0.2 * jumpVelocity

    if verticalVelocity > fastThreshold then

        return headPart or upperTorsoPart or lowerTorsoPart or rootPart
    elseif verticalVelocity > slowThreshold then

        return lowerTorsoPart or upperTorsoPart or headPart or rootPart
    elseif verticalVelocity < 

        return leftLowerLegPart or rightLowerLegPart or lowerTorsoPart or upperTorsoPart or headPart or rootPart
    else

        return lowerTorsoPart or upperTorsoPart or headPart or rootPart
    end
end

local function ComputePredictedPosition(targetPart, predictionTime, useVerticalBallistics)
    if not targetPart then return nil end
    local currentPosition = targetPart.Position
    local currentVelocity = GetPartVelocity(targetPart)

    local predictedX = currentPosition.X + currentVelocity.X * predictionTime
    local predictedZ = currentPosition.Z + currentVelocity.Z * predictionTime

    local predictedY
    if useVerticalBallistics then
        local gravityForce = Workspace.Gravity
        predictedY = currentPosition.Y + currentVelocity.Y * predictionTime 
    else
        predictedY = currentPosition.Y
    end

    return Vector3.new(predictedX, predictedY, predictedZ)
end

local function FindMurdererPlayer()
    local localPlayer = LocalPlayer
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local playerBackpack = player:FindFirstChild("Backpack")
            local hasKnifeInBackpack = playerBackpack and playerBackpack:FindFirstChild("Knife")
            local hasKnifeEquipped = player.Character:FindFirstChild("Knife")

            if hasKnifeInBackpack or hasKnifeEquipped then
                return player
            end
        end
    end
    return nil
end

local function DisconnectShootLoop()
    if currentShootConnection then
        currentShootConnection:Disconnect()
        currentShootConnection = nil
    end
end

local function SetupCharacterAutoShoot(character)
    DisconnectShootLoop()
    local playerBackpack = LocalPlayer:WaitForChild("Backpack", 5)
    if not playerBackpack then return end

    local function TryBindGunShooting()
        local gunTool = character:FindFirstChild("Gun") or playerBackpack:FindFirstChild("Gun")
        if not gunTool then return end

        local knifeLocalScript = gunTool:FindFirstChild("KnifeLocal")
        local createBeamFolder = knifeLocalScript and knifeLocalScript:FindFirstChild("CreateBeam")
        local remoteFunction = createBeamFolder and createBeamFolder:FindFirstChild("RemoteFunction")

        if not remoteFunction then return end

        if currentShootConnection then currentShootConnection:Disconnect() end

        currentShootConnection = RunService.Heartbeat:Connect(function()
            if not GlobalEnv.CRIMSON_AUTO_SHOOT.enabled then return end
            if not character:FindFirstChild("Gun") then return end

            local murdererPlayer = FindMurdererPlayer()
            local murdererCharacter = murdererPlayer and murdererPlayer.Character
            if not murdererCharacter then return end

            local murdererHumanoid = GetCharacterHumanoid(murdererCharacter)
            local isTargetInAir = IsCharacterInAir(murdererHumanoid)
            local targetJumpVelocity = GetJumpInitialVelocity(murdererHumanoid)

            local murdererHead = murdererCharacter:FindFirstChild("Head")
            local selectedAimPart

            if isTargetInAir then

                local torsoReference = FindBodyPart(murdererCharacter, {"UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}) or murdererHead
                local targetVerticalVelocity = torsoReference and GetPartVelocity(torsoReference).Y or 0
                selectedAimPart = SelectBestAimTarget(murdererCharacter, targetVerticalVelocity, targetJumpVelocity, false)
            else

                selectedAimPart = murdererHead or FindBodyPart(murdererCharacter, {"UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"})
            end

            if not selectedAimPart then return end

            local predictionTime = tonumber(GlobalEnv.CRIMSON_AUTO_SHOOT.prediction) or 0.14

            local predictedAimPosition = ComputePredictedPosition(selectedAimPart, predictionTime, isTargetInAir)

            if predictedAimPosition then
                remoteFunction:InvokeServer(1, predictedAimPosition, "AH2")
            end
        end)
    end

    character.ChildAdded:Connect(function(child)
        if child.Name == "Gun" then TryBindGunShooting() end
    end)

    character.ChildRemoved:Connect(function(child)
        if child.Name == "Gun" then DisconnectShootLoop() end
    end)

    TryBindGunShooting()
end

if LocalPlayer.Character then SetupCharacterAutoShoot(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SetupCharacterAutoShoot)

GlobalEnv.CRIMSON_AUTO_SHOOT.enable = function()
    GlobalEnv.CRIMSON_AUTO_SHOOT.enabled = true
end

GlobalEnv.CRIMSON_AUTO_SHOOT.disable = function()
    GlobalEnv.CRIMSON_AUTO_SHOOT.enabled = false
    DisconnectShootLoop()
end
