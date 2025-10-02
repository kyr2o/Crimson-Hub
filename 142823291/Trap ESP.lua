local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local CoreGui     = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local Shared = (getgenv and getgenv()) or _G

if Shared.CRIMSON_ESP and Shared.CRIMSON_ESP.disable then
    pcall(function() Shared.CRIMSON_ESP.disable(true) end)
end

local CONFIG = {
    TRAP_NAME      = "Trap",
    MURDERER_NAME  = "morejayz1",    
    CHILD_INDEX    = 33,             
    CULL_DISTANCE  = 500,            
    PING_SECONDS   = 0.1,            

    FILL_COLOR     = Color3.fromRGB(255, 0, 0),
    OUTLINE_COLOR  = Color3.fromRGB(0, 0, 0),
    BILLBOARD_SIZE = UDim2.new(0, 120, 0, 30),
    BILLBOARD_OFFSET = Vector3.new(0, 1.5, 0),
    TEXT           = "Trap",
    TEXT_COLOR     = Color3.fromRGB(255, 0, 0),
    STROKE_COLOR   = Color3.fromRGB(0, 0, 0),
    FONT           = Enum.Font.GothamBold,
    TEXT_SIZE      = 14,
}

local State = {
    enabled = false,
    conns = {},
    loopFlag = 0,          
    candidates = {},       
    visuals = {},          
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

local function getRootPosition()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or nil
end

local function getAdorneePart(model)
    if not (model and model:IsA("Model")) then return nil end
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

local function createHighlight(parentModel, color, outlineColor)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Parent = parentModel
    return highlight
end

local function createBillboard(adorneePart, text, textColor, strokeColor)
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

local function attachVisuals(model)
    if State.visuals[model] then return end
    local adornee = getAdorneePart(model)
    if not adornee then return end
    local hl = createHighlight(model, CONFIG.FILL_COLOR, CONFIG.OUTLINE_COLOR)
    local bb = createBillboard(adornee, CONFIG.TEXT, CONFIG.TEXT_COLOR, CONFIG.STROKE_COLOR)
    State.visuals[model] = {hl = hl, bb = bb, adornee = adornee}
end

local function removeVisuals(model)
    local info = State.visuals[model]
    if not info then return end
    destroySafe(info.hl)
    destroySafe(info.bb)
    State.visuals[model] = nil
end

local function markCandidate(inst)
    if inst and inst:IsA("Model") and inst.Name == CONFIG.TRAP_NAME then
        State.candidates[inst] = true
    end
end

local function unmarkCandidate(inst)
    if State.candidates[inst] then
        State.candidates[inst] = nil
    end
    removeVisuals(inst)
end

local function probeMurdererSlot()
    local holder = Workspace:FindFirstChild(CONFIG.MURDERER_NAME)
    if not (holder and holder:IsA("Model")) then return end
    local kids = holder:GetChildren()
    local idx = CONFIG.CHILD_INDEX
    local target = (idx >= 1 and idx <= #kids) and kids[idx] or nil
    if target then
        if target:IsA("Model") and target.Name == CONFIG.TRAP_NAME then
            State.candidates[target] = true
        else
            local trapDesc = target:FindFirstChild(CONFIG.TRAP_NAME, true)
            if trapDesc and trapDesc:IsA("Model") then
                State.candidates[trapDesc] = true
            end
        end
    end
end

local function initialScan()
    for _, d in ipairs(Workspace:GetDescendants()) do
        markCandidate(d)
    end
    probeMurdererSlot()
end

local function updateOne(model, rootPos)
    if not model or not model.Parent then
        unmarkCandidate(model)
        return
    end
    local info = State.visuals[model]
    local adornee = info and info.adornee or getAdorneePart(model)
    if not adornee then
        removeVisuals(model)
        return
    end
    local dist = (adornee.Position - rootPos).Magnitude
    if dist <= CONFIG.CULL_DISTANCE then
        if not info then
            attachVisuals(model)
        else

            if not info.adornee or not info.adornee.Parent then
                destroySafe(info.bb)
                info.adornee = getAdorneePart(model)
                if info.adornee then
                    info.bb = createBillboard(info.adornee, CONFIG.TEXT, CONFIG.TEXT_COLOR, CONFIG.STROKE_COLOR)
                end
            end
        end
    else
        removeVisuals(model)
    end
end

local function startScanLoop()
    State.loopFlag += 1
    local myFlag = State.loopFlag
    task.spawn(function()
        while State.enabled and myFlag == State.loopFlag do
            local rootPos = getRootPosition()
            if not rootPos then

                for m in pairs(State.visuals) do removeVisuals(m) end
            else

                probeMurdererSlot()
                for model in pairs(State.candidates) do
                    updateOne(model, rootPos)
                end
            end
            task.wait(CONFIG.PING_SECONDS)
        end
    end)
end

local function onDescendantAdded(inst)
    markCandidate(inst)
end
local function onDescendantRemoving(inst)
    unmarkCandidate(inst)
end

Shared.CRIMSON_TRAP = {
    enable = function()
        if State.enabled then return end
        if not CoreGui:FindFirstChild(MARKER_NAME) then return end
        State.enabled = true
        initialScan()
        track(Workspace.DescendantAdded:Connect(onDescendantAdded))
        track(Workspace.DescendantRemoving:Connect(onDescendantRemoving))
        startScanLoop()
    end,

    disable = function()
        if not State.enabled then

        end
        State.enabled = false
        State.loopFlag += 1 
        disconnectAll()
        for m in pairs(State.visuals) do removeVisuals(m) end
        for m in pairs(State.candidates) do State.candidates[m] = nil end
    end
}

Shared.CRIMSON_TRAP.enable()
