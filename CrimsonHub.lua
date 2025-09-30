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
	stroke.Color = Color3.fromRGB(139, 0, 0)
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

	local showTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -60)})
	local hideTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -60)})
	local timerTween = tweenService:Create(timerBar, TweenInfo.new(7.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 3)})

	showTween:Play()
	timerTween:Play()
	task.wait(7.5)
	hideTween:Play()
	hideTween.Completed:Wait()
	frame:Destroy()
end

local function httpGet(url)
	local success, result = pcall(function() return httpService:GetAsync(url) end)
	if success and result then return true, tostring(result) end
	local function tryRequest(reqFunc)
		if not reqFunc then return false, nil end
		local ok, resp = pcall(function()
			return reqFunc({Url = url, Method = "GET", Headers = { ["User-Agent"] = "CrimsonHub/1.0" }})
		end)
		if ok and resp then
			if type(resp) == "table" then
				return true, tostring(resp.Body or resp.body or "")
			end
			return true, tostring(resp)
		end
		return false, nil
	end
	local reqSuccess, reqResult = tryRequest(request)
	if reqSuccess then return reqSuccess, reqResult end
	local synSuccess, synResult = tryRequest(syn and syn.request)
	if synSuccess then return synSuccess, synResult end
	local oldHttpSuccess, oldHttpResult = tryRequest(http_request)
	if oldHttpSuccess then return oldHttpSuccess, oldHttpResult end
	local newHttpSuccess, newHttpResult = tryRequest(http and http.request)
	if newHttpSuccess then return newHttpSuccess, newHttpResult end
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
		local ok, resp = pcall(function()
			return reqFunc({Url = url, Method = "POST", Headers = { ["Content-Type"] = contentType, ["User-Agent"] = "CrimsonHub/1.0" }, Body = bodyContent})
		end)
		if ok and resp then
			if type(resp) == "table" then return true, tostring(resp.Body or resp.body or "") end
			return true, tostring(resp)
		end
		return false, nil
	end
	local reqSuccess, reqResult = tryRequest(request)
	if reqSuccess then return reqSuccess, reqResult end
	local synSuccess, synResult = tryRequest(syn and syn.request)
	if synSuccess then return synSuccess, synResult end
	local oldHttpSuccess, oldHttpResult = tryRequest(http_request)
	if oldHttpSuccess then return oldHttpSuccess, oldHttpResult end
	local newHttpSuccess, newHttpResult = tryRequest(http and http.request)
	if newHttpSuccess then return newHttpSuccess, newHttpResult end
	return false, tostring(result or "All HTTP methods failed.")
end

local function isPositiveResponse(responseText)
	if not responseText or type(responseText) ~= "string" then return false end
	local text = responseText:lower():match("^%s*(.-)%s*$")
	if text == "true" or text == "1" or text == "ok" or text == "success" or text == "200" then
		return true
	end
	local success, decoded = pcall(function() return httpService:JSONDecode(responseText) end)
	if success and type(decoded) == "table" and (decoded.success == true or decoded.Success == true) then
		return true
	end
	return false
end

local function getScriptTypeFromContent(content)
	local firstLine = content:match("^[^\r\n]+")
	if firstLine and firstLine:match("%-%-%s*CrimsonHub:%s*Type=Once") then
		return "Once"
	end
	return "Toggle"
end

local function executeScript(scriptName)
	if not scriptStates[scriptName] or not scriptStates[scriptName].Content then
		sendNotification("Script content not loaded for " .. scriptName)
		return
	end
	local content = scriptStates[scriptName].Content
	local f, err = pcall(loadstring(content))
	if f and type(f) == "function" then
		task.spawn(f)
	else
		sendNotification("Error executing " .. scriptName)
	end
end

local function toggleScript(scriptName, toggleButton, forceState)
	if not scriptStates[scriptName] then return end

	local currentState = scriptStates[scriptName].Enabled
	local newState = if forceState ~= nil then forceState else not currentState

	if newState == currentState then return end
	scriptStates[scriptName].Enabled = newState

	local pos = if newState then UDim2.new(1, -22, 0.5, -10) else UDim2.new(0, 2, 0.5, -10)
	local color = if newState then Color3.fromRGB(80, 255, 80) else Color3.fromRGB(255, 80, 80)

	tweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Position = pos,
		BackgroundColor3 = color
	}):Play()

	if newState then
		executeScript(scriptName)
	end
end

