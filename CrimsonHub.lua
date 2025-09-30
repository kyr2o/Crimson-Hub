local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

local VERBOSE = false
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://crimson-keys.vercel.app/api/verify"

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local uiSound = Instance.new("Sound")
uiSound.SoundId = "rbxassetid://6366382384" 
uiSound.Volume = 0.5
uiSound.Parent = screenGui

local function playSound()
    uiSound:Play()
end

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 320, 0, 160)
keyFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
keyFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
keyFrame.ZIndex = 2
keyFrame.Draggable = true
keyFrame.Active = true
keyFrame.Parent = screenGui
local keyFrameCorner = Instance.new("UICorner")
keyFrameCorner.CornerRadius = UDim.new(0, 8)
keyFrameCorner.Parent = keyFrame
local keyFrameStroke = Instance.new("UIStroke")
keyFrameStroke.Color = Color3.fromRGB(139, 0, 0)
keyFrameStroke.Thickness = 1
keyFrameStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
keyTitle.BorderSizePixel = 0
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Text = "Crimson Hub - Verification"
keyTitle.Font = Enum.Font.SourceSansBold
keyTitle.TextSize = 16
keyTitle.Parent = keyFrame
local keyTitleCorner = Instance.new("UICorner")
keyTitleCorner.CornerRadius = UDim.new(0, 8)
keyTitleCorner.Parent = keyTitle

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 35)
keyInput.Position = UDim2.new(0, 20, 0, 50)
keyInput.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
keyInput.BorderSizePixel = 0
keyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
keyInput.PlaceholderText = "Enter Password"
keyInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
keyInput.Font = Enum.Font.SourceSans
keyInput.TextSize = 14
keyInput.ClearTextOnFocus = false
keyInput.Parent = keyFrame
local keyInputCorner = Instance.new("UICorner")
keyInputCorner.CornerRadius = UDim.new(0, 6)
keyInputCorner.Parent = keyInput
local keyInputStroke = Instance.new("UIStroke")
keyInputStroke.Color = Color3.fromRGB(80, 80, 80)
keyInputStroke.Thickness = 1
keyInputStroke.Parent = keyInput

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(1, -40, 0, 30)
submitButton.Position = UDim2.new(0, 20, 0, 105)
submitButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
submitButton.BorderSizePixel = 0
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.Text = "Submit"
submitButton.Font = Enum.Font.SourceSansBold
submitButton.TextSize = 16
submitButton.Parent = keyFrame
local submitButtonCorner = Instance.new("UICorner")
submitButtonCorner.CornerRadius = UDim.new(0, 6)
submitButtonCorner.Parent = submitButton

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 350)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
mainFrame.ZIndex = 2
mainFrame.Visible = false
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 8)
mainFrameCorner.Parent = mainFrame
local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = Color3.fromRGB(139, 0, 0)
mainFrameStroke.Thickness = 2
mainFrameStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(40, 42, 48)
header.BorderSizePixel = 0
header.Parent = mainFrame
local headerStroke = Instance.new("UIStroke")
headerStroke.Color = Color3.fromRGB(139, 0, 0)
headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
headerStroke.Thickness = 1.5
headerStroke.Parent = header
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new(Color3.fromRGB(200, 20, 20), Color3.fromRGB(100, 0, 0))
headerGradient.Parent = header
runService.Heartbeat:Connect(function()
    if header.Parent then
        local sine = math.sin(tick() * 2)
        headerGradient.Offset = Vector2.new(0, sine * 0.2)
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -150, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Crimson Hub"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 20
titleLabel.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0.5, -10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.Text = ""
closeButton.Parent = header
local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(1, 0)
closeButtonCorner.Parent = closeButton

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -50, 0.5, -10)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 80)
minimizeButton.Text = ""
minimizeButton.Parent = header
local minimizeButtonCorner = Instance.new("UICorner")
minimizeButtonCorner.CornerRadius = UDim.new(1, 0)
minimizeButtonCorner.Parent = minimizeButton

local welcomeFrame = Instance.new("Frame")
welcomeFrame.Size = UDim2.new(1, -10, 0, 40)
welcomeFrame.Position = UDim2.new(0, 5, 0, 40)
welcomeFrame.BackgroundTransparency = 1
welcomeFrame.Parent = mainFrame

local headshotImage = Instance.new("ImageLabel")
headshotImage.Size = UDim2.new(0, 30, 0, 30)
headshotImage.Position = UDim2.new(1, -35, 0.5, -15)
headshotImage.BackgroundTransparency = 1
headshotImage.Parent = welcomeFrame
local headshotCorner = Instance.new("UICorner")
headshotCorner.CornerRadius = UDim.new(1, 0)
headshotCorner.Parent = headshotImage

