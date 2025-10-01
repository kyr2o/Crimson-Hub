local httpService = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")

local VERBOSE = false
local verificationUrl = "https://crimson-keys.vercel.app/api/verify" 
local privateApiBase = "https://crimson-hub-private.vercel.app"      
local privateGetPaths = { "/api/execute", "/api/script" }            
local privatePostPaths = { "/api/execute", "/api/script" }           

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

local localPlayer = players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonVerifyOnly"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = lighting

local function setBlur(active)
    tweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = active and 12 or 0 }):Play()
end

local sounds = {
    open = "rbxassetid://6366382384",
    close = "rbxassetid://6366382384",
    click = "rbxassetid://6366382384",
    error = "rbxassetid://5778393172",
    success = "rbxassetid://8621028374",
}
for name, id in pairs(sounds) do
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Name = name
    s.Volume = 0.4
    s.Parent = screenGui
    sounds[name] = s
end
local function playSound(n) local x = sounds[n]; if x then x:Play() end end

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

    local showTween = tweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -310, 1, -80)})
    local hideTween = tweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -80)})
    local progressTween = tweenService:Create(progressBar, TweenInfo.new(duration), {Size = UDim2.new(1, 0, 0, 2)})

    showTween:Play(); progressTween:Play()
    task.wait(duration)
    hideTween:Play(); hideTween.Completed:Wait()
    frame:Destroy()
end

local function tryRequest(tbl)
    local funcs = {
        request,
        syn and syn.request,
        http and http.request,
        http_request
    }
    for _, f in ipairs(funcs) do
        if f then
            local ok, resp = pcall(function() return f(tbl) end)
            if ok and resp and (resp.Body or resp.body or type(resp) == "string") then
                return true, tostring(resp.Body or resp.body or resp)
            end
        end
    end
    return false, nil
end

local function httpGet(url)
    local ok, res = pcall(function() return httpService:GetAsync(url) end)
    if ok and res then return true, tostring(res) end
    return tryRequest({ Url = url, Method = "GET" })
end

local function httpPostText(url, body)
    local bodyContent = tostring(body or "")
    local ok, res = pcall(function()
        return httpService:PostAsync(url, bodyContent, Enum.HttpContentType.TextPlain)
    end)
    if ok and res then return true, tostring(res) end
    return tryRequest({ Url = url, Method = "POST", Headers = {["Content-Type"] = "text/plain"}, Body = bodyContent })
end

local function httpPostJson(url, tbl)
    local payload = httpService:JSONEncode(tbl or {})
    local ok, res = pcall(function()
        return httpService:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson)
    end)
    if ok and res then return true, tostring(res) end
    return tryRequest({ Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload })
end

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function isPositiveResponse(responseText)
    if not responseText or type(responseText) ~= "string" then return false end
    local t = trim(responseText)
    local ok, dec = pcall(function() return httpService:JSONDecode(t) end)
    if ok and type(dec) == "table" then
        if dec.success == true or dec.Success == true or dec.ok == true or dec.status == 200 then return true end
        if dec.accepted == true or dec.verified == true then return true end
    end
    t = t:lower()
    if t == "true" or t == "1" or t == "ok" or t == "success" or t == "200" then return true end
    return false
end

local function extractCode(body)
    local t = trim(body or "")
    local ok, dec = pcall(function() return httpService:JSONDecode(t) end)
    if ok and type(dec) == "table" then
        if type(dec.code) == "string" then return dec.code end
        if type(dec.script) == "string" then return dec.script end
        if type(dec.lua) == "string" then return dec.lua end
        if type(dec.data) == "string" then return dec.data end
        if type(dec.payload) == "string" then return dec.payload end
    end
    return t
end

local function fetchPrivateScript(key)
    local encoded = httpService:UrlEncode(tostring(key or ""))

    for _, path in ipairs(privateGetPaths) do
        local url = string.format("%s%s?key=%s", privateApiBase, path, encoded)
        local ok, body = httpGet(url)
        if ok and body and #body > 0 then
            local code = extractCode(body)
            if code and #trim(code) > 0 then
                if VERBOSE then sendNotification("Debug", "GET ok (" .. path .. ")", 1, "success") end
                return true, code
            end
        end
    end

    for _, path in ipairs(privatePostPaths) do
        local url = string.format("%s%s", privateApiBase, path)
        local ok, body = httpPostJson(url, { key = key })
        if ok and body and #body > 0 then
            local code = extractCode(body)
            if code and #trim(code) > 0 then
                if VERBOSE then sendNotification("Debug", "POST JSON ok (" .. path .. ")", 1, "success") end
                return true, code
            end
        end
    end

    for _, path in ipairs(privatePostPaths) do
        local url = string.format("%s%s", privateApiBase, path)
        local ok, body = httpPostText(url, key)
        if ok and body and #body > 0 then
            local code = extractCode(body)
            if code and #trim(code) > 0 then
                if VERBOSE then sendNotification("Debug", "POST text ok (" .. path .. ")", 1, "success") end
                return true, code
            end
        end
    end

    return false, "No script from private API"
