local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

local VERBOSE = false
local HUB_VERSION = "v1.3"
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://eosd75fjrwrywy7.m.pipedream.net"

local themes = {
    original = {
        mainBg = Color3.fromRGB(30, 32, 38),
        keyBg = Color3.fromRGB(30, 32, 38),
        header = Color3.fromRGB(139, 0, 0),
        headerGrad = Color3.fromRGB(180, 0, 0),
        stroke = Color3.fromRGB(139, 0, 0),
        moduleBg = Color3.fromRGB(45, 48, 54),
        textColor = Color3.fromRGB(220, 220, 220)
    },
    lightBlack = {
        mainBg = Color3.fromRGB(25, 25, 25),
        keyBg = Color3.fromRGB(25, 25, 25),
        header = Color3.fromRGB(50, 50, 50),
        headerGrad = Color3.fromRGB(70, 70, 70),
        stroke = Color3.fromRGB(80, 80, 80),
        moduleBg = Color3.fromRGB(40, 40, 40),
        textColor = Color3.fromRGB(200, 200, 200)
    }
}
local currentTheme = "lightBlack"

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://916757943"
clickSound.Volume = 0.5
clickSound.Parent = screenGui

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 320, 0, 160)
keyFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = screenGui
local keyFrameCorner = Instance.new("UICorner")
keyFrameCorner.CornerRadius = UDim.new(0, 8)
keyFrameCorner.Parent = keyFrame
local keyFrameStroke = Instance.new("UIStroke")
keyFrameStroke.Thickness = 1
keyFrameStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
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
keyInputStroke.Thickness = 1
keyInputStroke.Parent = keyInput

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(1, -40, 0, 30)
submitButton.Position = UDim2.new(0, 20, 0, 105)
submitButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.Text = "Submit"
submitButton.Font = Enum.Font.SourceSansBold
submitButton.TextSize = 16
submitButton.Parent = keyFrame
local submitButtonCorner = Instance.new("UICorner")
submitButtonCorner.CornerRadius = UDim.new(0, 6)
submitButtonCorner.Parent = submitButton

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 8)
mainFrameCorner.Parent = mainFrame
local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Thickness = 2
mainFrameStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BorderSizePixel = 0
header.Parent = mainFrame
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header
local headerGradient = Instance.new("UIGradient")
headerGradient.Rotation = 90
headerGradient.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Crimson Hub"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local settingsButton = Instance.new("ImageButton")
settingsButton.Size = UDim2.new(0, 20, 0, 20)
settingsButton.Position = UDim2.new(1, -80, 0.5, -10)
settingsButton.BackgroundTransparency = 1
settingsButton.Image = "rbxassetid://11078717906"
settingsButton.Parent = header

local closeButton = Instance.new("ImageButton")
closeButton.Size = UDim2.new(0, 18, 0, 18)
closeButton.Position = UDim2.new(1, -25, 0.5, -9)
closeButton.BackgroundTransparency = 1
closeButton.Image = "rbxassetid://11078695536"
closeButton.Parent = header

local minimizeButton = Instance.new("ImageButton")
minimizeButton.Size = UDim2.new(0, 18, 0, 18)
minimizeButton.Position = UDim2.new(1, -50, 0.5, -9)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Image = "rbxassetid://11078738318"
minimizeButton.Parent = header

local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 100, 0, 20)
watermark.Position = UDim2.new(1, -105, 1, -25)
watermark.BackgroundTransparency = 1
watermark.Font = Enum.Font.SourceSans
watermark.TextSize = 12
watermark.Text = HUB_VERSION
watermark.TextXAlignment = Enum.TextXAlignment.Right
watermark.Parent = mainFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentList = Instance.new("ScrollingFrame")
contentList.Size = UDim2.new(1, -10, 1, -10)
contentList.Position = UDim2.new(0, 5, 0, 5)
contentList.BackgroundTransparency = 1
contentList.BorderSizePixel = 0
contentList.CanvasSize = UDim2.new(0, 0, 0, 0)
contentList.ScrollBarThickness = 6
contentList.Parent = contentFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Parent = contentList

