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
local serverUrl = "https://crimson-keys.vercel.app/api/verify"

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local uiSound = Instance.new("Sound")
uiSound.SoundId = "rbxassetid://6366382384" 
uiSound.Volume = 0.5
uiSound.Parent = screenGui

local function playSound()
    uiSound:Play()
end

local function sendNotification(text, duration)
    local notificationDuration = duration or 3
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 50)
    frame.Position = UDim2.new(1, 10, 1, -60)
    frame.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(139, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, -5)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextWrapped = true
    label.Parent = frame

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 4)
    progressBar.Position = UDim2.new(0, 0, 1, -4)
    progressBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame
    
    local showTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -60)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -60)})
    local progressTween = tweenService:Create(progressBar, TweenInfo.new(notificationDuration), {Size = UDim2.new(1, 0, 0, 4)})

    showTween:Play()
    progressTween:Play()
    
    task.wait(notificationDuration)
    
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
			if type(resp) == "table" then return true, tostring(resp.Body or resp.body or "") end
			return true, tostring(resp)
		end
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
            return reqFunc({Url = url, Method = "POST", Headers = { ["Content-Type"] = "text/plain" }, Body = bodyContent})
        end)
        if ok and resp then
            if type(resp) == "table" then return true, tostring(resp.Body or resp.body or "") end
            return true, tostring(resp)
        end
        return false, nil
    end
    local r, res = tryRequest(request)
    if r then return r, res end
    local s, res2 = tryRequest(syn and syn.request)
    if s then return s, res2 end
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
    local ui = {}
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(36, 37, 42)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(20, 21, 24)

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = Color3.fromRGB(30, 31, 36)
    header.TextColor3 = Color3.fromRGB(220, 220, 220)
    header.Font = Enum.Font.SourceSansBold
    header.Text = "Crimson Hub"
    header.TextSize = 16
    header.Parent = mainFrame
    
    local closeButton = Instance.new("ImageButton")
    closeButton.Size = UDim2.new(0, 16, 0, 16)
    closeButton.Position = UDim2.new(1, -25, 0.5, -8)
    closeButton.Image = "rbxassetid://13516603954"
    closeButton.ImageColor3 = Color3.fromRGB(180, 180, 180)
    closeButton.BackgroundTransparency = 1
    closeButton.Parent = header

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, -35)
    sidebar.Position = UDim2.new(0, 0, 0, 35)
    sidebar.BackgroundColor3 = Color3.fromRGB(30, 31, 36)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    
    local activeTabIndicator = Instance.new("Frame")
    activeTabIndicator.Size = UDim2.new(0, 3, 0, 20)
    activeTabIndicator.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    activeTabIndicator.BorderSizePixel = 0
    activeTabIndicator.ZIndex = 3
    Instance.new("UICorner", activeTabIndicator).CornerRadius = UDim.new(1, 0)
    activeTabIndicator.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout", sidebar)
    sidebarLayout.Padding = UDim.new(0, 10)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -120, 1, -35)
    contentContainer.Position = UDim2.new(0, 120, 0, 35)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    local scriptsPage = Instance.new("ScrollingFrame")
    scriptsPage.Size = UDim2.new(1, 0, 1, 0)
    scriptsPage.BackgroundTransparency = 1
    scriptsPage.BorderSizePixel = 0
    scriptsPage.ScrollBarThickness = 4
    scriptsPage.Parent = contentContainer
    
    local gridLayout = Instance.new("UIGridLayout", scriptsPage)
    gridLayout.CellSize = UDim2.new(0, 170, 0, 40)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function createTab(name, icon)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(1, -10, 0, 30)
        tab.BackgroundColor3 = Color3.fromRGB(45, 46, 51)
        tab.TextColor3 = Color3.fromRGB(180, 180, 180)
        tab.Text = "  " .. name
        tab.Font = Enum.Font.SourceSansSemibold
        tab.TextSize = 14
        tab.TextXAlignment = Enum.TextXAlignment.Left
        tab.Parent = sidebar
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 4)

        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Size = UDim2.new(0, 16, 0, 16)
        iconLabel.Position = UDim2.new(0, 8, 0.5, -8)
        iconLabel.Image = icon
        iconLabel.ImageColor3 = Color3.fromRGB(180, 180, 180)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Parent = tab
        
        tab.MouseEnter:Connect(function() tweenService:Create(tab, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255), ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
        tab.MouseLeave:Connect(function() tweenService:Create(tab, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(180, 180, 180), ImageColor3 = Color3.fromRGB(180, 180, 180)}):Play() end)
        tab.MouseButton1Click:Connect(function()
            playSound()
            tweenService:Create(activeTabIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, tab.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + 5)}):Play()
        end)
        return tab
    end
    
    local scriptsTab = createTab("Scripts", "rbxassetid://13516604212")
    task.wait()
    activeTabIndicator.Position = UDim2.new(0, 0, 0, scriptsTab.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + 5)
    
    local function createScriptButton(name, callback)
        local buttonData = {enabled = false, hold = false}
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 170, 0, 40)
        button.BackgroundColor3 = Color3.fromRGB(45, 46, 51)
        button.Text = ""
        button.Parent = scriptsPage
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Text = name
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = button

        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(0, 30, 0, 16)
        toggle.Position = UDim2.new(1, -40, 0.5, -8)
        toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggle.Parent = button
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

        local toggleKnob = Instance.new("Frame")
        toggleKnob.Size = UDim2.new(0, 12, 0, 12)
        toggleKnob.Position = UDim2.new(0, 2, 0.5, -6)
        toggleKnob.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        toggleKnob.Parent = toggle
        Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)
        
        local function updateToggle()
            playSound()
            buttonData.enabled = not buttonData.enabled
            local pos = buttonData.enabled and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            local color = buttonData.enabled and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
            tweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos, BackgroundColor3 = color}):Play()
            if not buttonData.hold then pcall(callback, buttonData.enabled) end
        end

        button.MouseButton1Click:Connect(updateToggle)
        button.MouseEnter:Connect(function() tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 56, 61)}):Play() end)
        button.MouseLeave:Connect(function() tweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 46, 51)}):Play() end)
    end
    
    function ui:LoadScripts(scriptLoader)
        for _, child in ipairs(scriptsPage:GetChildren()) do
            if child:IsA("UIGridLayout") then continue end
            child:Destroy()
        end
        local scripts = scriptLoader()
        if scripts then
            for name, executeFunc in pairs(scripts) do
                createScriptButton(name, executeFunc)
            end
        end
    end
    
    function ui:Show()
        mainFrame.Visible = true
        mainFrame.Position = UDim2.new(0.5, -250, 0.5, -140)
        mainFrame.BackgroundTransparency = 1
        for _, v in ipairs(mainFrame:GetDescendants()) do if v:IsA("GuiObject") then v.BackgroundTransparency=1; v.TextTransparency=1; v.ImageTransparency=1; if v:IsA("UIStroke") then v.Transparency=1 end end end
        
        tweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -250, 0.5, -160), BackgroundTransparency = 0}):Play()
        task.wait(0.1)
        for _, v in ipairs(mainFrame:GetDescendants()) do 
            if v:IsA("GuiObject") then
                local goals = {BackgroundTransparency = v.BackgroundTransparency, TextTransparency = 0, ImageTransparency = 0}
                if v:IsA("UIStroke") then goals.Transparency = 0 end
                tweenService:Create(v, TweenInfo.new(0.5), goals):Play()
            end
        end
    end

    closeButton.MouseButton1Click:Connect(function()
        playSound()
        mainFrame.Visible = false
    end)
    
    return ui
