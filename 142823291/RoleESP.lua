local CoreGui     = game:GetService("CoreGui")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local Shared = (getgenv and getgenv()) or _G
if Shared.CRIMSON_ESP and Shared.CRIMSON_ESP.disable then
    pcall(function() Shared.CRIMSON_ESP.disable(true) end)
end

local LocalPlayer = Players.LocalPlayer

local State = {
    enabled     = false,
    conns       = {},
    charConns   = {},
    highlights  = {},
    billboards  = {},
    bumpedOnce  = {},
    lastRole    = {},
}

local function track(conn)
    if conn then table.insert(State.conns, conn) end
    return conn
end

local function destroySafe(obj)
    if obj and obj.Destroy then
        pcall(function() obj:Destroy() end)
    end
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
    -- destroy tracked instances
    if State.highlights[player] then
        destroySafe(State.highlights[player])
        State.highlights[player] = nil
    end
    if State.billboards[player] then
        destroySafe(State.billboards[player])
        State.billboards[player] = nil
    end

    -- destroy any stray GUI/Highlight on character
    local char = player.Character
    if char then
        local hl = char:FindFirstChildOfClass("Highlight")
        if hl then destroySafe(hl) end
        local head = char:FindFirstChild("Head")
        if head then
            local bb = head:FindFirstChild("RoleBillboard")
            if bb then destroySafe(bb) end
        end
    end

    State.bumpedOnce[player] = nil
    State.lastRole[player]  = nil
end

local function sweepAllRoleESP()
    for p, inst in pairs(State.highlights) do
        destroySafe(inst)
        State.highlights[p] = nil
    end
    for p, inst in pairs(State.billboards) do
        destroySafe(inst)
        State.billboards[p] = nil
    end
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
        State.lastRole[plr]  = nil
    end
end

local function removeAllVisuals()
    sweepAllRoleESP()
end

local function createHighlight(character, color, outlineColor)
    local hl = Instance.new("Highlight")
    hl.FillColor        = color
    hl.FillTransparency = 0.5
    hl.OutlineColor     = outlineColor
    hl.OutlineTransparency = 0
    hl.Parent           = character
    return hl
end

local function createBillboard(character, text, textColor, strokeColor)
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local bg = Instance.new("BillboardGui")
    bg.Name       = "RoleBillboard"
    bg.Size       = UDim2.new(0, 120, 0, 30)
    bg.Adornee    = head
    bg.StudsOffset= Vector3.new(0, 1.5, 0)
    bg.AlwaysOnTop = true
    bg.Parent     = head

    local tl = Instance.new("TextLabel")
    tl.Size               = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text               = text
    tl.TextColor3         = textColor
    tl.TextSize           = 14
    tl.TextScaled         = false
    tl.Font               = Enum.Font.GothamBold
    tl.Parent             = bg

    local stroke = Instance.new("UIStroke")
    stroke.Color    = strokeColor
    stroke.Thickness= 2
    stroke.Parent   = tl

    return bg
end

local function hasItem(character, itemName)
    local plr = Players:GetPlayerFromCharacter(character)
    if not plr then return false end
    if character:FindFirstChild(itemName) then return true end
    local bp = plr:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(itemName) then return true end
    return false
end

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return false end
    if char:GetAttribute("Alive") == false then return false end
    return hum.Health > 0
end

local function setBillboard(player, character, roleText, textColor, strokeColor)
    local head = character:FindFirstChild("Head")
    if not head then return end

    if not State.billboards[player] then
        State.billboards[player] = createBillboard(character, roleText, textColor, strokeColor)
        State.bumpedOnce[player] = false
        State.lastRole[player]  = roleText
        return
    end

    local bg = State.billboards[player]
    bg.Adornee = head
    if bg.Parent ~= head then bg.Parent = head end
    bg.AlwaysOnTop = true

    local tl = bg:FindFirstChildOfClass("TextLabel")
    if tl then
        if tl.Text ~= roleText then
            tl.Text = roleText
            State.bumpedOnce[player] = false
            State.lastRole[player]  = roleText
        end
        tl.TextColor3 = textColor
        tl.TextSize   = 14
        tl.TextScaled = false
        local stroke = tl:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = strokeColor end
    end

    if not State.bumpedOnce[player] then
        local y = bg.StudsOffset.Y
        y = math.clamp(y + 0.25, 0.5, 3)
        bg.StudsOffset = Vector3.new(0, y, 0)
        State.bumpedOnce[player] = true
    end
end

local function setHighlight(player, character, fillColor, outlineColor)
    if not State.highlights[player] then
        State.highlights[player] = createHighlight(character, fillColor, outlineColor)
    else
        local hl = State.highlights[player]
        hl.FillColor    = fillColor
        hl.OutlineColor = outlineColor
    end
end

local function updatePlayer(player)
    if player == LocalPlayer then return end
    if not isAlive(player) then
        removeVisualsFor(player)
        return
    end
    local char = player.Character
    if not char then return end

    local knife = hasItem(char, "Knife")
    local gun   = hasItem(char, "Gun")

    if knife then
        setHighlight(player, char, Color3.new(1,0.7,0.7), Color3.new(0.7,0,0))
        setBillboard(player, char, "Murderer", Color3.new(1,0.7,0.7), Color3.new(0,0,0))
    elseif gun then
        setHighlight(player, char, Color3.new(0.7,0.7,1), Color3.new(0,0,0.7))
        setBillboard(player, char, "Sheriff", Color3.new(0.7,0.7,1), Color3.new(0,0,0))
    else
        setHighlight(player, char, Color3.new(0.7,1,0.7), Color3.new(0,0.7,0))
        setBillboard(player, char, "Innocent", Color3.new(0.7,1,0.7), Color3.new(0,0,0))
    end
end

local function updateAll()
    if not State.enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        updatePlayer(plr)
    end
end

local function disableRoleESP(silent)
    State.enabled = false
    disconnectAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        removeVisualsFor(plr)
    end
    for plr in pairs(State.highlights) do State.highlights[plr] = nil end
    for plr in pairs(State.billboards) do State.billboards[plr] = nil end
    if not silent then
        -- notification placeholder
    end
end

Shared.CRIMSON_ESP = {
    enable = function()
        if State.enabled then return end
        State.enabled = true
        for _, plr in ipairs(Players:GetPlayers()) do
            updatePlayer(plr)
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
    disable = disableRoleESP
}

Shared.CRIMSON_ESP.enable()