local scriptStates = {}
local isBindingKey = false

local function applyTheme(themeName)
    local theme = themes[themeName]
    mainFrame.BackgroundColor3 = theme.mainBg
    keyFrame.BackgroundColor3 = theme.keyBg
    keyFrameStroke.Color = theme.stroke
    header.BackgroundColor3 = theme.header
    headerGradient.Color = ColorSequence.new(theme.headerGrad, theme.header)
    mainFrameStroke.Color = theme.stroke
    watermark.TextColor3 = theme.textColor
    for _, item in ipairs(contentList:GetChildren()) do
        if item:IsA("Frame") and item.Name == "ModuleContainer" then
            item.BackgroundColor3 = theme.moduleBg
            local label = item:FindFirstChildOfClass("TextLabel")
            if label then label.TextColor3 = theme.textColor end
        elseif item:IsA("TextButton") and item.Name == "ExecButton" then
            item.BackgroundColor3 = theme.moduleBg
            item.TextColor3 = theme.textColor
        end
    end
end

local function addHoverEffect(button)
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor:Lerp(Color3.new(1,1,1), 0.2)}):Play()
    end)
    button.MouseLeave:Connect(function()
        tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

addHoverEffect(submitButton)

local function sendNotification(text)
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
    stroke.Color = themes[currentTheme].stroke
    stroke.Thickness = 1
    stroke.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextWrapped = true
    label.Parent = frame
    
    local timerBar = Instance.new("Frame")
    timerBar.Size = UDim2.new(0, 0, 0, 3)
    timerBar.Position = UDim2.new(0, 0, 1, -3)
    timerBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    timerBar.BorderSizePixel = 0
    timerBar.Parent = frame

    local showTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -60)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -60)})
    local timerTween = tweenService:Create(timerBar, TweenInfo.new(7.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 3)})

    showTween:Play()
    timerTween:Play()
    task.wait(7.5)
    hideTween:Play()
    hideTween.Completed:Wait()
    frame:Destroy()
end

local function httpGet(url)
	local s, r = pcall(function() return httpService:GetAsync(url) end)
	if s and r then return true, tostring(r) end
	local function try(f)
		if not f then return false, nil end
		local ok, resp = pcall(function() return f({Url = url, Method = "GET", Headers = { ["User-Agent"] = "CrimsonHub/1.0" }}) end)
		if ok and resp then
			if type(resp) == "table" then return true, tostring(resp.Body or resp.body or "") end
			return true, tostring(resp)
		end
		return false, nil
	end
	local s, r = try(request) if s then return s, r end
	local s, r = try(syn and syn.request) if s then return s, r end
	return false, tostring(r or "All HTTP GET methods failed.")
end

local function isPositiveResponse(responseText)
    if not responseText or type(responseText) ~= "string" then return false end
    local text = responseText:lower():match("^%s*(.-)%s*$")
    if text == "true" or text == "1" or text == "ok" then return true end
    local s, d = pcall(function() return httpService:JSONDecode(responseText) end)
    if s and type(d) == "table" and d.success == true then return true end
    return false
end

local function toggleScript(scriptName, toggleButton, forceState)
    if not scriptStates[scriptName] or scriptStates[scriptName].OnHold then return end
    
    local currentState = scriptStates[scriptName].Enabled
    local newState = if forceState ~= nil then forceState else not currentState
    
    if newState == currentState then return end
    scriptStates[scriptName].Enabled = newState

    local pos = if newState then UDim2.new(1, -22, 0.5, -10) else UDim2.new(0, 2, 0.5, -10)
    local color = if newState then Color3.fromRGB(80, 255, 80) else Color3.fromRGB(255, 80, 80)
    
    tweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = pos, BackgroundColor3 = color}):Play()

    if newState then
        local ok, content = httpGet(scriptStates[scriptName].Url)
        if ok and content then
            local f, err = pcall(loadstring(content))
            if f and type(f) == "function" then task.spawn(f) end
        end
    end
