local CoreGui    = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"

if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local TARGET_PARENT = workspace:WaitForChild("morejayz1")
local TARGET_INDEX  = 33                 
local TARGET_NAME   = "Trap"             

local State = { highlight = nil, billboard = nil }

local function destroySafe(obj)
    if obj and obj.Destroy then
        pcall(function() obj:Destroy() end)
    end
end

local function createHighlight(model)
    local h = Instance.new("Highlight")
    h.FillColor           = Color3.new(1,0,0)  
    h.FillTransparency    = 0.5
    h.OutlineColor        = Color3.new(1,0,0)
    h.OutlineTransparency = 0
    h.Parent = model
    return h
end

local function createBillboard(model)

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    local bb = Instance.new("BillboardGui")
    bb.Name          = "RoleBillboard"
    bb.Size          = UDim2.new(0,120,0,30)
    bb.AlwaysOnTop   = true
    bb.StudsOffset   = Vector3.new(0,3,0)
    bb.Adornee       = part
    bb.Parent        = part

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = "Trap"
    lbl.TextColor3             = Color3.new(1,0,0)
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 14
    lbl.Parent                 = bb

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.new(1,0,0)
    stroke.Thickness = 2
    stroke.Parent    = lbl

    return bb
end

local function updateTrap()
    local children = TARGET_PARENT:GetChildren()
    local child    = children[TARGET_INDEX]

    if not (child and child:IsA("Model") and child.Name == TARGET_NAME) then
        destroySafe(State.highlight)  State.highlight = nil
        destroySafe(State.billboard)  State.billboard = nil
        return
    end

    if not State.highlight then
        State.highlight = createHighlight(child)
    elseif State.highlight.Parent ~= child then
        State.highlight.Parent = child
    end

    if not State.billboard then
        State.billboard = createBillboard(child)
    elseif State.billboard.Adornee ~= (child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")) then
        destroySafe(State.billboard)        
        State.billboard = createBillboard(child)
    end
end

RunService.Heartbeat:Connect(updateTrap)
