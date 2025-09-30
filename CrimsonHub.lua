local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

local HUB_VERSION = "v1.1"
local VERBOSE = false
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://eosd75fjrwrywy7.m.pipedream.net"

local themes = {
    original = {
        main = Color3.fromRGB(30, 32, 38),
        container = Color3.fromRGB(45, 48, 54)
    },
    lightBlack = {
        main = Color3.fromRGB(25, 25, 25),
        container = Color3.fromRGB(35, 35, 35)
    }
}
local currentTheme = "original"

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://130633212"
clickSound.Volume = 0.5
clickSound.Parent = screenGui

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 320, 0, 160)
keyFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
keyFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
keyFrame.Parent = screenGui
local keyFrameCorner = Instance.new("UICorner", keyFrame)
keyFrameCorner.CornerRadius = UDim.new(0, 8)
local keyFrameStroke = Instance.new("UIStroke", keyFrame)
keyFrameStroke.Color = Color3.fromRGB(139, 0, 0)
keyFrameStroke.Thickness = 1

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Text = "Crimson Hub - Verification"
keyTitle.Font = Enum.Font.SourceSansBold
keyTitle.TextSize = 16
keyTitle.Parent = keyFrame
local keyTitleCorner = Instance.new("UICorner", keyTitle)
keyTitleCorner.CornerRadius = UDim.new(0, 8)

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 35)
keyInput.Position = UDim2.new(0, 20, 0, 50)
keyInput.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
keyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
keyInput.PlaceholderText = "Enter Password"
keyInput.Font = Enum.Font.SourceSans
keyInput.TextSize = 14
keyInput.Parent = keyFrame
local keyInputCorner = Instance.new("UICorner", keyInput)
keyInputCorner.CornerRadius = UDim.new(0, 6)
local keyInputStroke = Instance.new("UIStroke", keyInput)
keyInputStroke.Color = Color3.fromRGB(80, 80, 80)

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(1, -40, 0, 30)
submitButton.Position = UDim2.new(0, 20, 0, 105)
submitButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.Text = "Submit"
submitButton.Font = Enum.Font.SourceSansBold
submitButton.TextSize = 16
submitButton.Parent = keyFrame
local submitButtonCorner = Instance.new("UICorner", submitButton)
submitButtonCorner.CornerRadius = UDim.new(0, 6)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundColor3 = themes.original.main
mainFrame.Visible = false
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
local mainFrameCorner = Instance.new("UICorner", mainFrame)
mainFrameCorner.CornerRadius = UDim.new(0, 8)
local mainFrameStroke = Instance.new("UIStroke", mainFrame)
mainFrameStroke.Color = Color3.fromRGB(139, 0, 0)
mainFrameStroke.Thickness = 2

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
header.Parent = mainFrame
local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 8)
local headerGradient = Instance.new("UIGradient", header)
headerGradient.Color = ColorSequence.new(Color3.fromRGB(180, 0, 0), Color3.fromRGB(120, 0, 0))
headerGradient.Rotation = 90

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

local settingsButton = Instance.new("TextButton")
settingsButton.Size = UDim2.new(0, 20, 0, 20)
settingsButton.Position = UDim2.new(1, -75, 0.5, -10)
settingsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
settingsButton.Text = "⚙"
settingsButton.TextScaled = true
settingsButton.TextColor3 = Color3.fromRGB(50,50,50)
settingsButton.Parent = header
local settingsCorner = Instance.new("UICorner", settingsButton)
settingsCorner.CornerRadius = UDim.new(0, 4)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0.5, -10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.Text = ""
closeButton.Parent = header
local closeButtonCorner = Instance.new("UICorner", closeButton)
closeButtonCorner.CornerRadius = UDim.new(1, 0)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -50, 0.5, -10)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 80)
minimizeButton.Text = ""
minimizeButton.Parent = header
local minimizeButtonCorner = Instance.new("UICorner", minimizeButton)
minimizeButtonCorner.CornerRadius = UDim.new(1, 0)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local contentList = Instance.new("ScrollingFrame")
contentList.Size = UDim2.new(1, -10, 1, -10)
contentList.Position = UDim2.new(0, 5, 0, 5)
contentList.BackgroundTransparency = 1
contentList.CanvasSize = UDim2.new(0, 0, 0, 0)
contentList.ScrollBarThickness = 6
contentList.Parent = contentFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Parent = contentList

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 100, 0, 20)
versionLabel.Position = UDim2.new(1, -105, 1, -25)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.TextTransparency = 0.7
versionLabel.Font = Enum.Font.SourceSans
versionLabel.TextSize = 12
versionLabel.Text = "Crimson Hub " .. HUB_VERSION
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = mainFrame

