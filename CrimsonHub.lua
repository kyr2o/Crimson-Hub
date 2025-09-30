local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local function createMainUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "MyUI"
    screen.ResetOnSpawn = false
    screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 520, 0, 360)
    main.Position = UDim2.new(0.5, -260, 0.5, -180)
    main.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    main.BorderSizePixel = 0
    main.Parent = screen

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 12)
    layout.Parent = main

    return screen, main
end

local function addModuleButton(parent, labelText, isToggleable, onExecute)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 160, 0, 80)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = container

    local onHoldTag = Instance.new("TextLabel")
    onHoldTag.BackgroundTransparency = 1
    onHoldTag.Size = UDim2.new(1, -8, 0, 18)
    onHoldTag.Position = UDim2.new(0, 4, 1, -20)
    onHoldTag.TextXAlignment = Enum.TextXAlignment.Right
    onHoldTag.TextYAlignment = Enum.TextYAlignment.Bottom
    onHoldTag.Text = "(On Hold)"
    onHoldTag.TextColor3 = Color3.fromRGB(200, 200, 200)
    onHoldTag.TextSize = 12
    onHoldTag.Font = Enum.Font.Gotham
    onHoldTag.Visible = false
    onHoldTag.Parent = container

    local state = "off"
    local prevBeforeHold = nil

    local function setVisual()
        if state == "off" then
            container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            onHoldTag.Visible = false
        elseif state == "on" then
            container.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
            onHoldTag.Visible = false
        elseif state == "hold" then
            container.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
            onHoldTag.Visible = true
        end
    end
    setVisual()

    btn.MouseButton1Click:Connect(function()
        if not isToggleable then
            if typeof(onExecute) == "function" then onExecute() end
            return
        end
        if state == "hold" then return end
        state = (state == "on") and "off" or "on"
        setVisual()
        if typeof(onExecute) == "function" then onExecute(state) end
    end)

    btn.MouseButton2Click:Connect(function()
        if not isToggleable then return end
        if state ~= "hold" then
            prevBeforeHold = state
            state = "hold"
        else
            state = prevBeforeHold or "off"
            prevBeforeHold = nil
        end
        setVisual()
    end)

    return container
end

local function playIntro(nextStep)
    local screen = Instance.new("ScreenGui")
    screen.Name = "Intro"
    screen.ResetOnSpawn = false
    screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local cover = Instance.new("Frame")
    cover.Size = UDim2.new(1, 0, 1, 0)
    cover.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    cover.BackgroundTransparency = 1
    cover.Parent = screen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0.5, -30)
    title.BackgroundTransparency = 1
    title.Text = "Welcome"
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.TextSize = 38
    title.Font = Enum.Font.GothamBlack
    title.TextTransparency = 1
    title.Parent = cover

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    TweenService:Create(cover, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2}):Play()
    TweenService:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
    TweenService:Create(blur, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 12}):Play()

    task.wait(1.2)

    TweenService:Create(cover, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
    TweenService:Create(title, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
    TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = 0}):Play()

    task.wait(0.55)
    blur:Destroy()
    screen:Destroy()

    if typeof(nextStep) == "function" then nextStep() end
end

local function onKeyFinished()
    playIntro(function()
        local screen, main = createMainUI()
        addModuleButton(main, "Auto-Farm", true, function(state) end)
        addModuleButton(main, "Collect Daily", false, function() end)
    end)
end
