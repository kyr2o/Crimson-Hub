local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local stats = game:GetService("Stats")

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
    background = Color3.fromRGB(15, 16, 22),
    backgroundSecondary = Color3.fromRGB(22, 24, 32),
    accent = Color3.fromRGB(38, 42, 55),
    accentLight = Color3.fromRGB(55, 60, 75),
    primary = Color3.fromRGB(227, 38, 54),
    primaryGlow = Color3.fromRGB(255, 60, 75),
    secondary = Color3.fromRGB(120, 120, 255),
    text = Color3.fromRGB(245, 245, 245),
    textSecondary = Color3.fromRGB(160, 160, 160),
    success = Color3.fromRGB(0, 255, 127),
    warning = Color3.fromRGB(255, 165, 0),
    error = Color3.fromRGB(227, 38, 54),
    shadow = Color3.fromRGB(0, 0, 0),

    gradientPrimary = Color3.fromRGB(180, 30, 45),
    gradientSecondary = Color3.fromRGB(90, 95, 200),
    gradientAccent = Color3.fromRGB(45, 50, 65)
}

local CATEGORY_SPEC = {
    [MM2_PLACEID] = {
        { title = "ESP", modules = { "RoleESP", "Trap ESP" } },
        { title = "Actions", modules = { "KillAll", "Auto Shoot", "Break Gun", "Auto Knife Throw" } },
        { title = "Farming", modules = { "Coin Farm" } },
        { title = "Other", modules = "REMAINDER" },
    },
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
    tweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = active and 16 or 0 }):Play()
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
    frame.Size = UDim2.new(0, 320, 0, 80)
    frame.Position = UDim2.new(1, 10, 1, -90)
    frame.BackgroundColor3 = theme.backgroundSecondary
    frame.BorderSizePixel = 0
    frame.Parent = notificationContainer
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = color
    stroke.Thickness = 2

    local shadow = Instance.new("Frame", frame)
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, 3, 0, 3)
    shadow.BackgroundColor3 = theme.shadow
    shadow.BackgroundTransparency = 0.8
    shadow.ZIndex = frame.ZIndex - 1
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

    local gradient = Instance.new("UIGradient", frame)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.backgroundSecondary),
        ColorSequenceKeypoint.new(0.5, theme.accent),
        ColorSequenceKeypoint.new(1, theme.gradientAccent)
    })
    gradient.Rotation = 45

    local colorBar = Instance.new("Frame", frame)
    colorBar.Size = UDim2.new(0, 6, 1, 0)
    colorBar.BackgroundColor3 = color
    colorBar.BorderSizePixel = 0
    Instance.new("UICorner", colorBar).CornerRadius = UDim.new(0, 12)

    local colorBarGradient = Instance.new("UIGradient", colorBar)
    colorBarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(math.min(255, color.R * 255 + 30), math.min(255, color.G * 255 + 30), math.min(255, color.B * 255 + 30)))
    })
    colorBarGradient.Rotation = 90

    local iconLabel = Instance.new("ImageLabel", frame)
    iconLabel.Size = UDim2.new(0, 28, 0, 28)
    iconLabel.Position = UDim2.new(0, 18, 0, 18)
    iconLabel.Image = icon
    iconLabel.ImageColor3 = color
    iconLabel.BackgroundTransparency = 1

    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, -60, 0, 24)
    titleLabel.Position = UDim2.new(0, 55, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.Michroma
    titleLabel.TextColor3 = theme.text
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, -60, 0, 24)
    textLabel.Position = UDim2.new(0, 55, 0, 42)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextColor3 = theme.textSecondary
    textLabel.TextSize = 15
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true

    local progressBar = Instance.new("Frame", frame)
    progressBar.Size = UDim2.new(0, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 12)

    local showTween = tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -330, 1, -90)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -90)})
    local progressTween = tweenService:Create(progressBar, TweenInfo.new(duration), {Size = UDim2.new(1, 0, 0, 3)})

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

    if (lowered:find("break") and lowered:find("gun")) or lowered == "break gun" then
        if Shared.CRIMSON_BREAK_GUN and Shared.CRIMSON_BREAK_GUN.disable then
            pcall(function() Shared.CRIMSON_BREAK_GUN.disable(true) end)
        end
    end

    if (lowered == "roleesp" or lowered:find("role") or lowered == "esp") then
        if Shared.CRIMSON_ROLEESP and Shared.CRIMSON_ROLEESP.disable then
            pcall(function() Shared.CRIMSON_ROLEESP.disable(true) end)
        end
        if Shared.CRIMSON_ESP and Shared.CRIMSON_ESP.disable then
            pcall(function() Shared.CRIMSON_ESP.disable(true) end)
        end
        for _, plr in ipairs(players:GetPlayers()) do
            local ch = plr.Character
            if ch then
                local hl = ch:FindFirstChildOfClass("Highlight")
                if hl then pcall(function() hl:Destroy() end) end
                local head = ch:FindFirstChild("Head")
                if head then
                    local bb = head:FindFirstChild("RoleBillboard")
                    if bb then pcall(function() bb:Destroy() end) end
                end
            end
        end
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
    box.TextColor3 = Color3.new(1, 1, 1) 
    box.TextEditable = false
    box.ClearTextOnFocus = false
    box.Text = text
    box.Parent = parentForFallback
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", box).Color = theme.accent

    box:CaptureFocus()
    box.SelectionStart = 1
    box.CursorPosition = string.len(box.Text) + 1

    task.delay(5, function() if box and box.Parent then box:Destroy() end end)
    return false
end

local mainUI = {}

local function addCategoryRow(parent, titleText)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 35) 
    container.BackgroundTransparency = 1

    local padding = Instance.new("UIPadding", container)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 8)

    local title = Instance.new("TextLabel", container)
    title.Size = UDim2.new(0, 140, 1, 0)  
    title.Text = titleText
    title.Font = Enum.Font.Michroma
    title.TextSize = 16
    title.TextColor3 = theme.text
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", container)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = theme.accent
    line.Size = UDim2.new(1, -(140 + 25), 0, 3)  
    line.Position = UDim2.new(0, 140 + 15, 0.5, -1)
    Instance.new("UICorner", line).CornerRadius = UDim.new(0, 2)

    local lineGradient = Instance.new("UIGradient", line)
    lineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.accent),
        ColorSequenceKeypoint.new(0.5, theme.primary),
        ColorSequenceKeypoint.new(1, theme.gradientAccent)
    })

    return container
