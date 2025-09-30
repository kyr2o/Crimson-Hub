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

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 320, 0, 160)
keyFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
keyFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
keyFrame.BorderSizePixel = 0
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
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
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
mainFrameStroke.Color = Color3.fromRGB(139, 0, 0)
mainFrameStroke.Thickness = 2
mainFrameStroke.Parent = mainFrame
local mainFrameGradient = Instance.new("UIGradient")
mainFrameGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 42, 48)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 32, 38)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 42, 48))
})
mainFrameGradient.Rotation = 45
mainFrameGradient.Parent = mainFrame
task.spawn(function()
	while mainFrame.Parent do
		tweenService:Create(mainFrameGradient, TweenInfo.new(5, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 1)}):Play()
		task.wait(5)
		mainFrameGradient.Offset = Vector2.new(-1, -1)
		tweenService:Create(mainFrameGradient, TweenInfo.new(5, Enum.EasingStyle.Linear), {Offset = Vector2.new(0, 0)}):Play()
		task.wait(5)
	end
end)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
header.BorderSizePixel = 0
header.Parent = mainFrame
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new(Color3.fromRGB(180, 0, 0), Color3.fromRGB(120, 0, 0))
headerGradient.Rotation = 90
headerGradient.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Crimson Hub"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
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
contentList.Visible = false
contentList.Parent = contentFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Parent = contentList

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

local scriptStates = {}
local isBindingKey = false

local minimized = false
local isVerifying = false

-- 🔧 Fixed tween section here
submitButton.MouseButton1Click:Connect(function()
	if isVerifying then return end
	local userInput = tostring(keyInput.Text or "")
	if userInput:match("^%s*$") then
		return
	end

	isVerifying = true
	submitButton.Text = "Correct"
	task.wait(0.5)

	tweenService:Create(keyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	for _, v in ipairs(keyFrame:GetChildren()) do
		if v:IsA("GuiObject") then
			local props = {BackgroundTransparency = 1}
			if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
				props.TextTransparency = 1
			end
			if v:IsA("ImageLabel") or v:IsA("ImageButton") then
				props.ImageTransparency = 1
			end
			tweenService:Create(v, TweenInfo.new(0.3), props):Play()
		end
	end

	task.wait(0.3)
	keyFrame:Destroy()

	mainFrame.Visible = true
	tweenService:Create(mainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

	local introFrame = Instance.new("Frame")
	introFrame.Size = UDim2.new(1, 0, 0, 50)
	introFrame.Position = UDim2.new(0, 0, 0.5, -25)
	introFrame.BackgroundTransparency = 1
	introFrame.Parent = contentFrame
	local pfp = Instance.new("ImageLabel")
	pfp.Size = UDim2.new(0, 40, 0, 40)
	pfp.Position = UDim2.new(0.5, -100, 0.5, -20)
	pfp.BackgroundTransparency = 1
	pfp.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..localPlayer.UserId.."&width=420&height=420&format=png"
	pfp.ImageTransparency = 1
	pfp.Parent = introFrame
	local pfpCorner = Instance.new("UICorner")
	pfpCorner.CornerRadius = UDim.new(1,0)
	pfpCorner.Parent = pfp
	local welcomeLabel = Instance.new("TextLabel")
	welcomeLabel.Size = UDim2.new(1, -50, 1, 0)
	welcomeLabel.Position = UDim2.new(0.5, -80, 0, 0)
	welcomeLabel.BackgroundTransparency = 1
	welcomeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	welcomeLabel.Font = Enum.Font.SourceSansBold
	welcomeLabel.TextSize = 18
	welcomeLabel.Text = "Welcome, " .. localPlayer.DisplayName
	welcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	welcomeLabel.TextTransparency = 1
	welcomeLabel.Parent = introFrame

	task.wait(0.5)
	tweenService:Create(pfp, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
	tweenService:Create(welcomeLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	task.wait(2)

	tweenService:Create(pfp, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
	local hideWelcome = tweenService:Create(welcomeLabel, TweenInfo.new(0.5), {TextTransparency = 1})
	hideWelcome:Play()
	hideWelcome.Completed:Wait()
	introFrame:Destroy()

	contentList.Visible = true
	isVerifying = false
end)

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	toggleNotification.Visible = true
end)

minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	contentList.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0, 450, 0, 30) or UDim2.new(0, 450, 0, 300)
end)

userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or isBindingKey then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if not keyFrame.Parent then
			mainFrame.Visible = not mainFrame.Visible
			toggleNotification.Visible = not mainFrame.Visible
		end
	end
end)
