local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")

local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local VERBOSE = false
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://crimson-keys.vercel.app/api/verify"
local toggleKey = Enum.KeyCode.RightControl

local theme = {
    background = Color3.fromRGB(21, 22, 28),
    backgroundSecondary = Color3.fromRGB(30, 32, 40),
    accent = Color3.fromRGB(45, 48, 61),
    primary = Color3.fromRGB(227, 38, 54),
    primaryGlow = Color3.fromRGB(255, 60, 75),
    text = Color3.fromRGB(240, 240, 240),
    textSecondary = Color3.fromRGB(150, 150, 150),
    success = Color3.fromRGB(0, 255, 127),
    warning = Color3.fromRGB(255, 165, 0),
    error = Color3.fromRGB(227, 38, 54)
}

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = lighting

local function setBlur(active)
    tweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = active and 12 or 0 }):Play()
end

local sounds = {
    open = "rbxassetid://6366382384",
    close = "rbxassetid://6366382384", 
    toggleOn = "rbxassetid://6366382384",
    toggleOff = "rbxassetid://6366382384",
    click = "rbxassetid://6366382384",
    error = "rbxassetid://5778393172",
    success = "rbxassetid://8621028374",
}

for name, id in pairs(sounds) do
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Name = name
    sound.Volume = 0.4
    sound.Parent = screenGui
    sounds[name] = sound
end

local function playSound(soundName)
    if sounds[soundName] then
        sounds[soundName]:Play()
    end
end

local notificationContainer = Instance.new("Frame")
notificationContainer.Size = UDim2.new(1, 0, 1, 0)
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui
local notificationLayout = Instance.new("UIListLayout", notificationContainer)
notificationLayout.FillDirection = Enum.FillDirection.Vertical
notificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notificationLayout.Padding = UDim.new(0, 10)

local function sendNotification(title, text, duration, notifType)
    duration = duration or 5
    notifType = notifType or "info"

    local icon, color = "rbxassetid://7998631525", theme.primary
    if notifType == "success" then
        icon, color = "rbxassetid://8620935528", theme.success
    elseif notifType == "warning" then
        icon, color = "rbxassetid://8620936395", theme.warning
    elseif notifType == "error" then
        icon, color = "rbxassetid://8620934661", theme.error
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 70)
    frame.Position = UDim2.new(1, 10, 1, -80)
    frame.BackgroundColor3 = theme.backgroundSecondary
    frame.BorderSizePixel = 0
    frame.Parent = notificationContainer
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = theme.accent
    stroke.Thickness = 1.5

    local colorBar = Instance.new("Frame", frame)
    colorBar.Size = UDim2.new(0, 5, 1, 0)
    colorBar.BackgroundColor3 = color
    colorBar.BorderSizePixel = 0
    Instance.new("UICorner", colorBar).CornerRadius = UDim.new(0, 8)

    local iconLabel = Instance.new("ImageLabel", frame)
    iconLabel.Size = UDim2.new(0, 24, 0, 24)
    iconLabel.Position = UDim2.new(0, 15, 0, 15)
    iconLabel.Image = icon
    iconLabel.ImageColor3 = color
    iconLabel.BackgroundTransparency = 1

    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, -50, 0, 20)
    titleLabel.Position = UDim2.new(0, 45, 0, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.Michroma
    titleLabel.TextColor3 = theme.text
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, -50, 0, 20)
    textLabel.Position = UDim2.new(0, 45, 0, 35)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextColor3 = theme.textSecondary
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true

    local progressBar = Instance.new("Frame", frame)
    progressBar.Size = UDim2.new(0, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0

    local showTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -310, 1, -80)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -80)})
    local progressTween = tweenService:Create(progressBar, TweenInfo.new(duration), {Size = UDim2.new(1, 0, 0, 2)})

    showTween:Play()
    progressTween:Play()

    task.wait(duration)

    hideTween:Play()
    hideTween.Completed:Wait()
    frame:Destroy()
end

local function httpGet(url)
    local success, result = pcall(function() return httpService:GetAsync(url) end)
    if success and result then return true, tostring(result) end
    local function tryRequest(reqFunc)
        if not reqFunc then return false, nil end
        local ok, resp = pcall(function() return reqFunc({Url = url, Method = "GET"}) end)
        if ok and resp then return true, tostring(resp.Body or resp) end
        return false, nil
    end
    local r, res = tryRequest(request)
    if r then return r, res end
    local s, res2 = tryRequest(syn and syn.request)
    if s then return s, res2 end
    return false, tostring(result or "Failed")
end

