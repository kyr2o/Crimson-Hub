local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local VERBOSE = false
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://crimson-keys.vercel.app/api/verify"
local toggleKey = Enum.KeyCode.RightControl

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
local MM2_PLACEID = 142823291

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

do
    local old = CoreGui:FindFirstChild(MARKER_NAME)
    if old then old:Destroy() end
end

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
    duration = duration or 1
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

do
    local Shared = (getgenv and getgenv()) or _G
    Shared.CRIMSON_NOTIFY = function(title, text, duration, kind)
        sendNotification(title or "Crimson", text or "", duration or 1, kind or "info")
    end
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
        local ok, resp = pcall(function()
            return reqFunc({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "text/plain" },
                Body = bodyContent
            })
        end)
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

local function tryDisableByName(scriptName)
    local Shared = (getgenv and getgenv()) or _G
    local lowered = string.lower(scriptName or "")

    if Shared.CRIMSON_SCRIPTS and Shared.CRIMSON_SCRIPTS[scriptName] then
        local rec = Shared.CRIMSON_SCRIPTS[scriptName]
        if rec and rec.disable then pcall(function() rec.disable(true) end) end
    end

    if (lowered == "esp" or lowered:find("^esp$")) and Shared.CRIMSON_ESP and Shared.CRIMSON_ESP.disable then
        pcall(function() Shared.CRIMSON_ESP.disable(true) end)
    end
    if (lowered:find("trap")) and Shared.CRIMSON_TRAP and Shared.CRIMSON_TRAP.disable then
        pcall(function() Shared.CRIMSON_TRAP.disable(true) end)
    end

    if lowered:find("trap") then
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BillboardGui") and inst.Name == "TrapBillboard" then
                pcall(function() inst:Destroy() end)
            end
            if inst:IsA("Model") and inst.Name == "Trap" then
                local hl = inst:FindFirstChildOfClass("Highlight")
                if hl then pcall(function() hl:Destroy() end) end
            end
        end
    end
end

local function tryCopyToClipboard(text, parentForFallback)
    local ok = false
    local function try(f)
        if not ok and typeof(f) == "function" then
            local s = pcall(function() f(text) end)
            if s then ok = true end
        end
    end

    local env = (getgenv and getgenv()) or _G
    try(rawget(env or {}, "setclipboard"))
    try(rawget(_G, "setclipboard"))
    try(rawget(env or {}, "toclipboard"))
    if not ok and typeof(setclipboard) == "function" then try(setclipboard) end
    if not ok and typeof(toclipboard) == "function" then try(toclipboard) end
    if not ok and syn and typeof(syn.write_clipboard) == "function" then try(syn.write_clipboard) end
    if not ok and clipboard and typeof(clipboard.set) == "function" then try(clipboard.set) end

    if ok then return true end

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -40, 0, 36)
    box.Position = UDim2.new(0, 20, 1, 10)
    box.BackgroundColor3 = theme.backgroundSecondary
    box.TextColor3 = theme.text
    box.TextEditable = false
    box.ClearTextOnFocus = false
    box.Text = text
    box.Parent = parentForFallback
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", box).Color = theme.accent

    box:CaptureFocus()
    box.SelectionStart = 1
    box.CursorPosition = string.len(box.Text) + 1

    task.delay(5, function() if box and box.Parent then box:Destroy() end end)
    return false
end

local Shared = (getgenv and getgenv()) or _G
Shared.CRIMSON_UNI = Shared.CRIMSON_UNI or {
    ws = 16,
    jp = 50,
}
Shared.CRIMSON_UNI_ESP = Shared.CRIMSON_UNI_ESP or {}

local function applyMovement()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = Shared.CRIMSON_UNI.ws
    hum.JumpPower = Shared.CRIMSON_UNI.jp
end

localPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    applyMovement()
end)

