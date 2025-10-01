local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local highlights = {}
local billboards = {}
local bumpedOnce = {}
local lastRole = {}

local function removeHighlight(player)
	if highlights[player] then
		highlights[player]:Destroy()
		highlights[player] = nil
	end
	if billboards[player] then
		billboards[player]:Destroy()
		billboards[player] = nil
	end
	bumpedOnce[player] = nil
	lastRole[player] = nil
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
	local backpack = player.Backpack
	if character:FindFirstChild(itemName) then
		return true
	end
	if backpack and backpack:FindFirstChild(itemName) then
		return true
	end
	return false
end

local function isAlive(player)
	if not player.Character then return false end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return false end
	if player.Character:GetAttribute("Alive") == false then
		return false
	end
	if humanoid.Health <= 0 then
		return false
	end
	return true
end

local function setBillboard(player, character, roleText, textColor, strokeColor)
	local head = character:FindFirstChild("Head")
	if not head then return end

	if not billboards[player] then
		billboards[player] = createBillboard(character, roleText, textColor, strokeColor)
		bumpedOnce[player] = false
		lastRole[player] = roleText
	else
		local billboard = billboards[player]
		billboard.AlwaysOnTop = true
		billboard.Adornee = head
		if billboard.Parent ~= head then
			billboard.Parent = head
		end
		local textLabel = billboard:FindFirstChildOfClass("TextLabel")
		if textLabel then
			if textLabel.Text ~= roleText then
				textLabel.Text = roleText
				bumpedOnce[player] = false
				lastRole[player] = roleText
			end
			textLabel.TextScaled = false
			textLabel.TextSize = 14
			textLabel.TextColor3 = textColor
			local stroke = textLabel:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = strokeColor
			end
		end
		if not bumpedOnce[player] then
			local y = billboard.StudsOffset.Y
			y = math.clamp(y + 0.25, 0.5, 3)
			billboard.StudsOffset = Vector3.new(0, y, 0)
			bumpedOnce[player] = true
		end
	end
end

local function clearBillboard(player)
	if billboards[player] then
		billboards[player]:Destroy()
		billboards[player] = nil
	end
	bumpedOnce[player] = nil
	lastRole[player] = nil
end

local function setHighlight(player, character, fillColor, outlineColor)
	if not highlights[player] then
		highlights[player] = createHighlight(character, fillColor, outlineColor)
	else
		local h = highlights[player]
		h.FillColor = fillColor
		h.OutlineColor = outlineColor
	end
end

local function updatePlayerHighlight(player)
	if player == LocalPlayer then return end
	if not isAlive(player) then
		removeHighlight(player)
		return
	end

	local character = player.Character
	if not character then return end

	local hasGun = hasItem(character, "Gun")
	local hasKnife = hasItem(character, "Knife")

	if hasKnife then
		setHighlight(player, character, Color3.new(1, 0.7, 0.7), Color3.new(0.7, 0, 0))
		setBillboard(player, character, "Murderer", Color3.new(1, 0.7, 0.7), Color3.new(0, 0, 0))
	elseif hasGun then
		setHighlight(player, character, Color3.new(0.7, 0.7, 1), Color3.new(0, 0, 0.7))
		setBillboard(player, character, "Sheriff", Color3.new(0.7, 0.7, 1), Color3.new(0, 0, 0))
	else
		setHighlight(player, character, Color3.new(0.7, 1, 0.7), Color3.new(0, 0.7, 0))
		clearBillboard(player)
	end
end

local function updateAllPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			updatePlayerHighlight(player)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		updatePlayerHighlight(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removeHighlight(player)
end)

for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		updatePlayerHighlight(player)
	end
	player.CharacterAdded:Connect(function()
		task.wait(1)
		updatePlayerHighlight(player)
	end)
end

RunService.Heartbeat:Connect(function()
	updateAllPlayers()
end)
