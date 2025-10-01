-- Crimson-Verify.lua (verification-only)
-- Expects Vercel to return: { success: true, script: "<lua code>" }

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local localPlayer = Players.LocalPlayer

-- CONFIG
local SERVER_URL = "https://crimson-keys.vercel.app/api/verify" -- POST JSON {key, placeId}

-- Simple theme + blur
local theme = {
  bg = Color3.fromRGB(21,22,28),
  bg2 = Color3.fromRGB(30,32,40),
  accent = Color3.fromRGB(227,38,54),
  text = Color3.fromRGB(240,240,240),
  text2 = Color3.fromRGB(150,150,150),
  success = Color3.fromRGB(0,255,127),
  error = Color3.fromRGB(227,38,54)
}

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "CrimsonVerifyOnly"
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local function setBlur(on)
  TweenService:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = on and 12 or 0}):Play()
end

local function notify(msg, color)
  local m = Instance.new("Message")
  m.Text = msg
  m.Parent = workspace
  task.delay(1.2, function() m:Destroy() end)
end

-- Minimal request helpers (JSON)
local function postJson(url, jsonBody)
  -- Prefer exploit request if available to preserve status codes
  if request or (syn and syn.request) then
    local req = request or syn.request
    local ok, resp = pcall(function()
      return req({
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = jsonBody
      })
    end)
    if ok and resp and type(resp.Body) == "string" then
      return true, resp.Body
    end
  end
  -- Fallback to Roblox HttpService (no status), still returns body
  local ok, body = pcall(function()
    return HttpService:PostAsync(url, jsonBody, Enum.HttpContentType.ApplicationJson)
  end)
  return ok, body
end

-- UI
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 180)
frame.Position = UDim2.new(0.5, -190, 0.5, -90)
frame.BackgroundColor3 = theme.bg
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", frame).Color = theme.accent

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Michroma
title.Text = "CRIMSON VERIFICATION"
title.TextColor3 = theme.text
title.TextSize = 16

local input = Instance.new("TextBox", frame)
input.Size = UDim2.new(1, -40, 0, 40)
input.Position = UDim2.new(0, 20, 0, 60)
input.BackgroundColor3 = theme.bg2
input.TextColor3 = theme.text
input.PlaceholderText = "Enter key"
input.PlaceholderColor3 = theme.text2
input.Font = Enum.Font.SourceSans
input.TextSize = 16
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", input).Color = theme.accent

local submit = Instance.new("TextButton", frame)
submit.Size = UDim2.new(1, -40, 0, 38)
submit.Position = UDim2.new(0, 20, 0, 116)
submit.BackgroundColor3 = theme.accent
submit.Text = "VERIFY"
submit.Font = Enum.Font.Michroma
submit.TextColor3 = Color3.new(1,1,1)
submit.TextSize = 16
Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 6)

setBlur(true)

local busy = false
submit.MouseButton1Click:Connect(function()
  if busy then return end
  busy = true
  local key = (input.Text or ""):gsub("^%s*(.-)%s*$","%1")
  if key == "" then
    notify("Please enter a key.", theme.error)
    busy = false
    return
  end

  submit.Text = "Checking..."
  local payload = HttpService:JSONEncode({ key = key, placeId = game.PlaceId })

  task.spawn(function()
    local ok, body = postJson(SERVER_URL, payload)
    submit.Text = "VERIFY"
    if not ok or type(body) ~= "string" then
      notify("Verification server error.", theme.error)
      busy = false
      return
    end

    local good, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not good or type(data) ~= "table" then
      notify("Invalid server response.", theme.error)
      busy = false
      return
    end

    if data.success and type(data.script) == "string" then
      -- Close UI and run hub
      setBlur(false)
      frame:Destroy()
      local fn, err = loadstring(data.script)
      if not fn then
        notify("Hub load failed: "..tostring(err), theme.error)
        busy = false
        return
      end
      task.defer(fn)
      -- Done, verification-only flow complete
    else
      notify(data.message or "Invalid key.", theme.error)
    end
    busy = false
  end)
end)

-- Hide with RightControl for convenience
UserInputService.InputBegan:Connect(function(inputObj)
  if inputObj.KeyCode == Enum.KeyCode.RightControl then
    frame.Visible = not frame.Visible
    setBlur(frame.Visible)
  end
end)