do
    local State = {
        enabled = false,
        conns = {},
        perPlayer = {}, 
    }

    local function destroySafe(x)
        if x and x.Destroy then pcall(function() x:Destroy() end) end
    end

    local function addNameTag(character, player)
        local head = character:FindFirstChild("Head")
        if not head then return nil end
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 120, 0, 30)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        billboard.Name = "CrimsonUniName"
        billboard.Parent = head

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.DisplayName
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Parent = billboard

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60, 60, 60)
        stroke.Thickness = 2
        stroke.Parent = textLabel

        return billboard
    end

    local function addESP(plr)
        if plr == localPlayer then return end
        if State.perPlayer[plr] then return end
        local char = plr.Character
        if not char then return end
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.35
        hl.OutlineColor = Color3.fromRGB(60, 60, 60) 
        hl.OutlineTransparency = 0
        hl.Parent = char
        local bb = addNameTag(char, plr)
        State.perPlayer[plr] = {hl = hl, bb = bb}
    end

    local function removeESP(plr)
        local pack = State.perPlayer[plr]
        if not pack then return end
        destroySafe(pack.hl)
        destroySafe(pack.bb)
        State.perPlayer[plr] = nil
    end

    local function refreshPlayer(plr)
        removeESP(plr)
        addESP(plr)
    end

    local function enable()
        if State.enabled then return end
        State.enabled = true
        for _, p in ipairs(players:GetPlayers()) do
            addESP(p)
            State.perPlayer[p] = State.perPlayer[p]
            local c1 = p.CharacterAdded:Connect(function()
                task.wait(0.2)
                if State.enabled then refreshPlayer(p) end
            end)
            local c2 = p.CharacterRemoving:Connect(function()
                removeESP(p)
            end)
            State.conns[#State.conns+1] = c1
            State.conns[#State.conns+1] = c2
        end
        local c3 = players.PlayerAdded:Connect(function(p)
            if State.enabled then
                task.wait(0.2)
                addESP(p)
                local cA = p.CharacterAdded:Connect(function()
                    task.wait(0.2)
                    if State.enabled then refreshPlayer(p) end
                end)
                State.conns[#State.conns+1] = cA
            end
        end)
        local c4 = players.PlayerRemoving:Connect(function(p)
            removeESP(p)
        end)
        State.conns[#State.conns+1] = c3
        State.conns[#State.conns+1] = c4
    end

    local function disable()
        if not State.enabled then return end
        State.enabled = false
        for _, c in ipairs(State.conns) do
            pcall(function() c:Disconnect() end)
        end
        State.conns = {}
        for plr, _ in pairs(State.perPlayer) do
            removeESP(plr)
        end
    end

    Shared.CRIMSON_UNI_ESP.enable = enable
    Shared.CRIMSON_UNI_ESP.disable = disable
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
    sidebarLayout.Padding = UDim.new(0, 10)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

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
            local ind = otherTab:FindFirstChild("Indicator")
            if ind then
                tweenService:Create(ind, TweenInfo.new(0.3), { Size = UDim2.new(0, 2, 1, 0), BackgroundTransparency = 1 }):Play()
            end
            tweenService:Create(otherTab, TweenInfo.new(0.3), { TextColor3 = theme.textSecondary }):Play()
        end
        for _, page in pairs(pages) do
            page.Visible = false
        end
        local myInd = tab:FindFirstChild("Indicator")
        if myInd then
            tweenService:Create(myInd, TweenInfo.new(0.3), { Size = UDim2.new(0, 4, 1, 0), BackgroundTransparency = 0 }):Play()
        end
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
    local scriptsLayout = Instance.new("UIListLayout", scriptsPage)
    scriptsLayout.Padding = UDim.new(0, 10)
    scriptsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scriptsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

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
    infoLabel.Text = "Crimson Hub\n\nThe Latest Script Hub Built for Powerful Executors.\nBy Kyr2o !"
    infoLabel.TextColor3 = theme.text
    infoLabel.TextSize = 16
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = true

    createTab("Scripts")
    createTab("Settings")
    createTab("Info")

    do
        local row = Instance.new("Frame", settingsPage)
        row.Size = UDim2.new(1, -40, 0, 40)
        row.Position = UDim2.new(0, 20, 0, 20)
        row.BackgroundColor3 = theme.backgroundSecondary
        row.BackgroundTransparency = 0.3
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local label = Instance.new("TextLabel", row)
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "Toggle GUI:"
        label.Font = Enum.Font.Michroma
        label.TextSize = 14
        label.TextColor3 = theme.text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Position = UDim2.new(0, 10, 0, 0)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0.35, -10, 0, 28)
        btn.Position = UDim2.new(0.62, 0, 0.5, -14)
        btn.BackgroundColor3 = theme.accent
        btn.Font = Enum.Font.Michroma
        btn.TextSize = 14
        btn.TextColor3 = theme.text
        btn.Text = tostring(toggleKey.Name)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local waiting = false
        btn.MouseButton1Click:Connect(function()
            playSound("click")
            if waiting then return end
            waiting = true
            btn.Text = "..."
            local con
            con = userInputService.InputBegan:Connect(function(input, gpe)
                if not waiting then return end
                if gpe then return end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    toggleKey = input.KeyCode
                    btn.Text = tostring(toggleKey.Name)
                    waiting = false
                    con:Disconnect()
                end
            end)
        end)
    end

    local function createScriptButton(parent, name, callback)
        local buttonData = {enabled = false}

        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(0, 200, 0, 40)
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
            tweenService:Create(toggleKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos, BackgroundColor3 = color}):Play()
            if manual then pcall(callback, buttonData.enabled) end
        end

        button.MouseButton1Click:Connect(function() updateToggle(true) end)
        button.MouseEnter:Connect(function() tweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 58, 71)}):Play() end)
        button.MouseLeave:Connect(function() tweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.accent}):Play() end)
        return button
    end

    local function createActionButton(parent, name, callback)
        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(0, 200, 0, 40)
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
        button.MouseEnter:Connect(function() tweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 58, 71)}):Play() end)
        button.MouseLeave:Connect(function() tweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.accent}):Play() end)
        return button
    end

    local mm2Container, uniContainer
    local function buildScriptsContainers()
        scriptsPage:ClearAllChildren()
        local headerRow = Instance.new("Frame", scriptsPage)
        headerRow.Size = UDim2.new(1, -40, 0, 34)
        headerRow.Position = UDim2.new(0, 20, 0, 10)
        headerRow.BackgroundTransparency = 1

        local mm2Btn = Instance.new("TextButton", headerRow)
        mm2Btn.Size = UDim2.new(0, 90, 0, 30)
        mm2Btn.Position = UDim2.new(0, 0, 0, 0)
        mm2Btn.BackgroundColor3 = theme.accent
        mm2Btn.Text = "MM2"
        mm2Btn.Font = Enum.Font.Michroma
        mm2Btn.TextSize = 14
        mm2Btn.TextColor3 = theme.text
        Instance.new("UICorner", mm2Btn).CornerRadius = UDim.new(0, 6)

        local uniBtn = Instance.new("TextButton", headerRow)
        uniBtn.Size = UDim2.new(0, 110, 0, 30)
        uniBtn.Position = UDim2.new(0, 100, 0, 0)
        uniBtn.BackgroundColor3 = theme.accent
        uniBtn.Text = "Universal"
        uniBtn.Font = Enum.Font.Michroma
        uniBtn.TextSize = 14
        uniBtn.TextColor3 = theme.text
        Instance.new("UICorner", uniBtn).CornerRadius = UDim.new(0, 6)

        mm2Container = Instance.new("Frame", scriptsPage)
        mm2Container.Size = UDim2.new(1, -40, 1, -60)
        mm2Container.Position = UDim2.new(0, 20, 0, 50)
        mm2Container.BackgroundTransparency = 1

        uniContainer = Instance.new("Frame", scriptsPage)
        uniContainer.Size = UDim2.new(1, -40, 1, -60)
        uniContainer.Position = UDim2.new(0, 20, 0, 50)
        uniContainer.BackgroundTransparency = 1

        local function show(which)
            mm2Container.Visible = (which == "mm2")
            uniContainer.Visible = (which == "uni")
        end
        mm2Btn.MouseButton1Click:Connect(function() show("mm2") end)
        uniBtn.MouseButton1Click:Connect(function() show("uni") end)
        show("mm2")
    end

    local function buildUniversalUI()
        uniContainer:ClearAllChildren()
        local list = Instance.new("UIListLayout", uniContainer)
        list.Padding = UDim.new(0, 8)
        list.SortOrder = Enum.SortOrder.LayoutOrder

        local function numberRow(labelText, initial, onCommit)
            local row = Instance.new("Frame", uniContainer)
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = theme.backgroundSecondary
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            local lab = Instance.new("TextLabel", row)
            lab.Size = UDim2.new(0.5, -10, 1, 0)
            lab.Position = UDim2.new(0, 10, 0, 0)
            lab.BackgroundTransparency = 1
            lab.Text = labelText
            lab.Font = Enum.Font.Michroma
            lab.TextSize = 14
            lab.TextColor3 = theme.text
            lab.TextXAlignment = Enum.TextXAlignment.Left
            local box = Instance.new("TextBox", row)
            box.Size = UDim2.new(0.5, -20, 0, 28)
            box.Position = UDim2.new(0.5, 10, 0.5, -14)
            box.BackgroundColor3 = theme.accent
            box.Font = Enum.Font.SourceSans
            box.TextSize = 16
            box.TextColor3 = theme.text
            box.Text = tostring(initial)
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

            local last = box.Text
            box:GetPropertyChangedSignal("Text"):Connect(function()
                if box.Text == "" then last = "" return end
                if tonumber(box.Text) then
                    last = box.Text
                else
                    box.Text = last
                end
            end)
            box.FocusLost:Connect(function(enter)
                local n = tonumber(box.Text)
                if n then onCommit(n) else box.Text = tostring(initial) end
            end)
        end

        numberRow("WalkSpeed", Shared.CRIMSON_UNI.ws, function(v)
            Shared.CRIMSON_UNI.ws = v
            applyMovement()
        end)
        numberRow("JumpPower", Shared.CRIMSON_UNI.jp, function(v)
            Shared.CRIMSON_UNI.jp = v
            applyMovement()
        end)

        local espRow = Instance.new("Frame", uniContainer)
        espRow.Size = UDim2.new(1, 0, 0, 40)
        espRow.BackgroundColor3 = theme.backgroundSecondary
        Instance.new("UICorner", espRow).CornerRadius = UDim.new(0, 6)
        local lab = Instance.new("TextLabel", espRow)
        lab.Size = UDim2.new(0.5, -10, 1, 0)
        lab.Position = UDim2.new(0, 10, 0, 0)
        lab.BackgroundTransparency = 1
        lab.Text = "ESP (All players)"
        lab.Font = Enum.Font.Michroma
        lab.TextSize = 14
        lab.TextColor3 = theme.text
        lab.TextXAlignment = Enum.TextXAlignment.Left
        createScriptButton(espRow, "Enable", function(state)
            if state then
                if Shared.CRIMSON_UNI_ESP and Shared.CRIMSON_UNI_ESP.enable then
                    Shared.CRIMSON_UNI_ESP.enable()
                end
            else
                if Shared.CRIMSON_UNI_ESP and Shared.CRIMSON_UNI_ESP.disable then
                    Shared.CRIMSON_UNI_ESP.disable()
                end
            end
        end)
    end

    local function addCategory(parent, titleText)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 28)
        container.BackgroundTransparency = 1

        local title = Instance.new("TextLabel", container)
        title.Size = UDim2.new(0, 100, 1, 0)
        title.Text = titleText
        title.Font = Enum.Font.Michroma
        title.TextSize = 14
        title.TextColor3 = theme.text
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left

        local line = Instance.new("Frame", container)
        line.Size = UDim2.new(1, -110, 0, 2)
        line.Position = UDim2.new(0, 105, 0.5, -1)
        line.BackgroundColor3 = theme.accent
        line.BorderSizePixel = 0

        local list = Instance.new("UIListLayout", parent)
        list.Padding = UDim.new(0, 8)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        return container
    end

    function ui:LoadScripts(scriptLoader)
        scriptsPage:ClearAllChildren()
        if game.PlaceId == MM2_PLACEID then
            buildScriptsContainers()
            buildUniversalUI()

            local scripts = scriptLoader()

            local content = Instance.new("Frame", mm2Container)
            content.Size = UDim2.new(1, 0, 1, 0)
            content.BackgroundTransparency = 1
            local list = Instance.new("UIListLayout", content)
            list.Padding = UDim.new(0, 8)
            list.SortOrder = Enum.SortOrder.LayoutOrder

            addCategory(content, "ESP --------")
            local espRow = Instance.new("Frame", content)
            espRow.Size = UDim2.new(1, 0, 0, 48)
            espRow.BackgroundTransparency = 1
            local espList = Instance.new("UIListLayout", espRow)
            espList.FillDirection = Enum.FillDirection.Horizontal
            espList.Padding = UDim.new(0, 10)

            if scripts["ESP"] then
                createScriptButton(espRow, "Role ESP", function(state) if state then scripts["ESP"](true) else tryDisableByName("ESP") end end)
            end
            if scripts["Trap ESP"] then
                createScriptButton(espRow, "Trap ESP", function(state) if state then scripts["Trap ESP"](true) else tryDisableByName("Trap ESP") end end)
            end

            addCategory(content, "Actions ----")
            local actRow = Instance.new("Frame", content)
            actRow.Size = UDim2.new(1, 0, 0, 48)
            actRow.BackgroundTransparency = 1
            local actList = Instance.new("UIListLayout", actRow)
            actList.FillDirection = Enum.FillDirection.Horizontal
            actList.Padding = UDim.new(0, 10)

            if scripts["Break Gun"] then
                createActionButton(actRow, "Break Gun", function() scripts["Break Gun"](true) end)
            end
            if scripts["KillAll"] then
                createActionButton(actRow, "Kill All", function() scripts["KillAll"](true) end)
            end

            addCategory(content, "Other ------")
            for name, fn in pairs(scripts) do
                if name ~= "ESP" and name ~= "Trap ESP" and name ~= "Break Gun" and name ~= "KillAll" then
                    createScriptButton(content, name, fn)
                end
            end
        else

            local grid = Instance.new("UIGridLayout", scriptsPage)
            grid.CellSize = UDim2.new(0, 200, 0, 50)
            grid.CellPadding = UDim2.new(0, 15, 0, 15)
            grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            local scripts = scriptLoader()
            if scripts then
                for name, executeFunc in pairs(scripts) do
                    if name == "Break Gun" or name == "KillAll" then
                        createActionButton(scriptsPage, name, function() executeFunc(true) end)
                    else
                        createScriptButton(scriptsPage, name, executeFunc)
                    end
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
        if userInputService:GetFocusedTextBox() ~= nil then return end
        if input.KeyCode == toggleKey then
            ui:SetVisibility(not ui.Visible)
        end
    end)

    task.wait()
    selectTab(tabs["Scripts"])

    return ui
