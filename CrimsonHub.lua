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
local serverUrl = "https://eosd75fjrwrywy7.m.pipedream.net"

-----------------------------------------------------------
-- GUI Creation
-----------------------------------------------------------
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

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
keyTitle.BorderSizePixel = 0
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Text = "Crimson Hub - Verification"
keyTitle.Font = Enum.Font.SourceSansBold
keyTitle.TextSize = 16
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 35)
keyInput.Position = UDim2.new(0, 20, 0, 50)
keyInput.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
keyInput.BorderSizePixel = 0
keyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
keyInput.PlaceholderText = "Enter Password"
keyInput.Font = Enum.Font.SourceSans
keyInput.TextSize = 14
keyInput.ClearTextOnFocus = false
keyInput.Parent = keyFrame

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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
mainFrame.BackgroundTransparency = 1
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

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -50, 0.5, -10)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 80)
minimizeButton.Text = ""
minimizeButton.Parent = header

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
contentList.Visible = false
contentList.Parent = contentFrame

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

-----------------------------------------------------------
-- Notifications
-----------------------------------------------------------
local function sendNotification(text)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 250, 0, 50)
	frame.Position = UDim2.new(1, 10, 1, -60)
	frame.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
	frame.Parent = screenGui
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
	game:GetService("Debris"):AddItem(frame, 3)
end

-----------------------------------------------------------
-- HTTP Helpers
-----------------------------------------------------------
local function httpPost(url, bodyTable)
	local bodyJson = httpService:JSONEncode(bodyTable)
	-- Try Roblox HttpService first
	local success, result = pcall(function()
		return httpService:PostAsync(url, bodyJson, Enum.HttpContentType.ApplicationJson)
	end)
	if success and result then return true, tostring(result) end
	-- Fallback to exploit request functions
	if request then
		local ok, resp = pcall(function()
			return request({
				Url = url,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = bodyJson
			})
		end)
		if ok and resp then return true, tostring(resp.Body or resp.body or "") end
	end
	return false, "HTTP Post failed"
end

local function isPositiveResponse(respText)
	if not respText then return false end
	local trimmed = tostring(respText):gsub("^%s+", ""):gsub("%s+$", ""):lower()
	-- plain values
	if trimmed == "true" or trimmed == "1" or trimmed == "ok" or trimmed == "success" then
		return true
	end
	-- JSON
	local ok, decoded = pcall(function() return httpService:JSONDecode(respText) end)
	if ok and type(decoded) == "table" then
		if decoded.success == true or decoded.ok == true then return true end
	end
	return false
end

-----------------------------------------------------------
-- Submit Logic
-----------------------------------------------------------
local isVerifying = false

submitButton.MouseButton1Click:Connect(function()
	if isVerifying then return end
	local userInput = keyInput.Text
	if userInput == "" then
		sendNotification("Enter a password first")
		return
	end
	isVerifying = true
	submitButton.Text = "Verifying..."

	local ok, respText = httpPost(serverUrl, { password = userInput })
	if VERBOSE then sendNotification("Response: " .. tostring(respText)) end

	if ok and isPositiveResponse(respText) then
		submitButton.Text = "Correct"
		task.wait(0.5)
		keyFrame:Destroy()
		mainFrame.Visible = true
		contentList.Visible = true
		-- TODO: loadGameScripts() here if you want to fetch repo scripts
	else
		submitButton.Text = ok and "Incorrect" or "Server Error"
		task.wait(2)
		submitButton.Text = "Submit"
	end
	isVerifying = false
end)

-----------------------------------------------------------
-- Close / Minimize
-----------------------------------------------------------
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	toggleNotification.Visible = true
end)

minimizeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

-----------------------------------------------------------
-- Hotkey Toggle
-----------------------------------------------------------
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		mainFrame.Visible = not mainFrame.Visible
		toggleNotification.Visible = not mainFrame.Visible
	end
end)
