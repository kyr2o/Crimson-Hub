local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService = game:GetService("TweenService")

--[[ CONFIGURATION ]]--
local VERBOSE = false
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://eosd75fjrwrywy7.m.pipedream.net"

--[[ GUI SETUP ]]--
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
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.Parent = screenGui
local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 8)
mainFrameCorner.Parent = mainFrame
local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = Color3.fromRGB(139, 0, 0)
mainFrameStroke.Thickness = 2
mainFrameStroke.Parent = mainFrame
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
titleLabel.BackgroundColor3 = Color3.new(1, 1, 1)
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
contentFrame.Size = UDim2.new(1, -10, 1, -40)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundColor3 = Color3.new(1, 1, 1)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.Parent = contentFrame
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

--[[ HELPER FUNCTIONS ]]--
local function sendNotification(text, duration)
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
    local showTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -60)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -60)})
    showTween:Play()
    task.wait(duration or 3)
    hideTween:Play()
    hideTween.Completed:Wait()
    frame:Destroy()
end

local function httpGet(url)
	local success, result = pcall(function() return httpService:GetAsync(url) end)
	if success and result then return true, tostring(result) end
	if pcall(function() return game.HttpGet end) and game.HttpGet then
		local ok, res = pcall(function() return game:HttpGet(url) end)
		if ok and res then return true, tostring(res) end
	end
	local function tryRequest(reqFunc)
		if not reqFunc then return false, nil end
		local ok, resp = pcall(function()
			return reqFunc({Url = url, Method = "GET"})
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
            return reqFunc({Url = url, Method = "POST", Headers = { ["Content-Type"] = contentType, ["User-Agent"] = "Roblox" }, Body = bodyContent})
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

local function loadGameScripts()
    for i = #contentFrame:GetChildren(), 1, -1 do
        local child = contentFrame:GetChildren()[i]
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local gameId = tostring(game.PlaceId)
    local apiUrl = "https://api.github.com/repos/"..githubUsername.."/"..repoName.."/contents/"..gameId.."?ref="..branchName
    
    local ok, result = httpGet(apiUrl)
    if not ok then
        local err = tostring(result)
        if err:match("404") then
            sendNotification("No scripts found for this game.", 4)
        elseif err:match("403") then
            sendNotification("GitHub API rate limit hit. Try again later.", 5)
        else
            sendNotification("GitHub API error: " .. err:sub(1, 50), 5)
        end
        return
    end

    local decoded
    local ok2, dec = pcall(function() return httpService:JSONDecode(result) end)
    if not ok2 then
        sendNotification("Failed to decode GitHub response.", 4)
        return
    end
    if type(decoded) ~= "table" or not decoded[1] then
        sendNotification("No script files found in repo folder.", 4)
        return
    end
    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptButton = Instance.new("TextButton")
            scriptButton.Size = UDim2.new(1, -20, 0, 35)
            scriptButton.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
            scriptButton.TextColor3 = Color3.fromRGB(220, 220, 220)
            scriptButton.Text = scriptInfo.name:gsub("%.lua", "")
            scriptButton.Font = Enum.Font.SourceSansBold
            scriptButton.TextSize = 16
            scriptButton.Parent = contentFrame
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = scriptButton
            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = Color3.fromRGB(80, 80, 80)
            btnStroke.Thickness = 1
            btnStroke.Parent = scriptButton
            scriptButton.MouseButton1Click:Connect(function()
                local scriptUrl = scriptInfo.download_url
                local ok3, scriptContent = httpGet(scriptUrl)
                if ok3 and scriptContent then
                    local okRun, errRun = pcall(function()
                        local fn = loadstring(scriptContent)
                        if type(fn) == "function" then
                            fn()
                        end
                    end)
                    if okRun then
                        sendNotification("Executed: " .. scriptButton.Text, 2)
                    else
                        sendNotification("Error running script: " .. tostring(errRun), 4)
                    end
                else
                    sendNotification("Error loading script content.", 3)
                end
            end)
        end
    end
end

--[[ MAIN LOGIC ]]--
local minimized = false
local isVerifying = false

submitButton.MouseButton1Click:Connect(function()
    if isVerifying then return end
    local userInput = tostring(keyInput.Text or "")
    if userInput:match("^%s*$") then
        sendNotification("Enter a password first.", 2)
        return
    end
    isVerifying = true
    submitButton.Text = "Verifying..."
    local ok, respText = httpPost(serverUrl, userInput)
    if VERBOSE then
        sendNotification("Response: " .. (tostring(respText or "nil"):sub(1, 150)), 4)
    end
    if ok and isPositiveResponse(respText) then
        submitButton.Text = "Correct"
        task.wait(1)
        keyFrame:Destroy()
        mainFrame.Visible = true
        loadGameScripts()
    else
        submitButton.Text = ok and "Incorrect" or "Server Error"
        task.wait(2)
        submitButton.Text = "Submit"
    end
    isVerifying = false
end)

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    toggleNotification.Visible = true
end)

minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    contentFrame.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0, 450, 0, 30) or UDim2.new(0, 450, 0, 300)
end)

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not keyFrame.Parent then
            mainFrame.Visible = not mainFrame.Visible
            toggleNotification.Visible = not mainFrame.Visible
        end
    end
end)