end

local function loadGameScripts()
    for _, child in ipairs(contentList:GetChildren()) do
        if child.Name == "ModuleContainer" or child.Name == "ExecButton" then child:Destroy() end
    end
    
    local gameId = tostring(game.PlaceId)
    if gameId == "0" then return end

    local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
    local ok, result = httpGet(apiUrl)
    if not ok then return end
    local ok2, decoded = pcall(function() return httpService:JSONDecode(result) end)
    if not ok2 or type(decoded) ~= "table" or not decoded[1] then return end

    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptName = (scriptInfo.name or ""):gsub("%.lua$", "")
            local isToggle = scriptName:match("%(Toggle%)")
            scriptName = scriptName:gsub("%s*%(Toggle%)", "")

            if isToggle then
                scriptStates[scriptName] = {Enabled = false, Keybind = nil, Url = scriptInfo.download_url, OnHold = false}

                local container = Instance.new("Frame")
                container.Name = "ModuleContainer"
                container.Size = UDim2.new(1, -20, 0, 40)
                container.Parent = contentList
                local contCorner = Instance.new("UICorner")
                contCorner.CornerRadius = UDim.new(0, 6)
                contCorner.Parent = container

                local scriptLabel = Instance.new("TextLabel")
                scriptLabel.Size = UDim2.new(1, -80, 1, 0)
                scriptLabel.Position = UDim2.new(0, 10, 0, 0)
                scriptLabel.BackgroundTransparency = 1
                scriptLabel.Font = Enum.Font.SourceSansBold
                scriptLabel.TextSize = 16
                scriptLabel.Text = scriptName
                scriptLabel.TextXAlignment = Enum.TextXAlignment.Left
                scriptLabel.Parent = container

                local toggleBg = Instance.new("Frame")
                toggleBg.Size = UDim2.new(0, 40, 0, 20)
                toggleBg.Position = UDim2.new(1, -50, 0.5, -10)
                toggleBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                toggleBg.Parent = container
                local bgCorner = Instance.new("UICorner")
                bgCorner.CornerRadius = UDim.new(0, 6)
                bgCorner.Parent = toggleBg

                local toggleButton = Instance.new("TextButton")
                toggleButton.Size = UDim2.new(0, 20, 0, 20)
                toggleButton.Position = UDim2.new(0, 2, 0.5, -10)
                toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                toggleButton.Text = ""
                toggleButton.Parent = toggleBg
                local tglCorner = Instance.new("UICorner")
                tglCorner.CornerRadius = UDim.new(1, 0)
                tglCorner.Parent = toggleButton
                
                toggleButton.MouseButton1Click:Connect(function() clickSound:Play() toggleScript(scriptName, toggleButton) end)
                
                container.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        clickSound:Play()
                        scriptStates[scriptName].OnHold = not scriptStates[scriptName].OnHold
                        local holdLabel = container:FindFirstChild("HoldLabel")
                        if scriptStates[scriptName].OnHold and not holdLabel then
                            local newHoldLabel = Instance.new("TextLabel")
                            newHoldLabel.Name = "HoldLabel"
                            newHoldLabel.Size = UDim2.new(0, 60, 0, 20)
                            newHoldLabel.Position = UDim2.new(1, -70, 1, -20)
                            newHoldLabel.BackgroundTransparency = 1
                            newHoldLabel.Font = Enum.Font.SourceSans
                            newHoldLabel.TextSize = 10
                            newHoldLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
                            newHoldLabel.Text = "(On Hold)"
                            newHoldLabel.Parent = container
                        elseif not scriptStates[scriptName].OnHold and holdLabel then
                            holdLabel:Destroy()
                        end
                    end
                end)
            else
                local execButton = Instance.new("TextButton")
                execButton.Name = "ExecButton"
                execButton.Size = UDim2.new(1, -20, 0, 40)
                execButton.Text = scriptName
                execButton.Font = Enum.Font.SourceSansBold
                execButton.TextSize = 16
                execButton.Parent = contentList
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = execButton
                addHoverEffect(execButton)
                
                execButton.MouseButton1Click:Connect(function()
                    clickSound:Play()
                    local ok, content = httpGet(scriptInfo.download_url)
                    if ok and content then
                        local f = pcall(loadstring(content))
                        if f then sendNotification("Executed: " .. scriptName) end
                    end
                end)
            end
        end
    end
    uiListLayout.Parent = nil
    uiListLayout.Parent = contentList
    applyTheme(currentTheme)