local function loadGameScripts()
	for _, child in ipairs(contentList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local gameId = tostring(game.PlaceId)
	if gameId == "0" then
		sendNotification("Cannot load scripts in Studio. Please publish first.")
		return
	end

	local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
	local ok, result = httpGet(apiUrl)
	if not ok then
		local err = tostring(result)
		if err:match("404") then sendNotification("No scripts found for this game.")
		elseif err:match("403") then sendNotification("GitHub API blocked/limited. Try again later.")
		else sendNotification("GitHub API error: " .. err:sub(1, 50))
		end
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
			local contentOk, scriptContent = httpGet(scriptInfo.download_url)
			
			if contentOk and scriptContent then
				local scriptType = getScriptTypeFromContent(scriptContent)
				scriptStates[scriptName] = {
					Enabled = false,
					Keybind = nil,
					Url = scriptInfo.download_url,
					Content = scriptContent,
					Type = scriptType,
					Mode = "Toggle",
					Thread = nil
				}

				local container = Instance.new("Frame")
				container.Name = scriptName
				container.Size = UDim2.new(1, -20, 0, 40)
				container.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
				container.Parent = contentList
				local contCorner = Instance.new("UICorner")
				contCorner.CornerRadius = UDim.new(0, 6)
				contCorner.Parent = container

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

				if scriptType == "Toggle" then
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

					toggleButton.MouseButton1Click:Connect(function()
						if scriptStates[scriptName].Mode == "OnHold" then
							executeScript(scriptName)
						else
							toggleScript(scriptName, toggleButton)
						end
					end)

					scriptLabel.MouseButton2Click:Connect(function()
						local state = scriptStates[scriptName]
						local holdLabel = container:FindFirstChild("HoldLabel")
						if state.Mode == "Toggle" then
							state.Mode = "OnHold"
							if not holdLabel then
								holdLabel = Instance.new("TextLabel")
								holdLabel.Name = "HoldLabel"
								holdLabel.Size = UDim2.new(0, 50, 0, 15)
								holdLabel.Position = UDim2.new(1, -55, 1, -17)
								holdLabel.BackgroundTransparency = 1
								holdLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
								holdLabel.Text = "(On Hold)"
								holdLabel.Font = Enum.Font.SourceSans
								holdLabel.TextSize = 12
								holdLabel.TextXAlignment = Enum.TextXAlignment.Right
								holdLabel.Parent = container
							end
							holdLabel.Visible = true
						else
							state.Mode = "Toggle"
							if holdLabel then
								holdLabel.Visible = false
							end
						end
					end)

				elseif scriptType == "Once" then
					local execButton = Instance.new("TextButton")
					execButton.Size = UDim2.new(0, 60, 0, 24)
					execButton.Position = UDim2.new(1, -70, 0.5, -12)
					execButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
					execButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					execButton.Text = "Execute"
					execButton.Font = Enum.Font.SourceSansBold
					execButton.TextSize = 14
					execButton.Parent = container
					local execCorner = Instance.new("UICorner")
					execCorner.CornerRadius = UDim.new(0, 4)
					execCorner.Parent = execButton
					
					execButton.MouseButton1Click:Connect(function()
						execButton.Text = "..."
						executeScript(scriptName)
						task.wait(0.5)
						execButton.Text = "Execute"
					end)
				end
			end
		end
	end
	uiListLayout.Parent = nil
	uiListLayout.Parent = contentList
end

local minimized = false
local isVerifying = false

submitButton.MouseButton1Click:Connect(function()
	if isVerifying then return end
	local userInput = tostring(keyInput.Text or "")
	if userInput:match("^%s*$") then
		sendNotification("Please enter a value.")
		return
	end

	isVerifying = true
	submitButton.Text = "Correct"
	task.wait(0.5)
	tweenService:Create(keyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1)}):Play()
	for _,v in ipairs(keyFrame:GetChildren()) do
		if v:IsA("GuiObject") then
			tweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1, ImageTransparency = 1}):Play()
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
	loadGameScripts()
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
	if input.UserInputType == Enum.UserInputType.Keyboard then
		for name, state in pairs(scriptStates) do
			if state.Keybind and input.KeyCode == state.Keybind then
				local container = contentList:FindFirstChild(name)
				if container and state.Type == "Toggle" then
					local toggleButton = container:FindFirstChild("TextButton", true)
					if toggleButton then
						toggleScript(name, toggleButton)
					end
				end
			end
		end
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if not keyFrame.Parent then
			mainFrame.Visible = not mainFrame.Visible
			toggleNotification.Visible = not mainFrame.Visible
		end
	end
end)