local function httpPost(url, body)
    local bodyContent = tostring(body)
    local s, r = pcall(function() return httpService:PostAsync(url, bodyContent, Enum.HttpContentType.TextPlain) end)
    if s and r then return true, tostring(r) end
     local function tryRequest(reqFunc)
        if not reqFunc then return false, nil end
        local ok, resp = pcall(function() return reqFunc({Url = url, Method = "POST", Headers = { ["Content-Type"] = "text/plain" }, Body = bodyContent}) end)
        if ok and resp then return true, tostring(resp.Body or resp) end
        return false, nil
    end
    local r2, res = tryRequest(request)
    if r2 then return r2, res end
    local s2, res2 = tryRequest(syn and syn.request)
    if s2 then return s2, res2 end
    return false, tostring(r or "Failed")
end

local function isPositiveResponse(responseText)
    if not responseText or type(responseText) ~= "string" then return false end
    local text = responseText:lower():match("^%s*(.-)%s*$")
    if text == "true" or text == "1" or text == "ok" or text == "success" or text == "200" then return true end
    local success, decoded = pcall(function() return httpService:JSONDecode(responseText) end)
    if success and type(decoded) == "table" and (decoded.success == true or decoded.Success == true) then return true end
    return false
end

local mainUI = {}

function mainUI:Create()
    local ui = { Visible = false }
    local pages = {}
    local tabs = {}

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = theme.background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    local mainFrameStroke = Instance.new("UIStroke", mainFrame)
    mainFrameStroke.Color = theme.accent
    mainFrameStroke.Thickness = 2

    local bgPattern = Instance.new("ImageLabel", mainFrame)
    bgPattern.Image = "rbxassetid://2887559971" 
    bgPattern.ScaleType = Enum.ScaleType.Tile
    bgPattern.TileSize = UDim2.new(0, 50, 0, 50)
    bgPattern.Size = UDim2.new(2, 0, 2, 0)
    bgPattern.Position = UDim2.new(-0.5, 0, -0.5, 0)
    bgPattern.ImageTransparency = 0.95
    bgPattern.ImageColor3 = theme.primary
    bgPattern.BackgroundTransparency = 1
    bgPattern.ZIndex = 0

    runService.RenderStepped:Connect(function()
        if mainFrame.Visible then
            local center = Vector2.new(mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X / 2, mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y / 2)
            local offset = Vector2.new(mouse.X - center.X, mouse.Y - center.Y)
            bgPattern.Position = UDim2.new(-0.5 - offset.X * 0.0005, 0, -0.5 - offset.Y * 0.0005, 0)
        end
    end)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = theme.backgroundSecondary
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = mainFrame

    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.primary),
        ColorSequenceKeypoint.new(1, theme.primaryGlow)
    })
    headerGradient.Rotation = 90

    local headerDivider = Instance.new("Frame", mainFrame)
    headerDivider.Size = UDim2.new(1, 0, 0, 3)
    headerDivider.Position = UDim2.new(0, 0, 0, 40)
    headerDivider.BackgroundColor3 = theme.primary
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 3
    headerDivider.Parent = headerGradient

    local logo = Instance.new("ImageLabel", header)
    logo.Image = "rbxassetid://3921711226" 
    logo.Size = UDim2.new(0, 24, 0, 24)
    logo.Position = UDim2.new(0, 10, 0.5, -12)
    logo.ImageColor3 = theme.primary
    logo.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", header)
    title.Text = "Crimson Hub"
    title.Font = Enum.Font.Michroma
    title.TextSize = 18
    title.TextColor3 = theme.text
    title.Position = UDim2.new(0, 45, 0, 0)
    title.Size = UDim2.new(0, 200, 1, 0)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    local clock = Instance.new("TextLabel", header)
    clock.Font = Enum.Font.Michroma
    clock.TextSize = 14
    clock.TextColor3 = theme.textSecondary
    clock.Position = UDim2.new(1, -200, 0, 0)
    clock.Size = UDim2.new(0, 100, 1, 0)
    clock.BackgroundTransparency = 1
    clock.TextXAlignment = Enum.TextXAlignment.Right
    runService.RenderStepped:Connect(function()
        clock.Text = os.date("%I:%M %p")
    end)

    local closeButton = Instance.new("ImageButton", header)
    closeButton.Size = UDim2.new(0, 18, 0, 18)
    closeButton.Position = UDim2.new(1, -28, 0.5, -9)
    closeButton.Image = "rbxassetid://13516603954"
    closeButton.ImageColor3 = theme.textSecondary
    closeButton.BackgroundTransparency = 1
    closeButton.ZIndex = 3

    local minimizeButton = Instance.new("ImageButton", header)
    minimizeButton.Size = UDim2.new(0, 18, 0, 18)
    minimizeButton.Position = UDim2.new(1, -56, 0.5, -9)
    minimizeButton.Image = "rbxassetid://13516604101" 
    minimizeButton.ImageColor3 = theme.textSecondary
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.ZIndex = 3

    local sidebar = Instance.new("Frame", mainFrame)
    sidebar.Size = UDim2.new(0, 150, 1, -40)
    sidebar.Position = UDim2.new(0, 0, 0, 40)
    sidebar.BackgroundColor3 = theme.backgroundSecondary
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
    local sidebarLayout = Instance.new("UIListLayout", sidebar)
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 10)

    local welcomeMessage = Instance.new("TextLabel", sidebar)
    welcomeMessage.Size = UDim2.new(1, -20, 0, 50)
    welcomeMessage.Text = "Welcome,\n" .. localPlayer.DisplayName
    welcomeMessage.Font = Enum.Font.Michroma
    welcomeMessage.TextSize = 14
    welcomeMessage.TextColor3 = theme.textSecondary
    welcomeMessage.TextWrapped = true
    welcomeMessage.BackgroundTransparency = 1
    welcomeMessage.LayoutOrder = -1

    local contentContainer = Instance.new("Frame", mainFrame)
    contentContainer.Size = UDim2.new(1, -150, 1, -40)
    contentContainer.Position = UDim2.new(0, 150, 0, 40)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = 1

    local function selectTab(tab)
        playSound("click")
        for _, otherTab in pairs(tabs) do
            tweenService:Create(otherTab:FindFirstChild("Indicator"), TweenInfo.new(0.3), { Size = UDim2.new(0, 2, 1, 0), BackgroundTransparency = 1 }):Play()
            tweenService:Create(otherTab, TweenInfo.new(0.3), { TextColor3 = theme.textSecondary }):Play()
        end
        for _, page in pairs(pages) do
            page.Visible = false
        end

        tweenService:Create(tab:FindFirstChild("Indicator"), TweenInfo.new(0.3), { Size = UDim2.new(0, 4, 1, 0), BackgroundTransparency = 0 }):Play()
        tweenService:Create(tab, TweenInfo.new(0.3), { TextColor3 = theme.text }):Play()
        pages[tab.Name].Visible = true
    end

    local function createTab(name)
        local tab = Instance.new("TextButton", sidebar)
        tab.Name = name
        tab.Size = UDim2.new(1, -20, 0, 40)
        tab.BackgroundColor3 = theme.accent
        tab.Text = name
        tab.Font = Enum.Font.Michroma
        tab.TextSize = 15
        tab.TextColor3 = theme.textSecondary
        tab.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)

        local indicator = Instance.new("Frame", tab)
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 2, 1, 0)
        indicator.BackgroundColor3 = theme.primary
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = 1
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 6)

        tab.MouseEnter:Connect(function() tweenService:Create(tab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 58, 71)}):Play() end)
        tab.MouseLeave:Connect(function() tweenService:Create(tab, TweenInfo.new(0.2), {BackgroundColor3 = theme.accent}):Play() end)
        tab.MouseButton1Click:Connect(function() selectTab(tab) end)

        tabs[name] = tab
        return tab
    end

    local function createPage(name)
        local page = Instance.new("ScrollingFrame", contentContainer)
        page.Name = name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarImageColor3 = theme.primary
        page.ScrollBarThickness = 6
        page.Visible = false
        pages[name] = page
        return page
    end

    local scriptsPage = createPage("Scripts")
    local scriptsLayout = Instance.new("UIGridLayout", scriptsPage)
    scriptsLayout.CellSize = UDim2.new(0, 200, 0, 50)
    scriptsLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    scriptsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scriptsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local settingsPage = createPage("Settings")
    local settingsLayout = Instance.new("UIListLayout", settingsPage)
    settingsLayout.Padding = UDim.new(0, 10)

    local infoPage = createPage("Info")
    local infoLabel = Instance.new("TextLabel", infoPage)
    infoLabel.Size = UDim2.new(1, -40, 0, 0)
    infoLabel.AutomaticSize = Enum.AutomaticSize.Y
    infoLabel.Position = UDim2.new(0, 20, 0, 20)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Text = "Crimson Hub\n\nUI Revamped by HackMrTank\nOriginal script by kyr2o."
    infoLabel.TextColor3 = theme.text
    infoLabel.TextSize = 16
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = true

    createTab("Scripts")
    createTab("Settings")
    createTab("Info")

    local function createScriptButton(name, callback)
        local buttonData = {enabled = false}

        local button = Instance.new("TextButton", scriptsPage)
        button.Size = UDim2.new(0, 200, 0, 50)
        button.BackgroundColor3 = theme.accent
        button.Text = ""
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel", button)
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = theme.text
        label.Text = name
        label.Font = Enum.Font.Michroma
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left

        local toggle = Instance.new("Frame", button)
        toggle.Size = UDim2.new(0, 40, 0, 20)
        toggle.Position = UDim2.new(1, -50, 0.5, -10)
        toggle.BackgroundColor3 = theme.background
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

        local toggleKnob = Instance.new("Frame", toggle)
        toggleKnob.Size = UDim2.new(0, 14, 0, 14)
        toggleKnob.Position = UDim2.new(0, 3, 0.5, -7)
        toggleKnob.BackgroundColor3 = theme.primary
        Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)

        local function updateToggle(manual)
            buttonData.enabled = not buttonData.enabled
            playSound(buttonData.enabled and "toggleOn" or "toggleOff")

            local pos = buttonData.enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            local color = buttonData.enabled and theme.success or theme.primary
            tweenService:Create(toggleKnob, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos, BackgroundColor3 = color}):Play()
            if manual then pcall(callback, buttonData.enabled) end
        end

        button.MouseButton1Click:Connect(function() updateToggle(true) end)
        button.MouseEnter:Connect(function() tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 58, 71)}):Play() end)
        button.MouseLeave:Connect(function() tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = theme.accent}):Play() end)
    end

    local function createScriptActionButton(name, callback)
        local button = Instance.new("TextButton", scriptsPage)
        button.Size = UDim2.new(0, 200, 0, 50)
        button.BackgroundColor3 = theme.accent
        button.Text = name
        button.Font = Enum.Font.Michroma
        button.TextSize = 14
        button.TextColor3 = theme.text
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

        button.MouseButton1Click:Connect(function()
            playSound("click")
            pcall(callback)
        end)
        button.MouseEnter:Connect(function() tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 58, 71)}):Play() end)
        button.MouseLeave:Connect(function() tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = theme.accent}):Play() end)
    end

    function ui:LoadScripts(scriptLoader)
        for _, child in ipairs(scriptsPage:GetChildren()) do
            if not child:IsA("UIGridLayout") then child:Destroy() end
        end
        local scripts = scriptLoader()
        if scripts then
            for name, executeFunc in pairs(scripts) do
                if name == "Break Gun" then
                    createScriptActionButton(name, function() executeFunc(true) end)
                else
                    createScriptButton(name, executeFunc)
                end
            end
        end
    end

    function ui:SetVisibility(visible)
        if ui.Visible == visible then return end
        ui.Visible = visible

        if visible then
            playSound("open")
            setBlur(true)
            mainFrame.Visible = true
            local introTween = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            mainFrame.Size = UDim2.new(0, 600, 0, 20)
            mainFrame.Position = UDim2.new(0.5, -300, 0.5, -10)
            tweenService:Create(mainFrame, introTween, {Size = UDim2.new(0, 600, 0, 400), Position = UDim2.new(0.5, -300, 0.5, -200)}):Play()
        else
            playSound("close")
            setBlur(false)
            local outroTween = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            tweenService:Create(mainFrame, outroTween, {Size = UDim2.new(0, 600, 0, 0), Position = UDim2.new(0.5, -300, 0.5, 0)}):Play()
            task.wait(0.4)
            mainFrame.Visible = false
        end
    end

    closeButton.MouseButton1Click:Connect(function() ui:SetVisibility(false) end)
    minimizeButton.MouseButton1Click:Connect(function() ui:SetVisibility(false) end)

    userInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey and userInputService:GetFocusedTextBox() == nil then
            ui:SetVisibility(not ui.Visible)
        end
    end)

    task.wait()
    selectTab(tabs["Scripts"])

    return ui