end

local function createAutoBreakGun()
    local Shared = (getgenv and getgenv()) or _G

    Shared.CRIMSON_BREAK_GUN = Shared.CRIMSON_BREAK_GUN or {
        enabled = false,
        connection = nil,
        currentSheriff = nil
    }

    local function isAlive(plr)
        local ch = plr.Character
        if not ch then return false end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        if ch:GetAttribute("Alive") == false then return false end
        return hum.Health > 0
    end

    local function findSheriff()
        for _, p in ipairs(players:GetPlayers()) do
            if p ~= players.LocalPlayer and p.Character and isAlive(p) then
                local ch = p.Character
                local backpack = p:FindFirstChild("Backpack")
                if ch:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
                    return p
                end
            end
        end
        return nil
    end

    local function breakGunLoop(gun)
        local shoot = gun and gun:FindFirstChild("ShootGun", true)
        while shoot and shoot.Parent and Shared.CRIMSON_BREAK_GUN.enabled do
            shoot:InvokeServer(1, 0, "AH2")
            runService.Heartbeat:Wait()
        end
    end

    local function autoBreakGunLoop()
        while Shared.CRIMSON_BREAK_GUN.enabled do
            local sheriff = findSheriff()

            if sheriff and isAlive(sheriff) then
                Shared.CRIMSON_BREAK_GUN.currentSheriff = sheriff
                local ch = sheriff.Character
                local gun = ch and (ch:FindFirstChild("Gun") or ch:FindFirstChild("Gun", true))

                if gun then
                    breakGunLoop(gun)
                else

                    local equipped = false
                    local timeout = 0

                    while Shared.CRIMSON_BREAK_GUN.enabled and not equipped and timeout < 50 and isAlive(sheriff) do
                        local updatedCh = sheriff.Character
                        if updatedCh and updatedCh:FindFirstChild("Gun") then
                            equipped = true
                            gun = updatedCh:FindFirstChild("Gun")
                            if gun then
                                breakGunLoop(gun)
                            end
                        else
                            runService.Heartbeat:Wait()
                            timeout = timeout + 1
                        end
                    end
                end
            end

            if Shared.CRIMSON_BREAK_GUN.enabled then
                task.wait(0.5)
            end
        end
    end

    local function toggleAutoBreakGun(state)
        Shared.CRIMSON_BREAK_GUN.enabled = state

        if state then
            if not CoreGui:FindFirstChild(MARKER_NAME) then
                sendNotification("Locked", "Verify to run scripts.", 2, "warning")
                return false
            end

            sendNotification("Break Gun", "Auto break gun enabled!", 1, "success")

            task.spawn(function()
                autoBreakGunLoop()
            end)
        else
            sendNotification("Break Gun", "Auto break gun disabled.", 1, "info")
            Shared.CRIMSON_BREAK_GUN.currentSheriff = nil
        end

        return state
    end

    Shared.CRIMSON_BREAK_GUN.disable = function(force)
        Shared.CRIMSON_BREAK_GUN.enabled = false
        Shared.CRIMSON_BREAK_GUN.currentSheriff = nil
        if force then
            sendNotification("Break Gun", "Auto break gun stopped.", 1, "warning")
        end
    end

    return toggleAutoBreakGun
end

