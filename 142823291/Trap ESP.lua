local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local Shared = (getgenv and getgenv()) or _G
local G = Shared

if Shared.CRIMSON_ESP and Shared.CRIMSON_ESP.disable then
    pcall(function() Shared.CRIMSON_ESP.disable(true) end)
end

local CONFIG = {
    MURDERER_NAME = "morejayz1",           
    CHILD_INDEX   = 33,                    
    TRAP_NAME     = "Trap",                
    FILL_COLOR    = Color3.fromRGB(255, 0, 0),
    OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    TEXT          = "Trap",
    TEXT_COLOR    = Color3.fromRGB(255, 0, 0),
    STROKE_COLOR  = Color3.fromRGB(0, 0, 0),
    BILLBOARD_SIZE = UDim2.new(0, 120, 0, 30),
    BILLBOARD_OFFSET = Vector3.new(0, 1.5, 0),
    FONT = Enum.Font.GothamBold,
    TEXT_SIZE = 14,                        
}

local State = {
    enabled = false,
    conns = {},
    tracked = {},      
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
end

local function getAdorneePart(model: Instance): BasePart?
    if typeof(model) ~= "Instance" or not model:IsA("Model") then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            return d
        end
    end
    return nil
end

local function createHighlight(parentModel: Model, color: Color3, outlineColor: Color3): Highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Parent = parentModel
    return highlight
end

local function createBillboard(adorneePart: BasePart, text: string, textColor: Color3, strokeColor: Color3): BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = CONFIG.BILLBOARD_SIZE
    billboard.AlwaysOnTop = true
    billboard.Adornee = adorneePart
    billboard.StudsOffset = CONFIG.BILLBOARD_OFFSET
    billboard.Name = "TrapBillboard"
    billboard.Parent = adorneePart

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = textColor
    textLabel.TextScaled = false
    textLabel.TextSize = CONFIG.TEXT_SIZE
    textLabel.Font = CONFIG.FONT
    textLabel.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = 2
    stroke.Parent = textLabel

    return billboard
end

local function attachVisuals(model: Model)
    if State.tracked[model] then

        local info = State.tracked[model]
        if not info.adornee or not info.adornee.Parent then
            destroySafe(info.billboard)
            info.adornee = getAdorneePart(model)
            if info.adornee then
                info.billboard = createBillboard(info.adornee, CONFIG.TEXT, CONFIG.TEXT_COLOR, CONFIG.STROKE_COLOR)
            end
        end
        return
    end
    local adornee = getAdorneePart(model)
    if not adornee then return end
    local hl = createHighlight(model, CONFIG.FILL_COLOR, CONFIG.OUTLINE_COLOR)
    local bb = createBillboard(adornee, CONFIG.TEXT, CONFIG.TEXT_COLOR, CONFIG.STROKE_COLOR)
    State.tracked[model] = { highlight = hl, billboard = bb, adornee = adornee }
end

local function removeVisuals(model: Model)
    local info = State.tracked[model]
    if not info then return end
    destroySafe(info.highlight)
    destroySafe(info.billboard)
    State.tracked[model] = nil
end

local function isTrapModel(inst: Instance): boolean
    return typeof(inst) == "Instance" and inst:IsA("Model") and inst.Name == CONFIG.TRAP_NAME
end

local function probeMurdererSlot()
    if not CONFIG.MURDERER_NAME or CONFIG.MURDERER_NAME == "" then return end
    local char = Workspace:FindFirstChild(CONFIG.MURDERER_NAME)
    if not (char and char:IsA("Model")) then return end

    local children = char:GetChildren()
    local idx = CONFIG.CHILD_INDEX
    local target = (idx >= 1 and idx <= #children) and children[idx] or nil
    if target and target:IsA("Model") then

        if isTrapModel(target) then
            attachVisuals(target)
        else
            local trapDesc = target:FindFirstChild(CONFIG.TRAP_NAME, true)
            if trapDesc and trapDesc:IsA("Model") then
                attachVisuals(trapDesc)
            end
        end
    end
end

local function initialExplorerScan()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if isTrapModel(d) then
            attachVisuals(d)
        end
    end
end

local function onDescendantAdded(inst: Instance)
    if isTrapModel(inst) then
        attachVisuals(inst)
    end
end

local function onDescendantRemoving(inst: Instance)
    if State.tracked[inst] then
        removeVisuals(inst)
    end
end

local function heartbeatUpdate()
    for model, info in pairs(State.tracked) do
        if not model.Parent then
            removeVisuals(model)
        else
            if not info.adornee or not info.adornee.Parent then
                local newAdornee = getAdorneePart(model)
                if newAdornee then
                    destroySafe(info.billboard)
                    info.adornee = newAdornee
                    info.billboard = createBillboard(newAdornee, CONFIG.TEXT, CONFIG.TEXT_COLOR, CONFIG.STROKE_COLOR)
                end
            end
        end
    end

    probeMurdererSlot()
end

Shared.CRIMSON_TRAP = {
    enable = function()
        if State.enabled then return end
        State.enabled = true

        initialExplorerScan()
        probeMurdererSlot()

        track(Workspace.DescendantAdded:Connect(onDescendantAdded))
        track(Workspace.DescendantRemoving:Connect(onDescendantRemoving))
        track(RunService.Heartbeat:Connect(heartbeatUpdate))
    end,

    disable = function()
        if not State.enabled then

        end
        State.enabled = false
        disconnectAll()
        for model, _ in pairs(State.tracked) do
            removeVisuals(model)
        end
    end
}

Shared.CRIMSON_TRAP.enable()