end

local function loadGameScripts()
    local gameId = tostring(game.PlaceId)
    if gameId == "0" then sendNotification("Cannot load scripts in Studio.", 5); return end
    local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(githubUsername, repoName, gameId, branchName)
    local ok, result = httpGet(apiUrl)
    if not ok then sendNotification("Error loading scripts.", 4); return end
    local success, decoded = pcall(function() return httpService:JSONDecode(result) end)
    if not success or type(decoded) ~= "table" then sendNotification("No scripts found.", 4); return end
    
    local scriptList = {}
    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
            local scriptName = (scriptInfo.name or ""):gsub("%.lua$", "")
            scriptList[scriptName] = function(state)
                if state == false then return end
                local s, content = httpGet(scriptInfo.download_url)
                if s and content then
                    local f, e = loadstring(content)
                    if f then f() else sendNotification("Script error: " .. tostring(e), 5) end
                else
                    sendNotification("Failed to download script.", 3)
                end
            end
        end
    end
    return scriptList
end

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 320, 0, 160)
keyFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
keyFrame.BackgroundColor3 = Color3.fromRGB(36, 37, 42)
keyFrame.Draggable = true
keyFrame.Active = true
keyFrame.Parent = screenGui
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", keyFrame).Color = Color3.fromRGB(20, 21, 24)

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Text = "Verification"
keyTitle.Font = Enum.Font.SourceSansBold
keyTitle.TextSize = 16
keyTitle.Parent = keyFrame
Instance.new("UICorner", keyTitle).CornerRadius = UDim.new(0, 6)

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 35)
keyInput.Position = UDim2.new(0, 20, 0, 50)
keyInput.BackgroundColor3 = Color3.fromRGB(30, 31, 36)
keyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
keyInput.PlaceholderText = "Enter Key"
keyInput.Font = Enum.Font.SourceSans
keyInput.TextSize = 14
keyInput.Parent = keyFrame
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 4)

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(1, -40, 0, 30)
submitButton.Position = UDim2.new(0, 20, 0, 105)
submitButton.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.Text = "Submit"
submitButton.Font = Enum.Font.SourceSansBold
submitButton.TextSize = 16
submitButton.Parent = keyFrame
Instance.new("UICorner", submitButton).CornerRadius = UDim.new(0, 4)

submitButton.MouseButton1Click:Connect(function()
    playSound()
    local userInput = keyInput.Text
    if not userInput or userInput == "" then sendNotification("Enter a key.", 2) return end
    
    submitButton.Text = "..."
    local ok, respText = httpPost(serverUrl, userInput)
    
    if ok and isPositiveResponse(respText) then
        tweenService:Create(keyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        for _, v in ipairs(keyFrame:GetDescendants()) do if v:IsA("GuiObject") then tweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1, Transparency = 1}):Play() end end
        task.wait(0.3)
        keyFrame:Destroy()

        local hub = mainUI:Create()
        hub:LoadScripts(loadGameScripts)
        hub:Show()
    else
        submitButton.Text = "Submit"
        local originalPos = keyFrame.Position
        local shake1 = tweenService:Create(keyFrame, TweenInfo.new(0.07), {Position = originalPos + UDim2.fromOffset(7, 0)})
        local shake2 = tweenService:Create(keyFrame, TweenInfo.new(0.07), {Position = originalPos - UDim2.fromOffset(7, 0)})
        shake1:Play(); shake1.Completed:Wait(); shake2:Play(); shake2.Completed:Wait(); shake1:Play(); shake1.Completed:Wait(); shake2:Play(); shake2.Completed:Wait(); shake1:Play(); shake1.Completed:Wait(); shake2:Play(); shake2.Completed:Wait(); tweenService:Create(keyFrame, TweenInfo.new(0.07), {Position = originalPos}):Play()
    end
end)
