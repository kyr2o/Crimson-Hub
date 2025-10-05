local CoreGui = game:GetService("CoreGui")
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"

if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local Shared = (getgenv and getgenv()) or _G
local G = Shared

if Shared.CRIMSON_ESP and Shared.CRIMSON_ESP.disable then
    pcall(function() Shared.CRIMSON_ESP.disable(true) end)
end

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local State = {
    enabled = false,
    conns = {},
    charConns = {},
    highlights = {},
    billboards = {},
    bumpedOnce = {},
    lastRole = {},
}

local function track(conn)
    if conn then table.insert(State.conns, conn) end
    return conn
end

local function destroySafe(x)
    if x and x.Destroy then pcall(function() x:Destroy() end) end
end

local function disconnectAll()
    for i, c in ipairs(State.conns) do
        if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        State.conns[i] = nil
    end
    for plr, c in pairs(State.charConns) do
        if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        State.charConns[plr] = nil
    end
end

local function removeVisualsFor(player)
    if State.highlights[player] then destroySafe(State.highlights[player]); State.highlights[player] = nil end
    if State.billboards[player] then destroySafe(State.billboards[player]); State.billboards[player] = nil end

    local character = player.Character
    if character then
        local hl = character:FindFirstChildOfClass("Highlight"); if hl then destroySafe(hl) end
        local head = character:FindFirstChild("Head")
        if head then
            local bb = head:FindFirstChild("RoleBillboard"); if bb then destroySafe(bb) end
        end
    end

    State.bumpedOnce[player] = nil
    State.lastRole[player] = nil
end

local function sweepAllRoleESP()
    for plr, inst in pairs(State.highlights) do destroySafe(inst); State.highlights[plr] = nil end
    for plr, inst in pairs(State.billboards) do destroySafe(inst); State.billboards[plr] = nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Highlight") then destroySafe(obj) end
            end

            local head = char:FindFirstChild("Head")
            if head then
                for _, obj in ipairs(head:GetChildren()) do
                    if obj:IsA("BillboardGui") and obj.Name == "RoleBillboard" then
                        destroySafe(obj)
                    end
                end
            end
        end

        State.bumpedOnce[plr] = nil
        State.lastRole[plr] = nil
    end
end

local function removeAllVisuals()
    sweepAllRoleESP()
end

local function createHighlight(character, color, outlineColor)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    return highlight
end

local function createBillboard(character, text, textColor, strokeColor)
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.Name = "RoleBillboard"
    billboard.Parent = head

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = textColor
    textLabel.TextScaled = false
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = 2
    stroke.Parent = textLabel

    return billboard
end

local function hasItem(character, itemName)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return false end
    local backpack = player:FindFirstChild("Backpack")
    if character:FindFirstChild(itemName) then return true end
    if backpack and backpack:FindFirstChild(itemName) then return true end
    return false
end

local function isAlive(player)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    if character:GetAttribute("Alive") == false then return false end
    return humanoid.Health > 0
end

local function setBillboard(player, character, roleText, textColor, strokeColor)
    local head = character:FindFirstChild("Head")
    if not head then return end

    if not State.billboards[player] then
        State.billboards[player] = createBillboard(character, roleText, textColor, strokeColor)
        State.bumpedOnce[player] = false
        State.lastRole[player] = roleText
        return
    end

    local billboard = State.billboards[player]
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    if billboard.Parent ~= head then billboard.Parent = head end

    local textLabel = billboard:FindFirstChildOfClass("TextLabel")
    if textLabel then
        if textLabel.Text ~= roleText then
            textLabel.Text = roleText
            State.bumpedOnce[player] = false
            State.lastRole[player] = roleText
        end
        textLabel.TextScaled = false
        textLabel.TextSize = 14
        textLabel.TextColor3 = textColor
        local stroke = textLabel:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = strokeColor end
    end

    if not State.bumpedOnce[player] then
        local y = billboard.StudsOffset.Y
        y = math.clamp(y + 0.25, 0.5, 3)
        billboard.StudsOffset = Vector3.new(0, y, 0)
        State.bumpedOnce[player] = true
    end
end

local function setHighlight(player, character, fillColor, outlineColor)
    if not State.highlights[player] then
        State.highlights[player] = createHighlight(character, fillColor, outlineColor)
    else
        local h = State.highlights[player]
        h.FillColor = fillColor
        h.OutlineColor = outlineColor
    end
end

local function updatePlayer(player)
    if player == LocalPlayer then return end
    if not isAlive(player) then
        removeVisualsFor(player)
        return
    end

    local character = player.Character
    if not character then return end

    local hasGun   = hasItem(character, "Gun")
    local hasKnife = hasItem(character, "Knife")

    if hasKnife then
        setHighlight(player, character, Color3.new(1, 0.7, 0.7), Color3.new(0.7, 0, 0))
        setBillboard(player, character, "Murderer", Color3.new(1, 0.7, 0.7), Color3.new(0, 0, 0))
    elseif hasGun then
        setHighlight(player, character, Color3.new(0.7, 0.7, 1), Color3.new(0, 0, 0.7))
        setBillboard(player, character, "Sheriff", Color3.new(0.7, 0.7, 1), Color3.new(0, 0, 0))
    else
        setHighlight(player, character, Color3.new(0.7, 1, 0.7), Color3.new(0, 0.7, 0))
        setBillboard(player, character, "Innocent", Color3.new(0.7, 1, 0.7), Color3.new(0, 0, 0))
    end
end

local function updateAll()
    if not State.enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then updatePlayer(plr) end
    end
end

Shared.CRIMSON_ESP = {
    enable = function()
        if State.enabled then return end
        State.enabled = true

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then updatePlayer(plr) end
            State.charConns[plr] = track(plr.CharacterAdded:Connect(function()
                task.wait(1)
                updatePlayer(plr)
            end))
        end

        track(Players.PlayerAdded:Connect(function(plr)
            State.charConns[plr] = track(plr.CharacterAdded:Connect(function()
                task.wait(1)
                updatePlayer(plr)
            end))
        end))

        track(Players.PlayerRemoving:Connect(function(plr)
            if State.charConns[plr] then
                pcall(function() State.charConns[plr]:Disconnect() end)
                State.charConns[plr] = nil
            end
            removeVisualsFor(plr)
        end))

        track(RunService.Heartbeat:Connect(updateAll))
    end,

    disable = function(silent)
        State.enabled = false
        disconnectAll()
        sweepAllRoleESP()
    end
}

Shared.CRIMSON_ESP.enable()