local welcomeLabel = Instance.new("TextLabel")
welcomeLabel.Size = UDim2.new(1, -40, 1, 0)
welcomeLabel.Position = UDim2.new(0, 0, 0, 0)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
welcomeLabel.Font = Enum.Font.SourceSans
welcomeLabel.TextSize = 16
welcomeLabel.TextXAlignment = Enum.TextXAlignment.Right
welcomeLabel.Parent = welcomeFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -10, 1, -85)
contentFrame.Position = UDim2.new(0, 5, 0, 80)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Parent = contentFrame

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 50, 0, 20)
versionLabel.Position = UDim2.new(1, -55, 1, -20)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
versionLabel.Text = "v1.3"
versionLabel.Font = Enum.Font.SourceSans
versionLabel.TextSize = 12
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = mainFrame

local toggleNotification = Instance.new("TextLabel")
toggleNotification.Size = UDim2.new(0, 200, 0, 30)
toggleNotification.Position = UDim2.new(0.5, -100, 1, -40)
toggleNotification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
toggleNotification.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleNotification.Text = "Press RightShift to Toggle"
toggleNotification.Font = Enum.Font.SourceSans
toggleNotification.TextSize = 14
toggleNotification.Visible = false
toggleNotification.Parent = screenGui
local toggleNotificationCorner = Instance.new("UICorner")
toggleNotificationCorner.CornerRadius = UDim.new(0, 6)
toggleNotificationCorner.Parent = toggleNotification

local function sendNotification(text, duration)
    local notificationDuration = duration or 3
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 50)
    frame.Position = UDim2.new(1, 10, 1, -60)
    frame.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(139, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, -5)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextWrapped = true
    label.Parent = frame

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 4)
    progressBar.Position = UDim2.new(0, 0, 1, -4)
    progressBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame
    
    local showTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -60)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -60)})
    local progressTween = tweenService:Create(progressBar, TweenInfo.new(notificationDuration), {Size = UDim2.new(1, 0, 0, 4)})

    showTween:Play()
    progressTween:Play()
    
    task.wait(notificationDuration)
    
    hideTween:Play()
    hideTween.Completed:Wait()
    frame:Destroy()
end

local function httpGet(url)
	local success, result = pcall(function() return httpService:GetAsync(url) end)
	if success and result then return true, tostring(result) end
	local function tryRequest(reqFunc)
		if not reqFunc then return false, nil end
		local ok, resp = pcall(function()
			return reqFunc({Url = url, Method = "GET", Headers = { ["User-Agent"] = "CrimsonHub/1.0" }})
		end)
		if ok and resp then
			if type(resp) == "table" then
				return true, tostring(resp.Body or resp.body or "")
			end
			return true, tostring(resp)
		end
		return false, nil
	end
	local reqSuccess, reqResult = tryRequest(request)
	if reqSuccess then return reqSuccess, reqResult end
	local synSuccess, synResult = tryRequest(syn and syn.request)
	if synSuccess then return synSuccess, synResult end
	return false, tostring(result or "All HTTP GET methods failed.")
end

local function httpPost(url, body)
    local bodyContent, contentType, contentTypeEnum = tostring(body), "text/plain", Enum.HttpContentType.TextPlain
    local success, result = pcall(function() return httpService:PostAsync(url, bodyContent, contentTypeEnum) end)
    if success and result then return true, tostring(result) end
    local function tryRequest(reqFunc)
        if not reqFunc then return false, nil end
        local ok, resp = pcall(function()
            return reqFunc({Url = url, Method = "POST", Headers = { ["Content-Type"] = contentType, ["User-Agent"] = "CrimsonHub/1.0" }, Body = bodyContent})
        end)
        if ok and resp then
            if type(resp) == "table" then return true, tostring(resp.Body or resp.body or "") end
            return true, tostring(resp)
        end
        return false, nil
    end
    local reqSuccess, reqResult = tryRequest(request)
    if reqSuccess then return reqSuccess, reqResult end
    local synSuccess, synResult = tryRequest(syn and syn.request)
    if synSuccess then return synSuccess, synResult end
    return false, tostring(result or "All HTTP methods failed.")
end

local function isPositiveResponse(responseText)
    if not responseText or type(responseText) ~= "string" then return false end
    local text = responseText:lower():match("^%s*(.-)%s*$")
    if text == "true" or text == "1" or text == "ok" or text == "success" or text == "200" then
        return true
    end
    local success, decoded = pcall(function() return httpService:JSONDecode(responseText) end)
    if success and type(decoded) == "table" and (decoded.success == true or decoded.Success == true) then
        return true
    end
    return false
end

