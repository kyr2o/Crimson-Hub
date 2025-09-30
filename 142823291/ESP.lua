local Players = game:GetService("Players")

local COLORS = {
	Murderer = {fill = Color3.fromRGB(255,120,120), outline = Color3.fromRGB(150,0,0)},
	Sheriff = {fill = Color3.fromRGB(120,180,255), outline = Color3.fromRGB(0,60,150)},
	Innocent = {fill = Color3.fromRGB(150,255,150), outline = Color3.fromRGB(0,120,0)},
}

local function hasItem(player, itemName)
	if player:GetAttribute(itemName) then
		return true
	end
	local character = player.Character
	if character then
		local item = character:FindFirstChild(itemName)
		if item and item:IsA("Tool") then
			return true
		end
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and child.Name == itemName then
				return true
			end
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local item = backpack:FindFirstChild(itemName)
		if item and item:IsA("Tool") then
			return true
		end
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and child.Name == itemName then
				return true
			end
		end
	end
	return false
end

local function getRole(player)
	if hasItem(player, "Knife") then
		return "Murderer"
	elseif hasItem(player, "Gun") then
		return "Sheriff"
	else
		return "Innocent"
	end
end

local function removeAllESPVisuals()
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        local char = plr.Character
        if char then
            local hl = char:FindFirstChild("RoleHighlight")
            if hl then hl:Destroy() end
        end
        local head = char and char:FindFirstChild("Head")
        if head then
            local bb = head:FindFirstChild("RoleBillboard")
            if bb then bb:Destroy() end
        end
    end
end


local function ensureBillboard(head)
	local billboard = head:FindFirstChild("RoleBillboard")
	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "RoleBillboard"
		billboard.Adornee = head
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.new(0, 200, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.Parent = head
	end
	local label = billboard:FindFirstChild("RoleLabel")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "RoleLabel"
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.TextScaled = false
		label.TextSize = 20
		label.Font = Enum.Font.SourceSansSemibold
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.Parent = billboard
	end
	return billboard, billboard:FindFirstChild("RoleLabel")
end

local function removeBillboard(head)
	local billboard = head and head:FindFirstChild("RoleBillboard")
	if billboard then
		billboard:Destroy()
	end
end

local function ensureHighlight(character)
	local hl = character:FindFirstChild("RoleHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "RoleHighlight"
		hl.Adornee = character
		hl.Parent = character
	end
	return hl
end

local function removeHighlight(character)
	local hl = character and character:FindFirstChild("RoleHighlight")
	if hl then
		hl:Destroy()
	end
end

local function applyVisuals(player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	local alive = player:GetAttribute("Alive") == true
	if not alive then
		removeHighlight(character)
		removeBillboard(head)
		return
	end
	local role = getRole(player)
	local colors = COLORS[role]
	local hl = ensureHighlight(character)
	hl.Adornee = character
	hl.FillColor = colors.fill
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0
	hl.OutlineColor = colors.outline
	if role == "Murderer" or role == "Sheriff" then
		if head then
			local billboard, label = ensureBillboard(head)
			if label then
				label.Text = role
				label.TextColor3 = colors.fill
			end
		end
	else
		removeBillboard(head)
	end
end

local function trackPlayer(player)
	local function onCharacterAdded(character)
		task.defer(applyVisuals, player)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.defer(applyVisuals, player)
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				task.defer(applyVisuals, player)
			end
		end)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	local function watchBackpack(bp)
		bp.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.defer(applyVisuals, player)
			end
		end)
		bp.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				task.defer(applyVisuals, player)
			end
		end)
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		watchBackpack(backpack)
	end
	player.ChildAdded:Connect(function(child)
		if child.Name == "Backpack" then
			watchBackpack(child)
		end
	end)
	player.AttributeChanged:Connect(function(attr)
		if attr == "Alive" or attr == "Gun" or attr == "Knife" then
			task.defer(applyVisuals, player)
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	trackPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
	trackPlayer(plr)
end)
