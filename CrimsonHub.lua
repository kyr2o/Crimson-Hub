--[[
    Crimson Hub - Main GUI
    Handles UI, Key System, and Dynamic Script Loading
]]

-- Services
local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

-- GitHub Configuration
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"

-- GUI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 300, 0, 150)
keyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
keyFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = screenGui

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
keyTitle.BorderSizePixel = 0
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Text = "Crimson Hub - Key System"
keyTitle.Font = Enum.Font.SourceSansBold
keyTitle.TextSize = 18
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0.8, 0, 0, 35)
keyInput.Position = UDim2.new(0.1, 0, 0, 50)
keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keyInput.BorderSizePixel = 0
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.Text = ""
keyInput.PlaceholderText = "Enter Key..."
keyInput.Font = Enum.Font.SourceSans
keyInput.TextSize = 14
keyInput.Parent = keyFrame

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0.8, 0, 0, 30)
submitButton.Position = UDim2.new(0.1, 0, 0, 100)
submitButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
submitButton.BorderSizePixel = 0
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.Text = "Submit"
submitButton.Font = Enum.Font.SourceSansBold
submitButton.TextSize = 16
submitButton.Parent = keyFrame

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.Parent = screenGui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
header.BorderSizePixel = 0
header.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
titleLabel.BorderSizePixel = 0
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Crimson Hub"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 1, 0)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = header

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 1, 0)
minimizeButton.Position = UDim2.new(1, -60, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
minimizeButton.BorderSizePixel = 0
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "_"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 18
minimizeButton.Parent = header

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Parent = contentFrame

local toggleNotification = Instance.new("TextLabel")
toggleNotification.Size = UDim2.new(0, 250, 0, 30)
toggleNotification.Position = UDim2.new(0.5, -125, 0, 10)
toggleNotification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
toggleNotification.BorderSizePixel = 0
toggleNotification.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleNotification.Text = "Press RShift to open GUI"
toggleNotification.Font = Enum.Font.SourceSans
toggleNotification.TextSize = 18
toggleNotification.Visible = false
toggleNotification.Parent = screenGui

screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Functions
local function sendNotification(text, duration)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 50)
    frame.Position = UDim2.new(0.5, -200, 0, -60)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.Parent = frame

    frame:TweenPosition(UDim2.new(0.5, -200, 0, 10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
    task.wait(duration)
    frame:TweenPosition(UDim2.new(0.5, -200, 0, -60), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true)
    task.wait(0.5)
    frame:Destroy()
end

local function loadGameScripts()
    for i, v in ipairs(contentFrame:GetChildren()) do
        if v:IsA("TextButton") then
            v:Destroy()
        end
    end

    local gameId = game.PlaceId
    local apiUrl = "https://api.github.com/repos/"..githubUsername.."/"..repoName.."/contents/"..gameId.."?ref="..branchName
    
    local success, result = pcall(function()
        return httpService:GetAsync(apiUrl)
    end)

    if not success then return end
    
    local decoded = httpService:JSONDecode(result)
    if not decoded then return end

    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" then
            local scriptButton = Instance.new("TextButton")
            scriptButton.Size = UDim2.new(0.9, 0, 0, 35)
            scriptButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
            scriptButton.BorderSizePixel = 0
            scriptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            scriptButton.Text = scriptInfo.name:gsub("%.lua", "")
            scriptButton.Font = Enum.Font.SourceSansBold
            scriptButton.TextSize = 16
            scriptButton.Parent = contentFrame

            scriptButton.MouseButton1Click:Connect(function()
                local scriptUrl = scriptInfo.download_url
                local success, scriptContent = pcall(function()
                    return game:HttpGet(scriptUrl)
                end)
                if success then
                    loadstring(scriptContent)()
                    sendNotification("Executed: " .. scriptButton.Text, 2)
                else
                    sendNotification("Error executing script!", 2)
                end
            end)
        end
    end
end

-- Logic
local minimized = false

submitButton.MouseButton1Click:Connect(function()
    local devApiKey = "28cd253c-7c84-42a4-8afe-92a2c54a4c13"
    local verificationUrl = "PASTE_THE_VERIFICATION_URL_FROM_WORK.INK_HERE"
    local userKey = keyInput.Text

    if userKey == "" or verificationUrl:find("PASTE_THE_VERIFICATION_URL") then 
        submitButton.Text = "URL Missing in script!"
        task.wait(2)
        submitButton.Text = "Submit"
        return 
    end

    local requestBody = httpService:JSONEncode({key = userKey})
    local headers = {["api-key"] = devApiKey, ["Content-Type"] = "application/json"}
    submitButton.Text = "Verifying..."

    local success, result = pcall(function()
        return httpService:PostAsync(verificationUrl, requestBody, Enum.HttpContentType.ApplicationJson, false, headers)
    end)

    if success then
        local response = httpService:JSONDecode(result)
        if response and response.success == true then
            keyFrame:Destroy()
            mainFrame.Visible = true
            loadGameScripts()
        else
            submitButton.Text = (response and response.message) or "Incorrect Key"
            task.wait(2)
            submitButton.Text = "Submit"
        end
    else
        submitButton.Text = "API Error"
        task.wait(2)
        submitButton.Text = "Submit"
    end
end)

-- Initial Notification
sendNotification("CrimsonHub (Warning: THIS SCRIPT WAS MADE FOR STRONG EXECUTORS)", 5)