end

local function createVerificationUI()
    setBlur(true)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 220)
    frame.Position = UDim2.new(0.5, -200, 0.5, -110)
    frame.BackgroundColor3 = theme.background
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local frameStroke = Instance.new("UIStroke", frame)
    frameStroke.Color = theme.accent
    frameStroke.Thickness = 2

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "VERIFICATION"
    title.Font = Enum.Font.Michroma
    title.TextColor3 = theme.text
    title.TextSize = 24

    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 56)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter key to continue"
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextColor3 = theme.textSecondary
    subtitle.TextSize = 16

    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(1, -40, 0, 45)
    input.Position = UDim2.new(0, 20, 0, 92)
    input.BackgroundColor3 = theme.backgroundSecondary
    input.TextColor3 = theme.text
    input.PlaceholderText = "Your Key"
    input.PlaceholderColor3 = theme.textSecondary
    input.Font = Enum.Font.SourceSans
    input.TextSize = 16
    input.ClearTextOnFocus = false
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    local inputStroke = Instance.new("UIStroke", input)
    inputStroke.Color = theme.accent

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(1, -40, 0, 40)
    submit.Position = UDim2.new(0, 20, 0, 152)
    submit.BackgroundColor3 = theme.primary
    submit.Text = "SUBMIT"
    submit.Font = Enum.Font.Michroma
    submit.TextColor3 = Color3.new(1, 1, 1)
    submit.TextSize = 18
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 6)

    local spinner = Instance.new("ImageLabel", submit)
    spinner.Image = "rbxassetid://5107930337"
    spinner.Size = UDim2.new(0, 24, 0, 24)
    spinner.Position = UDim2.new(0.5, -12, 0.5, -12)
    spinner.BackgroundTransparency = 1
    spinner.ImageColor3 = Color3.new(1, 1, 1)
    spinner.Visible = false

    local spinning = false
    local function startSpin()
        spinner.Visible = true
        spinning = true
        task.spawn(function()
            while spinning do
                spinner.Rotation = 0
                tweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear), { Rotation = 360 }):Play()
                task.wait(1)
            end
            spinner.Visible = false
            spinner.Rotation = 0
        end)
    end
    local function stopSpin() spinning = false end

    local function disableUI(disabled)
        input.Active = not disabled
        input.TextEditable = not disabled
        submit.AutoButtonColor = not disabled
    end

    submit.MouseButton1Click:Connect(function()
        playSound("click")
        local key = input.Text
        if not key or key == "" then
            sendNotification("Error", "Please enter a key.", 1, "error")
            return
        end

        disableUI(true)
        local oldText = submit.Text
        submit.Text = ""
        startSpin()

        task.spawn(function()

            local ok, resp = httpPostText(verificationUrl, key)
            if VERBOSE and resp then sendNotification("Debug", "Verify resp len=" .. tostring(#resp), 1, ok and "success" or "error") end

            if ok and isPositiveResponse(resp) then
                playSound("success")
                sendNotification("Success", "Verification successful.", 1, "success")

                local got, codeOrErr = fetchPrivateScript(key)
                if got then

                    local f, e = loadstring(codeOrErr)
                    if f then
                        local okRun, runErr = pcall(f)
                        if okRun then
                            sendNotification("Loaded", "Script executed.", 1, "success")
                            playSound("close")
                            stopSpin()
                            submit.Text = oldText

                            tweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}):Play()
                            task.wait(0.35)
                            frame:Destroy()
                            setBlur(false)
                            return
                        else
                            sendNotification("Runtime Error", tostring(runErr), 3, "error")
                            playSound("error")
                        end
                    else
                        sendNotification("Script Error", tostring(e), 3, "error")
                        playSound("error")
                    end
                else
                    sendNotification("Download Failed", tostring(codeOrErr), 3, "error")
                    playSound("error")
                end
            else
                playSound("error")
                sendNotification("Failed", "Invalid or rejected key.", 1, "error")

                local originalPos = frame.Position
                local info = TweenInfo.new(0.07)
                for _ = 1, 3 do
                    tweenService:Create(frame, info, {Position = originalPos + UDim2.fromOffset(10, 0)}):Play()
                    task.wait(0.07)
                    tweenService:Create(frame, info, {Position = originalPos - UDim2.fromOffset(10, 0)}):Play()
                    task.wait(0.07)
                end
                tweenService:Create(frame, info, {Position = originalPos}):Play()
            end

            stopSpin()
            submit.Text = oldText
            disableUI(false)
        end)
    end)

    playSound("open")
end

createVerificationUI()