end

local function createVerificationUI(onSuccess)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 220)
    frame.Position = UDim2.new(0.5, -200, 0.5, -110)
    frame.BackgroundColor3 = theme.background
    frame.Draggable = true
    frame.Active = true
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", frame).Color = theme.accent

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = "VERIFICATION"
    title.Font = Enum.Font.Michroma
    title.TextColor3 = theme.text
    title.TextSize = 28

    local titleGlow = Instance.new("TextLabel", frame)
    titleGlow.Size = title.Size
    titleGlow.Position = title.Position
    titleGlow.BackgroundTransparency = 1
    titleGlow.Text = title.Text
    titleGlow.Font = title.Font
    titleGlow.TextColor3 = theme.primary
    titleGlow.TextSize = title.TextSize
    titleGlow.TextTransparency = 0.7
    titleGlow.ZIndex = -1

    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 60)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Please enter your key to continue"
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextColor3 = theme.textSecondary
    subtitle.TextSize = 16

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -40, 0, 45)
    input.Position = UDim2.new(0, 20, 0, 100)
    input.BackgroundColor3 = theme.backgroundSecondary
    input.TextColor3 = theme.text
    input.PlaceholderText = "Your Key"
    input.PlaceholderColor3 = theme.textSecondary
    input.Font = Enum.Font.SourceSans
    input.TextSize = 16
    input.Parent = frame
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", input).Color = theme.accent

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(1, -40, 0, 40)
    submit.Position = UDim2.new(0, 20, 0, 160)
    submit.BackgroundColor3 = theme.primary
    submit.Text = "SUBMIT"
    submit.Font = Enum.Font.Michroma
    submit.TextColor3 = Color3.new(1, 1, 1)
    submit.TextSize = 18
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 6)

    local loadingSpinner = Instance.new("ImageLabel", submit)
    loadingSpinner.Image = "rbxassetid://5107930337" 
    loadingSpinner.Size = UDim2.new(0, 24, 0, 24)
    loadingSpinner.Position = UDim2.new(0.5, -12, 0.5, -12)
    loadingSpinner.BackgroundTransparency = 1
    loadingSpinner.ImageColor3 = Color3.new(1, 1, 1)
    loadingSpinner.Visible = false

    submit.MouseButton1Click:Connect(function()
        playSound("click")
        local key = input.Text
        if not key or key == "" then
            sendNotification("Error", "Please enter a key.", 3, "error")
            return
        end

        submit.Text = ""
        loadingSpinner.Visible = true
        local rotationTween = tweenService:Create(loadingSpinner, TweenInfo.new(1, Enum.EasingStyle.Linear), { Rotation = 360 })
        local conn
        conn = rotationTween.Completed:Connect(function()
             if loadingSpinner.Visible then rotationTween:Play() end
        end)
        rotationTween:Play()

        task.spawn(function()
            local ok, respText = httpPost(serverUrl, key)

            rotationTween:Cancel()
            conn:Disconnect()
            loadingSpinner.Visible = false
            submit.Text = "SUBMIT"

            if ok and isPositiveResponse(respText) then
                playSound("success")
                sendNotification("Success", "Verification successful!", 3, "success")
                local outro = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)})
                outro:Play()
                outro.Completed:Wait()
                frame:Destroy()
                onSuccess()
            else
                playSound("error")
                sendNotification("Failed", "Invalid key provided.", 4, "error")
                local originalPos = frame.Position
                local shakeInfo = TweenInfo.new(0.07)
                for i = 1, 3 do
                    tweenService:Create(frame, shakeInfo, {Position = originalPos + UDim2.fromOffset(10, 0)}):Play()
                    task.wait(0.07)
                    tweenService:Create(frame, shakeInfo, {Position = originalPos - UDim2.fromOffset(10, 0)}):Play()
                    task.wait(0.07)
                end
                tweenService:Create(frame, shakeInfo, {Position = originalPos}):Play()
            end
        end)
    end)

    setBlur(true)
