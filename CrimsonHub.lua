local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

--[[ CONFIGURATION ]]--
local VERBOSE = false -- Set to true to see debug notifications (e.g., raw server response)
local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"
local serverUrl = "https://eosd75fjrwrywy7.m.pipedream.net"

--[[ GUI SETUP (No changes here) ]]--
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
keyTitle.Text = "Crimson Hub - Password"
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
keyInput.PlaceholderText = "Enter Password..."
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

--[[ HELPER FUNCTIONS ]]--
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
    task.wait(duration or 2)
    frame:TweenPosition(UDim2.new(0.5, -200, 0, -60), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true)
    task.wait(0.5)
    frame:Destroy()
end

local function httpPost(url, body)
    local bodyContent
    local contentType
    local contentTypeEnum

    if type(body) == "table" then
        local ok, encoded = pcall(function() return httpService:JSONEncode(body) end)
        if not ok then return false, "Failed to encode JSON payload" end
        bodyContent = encoded
        contentType = "application/json"
        contentTypeEnum = Enum.HttpContentType.ApplicationJson
    else
        bodyContent = tostring(body)
        contentType = "text/plain"
        contentTypeEnum = Enum.HttpContentType.TextPlain
    end
    
    local success, result = pcall(function()
        return httpService:PostAsync(url, bodyContent, contentTypeEnum)
    end)
    if success and result then return true, tostring(result) end

    local function tryRequest(reqFunc)
        if not reqFunc then return false, nil end
        local ok, resp = pcall(function()
            return reqFunc({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = contentType, ["User-Agent"] = "Roblox" },
                Body = bodyContent
            })
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
    local ok, result = pcall(function() return httpService:GetAsync(apiUrl) end)
    if not ok then
        sendNotification("GitHub API error: " .. tostring(result), 5)
        return
    end
    local decoded
    local ok2, dec = pcall(function() return httpService:JSONDecode(result) end)
    if ok2 then decoded = dec else
        sendNotification("Failed decoding GitHub response", 4)
        return
    end
    if type(decoded) ~= "table" then
        sendNotification("No scripts found in repo folder: " .. gameId, 4)
        return
    end
    for _, scriptInfo in ipairs(decoded) do
        if scriptInfo.type == "file" and scriptInfo.download_url then
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
                local ok3, scriptContent = pcall(function()
                    if pcall(function() return game.HttpGet end) and game.HttpGet then
                        return game:HttpGet(scriptUrl)
                    else
                        return httpService:GetAsync(scriptUrl)
                    end
                end)
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
                    sendNotification("Error loading script!", 3)
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
        if not keyFrame.Parent then -- Only toggle if key is already verified
            mainFrame.Visible = not mainFrame.Visible
            toggleNotification.Visible = not mainFrame.Visible
        end
    end
end)

sendNotification("CrimsonHub Loaded", 3)