local function createScriptButton(name, callback)
    local buttonData = {
        enabled = false,
        keybind = "N/A",
        hold = false,
        settingKeybind = false,
        pulseTween = nil
    }

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
    button.Text = ""
    button.Parent = contentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Thickness = 1
    stroke.Parent = button

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button
    
    local holdLabel = Instance.new("TextLabel")
    holdLabel.Size = UDim2.new(0, 40, 1, 0)
    holdLabel.Position = UDim2.new(0, 50, 0, 0)
    holdLabel.BackgroundTransparency = 1
    holdLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    holdLabel.Text = "[Hold]"
    holdLabel.Font = Enum.Font.SourceSansSemibold
    holdLabel.TextSize = 12
    holdLabel.TextXAlignment = Enum.TextXAlignment.Left
    holdLabel.Visible = false
    holdLabel.Parent = label

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 18, 0, 18)
    toggleCircle.Position = UDim2.new(1, -30, 0.5, -9)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    toggleCircle.Parent = button
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle

    local keybindButton = Instance.new("TextButton")
    keybindButton.Size = UDim2.new(0, 60, 0, 22)
    keybindButton.Position = UDim2.new(1, -100, 0.5, -11)
    keybindButton.BackgroundColor3 = Color3.fromRGB(60, 63, 70)
    keybindButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    keybindButton.Text = buttonData.keybind
    keybindButton.Font = Enum.Font.SourceSansSemibold
    keybindButton.TextSize = 12
    keybindButton.Parent = button
    local keybindCorner = Instance.new("UICorner")
    keybindCorner.CornerRadius = UDim.new(0, 4)
    keybindCorner.Parent = keybindButton

    local function updateToggle()
        playSound()
        buttonData.enabled = not buttonData.enabled
        local color = buttonData.enabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        tweenService:Create(toggleCircle, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        if not buttonData.hold then
            pcall(callback, buttonData.enabled)
        end
    end

    button.MouseButton1Click:Connect(updateToggle)
    
    button.MouseEnter:Connect(function()
        tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(65, 68, 74)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 48, 54)}):Play()
    end)

    button.MouseButton2Click:Connect(function()
        playSound()
        buttonData.hold = not buttonData.hold
        holdLabel.Visible = buttonData.hold
    end)
    
    keybindButton.MouseButton1Click:Connect(function()
        playSound()
        if buttonData.settingKeybind then return end
        buttonData.settingKeybind = true
        keybindButton.Text = "..."
        buttonData.pulseTween = tweenService:Create(keybindButton, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3 = Color3.fromRGB(80, 83, 90)})
        buttonData.pulseTween:Play()
    end)

    local function handleKeyPress(input)
        if not button.Visible or not button.Parent then return end
        if buttonData.settingKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
            buttonData.keybind = input.KeyCode.Name
            keybindButton.Text = buttonData.keybind
            buttonData.settingKeybind = false
            if buttonData.pulseTween then
                buttonData.pulseTween:Cancel()
                buttonData.pulseTween = nil
            end
            tweenService:Create(keybindButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 63, 70)}):Play()
        elseif input.KeyCode.Name == buttonData.keybind and not buttonData.settingKeybind then
            if buttonData.hold then
                if input.UserInputState == Enum.UserInputState.Begin then
                    pcall(callback, true)
                elseif input.UserInputState == Enum.UserInputState.End then
                    pcall(callback, false)
                end
            elseif input.UserInputState == Enum.UserInputState.Begin then
                updateToggle()
            end
        end
    end
    
    userInputService.InputBegan:Connect(handleKeyPress)
    userInputService.InputEnded:Connect(handleKeyPress)
    
    return button
end

local function loadGameScripts()
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local gameId = tostring(game.PlaceId)
    if gameId == "0" then
        sendNotification("Cannot load scripts in Studio.", 5)
        return
    end

    local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
    
    local ok, result = httpGet(apiUrl)
    if not ok then
        sendNotification("Error loading scripts.", 4)
        if VERBOSE then print("GitHub API Error: " .. tostring(result)) end
        return
    end

    local success, decoded = pcall(function() return httpService:JSONDecode(result) end)
    if not success or type(decoded) ~= "table" then
        sendNotification("No scripts found for this game.", 4)
        return
    end

    local buttons = {}
    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptName = (scriptInfo.name or ""):gsub("%.lua$", "")
            local function executeScript(state)
                pcall(function()
                    if state == false then return end
                    local ok, scriptContent = httpGet(scriptInfo.download_url)
                    if ok and scriptContent then
                        local func, err = loadstring(scriptContent)
                        if func then
                            func()
                        else
                            sendNotification("Script error: " .. tostring(err), 5)
                        end
                    else
                        sendNotification("Failed to download script.", 3)
                    end
                end)
            end
            local newButton = createScriptButton(scriptName, executeScript)
            table.insert(buttons, newButton)
        end
    end
    return buttons
end