local function createAutoShoot()
    local G = (getgenv and getgenv()) or _G
    G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }

    do
        local function predictionFromPing(ms)
            if not ms or ms ~= ms then return 0.14 end
            if ms <= 40  then return 0.06 end
            if ms <= 60  then return 0.08 end
            if ms <= 80  then return 0.10 end
            if ms <= 100 then return 0.12 end
            if ms <= 120 then return 0.135 end
            if ms <= 150 then return 0.15 end
            if ms <= 180 then return 0.17 end
            if ms <= 220 then return 0.19 end
            return 0.21
        end

        local function getPingMs()
            local net = stats and stats.Network
            local item = net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"]
            local v = item and item:GetValue()
            if v and v < 1 then return math.floor(v*1000 + 0.5) end
            return math.floor((v or 0) + 0.5)
        end

        G.CRIMSON_AUTO_SHOOT.calibrate = function()
            local ms = getPingMs()
            local pred = predictionFromPing(ms)
            G.CRIMSON_AUTO_SHOOT.prediction = pred
            return ms, pred
        end
    end

    local shootConnection

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
            local rf = gun:FindFirstChild("KnifeLocal")
                and gun.KnifeLocal:FindFirstChild("CreateBeam")
                and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
            if not rf then return end
            if shootConnection then shootConnection:Disconnect() end
            shootConnection = runService.Heartbeat:Connect(function()
                if not G.CRIMSON_AUTO_SHOOT.enabled then return end
                if not character:FindFirstChild("Gun") then return end
                local murderer = findMurderer()
                local root = murderer and murderer.Character and murderer.Character:FindFirstChild("UpperTorso")
                if root then
                    local pred = tonumber(G.CRIMSON_AUTO_SHOOT.prediction) or 0
                    local aimPos = root.Position + (root.Velocity * pred)
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

    if localPlayer.Character then onCharacter(localPlayer.Character) end
    localPlayer.CharacterAdded:Connect(onCharacter)

    G.CRIMSON_AUTO_SHOOT.enable = function()
        G.CRIMSON_AUTO_SHOOT.enabled = true
    end
    G.CRIMSON_AUTO_SHOOT.disable = function()
        G.CRIMSON_AUTO_SHOOT.enabled = false
        disconnectShoot()
    end
	
	return function(state)
		if state then
			G.CRIMSON_AUTO_SHOOT.enable()
		else
			G.CRIMSON_AUTO_SHOOT.disable()
		end
	end
end

function mainUI:Create()
    local ui = { Visible = false }
    local pages = {}
    local tabs = {}
    local G = (getgenv and getgenv()) or _G
    G.CRIMSON_SETTINGS = G.CRIMSON_SETTINGS or { WalkSpeed = 16, JumpPower = 50 }

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 720, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
    mainFrame.BackgroundColor3 = theme.background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

    local mainFrameStroke = Instance.new("UIStroke", mainFrame)
    mainFrameStroke.Color = theme.primary
    mainFrameStroke.Thickness = 3
    mainFrameStroke.Transparency = 0.3

    local mainShadow = Instance.new("Frame", screenGui)
    mainShadow.Size = UDim2.new(0, 720 + 20, 0, 480 + 20)
    mainShadow.Position = UDim2.new(0.5, -360 - 10, 0.5, -240 - 10)
    mainShadow.BackgroundColor3 = theme.shadow
    mainShadow.BackgroundTransparency = 0.7
    mainShadow.BorderSizePixel = 0
    mainShadow.Visible = false
    mainShadow.ZIndex = mainFrame.ZIndex - 1
    Instance.new("UICorner", mainShadow).CornerRadius = UDim.new(0, 20)

    local bgGradient = Instance.new("UIGradient", mainFrame)
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.background),
        ColorSequenceKeypoint.new(0.3, theme.backgroundSecondary),
        ColorSequenceKeypoint.new(0.7, theme.gradientAccent),
        ColorSequenceKeypoint.new(1, theme.background)
    })
    bgGradient.Rotation = 135

    local bgPattern = Instance.new("ImageLabel", mainFrame)
    bgPattern.Image = "rbxassetid://2887559971"
    bgPattern.ScaleType = Enum.ScaleType.Tile
    bgPattern.TileSize = UDim2.new(0, 60, 0, 60)
    bgPattern.Size = UDim2.new(2.5, 0, 2.5, 0)
    bgPattern.Position = UDim2.new(-0.75, 0, -0.75, 0)
    bgPattern.ImageTransparency = 0.97
    bgPattern.ImageColor3 = theme.primary
    bgPattern.BackgroundTransparency = 1
    bgPattern.ZIndex = 0

    runService.RenderStepped:Connect(function()
        if mainFrame.Visible then
            local center = Vector2.new(mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X / 2, mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y / 2)
            local offset = Vector2.new(mouse.X - center.X, mouse.Y - center.Y)
            bgPattern.Position = UDim2.new(-0.75 - offset.X * 0.0003, 0, -0.75 - offset.Y * 0.0003, 0)
        end
    end)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = theme.backgroundSecondary
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

    local headerGradient = Instance.new("UIGradient", header)
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.gradientPrimary),
        ColorSequenceKeypoint.new(0.25, theme.primary),
        ColorSequenceKeypoint.new(0.5, theme.primaryGlow),
        ColorSequenceKeypoint.new(0.75, theme.secondary),
        ColorSequenceKeypoint.new(1, theme.gradientSecondary)
    })
    headerGradient.Rotation = 90

    local headerDivider = Instance.new("Frame", mainFrame)
    headerDivider.Size = UDim2.new(1, 0, 0, 4)
    headerDivider.Position = UDim2.new(0, 0, 0, 50)
    headerDivider.BackgroundColor3 = theme.primary
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 3

    local dividerGlow = Instance.new("UIGradient", headerDivider)
    dividerGlow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.gradientPrimary),
        ColorSequenceKeypoint.new(0.2, theme.primary),
        ColorSequenceKeypoint.new(0.5, theme.primaryGlow),
        ColorSequenceKeypoint.new(0.8, theme.primary),
        ColorSequenceKeypoint.new(1, theme.gradientPrimary)
    })

    local logo = Instance.new("ImageLabel", header)
    logo.Image = "rbxassetid://3921711226"
    logo.Size = UDim2.new(0, 30, 0, 30)
    logo.Position = UDim2.new(0, 15, 0.5, -15)
    logo.ImageColor3 = theme.text
    logo.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", header)
    title.Text = "Crimson Hub"
    title.Font = Enum.Font.Michroma
    title.TextSize = 22
    title.TextColor3 = theme.text
    title.Position = UDim2.new(0, 55, 0, 0)
    title.Size = UDim2.new(0, 250, 1, 0)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeButton = Instance.new("TextButton", header)
    closeButton.Size = UDim2.new(0, 28, 0, 28) 
    closeButton.Position = UDim2.new(1, -38, 0.5, -14)
    closeButton.Text = "✕" 
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.TextColor3 = Color3.new(1, 1, 1) 
    closeButton.BackgroundColor3 = theme.error 
    closeButton.ZIndex = 3
    Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

    local closeButtonGradient = Instance.new("UIGradient", closeButton)
    closeButtonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.error),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 40)) 
    })
    closeButtonGradient.Rotation = 45

    local closeButtonStroke = Instance.new("UIStroke", closeButton)
    closeButtonStroke.Color = Color3.fromRGB(200, 30, 50)
    closeButtonStroke.Thickness = 1
    closeButtonStroke.Transparency = 0.3

    closeButton.MouseEnter:Connect(function()
        tweenService:Create(closeButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(180, 20, 40),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    closeButton.MouseLeave:Connect(function()
        tweenService:Create(closeButton, TweenInfo.new(0.2), {
            BackgroundColor3 = theme.error,
            TextColor3 = Color3.new(1, 1, 1)
        }):Play()
    end)

    local sidebar = Instance.new("Frame", mainFrame)
    sidebar.Size = UDim2.new(0, 180, 1, -50)
    sidebar.Position = UDim2.new(0, 0, 0, 50)
    sidebar.BackgroundColor3 = theme.backgroundSecondary
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

    local sidebarGradient = Instance.new("UIGradient", sidebar)
    sidebarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.backgroundSecondary),
        ColorSequenceKeypoint.new(0.3, theme.accent),
        ColorSequenceKeypoint.new(0.7, theme.gradientAccent),
        ColorSequenceKeypoint.new(1, theme.backgroundSecondary)
    })
    sidebarGradient.Rotation = 180

    local sidebarLayout = Instance.new("UIListLayout", sidebar)
    sidebarLayout.Padding = UDim.new(0, 12)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local welcomeMessage = Instance.new("TextLabel", sidebar)
    welcomeMessage.Size = UDim2.new(1, -20, 0, 60)
    welcomeMessage.Text = "Welcome,\n" .. localPlayer.DisplayName
    welcomeMessage.Font = Enum.Font.Michroma
    welcomeMessage.TextSize = 16
    welcomeMessage.TextColor3 = theme.text 
    welcomeMessage.TextWrapped = true
    welcomeMessage.BackgroundTransparency = 1
    welcomeMessage.LayoutOrder = -1

    local contentContainer = Instance.new("Frame", mainFrame)
    contentContainer.Size = UDim2.new(1, -180, 1, -50)
    contentContainer.Position = UDim2.new(0, 180, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = 1

    local function selectTab(tab)
        playSound("click")
        for _, otherTab in pairs(tabs) do
            local ind = otherTab:FindFirstChild("Indicator")
            if ind then
                tweenService:Create(ind, TweenInfo.new(0.3), { Size = UDim2.new(0, 4, 1, 0), BackgroundTransparency = 1 }):Play()
            end
            tweenService:Create(otherTab, TweenInfo.new(0.3), { TextColor3 = theme.text, BackgroundColor3 = theme.accent }):Play()
        end
        for _, page in pairs(pages) do
            page.Visible = false
        end
        local myInd = tab:FindFirstChild("Indicator")
        if myInd then
            tweenService:Create(myInd, TweenInfo.new(0.3), { Size = UDim2.new(0, 6, 1, 0), BackgroundTransparency = 0 }):Play()
        end
        tweenService:Create(tab, TweenInfo.new(0.3), { TextColor3 = theme.text, BackgroundColor3 = theme.accentLight }):Play()
        pages[tab.Name].Visible = true
    end

    local function createTab(name)
        local tab = Instance.new("TextButton", sidebar)
        tab.Name = name
        tab.Size = UDim2.new(1, -20, 0, 50)
        tab.BackgroundColor3 = theme.accent
        tab.Text = name
        tab.Font = Enum.Font.Michroma
        tab.TextSize = 17
        tab.TextColor3 = theme.text 
        tab.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 10)

        local tabGradient = Instance.new("UIGradient", tab)
        tabGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.accent),
            ColorSequenceKeypoint.new(0.5, theme.accentLight),
            ColorSequenceKeypoint.new(1, theme.gradientAccent)
        })
        tabGradient.Rotation = 45

        local indicator = Instance.new("Frame", tab)
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 4, 1, 0)
        indicator.BackgroundColor3 = theme.primary
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = 1
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 10)

        local indicatorGradient = Instance.new("UIGradient", indicator)
        indicatorGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.primary),
            ColorSequenceKeypoint.new(1, theme.primaryGlow)
        })
        indicatorGradient.Rotation = 90

        tab.MouseEnter:Connect(function() 
            if pages[name] and not pages[name].Visible then
                tweenService:Create(tab, TweenInfo.new(0.2), {BackgroundColor3 = theme.accentLight}):Play() 
            end
        end)
        tab.MouseLeave:Connect(function() 
            if pages[name] and not pages[name].Visible then
                tweenService:Create(tab, TweenInfo.new(0.2), {BackgroundColor3 = theme.accent}):Play() 
            end
        end)
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
        page.ScrollBarThickness = 8
        page.Visible = false

        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        pages[name] = page
        return page
    end

    local scriptsPage = createPage("Scripts")
    local scriptsLayout = Instance.new("UIListLayout", scriptsPage)
    scriptsLayout.Padding = UDim.new(0, 18)
    scriptsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scriptsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left 

    local universalPage = createPage("Universal")
    local universalLayout = Instance.new("UIListLayout", universalPage)
    universalLayout.Padding = UDim.new(0, 18)
    universalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    universalLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local settingsPage = createPage("Settings")
    local settingsLayout = Instance.new("UIListLayout", settingsPage)
    settingsLayout.Padding = UDim.new(0, 12)
    settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local infoPage = createPage("Info")
    local infoLabel = Instance.new("TextLabel", infoPage)
    infoLabel.Size = UDim2.new(1, -50, 0, 0)
    infoLabel.AutomaticSize = Enum.AutomaticSize.Y
    infoLabel.Position = UDim2.new(0, 25, 0, 25)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Text = "Crimson Hub\n\nThe Latest Script Hub Built for Powerful Executors.\nBy Kyr2o !"
    infoLabel.TextColor3 = theme.text
    infoLabel.TextSize = 18
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = true

    createTab("Scripts")
    createTab("Universal")
    createTab("Settings")
    createTab("Info")

    local function createScriptButton(parent, name, callback)
        local buttonData = {enabled = false}

        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(0, 220, 0, 60)
        button.BackgroundColor3 = theme.accent
        button.Text = ""
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)

        local buttonGradient = Instance.new("UIGradient", button)
        buttonGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.accent),
            ColorSequenceKeypoint.new(0.5, theme.accentLight),
            ColorSequenceKeypoint.new(1, theme.gradientAccent)
        })
        buttonGradient.Rotation = 45

        local buttonStroke = Instance.new("UIStroke", button)
        buttonStroke.Color = theme.accentLight
        buttonStroke.Thickness = 2
        buttonStroke.Transparency = 0.5

        local label = Instance.new("TextLabel", button)
        label.Size = UDim2.new(1, -80, 1, 0)
        label.Position = UDim2.new(0, 20, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = theme.text
        label.Text = name
        label.Font = Enum.Font.Michroma
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left

        local toggle = Instance.new("Frame", button)
        toggle.Size = UDim2.new(0, 60, 0, 30)
        toggle.Position = UDim2.new(1, -75, 0.5, -15)
        toggle.BackgroundColor3 = theme.background
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

        local toggleGradient = Instance.new("UIGradient", toggle)
        toggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.background),
            ColorSequenceKeypoint.new(0.5, theme.backgroundSecondary),
            ColorSequenceKeypoint.new(1, theme.gradientAccent)
        })

        local toggleStroke = Instance.new("UIStroke", toggle)
        toggleStroke.Color = theme.accent
        toggleStroke.Thickness = 2

        local toggleKnob = Instance.new("Frame", toggle)
        toggleKnob.Size = UDim2.new(0, 22, 0, 22) 
        toggleKnob.Position = UDim2.new(0, 4, 0.5, -11)
        toggleKnob.BackgroundColor3 = theme.primary
        Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)

        local knobGradient = Instance.new("UIGradient", toggleKnob)
        knobGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.gradientPrimary),
            ColorSequenceKeypoint.new(0.5, theme.primary),
            ColorSequenceKeypoint.new(1, theme.primaryGlow)
        })
        knobGradient.Rotation = 45

        local knobStroke = Instance.new("UIStroke", toggleKnob)
        knobStroke.Color = theme.text
        knobStroke.Thickness = 1
        knobStroke.Transparency = 0.8

        local function updateToggle(manual)
            buttonData.enabled = not buttonData.enabled
            playSound(buttonData.enabled and "toggleOn" or "toggleOff")

            local pos = buttonData.enabled and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 4, 0.5, -11)
            local color = buttonData.enabled and theme.success or theme.primary
            local toggleBgColor = buttonData.enabled and theme.accentLight or theme.background

            tweenService:Create(toggleKnob, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos, BackgroundColor3 = color}):Play()
            tweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = toggleBgColor}):Play()

            if manual then pcall(callback, buttonData.enabled) end
        end

        button.MouseButton1Click:Connect(function() updateToggle(true) end)
        button.MouseEnter:Connect(function() 
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = theme.accentLight}):Play() 
            tweenService:Create(buttonStroke, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
        end)
        button.MouseLeave:Connect(function() 
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = theme.accent}):Play() 
            tweenService:Create(buttonStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        return button
    end

    local function createActionButton(parent, name, callback)
        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(0, 220, 0, 60)
        button.BackgroundColor3 = theme.accent 
        button.Text = name
        button.Font = Enum.Font.Michroma
        button.TextSize = 16
        button.TextColor3 = theme.text 
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)

        local buttonGradient = Instance.new("UIGradient", button)
        buttonGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.accent),
            ColorSequenceKeypoint.new(0.5, theme.accentLight),
            ColorSequenceKeypoint.new(1, theme.gradientAccent)
        })
        buttonGradient.Rotation = 45

        local buttonStroke = Instance.new("UIStroke", button)
        buttonStroke.Color = theme.accentLight
        buttonStroke.Thickness = 2
        buttonStroke.Transparency = 0.5

        button.MouseButton1Click:Connect(function()
            playSound("click")
            pcall(callback)
        end)
        button.MouseEnter:Connect(function() 
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = theme.accentLight}):Play()
            tweenService:Create(buttonStroke, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
        end)
        button.MouseLeave:Connect(function() 
            tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = theme.accent}):Play() 
            tweenService:Create(buttonStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        return button
    end

    do

        local rebindButton = Instance.new("TextButton", settingsPage)
        rebindButton.Size = UDim2.new(0, 240, 0, 50)
        rebindButton.BackgroundColor3 = theme.accent
        rebindButton.Text = "Toggle Key: " .. toggleKey.Name
        rebindButton.Font = Enum.Font.Michroma
        rebindButton.TextSize = 16
        rebindButton.TextColor3 = theme.text
        Instance.new("UICorner", rebindButton).CornerRadius = UDim.new(0, 10)

        local rebindGradient = Instance.new("UIGradient", rebindButton)
        rebindGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.accent),
            ColorSequenceKeypoint.new(0.5, theme.accentLight),
            ColorSequenceKeypoint.new(1, theme.gradientAccent)
        })
        rebindGradient.Rotation = 45

        rebindButton.MouseButton1Click:Connect(function()
            rebindButton.Text = "Press a key..."
            local conn  
            conn = userInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
                    toggleKey = input.KeyCode
                    rebindButton.Text = "Toggle Key: " .. toggleKey.Name
                    sendNotification("Success", "GUI toggle key set to " .. toggleKey.Name, 2, "success")
                    conn:Disconnect()
                end
            end)
        end)

        local function createSettingInput(parent, name, property, defaultValue)
            local container = Instance.new("Frame", parent)
            container.Size = UDim2.new(0, 350, 0, 50)
            container.BackgroundTransparency = 1

            local label = Instance.new("TextLabel", container)
            label.Size = UDim2.new(0.5, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Michroma
            label.Text = name
            label.TextColor3 = theme.text
            label.TextSize = 16
            label.TextXAlignment = Enum.TextXAlignment.Left

            local input = Instance.new("TextBox", container)
            input.Size = UDim2.new(0.4, 0, 1, -12)
            input.Position = UDim2.new(0.6, 0, 0.5, 0)
            input.AnchorPoint = Vector2.new(0, 0.5)
            input.BackgroundColor3 = theme.backgroundSecondary
            input.TextColor3 = Color3.new(1, 1, 1) 
            input.Font = Enum.Font.SourceSans
            input.TextSize = 16
            input.Text = tostring(G.CRIMSON_SETTINGS[property] or defaultValue)
            Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)

            local inputStroke = Instance.new("UIStroke", input)
            inputStroke.Color = theme.accent
            inputStroke.Thickness = 2

            local inputGradient = Instance.new("UIGradient", input)
            inputGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.backgroundSecondary),
                ColorSequenceKeypoint.new(1, theme.gradientAccent)
            })
            inputGradient.Rotation = 45

            input.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local num = tonumber(input.Text)
                    if num then
                        G.CRIMSON_SETTINGS[property] = num
                        local char = localPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid[property] = num
                        end
                    else
                        input.Text = tostring(G.CRIMSON_SETTINGS[property])
                    end
                end
            end)
            return container
        end

        createSettingInput(universalPage, "WalkSpeed", "WalkSpeed", 16)
        createSettingInput(universalPage, "JumpPower", "JumpPower", 50)

        local function toggleESP(state)
            G.CRIMSON_ESP_DATA = G.CRIMSON_ESP_DATA or { connections = {}, active = false, highlights = {} }
            G.CRIMSON_ESP_DATA.active = state
            if not state then
                for player, data in pairs(G.CRIMSON_ESP_DATA.highlights) do
                    if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
                    if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
                end
                G.CRIMSON_ESP_DATA.highlights = {}
                for _, conn in ipairs(G.CRIMSON_ESP_DATA.connections) do conn:Disconnect() end
                G.CRIMSON_ESP_DATA.connections = {}
                return
            end

            local function setupESP(player)
                if player == localPlayer then return end
                local function apply(char)
                    if G.CRIMSON_ESP_DATA.highlights[player] and G.CRIMSON_ESP_DATA.highlights[player].highlight.Parent then return end
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.new(1, 1, 1)
                    highlight.OutlineColor = Color3.new(0, 0, 0)
                    highlight.Parent = char

                    local billboard = Instance.new("BillboardGui")
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    local textLabel = Instance.new("TextLabel", billboard)
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Text = player.Name
                    textLabel.TextColor3 = Color3.new(1, 1, 1)
                    textLabel.TextSize = 14
                    billboard.Parent = char:WaitForChild("Head")

                    G.CRIMSON_ESP_DATA.highlights[player] = { highlight = highlight, billboard = billboard }
                end
                if player.Character then pcall(apply, player.Character) end
                player.CharacterAdded:Connect(apply)
            end

            for _, player in ipairs(players:GetPlayers()) do setupESP(player) end
            table.insert(G.CRIMSON_ESP_DATA.connections, players.PlayerAdded:Connect(setupESP))
        end
        createScriptButton(universalPage, "ESP", toggleESP)

        localPlayer.CharacterAdded:Connect(function(char)
            local humanoid = char:WaitForChild("Humanoid")
            humanoid.WalkSpeed = G.CRIMSON_SETTINGS.WalkSpeed
            humanoid.JumpPower = G.CRIMSON_SETTINGS.JumpPower
        end)
    end

    function ui:LoadScripts(scriptLoader)
        for _, child in ipairs(scriptsPage:GetChildren()) do
            if not child:IsA("UILayout") then child:Destroy() end
        end

        scriptsPage.CanvasSize = UDim2.new(0, 0, 0, 0) 

        local scripts = scriptLoader()
        if not scripts then return end

        local spec = CATEGORY_SPEC[game.PlaceId]
        if spec then

            if scriptsPage:FindFirstChildOfClass("UIGridLayout") then
                scriptsPage:FindFirstChildOfClass("UIGridLayout"):Destroy()
            end

            local vertList = scriptsPage:FindFirstChildOfClass("UIListLayout")
            if not vertList then
                vertList = Instance.new("UIListLayout", scriptsPage)
                vertList.Padding = UDim.new(0, 18) 
                vertList.SortOrder = Enum.SortOrder.LayoutOrder
                vertList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            end

            local used = {}
            for _, cat in ipairs(spec) do
                if cat.modules ~= "REMAINDER" then

                    addCategoryRow(scriptsPage, cat.title)

                    local row = Instance.new("Frame", scriptsPage)
                    row.Size = UDim2.new(1, 0, 0, 60) 
                    row.BackgroundTransparency = 1
                    row.AutomaticSize = Enum.AutomaticSize.Y

                    local content = Instance.new("Frame", row)
                    content.Name = "RowContent"
                    content.BackgroundTransparency = 1
                    content.Position = UDim2.new(0, 180, 0, 12)  
                    content.Size = UDim2.new(1, -210, 0, 0)    
                    content.AutomaticSize = Enum.AutomaticSize.Y

                    local grid = Instance.new("UIGridLayout", content)
                    grid.CellSize = UDim2.new(0, 220, 0, 120)
                    grid.CellPadding = UDim2.new(0, 20, 0, 20)
                    grid.SortOrder = Enum.SortOrder.LayoutOrder
                    grid.FillDirection = Enum.FillDirection.Horizontal
                    grid.HorizontalAlignment = Enum.HorizontalAlignment.Left

                    local function resizeRow()
                        row.Size = UDim2.new(1, 0, 0, math.max(60, grid.AbsoluteContentSize.Y + 25))
                    end
                    resizeRow()
                    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeRow)

                    for _, modName in ipairs(cat.modules) do
                        local fn = scripts[modName]
                        if fn then
                            used[modName] = true
                            if modName == "Break Gun" then
                                local autoBreakGunToggle = createAutoBreakGun()
                                createScriptButton(content, modName, autoBreakGunToggle)
                            elseif modName == "KillAll" then
                                createActionButton(content, modName, function() fn(true) end)
                            elseif modName == "Auto Shoot" then
                                grid.CellSize = UDim2.new(0, 220, 0, 170)
                                local parentContainer = row:FindFirstChild("RowContent") or row
                                local autoContainer = Instance.new("Frame", parentContainer)
                                autoContainer.Size = UDim2.new(0, 220, 0, 0)
                                autoContainer.AutomaticSize = Enum.AutomaticSize.Y
                                autoContainer.BackgroundTransparency = 1
                                local vList = Instance.new("UIListLayout", autoContainer)
                                vList.Padding = UDim.new(0, 8)
                                vList.SortOrder = Enum.SortOrder.LayoutOrder
                                local autoBtn = createScriptButton(autoContainer, "Auto Shoot", function(state)
                                    local G = (getgenv and getgenv()) or _G
                                    G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.14 }
                                    G.CRIMSON_AUTO_SHOOT.enabled = state
                                    fn(state) 
                                end)
                                autoBtn.LayoutOrder = 1
                                autoBtn.Size = UDim2.new(1, 0, 0, 60)
                                local predCard = Instance.new("Frame", autoContainer)
                                predCard.Size = UDim2.new(1, 0, 0, 50)
                                predCard.BackgroundColor3 = theme.accent
                                Instance.new("UICorner", predCard).CornerRadius = UDim.new(0, 8)
                                predCard.LayoutOrder = 2

                                local predCardGradient = Instance.new("UIGradient", predCard)
                                predCardGradient.Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, theme.accent),
                                    ColorSequenceKeypoint.new(1, theme.gradientAccent)
                                })
                                predCardGradient.Rotation = 45

                                local predLabel = Instance.new("TextLabel", predCard)
                                predLabel.BackgroundTransparency = 1
                                predLabel.Text = "Prediction"
                                predLabel.Font = Enum.Font.Michroma
                                predLabel.TextSize = 15
                                predLabel.TextColor3 = theme.text
                                predLabel.Size = UDim2.new(1, -90, 1, 0)
                                predLabel.TextXAlignment = Enum.TextXAlignment.Left
                                predLabel.Position = UDim2.new(0, 15, 0, 0)
                                local predBox = Instance.new("TextBox", predCard)
                                predBox.Size = UDim2.new(0, 75, 0, 35)
                                predBox.AnchorPoint = Vector2.new(1, 0.5)
                                predBox.Position = UDim2.new(1, -15, 0.5, 0)
                                predBox.BackgroundColor3 = theme.background
                                predBox.Font = Enum.Font.SourceSans
                                predBox.TextSize = 16
                                predBox.TextColor3 = Color3.new(1, 1, 1) 
                                do
                                    local G = (getgenv and getgenv()) or _G
                                    local defaultPred = (G.CRIMSON_AUTO_SHOOT and G.CRIMSON_AUTO_SHOOT.prediction) or 0.15
                                    predBox.Text = tostring(defaultPred)
                                end
                                Instance.new("UICorner", predBox).CornerRadius = UDim.new(0, 8)

                                local predBoxGradient = Instance.new("UIGradient", predBox)
                                predBoxGradient.Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, theme.background),
                                    ColorSequenceKeypoint.new(1, theme.backgroundSecondary)
                                })
                                predBoxGradient.Rotation = 45

                                local last = predBox.Text
                                predBox:GetPropertyChangedSignal("Text"):Connect(function()
                                    if predBox.Text == "" then last = "" return end
                                    if tonumber(predBox.Text) then last = predBox.Text else predBox.Text = last end
                                end)
                                predBox.FocusLost:Connect(function()
                                    local v = tonumber(predBox.Text) or 0
                                    local G = (getgenv and getgenv()) or _G
                                    G.CRIMSON_AUTO_SHOOT = G.CRIMSON_AUTO_SHOOT or { enabled = false, prediction = 0.15 }
                                    G.CRIMSON_AUTO_SHOOT.prediction = v
                                end)

                                local calibrateBtn = createActionButton(autoContainer, "Auto-Calibrate", function()
                                    local G = (getgenv and getgenv()) or _G
                                    if G.CRIMSON_AUTO_SHOOT and G.CRIMSON_AUTO_SHOOT.calibrate then
                                        local ms, pred = G.CRIMSON_AUTO_SHOOT.calibrate()
                                        if pred then
                                            predBox.Text = string.format("%.3f", pred)
                                            G.CRIMSON_AUTO_SHOOT.prediction = pred
                                            sendNotification("Calibrated", string.format("Ping: %dms → Pred: %.3f", ms or 0, pred), 3, "success")
                                        else
                                            sendNotification("Error", "Calibration failed.", 2, "error")
                                        end
                                    else
                                        sendNotification("Error", "Calibration function not found.", 3, "error")
                                    end
                                end)
                                calibrateBtn.Size = UDim2.new(1, 0, 0, 40)
                                calibrateBtn.TextSize = 14
                                calibrateBtn.LayoutOrder = 3
                            elseif modName == "Auto Knife Throw" then
                                createScriptButton(content, modName, function(state)
                                    local G = (getgenv and getgenv()) or _G
                                    G.CRIMSON_AUTO_KNIFE = G.CRIMSON_AUTO_KNIFE or { enabled = false }
                                    
                                    if state then
                                        G.CRIMSON_AUTO_KNIFE.enabled = true
                                        if G.CRIMSON_AUTO_KNIFE.enable then
                                            G.CRIMSON_AUTO_KNIFE.enable()
                                        end
                                    else
                                        G.CRIMSON_AUTO_KNIFE.enabled = false
                                        if G.CRIMSON_AUTO_KNIFE.disable then
                                            G.CRIMSON_AUTO_KNIFE.disable()
                                        end
                                    end
                                    
                                    if state then
                                        fn(true)
                                    end
                                end)
                            else
                                createScriptButton(content, modName, function(state)
                                    if state then fn(true) end
                                end)
                            end
                        end
                    end
                end
            end

            for _, cat in ipairs(spec) do
                if cat.modules == "REMAINDER" then
                    local remainderScripts = {}
                    for name, fn in pairs(scripts) do
                        if not used[name] then
                            table.insert(remainderScripts, {name=name, fn=fn})
                        end
                    end

                    if #remainderScripts > 0 then
                        addCategoryRow(scriptsPage, cat.title)
                        local row = Instance.new("Frame", scriptsPage)
                        row.Size = UDim2.new(1, 0, 0, 60)
                        row.BackgroundTransparency = 1

                        row.AutomaticSize = Enum.AutomaticSize.Y 

                        local content = Instance.new("Frame", row)
                        content.Name = "RowContent"
                        content.BackgroundTransparency = 1
                        content.Position = UDim2.new(0, 180, 0, 12)
                        content.Size = UDim2.new(1, -210, 0, 0)
                        content.AutomaticSize = Enum.AutomaticSize.Y

                        local grid = Instance.new("UIGridLayout", content)
                        grid.CellSize = UDim2.new(0, 220, 0, 120) 
                        grid.CellPadding = UDim2.new(0, 20, 0, 20) 
                        grid.SortOrder = Enum.SortOrder.LayoutOrder
                        grid.FillDirection = Enum.FillDirection.Horizontal
                        grid.HorizontalAlignment = Enum.HorizontalAlignment.Left

                        local function resizeRow()
                            row.Size = UDim2.new(1, 0, 0, math.max(60, grid.AbsoluteContentSize.Y + 25))
                        end
                        resizeRow()
                        grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeRow)

                        for _, scriptData in pairs(remainderScripts) do
                            if scriptData.name == "Break Gun" then

                                local autoBreakGunToggle = createAutoBreakGun()
                                createScriptButton(content, scriptData.name, autoBreakGunToggle)
                            else
                                createScriptButton(content, scriptData.name, scriptData.fn)
                            end
                        end
                    end
                end
            end
        else

            local grid = Instance.new("UIGridLayout", scriptsPage)
            grid.CellSize = UDim2.new(0, 220, 0, 60)
            grid.CellPadding = UDim2.new(0, 18, 0, 18)
            grid.SortOrder = Enum.SortOrder.LayoutOrder
            grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            for name, executeFunc in pairs(scripts) do
                if name == "Break Gun" then

                    local autoBreakGunToggle = createAutoBreakGun()
                    createScriptButton(scriptsPage, name, autoBreakGunToggle)
                elseif name == "KillAll" then
                    createActionButton(scriptsPage, name, function() executeFunc(true) end)
                else
                    createScriptButton(scriptsPage, name, executeFunc)
                end
            end
        end
    end

    function ui:SetVisibility(visible)
        if ui.Visible == visible then return end
        ui.Visible = visible
        mainShadow.Visible = visible

        if visible then
            playSound("open")
            setBlur(true)
            mainFrame.Visible = true
            mainShadow.Visible = true
            local introTween = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            mainFrame.Size = UDim2.new(0, 720, 0, 25)
            mainFrame.Position = UDim2.new(0.5, -360, 0.5, -12)
            mainShadow.Size = UDim2.new(0, 740, 0, 45)
            mainShadow.Position = UDim2.new(0.5, -370, 0.5, -22)
            tweenService:Create(mainFrame, introTween, {Size = UDim2.new(0, 720, 0, 480), Position = UDim2.new(0.5, -360, 0.5, -240)}):Play()
            tweenService:Create(mainShadow, introTween, {Size = UDim2.new(0, 740, 0, 500), Position = UDim2.new(0.5, -370, 0.5, -250)}):Play()
        else
            playSound("close")
            setBlur(false)
            local outroTween = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            tweenService:Create(mainFrame, outroTween, {Size = UDim2.new(0, 720, 0, 0), Position = UDim2.new(0.5, -360, 0.5, 0)}):Play()
            tweenService:Create(mainShadow, outroTween, {Size = UDim2.new(0, 740, 0, 20), Position = UDim2.new(0.5, -370, 0.5, -10)}):Play()
            task.wait(0.5)
            mainFrame.Visible = false
            mainShadow.Visible = false
        end
    end

    closeButton.MouseButton1Click:Connect(function() ui:SetVisibility(false) end)

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
    frame.Size = UDim2.new(0, 450, 0, 300)
    frame.Position = UDim2.new(0.5, -225, 0.5, -150)
    frame.BackgroundColor3 = theme.background
    frame.Draggable = true
    frame.Active = true
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    local frameStroke = Instance.new("UIStroke", frame)
    frameStroke.Color = theme.primary
    frameStroke.Thickness = 3

    local verifyGradient = Instance.new("UIGradient", frame)
    verifyGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.background),
        ColorSequenceKeypoint.new(0.5, theme.backgroundSecondary),
        ColorSequenceKeypoint.new(1, theme.gradientAccent)
    })
    verifyGradient.Rotation = 135

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 70)
    title.BackgroundTransparency = 1
    title.Text = "VERIFICATION"
    title.Font = Enum.Font.Michroma
    title.TextColor3 = theme.text 
    title.TextSize = 32

    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.Position = UDim2.new(0, 0, 0, 70)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Please enter your key to continue"
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextColor3 = theme.textSecondary 
    subtitle.TextSize = 18

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -50, 0, 55)
    input.Position = UDim2.new(0, 25, 0, 115)
    input.BackgroundColor3 = theme.backgroundSecondary
    input.TextColor3 = Color3.new(1, 1, 1) 
    input.PlaceholderText = "Your Key"
    input.PlaceholderColor3 = theme.textSecondary
    input.Font = Enum.Font.SourceSans
    input.TextSize = 18
    input.Parent = frame
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)

    local inputStroke = Instance.new("UIStroke", input)
    inputStroke.Color = theme.accent
    inputStroke.Thickness = 2

    local inputGradient = Instance.new("UIGradient", input)
    inputGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.backgroundSecondary),
        ColorSequenceKeypoint.new(1, theme.gradientAccent)
    })
    inputGradient.Rotation = 45

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(1, -50, 0, 50)
    submit.Position = UDim2.new(0, 25, 0, 185)
    submit.BackgroundColor3 = theme.primary
    submit.Text = "VERIFY"
    submit.Font = Enum.Font.Michroma
    submit.TextColor3 = Color3.fromRGB(40, 40, 40) 
    submit.TextSize = 20
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 10)

    local submitGradient = Instance.new("UIGradient", submit)
    submitGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.gradientPrimary),
        ColorSequenceKeypoint.new(0.5, theme.primary),
        ColorSequenceKeypoint.new(1, theme.primaryGlow)
    })

    local loadingSpinner = Instance.new("ImageLabel", submit)
    loadingSpinner.Image = "rbxassetid://5107930337"
    loadingSpinner.Size = UDim2.new(0, 30, 0, 30)
    loadingSpinner.Position = UDim2.new(0.5, -15, 0.5, -15)
    loadingSpinner.BackgroundTransparency = 1
    loadingSpinner.ImageColor3 = Color3.fromRGB(40, 40, 40) 
    loadingSpinner.Visible = false

    local getLink = Instance.new("TextButton", frame)
    getLink.Size = UDim2.new(1, -50, 0, 45)
    getLink.Position = UDim2.new(0, 25, 0, 248)
    getLink.BackgroundColor3 = theme.accent
    getLink.Text = "GET LINK"
    getLink.Font = Enum.Font.Michroma
    getLink.TextColor3 = theme.text 
    getLink.TextSize = 18
    Instance.new("UICorner", getLink).CornerRadius = UDim.new(0, 10)

    local getLinkStroke = Instance.new("UIStroke", getLink)
    getLinkStroke.Color = theme.accentLight
    getLinkStroke.Thickness = 2

    local getLinkGradient = Instance.new("UIGradient", getLink)
    getLinkGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.accent),
        ColorSequenceKeypoint.new(0.5, theme.accentLight),
        ColorSequenceKeypoint.new(1, theme.gradientAccent)
    })
    getLinkGradient.Rotation = 45

    local LINK_TO_COPY = "[https://workink.net/25bz/0qrqef0f](https://workink.net/25bz/0qrqef0f)"

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
                local outro = tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)})

                outro:Play()
                outro.Completed:Wait()
                frame:Destroy()

                onSuccess()
            else
                playSound("error")
                sendNotification("Failed", "Invalid key provided.", 1, "error")
                local originalPos = frame.Position
                local shakeInfo = TweenInfo.new(0.08)
                for i = 1, 4 do
                    tweenService:Create(frame, shakeInfo, {Position = originalPos + UDim2.fromOffset(12, 0)}):Play()
                    task.wait(0.08)
                    tweenService:Create(frame, shakeInfo, {Position = originalPos - UDim2.fromOffset(12, 0)}):Play()
                    task.wait(0.08)
                end
                tweenService:Create(frame, shakeInfo, {Position = originalPos}):Play()
            end
        end)
    end)

    setBlur(true)