end

local function playIntro()
    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundColor3 = themes[currentTheme].mainBg
    introFrame.BackgroundTransparency = 1
    introFrame.Parent = screenGui
    
    local pfp = Instance.new("ImageLabel")
    pfp.Size = UDim2.new(0, 128, 0, 128)
    pfp.Position = UDim2.new(0.5, -64, 0.5, -84)
    pfp.BackgroundTransparency = 1
    pfp.ImageTransparency = 1
    pfp.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..localPlayer.UserId.."&width=420&height=420&format=png"
    pfp.Parent = introFrame
    local pfpCorner = Instance.new("UICorner")
    pfpCorner.CornerRadius = UDim.new(1,0)
    pfpCorner.Parent = pfp

    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Size = UDim2.new(1, 0, 0, 40)
    welcomeLabel.Position = UDim2.new(0, 0, 0.5, 64)
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.TextTransparency = 1
    welcomeLabel.TextColor3 = themes[currentTheme].textColor
    welcomeLabel.Font = Enum.Font.SourceSansBold
    welcomeLabel.TextSize = 24
    welcomeLabel.Text = "Welcome, " .. localPlayer.DisplayName
    welcomeLabel.Parent = introFrame

    tweenService:Create(introFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    task.wait(0.3)
    tweenService:Create(pfp, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
    tweenService:Create(welcomeLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    
    task.wait(2.5)
    
    tweenService:Create(introFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    tweenService:Create(pfp, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
    tweenService:Create(welcomeLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(0.5)
    introFrame:Destroy()

    mainFrame.Visible = true
    tweenService:Create(mainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    loadGameScripts()
end

local minimized = false
local isVerifying = false

submitButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    if isVerifying then return end
    local userInput = tostring(keyInput.Text or "")
    if userInput:match("^%s*$") then sendNotification("Enter a password first.") return end
    isVerifying = true
    submitButton.Text = "Verifying..."
    local ok, respText = pcall(function() return "true" end)
    if ok and isPositiveResponse(respText) then
        submitButton.Text = "Correct"
        task.wait(0.5)
        tweenService:Create(keyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1)}):Play()
        keyFrame:Destroy()
        playIntro()
    else
        submitButton.Text = ok and "Incorrect" or "Server Error"
        task.wait(2)
        submitButton.Text = "Submit"
    end
    isVerifying = false
end)

settingsButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    currentTheme = (currentTheme == "original") and "lightBlack" or "original"
    applyTheme(currentTheme)
end)

closeButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    mainFrame.Visible = false
end)

minimizeButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    minimized = not minimized
    contentList.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0, 450, 0, 30) or UDim2.new(0, 450, 0, 300)
end)

userInputService.InputBegan:Connect(function(input, gp)
    if gp or isBindingKey then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for name, state in pairs(scriptStates) do
            if state.Keybind and input.KeyCode == state.Keybind then
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not keyFrame.Parent then
            mainFrame.Visible = not mainFrame.Visible
        end
    end
end)

applyTheme(currentTheme)