local scriptStates = {}
local isBindingKey = false

local function addHoverEffect(button)
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor:Lerp(Color3.new(1,1,1), 0.2)}):Play()
    end)
    button.MouseLeave:Connect(function()
        tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

local function sendNotification(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 50)
    frame.Position = UDim2.new(1, 260, 1, -60)
    frame.BackgroundTransparency = 1
    frame.Parent = screenGui
    
    local frameBg = Instance.new("Frame", frame)
    frameBg.Size = UDim2.fromScale(1,1)
    frameBg.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
    local corner = Instance.new("UICorner", frameBg)
    corner.CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", frameBg)
    stroke.Color = Color3.fromRGB(139, 0, 0)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextWrapped = true
    label.Parent = frameBg
    
    local timerBar = Instance.new("Frame", frameBg)
    timerBar.Size = UDim2.new(0, 0, 0, 3)
    timerBar.Position = UDim2.new(0, 0, 1, -3)
    timerBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    timerBar.BorderSizePixel = 0
    
    local showTween = tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -60)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 260, 1, -60)})
    local timerTween = tweenService:Create(timerBar, TweenInfo.new(7.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 3)})
    
    showTween:Play()
    timerTween:Play()
    task.wait(7.5)
    hideTween:Play()
    hideTween.Completed:Wait()
    frame:Destroy()
end