local function setObjectTransparency(guiObject, transparency)
    for _, obj in ipairs(guiObject:GetDescendants()) do
        if obj:IsA("GuiObject") then
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                obj.TextTransparency = transparency
            elseif obj:IsA("ImageLabel") then
                obj.ImageTransparency = transparency
            elseif obj:IsA("UIStroke") then
                obj.Transparency = transparency
            end
            obj.BackgroundTransparency = transparency
        end
    end
    guiObject.BackgroundTransparency = transparency
end

local function playIntroAnimation(buttons)
    mainFrame.Visible = true
    header.Position = UDim2.new(0, 0, 0, -header.AbsoluteSize.Y)
    setObjectTransparency(welcomeFrame, 1)

    tweenService:Create(header, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0,0)}):Play()
    task.wait(0.2)
    
    local welcomeGoals = {}
    for _, v in ipairs(welcomeFrame:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then v.TextTransparency = 0 end
        if v:IsA("ImageLabel") then v.ImageTransparency = 0 end
    end
    tweenService:Create(welcomeFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    
    if buttons then
        for _, button in ipairs(buttons) do
            setObjectTransparency(button, 1)
            task.wait(0.05)
            local buttonGoals = {BackgroundTransparency = 0}
            tweenService:Create(button, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), buttonGoals):Play()
            for _, child in ipairs(button:GetChildren()) do
                local childGoals = {BackgroundTransparency = child.BackgroundTransparency, TextTransparency = 0}
                if child:IsA("UIStroke") then childGoals.Transparency = 0 end
                tweenService:Create(child, TweenInfo.new(0.4), childGoals):Play()
            end
        end
    end
end

welcomeLabel.Text = "Welcome, " .. localPlayer.DisplayName
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420
local content, isReady = players:GetUserThumbnailAsync(localPlayer.UserId, thumbType, thumbSize)
headshotImage.Image = content
headshotImage.Size = isReady and UDim2.new(0, 30, 0, 30) or UDim2.new(0,0,0,0)

local minimized = false
local isVerifying = false

submitButton.MouseButton1Click:Connect(function()
    playSound()
    if isVerifying then return end
    local userInput = tostring(keyInput.Text or "")
    if userInput:match("^%s*$") then
        sendNotification("Enter a password first.", 2)
        return
    end
    isVerifying = true
    submitButton.Text = "Verifying..."
    
    local ok, respText = httpPost(serverUrl, userInput)
    
    if ok and isPositiveResponse(respText) then
        submitButton.Text = "Correct"
        local colorTween = tweenService:Create(keyFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 255, 80)})
        colorTween:Play()
        colorTween.Completed:Wait()
        local fadeOut = tweenService:Create(keyFrame, TweenInfo.new(1), {BackgroundTransparency = 1})
        fadeOut:Play()
        for _, v in ipairs(keyFrame:GetDescendants()) do
             if v:IsA("GuiObject") then
                local goals = {BackgroundTransparency = 1}
                if v:IsA("TextLabel") or v:IsA("TextButton") then
                    goals.TextTransparency = 1
                elseif v:IsA("UIStroke") then
                    goals.Transparency = 1
                end
                tweenService:Create(v, TweenInfo.new(1), goals):Play()
             end
        end
        fadeOut.Completed:Wait()
        keyFrame:Destroy()
        
        mainFrame.Visible = true
        local buttons = loadGameScripts()
        playIntroAnimation(buttons)
    else
        submitButton.Text = "Incorrect"
        local originalPos = keyFrame.Position
        local shake1 = tweenService:Create(keyFrame, TweenInfo.new(0.07), {Position = originalPos + UDim2.fromOffset(7, 0)})
        local shake2 = tweenService:Create(keyFrame, TweenInfo.new(0.07), {Position = originalPos - UDim2.fromOffset(7, 0)})
        local shake3 = tweenService:Create(keyFrame, TweenInfo.new(0.07), {Position = originalPos})
        shake1:Play(); shake1.Completed:Wait(); shake2:Play(); shake2.Completed:Wait(); shake1:Play(); shake1.Completed:Wait(); shake2:Play(); shake2.Completed:Wait(); shake3:Play()
        
        task.wait(1.5)
        submitButton.Text = "Submit"
    end
    isVerifying = false
end)

closeButton.MouseButton1Click:Connect(function()
    playSound()
    mainFrame.Visible = false
    toggleNotification.Visible = true
end)

minimizeButton.MouseButton1Click:Connect(function()
    playSound()
    minimized = not minimized
    contentFrame.Visible = not minimized
    welcomeFrame.Visible = not minimized
    versionLabel.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0, 450, 0, 40) or UDim2.new(0, 450, 0, 350)
end)

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not keyFrame.Parent then
            mainFrame.Visible = not mainFrame.Visible
            toggleNotification.Visible = not mainFrame.Visible
        end
    end
end)