end

local function loadGameScripts()
    local gameId = tostring(game.PlaceId)
    if gameId == "0" then sendNotification("Studio", "Cannot load scripts in Studio.", 5, "warning"); return end
    local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
    local ok, result = httpGet(apiUrl)
    if not ok then sendNotification("Error", "Failed to contact GitHub.", 4, "error"); return end
    local success, decoded = pcall(function() return httpService:JSONDecode(result) end)
    if not success or type(decoded) ~= "table" or decoded.message then 
        sendNotification("Not Found", "No scripts found for this game.", 4, "warning")
        return 
    end

    local scriptList = {}
    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptName = (scriptInfo.name or ""):gsub("%.lua$", "")
            scriptList[scriptName] = function(state)
                if state == false then return end
                local s, content = httpGet(scriptInfo.download_url)
                if s and content then
                    local f, e = loadstring(content)
                    if f then 
                        pcall(f)
                    else 
                        sendNotification("Script Error", tostring(e), 5, "error") 
                    end
                else
                    sendNotification("Download Failed", "Could not download script.", 3, "error")
                end
            end
        end
    end
    return scriptList
end

createVerificationUI(function()
    local hub = mainUI:Create()
    hub:LoadScripts(loadGameScripts)
    hub:SetVisibility(true)
end)
