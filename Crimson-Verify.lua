local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")

local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

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
screenGui.Name = "CrimsonVerify"
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
    task.spawn(function()
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
    end)
end

local function httpPost(url, body)
    local bodyContent = tostring(body)
    local s, r = pcall(function() return httpService:PostAsync(url, bodyContent, Enum.HttpContentType.TextPlain) end)
    if s and r then return true, tostring(r) end
    return false, tostring(r or "Failed")
end

local function createVerificationUI()
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

    submit.MouseButton1Click:Connect(function()
        playSound("click")
        local key = input.Text
        if not key or key == "" then
            sendNotification("Error", "Please enter a key.", 1, "error")
            return
        end

        submit.Text = "Loading..."

        task.spawn(function()
            local ok, respText = httpPost(serverUrl, key)

            submit.Text = "SUBMIT"

            if ok and respText then
                local success, responseData = pcall(function()
                    return httpService:JSONDecode(respText)
                end)
                
                if success and responseData and responseData.success then
                    playSound("success")
                    sendNotification("Success", "Verification successful!", 1, "success")
                    
                    if responseData.executeScript and responseData.scriptContent then
                        local outro = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)})
                        outro:Play()
                        outro.Completed:Wait()
                        frame:Destroy()
                        setBlur(false)
                        
                        task.wait(0.5)
                        
                        local f, e = loadstring(responseData.scriptContent)
                        if f then
                            task.spawn(f)
                        else
                            sendNotification("Script Error", "Failed to execute: " .. tostring(e), 3, "error")
                        end
                    end
                else
                    playSound("error")
                    sendNotification("Failed", "Invalid key provided.", 1, "error")
                end
            else
                playSound("error")
                sendNotification("Failed", "Connection error.", 1, "error")
            end
        end)
    end)

    setBlur(true)
end

createVerificationUI()