local function playIntro()
    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.fromScale(1,1)
    introFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    introFrame.BackgroundTransparency = 1
    introFrame.Parent = screenGui
    
    local pfp = Instance.new("ImageLabel")
    pfp.Size = UDim2.new(0, 100, 0, 100)
    pfp.Position = UDim2.new(0.5, -50, 0.5, -70)
    pfp.BackgroundTransparency = 1
    pfp.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..localPlayer.UserId.."&width=420&height=420&format=png"
    pfp.ImageTransparency = 1
    pfp.Parent = introFrame
    local pfpCorner = Instance.new("UICorner", pfp)
    pfpCorner.CornerRadius = UDim.new(1,0)
    
    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Size = UDim2.new(1, 0, 0, 30)
    welcomeLabel.Position = UDim2.new(0, 0, 0.5, 50)
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    welcomeLabel.Font = Enum.Font.SourceSansBold
    welcomeLabel.TextSize = 24
    welcomeLabel.Text = "Welcome, " .. localPlayer.DisplayName
    welcomeLabel.TextTransparency = 1
    welcomeLabel.Parent = introFrame

    tweenService:Create(introFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    task.wait(0.5)
    tweenService:Create(pfp, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
    tweenService:Create(welcomeLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(2)
    tweenService:Create(introFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    
    mainFrame.Visible = true
    for _,v in ipairs(mainFrame:GetDescendants()) do
        if v:IsA("GuiObject") then
            if v:IsA("Frame") or v:IsA("ImageLabel") then pcall(function() v.BackgroundTransparency = 1 end)
            elseif v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then pcall(function() v.TextTransparency = 1 end) end
        end
    end
    
    wait(0.5)
    introFrame:Destroy()
    
    for _,v in ipairs(mainFrame:GetDescendants()) do
        if v:IsA("GuiObject") then
            if v:IsA("Frame") or v:IsA("ImageLabel") then tweenService:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = v.Name == "contentList" and 1 or 0}):Play()
            elseif v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then tweenService:Create(v, TweenInfo.new(0.5), {TextTransparency = 0}):Play() end
        end
    end
end

local function httpGet(url)
	local success, result = pcall(function() return httpService:GetAsync(url) end)
	if success and result then return true, tostring(result) end
	local function tryRequest(reqFunc)
		if not reqFunc then return false, nil end
		local ok, resp = pcall(function() return reqFunc({Url = url, Method = "GET", Headers = { ["User-Agent"] = "CrimsonHub/1.0" }}) end)
		if ok and resp then return true, tostring(type(resp) == "table" and (resp.Body or resp.body or "") or resp) end
		return false, nil
	end
	local s,r = tryRequest(request) if s then return s,r end
	s,r = tryRequest(syn and syn.request) if s then return s,r end
	s,r = tryRequest(http_request) if s then return s,r end
	s,r = tryRequest(http and http.request) if s then return s,r end
	return false, tostring(result or "All HTTP GET methods failed.")
end

local function httpPost(url, body)
    local bodyContent, contentType, contentTypeEnum
    if type(body) == "table" then
        local ok, encoded = pcall(function() return httpService:JSONEncode(body) end)
        if not ok then return false, "Failed to encode JSON payload" end
        bodyContent, contentType, contentTypeEnum = encoded, "application/json", Enum.HttpContentType.ApplicationJson
    else
        bodyContent, contentType, contentTypeEnum = tostring(body), "text/plain", Enum.HttpContentType.TextPlain
    end
    local success, result = pcall(function() return httpService:PostAsync(url, bodyContent, contentTypeEnum) end)
    if success and result then return true, tostring(result) end
    local function tryRequest(reqFunc)
        if not reqFunc then return false, nil end
        local ok, resp = pcall(function() return reqFunc({Url = url, Method = "POST", Headers = { ["Content-Type"] = contentType, ["User-Agent"] = "CrimsonHub/1.0" }, Body = bodyContent}) end)
        if ok and resp then return true, tostring(type(resp) == "table" and (resp.Body or resp.body or "") or resp) end
        return false, nil
    end
    local s,r = tryRequest(request) if s then return s,r end
    s,r = tryRequest(syn and syn.request) if s then return s,r end
    s,r = tryRequest(http_request) if s then return s,r end
    s,r = tryRequest(http and http.request) if s then return s,r end
    return false, tostring(result or "All HTTP methods failed.")
end

local function isPositiveResponse(responseText)
    if not responseText or type(responseText) ~= "string" then return false end
    local text = responseText:lower():match("^%s*(.-)%s*$")
    if text == "true" or text == "1" or text == "ok" or text == "success" or text == "200" then return true end
    local success, decoded = pcall(function() return httpService:JSONDecode(responseText) end)
    if success and type(decoded) == "table" and (decoded.success == true or decoded.Success == true) then return true end
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
            if f and type(f) == "function" then
                task.spawn(f)
            else sendNotification("Error executing " .. scriptName) end
        end
    end
end

local function loadGameScripts()
    for _, child in ipairs(contentList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local gameId = tostring(game.PlaceId)
    if gameId == "0" then sendNotification("Cannot load scripts in Studio. Please publish first.") return end

    local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
    local ok, result = httpGet(apiUrl)
    if not ok then
        local err = tostring(result)
        if err:match("404") then sendNotification("No scripts found for this game.")
        elseif err:match("403") then sendNotification("GitHub API blocked/limited. Try again later.")
        else sendNotification("GitHub API error: " .. err:sub(1, 50)) end
        return
    end

    local ok2, decoded = pcall(function() return httpService:JSONDecode(result) end)
    if not ok2 or type(decoded) ~= "table" or not decoded[1] then
        sendNotification("No script files found in repo folder.")
        return
    end

    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptName = (scriptInfo.name or ""):gsub("%.lua$", "")
            local isToggle = scriptName:lower():find("toggle")

            if isToggle then
                scriptStates[scriptName] = {Enabled = false, Keybind = nil, Url = scriptInfo.download_url, OnHold = false}
                local container = Instance.new("Frame")
                container.Name = scriptName
                container.Size = UDim2.new(1, -20, 0, 40)
                container.BackgroundColor3 = themes[currentTheme].container
                container.Parent = contentList
                local contCorner = Instance.new("UICorner", container)
                contCorner.CornerRadius = UDim.new(0, 6)
                local scriptLabel = Instance.new("TextLabel")
                scriptLabel.Size = UDim2.new(1, -80, 1, 0)
                scriptLabel.Position = UDim2.new(0, 10, 0, 0)
                scriptLabel.BackgroundTransparency = 1
                scriptLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                scriptLabel.Text = scriptName
                scriptLabel.Font = Enum.Font.SourceSansBold
                scriptLabel.TextSize = 16
                scriptLabel.TextXAlignment = Enum.TextXAlignment.Left
                scriptLabel.Parent = container
                local toggleBg = Instance.new("Frame")
                toggleBg.Size = UDim2.new(0, 40, 0, 20)
                toggleBg.Position = UDim2.new(1, -50, 0.5, -10)
                toggleBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                toggleBg.Parent = container
                local bgCorner = Instance.new("UICorner", toggleBg)
                bgCorner.CornerRadius = UDim.new(0, 6)
                local toggleButton = Instance.new("TextButton")
                toggleButton.Size = UDim2.new(0, 20, 0, 20)
                toggleButton.Position = UDim2.new(0, 2, 0.5, -10)
                toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                toggleButton.Text = ""
                toggleButton.Parent = toggleBg
                local tglCorner = Instance.new("UICorner", toggleButton)
                tglCorner.CornerRadius = UDim.new(1, 0)
                toggleButton.MouseButton1Click:Connect(function() clickSound:Play() toggleScript(scriptName, toggleButton) end)
                toggleButton.MouseButton2Click:Connect(function()
                    clickSound:Play()
                    scriptStates[scriptName].OnHold = not scriptStates[scriptName].OnHold
                    local holdLabel = container:FindFirstChild("HoldLabel")
                    if scriptStates[scriptName].OnHold then
                        if not holdLabel then
                            holdLabel = Instance.new("TextLabel")
                            holdLabel.Name = "HoldLabel"
                            holdLabel.Size = UDim2.new(0, 50, 0, 15)
                            holdLabel.Position = UDim2.new(1, -55, 1, -15)
                            holdLabel.BackgroundTransparency = 1
                            holdLabel.TextColor3 = Color3.fromRGB(255,180,80)
                            holdLabel.Font = Enum.Font.SourceSans
                            holdLabel.TextSize = 12
                            holdLabel.Text = "(On Hold)"
                            holdLabel.Parent = container
                        end
                        holdLabel.Visible = true
                    else
                        if holdLabel then holdLabel.Visible = false end
                    end
                end)
            else
                local scriptButton = Instance.new("TextButton")
                scriptButton.Name = scriptName
                scriptButton.Size = UDim2.new(1, -20, 0, 40)
                scriptButton.BackgroundColor3 = themes[currentTheme].container
                scriptButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                scriptButton.Text = scriptName
                scriptButton.Font = Enum.Font.SourceSansBold
                scriptButton.TextSize = 16
                scriptButton.Parent = contentList
                local btnCorner = Instance.new("UICorner", scriptButton)
                btnCorner.CornerRadius = UDim.new(0, 6)
                addHoverEffect(scriptButton)
                scriptButton.MouseButton1Click:Connect(function()
                    clickSound:Play()
                    local ok3, scriptContent = httpGet(scriptInfo.download_url)
                    if ok3 and scriptContent then
                        local okRun, errRun = pcall(loadstring(scriptContent))
                        if okRun then sendNotification("Executed: " .. scriptButton.Text) else sendNotification("Error running script: " .. tostring(errRun)) end
                    else sendNotification("Error loading script content.") end
                end)
            end
        end
    end
    uiListLayout.Parent = nil uiListLayout.Parent = contentList
end

local minimized = false
local isVerifying = false

addHoverEffect(submitButton)
addHoverEffect(settingsButton)
addHoverEffect(closeButton)
addHoverEffect(minimizeButton)

settingsButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    currentTheme = (currentTheme == "original" and "lightBlack" or "original")
    mainFrame.BackgroundColor3 = themes[currentTheme].main
    for _, child in ipairs(contentList:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child.BackgroundColor3 = themes[currentTheme].container
        end
    end
end)

submitButton.MouseButton1Click:Connect(function()
    if isVerifying then return end
    clickSound:Play()
    isVerifying = true
    submitButton.Text = "Verifying..."
    local ok, respText = httpPost(serverUrl, keyInput.Text)
    if ok and isPositiveResponse(respText) then
        submitButton.Text = "Correct"
        task.wait(0.5)
        keyFrame:Destroy()
        playIntro()
        loadGameScripts()
    else
        submitButton.Text = ok and "Incorrect" or "Server Error"
        task.wait(2)
        submitButton.Text = "Submit"
    end
    isVerifying = false
end)

closeButton.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    contentList.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0, 450, 0, 30) or UDim2.new(0, 450, 0, 300)
end)

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or isBindingKey then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for name, state in pairs(scriptStates) do
            if state.Keybind and input.KeyCode == state.Keybind then
                local container = contentList:FindFirstChild(name)
                if container then toggleScript(name, container.Frame.TextButton) end
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not keyFrame.Parent then mainFrame.Visible = not mainFrame.Visible end
    end
end)