end

local function createVerificationUI(onSuccess)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 270)
    frame.Position = UDim2.new(0.5, -200, 0.5, -135)
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
    submit.Text = "VERIFY"
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

    local getLink = Instance.new("TextButton", frame)
    getLink.Size = UDim2.new(1, -40, 0, 36)
    getLink.Position = UDim2.new(0, 20, 0, 208)
    getLink.BackgroundColor3 = theme.accent
    getLink.Text = "GET LINK"
    getLink.Font = Enum.Font.Michroma
    getLink.TextColor3 = theme.text
    getLink.TextSize = 16
    Instance.new("UICorner", getLink).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", getLink).Color = theme.accent

    local LINK_TO_COPY = "https://workink.net/25bz/0qrqef0f"

    getLink.MouseButton1Click:Connect(function()
        playSound("click")
        local ok = tryCopyToClipboard(LINK_TO_COPY, frame)
        if ok then
            sendNotification("Copied", "Link copied to clipboard.", 1, "success")
        else
            sendNotification("Copy", "Clipboard not available; select and copy.", 2, "warning")
        end
    end)

    submit.MouseButton1Click:Connect(function()
        playSound("click")
        local key = input.Text
        if not key or key == "" then
            sendNotification("Error", "Please enter a key.", 1, "error")
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
            submit.Text = "VERIFY"

            if ok and isPositiveResponse(respText) then
                local marker = CoreGui:FindFirstChild(MARKER_NAME) or Instance.new("Folder")
                marker.Name = MARKER_NAME
                marker:SetAttribute("ver", 1)
                marker.Parent = CoreGui

                playSound("success")
                sendNotification("Success", "Verification successful!", 1, "success")
                local outro = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)})
                outro:Play()
                outro.Completed:Wait()
                frame:Destroy()
                onSuccess()
            else
                playSound("error")
                sendNotification("Failed", "Invalid key provided.", 1, "error")
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
            local url = scriptInfo.download_url

            scriptList[scriptName] = function(state)
                if state == false then
                    tryDisableByName(scriptName)
                    return
                end

                if not CoreGui:FindFirstChild(MARKER_NAME) then
                    sendNotification("Locked", "Verify to run scripts.", 2, "warning")
                    return
                end

                local s, content = httpGet(url)
                if s and content then
                    local f, e = loadstring(content)
                    if f then
                        local okRun, err = pcall(f)
                        if not okRun and err then
                            sendNotification("Script Error", tostring(err), 5, "error")
                        end
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