end

local function loadGameScripts()
    local gameId = tostring(game.PlaceId)
    if gameId == "0" then sendNotification("Studio", "Cannot load scripts in Studio.", 5, "warning"); return {} end

    -- Register built-in scripts
    local builtInScripts = {}
    if gameId == tostring(MM2_PLACEID) then
        builtInScripts["Auto Shoot"] = createAutoShoot()
    end

    local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
    local ok, result = httpGet(apiUrl)
    if not ok then 
        sendNotification("GitHub Error", "Could not fetch scripts.", 4, "error")
        return builtInScripts 
    end

    local success, decoded = pcall(function() return httpService:JSONDecode(result) end)
    if not success or type(decoded) ~= "table" or decoded.message then
        sendNotification("Notice", "No additional scripts found for this game.", 4, "info")
        return builtInScripts
    end

    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptName = (scriptInfo.name or ""):gsub("%.lua$", "")
            
            -- Prevent overwriting the built-in auto-shoot
            if scriptName == "Auto Shoot" and builtInScripts["Auto Shoot"] then
                goto continue
            end

            local url = scriptInfo.download_url

            builtInScripts[scriptName] = function(state)
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
            ::continue::
        end
    end
    return builtInScripts
end

createVerificationUI(function()
    local hub = mainUI:Create()
    hub:LoadScripts(loadGameScripts)
    hub:SetVisibility(true)
end)
