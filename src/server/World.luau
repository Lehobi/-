-- The complete starter map is generated from original parts; no downloaded assets.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimalFactory =
	require(ReplicatedStorage:WaitForChild("GoofyEgg"):WaitForChild("Shared"):WaitForChild("AnimalFactory"))

local World = {}
World.__index = World

local COLORS = {
	grass = Color3.fromRGB(135, 201, 121),
	path = Color3.fromRGB(249, 226, 169),
	edge = Color3.fromRGB(255, 248, 221),
	ink = Color3.fromRGB(37, 54, 72),
	wood = Color3.fromRGB(143, 102, 75),
	leaf = Color3.fromRGB(77, 166, 108),
	mint = Color3.fromRGB(102, 222, 183),
	white = Color3.fromRGB(255, 254, 242),
}

local BASE_COLORS = {
	Color3.fromRGB(117, 203, 239),
	Color3.fromRGB(255, 185, 119),
	Color3.fromRGB(204, 170, 244),
	Color3.fromRGB(244, 159, 190),
	Color3.fromRGB(157, 218, 135),
}

local function colorFrom(value)
	if typeof(value) == "Color3" then
		return value
	end
	value = value or {}
	return Color3.fromRGB(value.r or value[1] or 140, value.g or value[2] or 210, value.b or value[3] or 140)
end

local function folder(name, parent)
	local result = Instance.new("Folder")
	result.Name = name
	result.Parent = parent
	return result
end

local function model(name, parent)
	local result = Instance.new("Model")
	result.Name = name
	result.Parent = parent
	return result
end

local function part(parent, name, size, position, color, collidable, shape, rotation)
	local result = Instance.new("Part")
	result.Name = name
	result.Size = size
	result.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	result.Color = color
	result.Material = Enum.Material.SmoothPlastic
	result.Shape = shape or Enum.PartType.Block
	result.Anchored = true
	result.CanCollide = collidable == true
	result.CanTouch = false
	result.CanQuery = collidable == true
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result.Parent = parent
	return result
end

local function disc(parent, name, diameter, thickness, position, color, collidable)
	return part(
		parent,
		name,
		Vector3.new(thickness, diameter, diameter),
		position,
		color,
		collidable,
		Enum.PartType.Cylinder,
		CFrame.Angles(0, 0, math.pi / 2)
	)
end

local function billboard(parent, name, width, height, offset, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = parent
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or 95
	gui.Parent = parent
	return gui
end

local function textLabel(parent, name, text, color, y, height)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, height or 1)
	label.Position = UDim2.fromScale(0, y or 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or COLORS.white
	label.TextStrokeColor3 = COLORS.ink
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function prompt(parent, name, action, object, holdDuration)
	local result = Instance.new("ProximityPrompt")
	result.Name = name
	result.ActionText = action
	result.ObjectText = object
	result.HoldDuration = holdDuration or 0.25
	result.MaxActivationDistance = 11
	result.RequiresLineOfSight = false
	result.KeyboardKeyCode = Enum.KeyCode.E
	result.GamepadKeyCode = Enum.KeyCode.ButtonX
	result.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	result.Parent = parent
	return result
end

local function sign(parent, name, position, text, color, width, maxDistance)
	part(
		parent,
		name .. "Post",
		Vector3.new(0.6, 5, 0.6),
		position + Vector3.new(0, 2.5, 0),
		COLORS.wood,
		false
	)
	local board = part(
		parent,
		name,
		Vector3.new(width or 12, 3, 0.65),
		position + Vector3.new(0, 5, 0),
		color or COLORS.ink,
		false
	)
	local gui = billboard(board, name .. "Billboard", 280, 65, Vector3.zero, maxDistance or 110)
	return textLabel(gui, "Title", text, COLORS.white)
end

local function tree(parent, x, z, scale)
	local base = Vector3.new(x, 0, z)
	local treeModel = model("LollipopTree", parent)
	part(
		treeModel,
		"Trunk",
		Vector3.new(1.8, 8, 1.8) * scale,
		base + Vector3.new(0, 4 * scale, 0),
		COLORS.wood,
		false
	)
	part(
		treeModel,
		"Crown",
		Vector3.new(8, 8, 8) * scale,
		base + Vector3.new(0, 10 * scale, 0),
		COLORS.leaf,
		false,
		Enum.PartType.Ball
	)
	part(
		treeModel,
		"CrownLight",
		Vector3.new(5, 5, 5) * scale,
		base + Vector3.new(-2 * scale, 12 * scale, -scale),
		COLORS.leaf:Lerp(COLORS.white, 0.13),
		false,
		Enum.PartType.Ball
	)
end

local function shrubs(parent, x, z, color)
	for index = 1, 3 do
		part(
			parent,
			"Shrub",
			Vector3.new(3.8, 3.2, 3.5),
			Vector3.new(x + (index - 2) * 2.8, 1.2, z),
			color or COLORS.leaf,
			false,
			Enum.PartType.Ball
		)
	end
end

local function buildGround(root)
	local map = folder("Landscape", root)
	local ground = part(map, "Meadow", Vector3.new(360, 2, 760), Vector3.new(0, -1, 85), COLORS.grass, true)
	ground.Material = Enum.Material.Grass
	part(map, "MainPath", Vector3.new(64, 0.16, 405), Vector3.new(0, 0.08, 200), COLORS.path, true)
	part(map, "LobbyPlaza", Vector3.new(235, 0.2, 45), Vector3.new(0, 0.1, 21), COLORS.path, true)
	for _, x in ipairs({ -33, 33 }) do
		part(map, "PathTrim", Vector3.new(1.5, 0.22, 405), Vector3.new(x, 0.11, 200), COLORS.edge, false)
	end
	for _, x in ipairs({ -179, 179 }) do
		part(map, "Boundary", Vector3.new(2, 4, 760), Vector3.new(x, 2, 85), COLORS.leaf, true)
	end
	for _, z in ipairs({ -294, 464 }) do
		part(map, "Boundary", Vector3.new(360, 4, 2), Vector3.new(0, 2, z), COLORS.leaf, true)
	end
	local decor = folder("Decorations", root)
	for index = 1, 10 do
		local z = -235 + index * 63
		tree(decor, -153, z, 0.8 + (index % 3) * 0.16)
		tree(decor, 151, z + 18, 0.95 + (index % 2) * 0.18)
	end
	for _, z in ipairs({ 72, 220, 395 }) do
		shrubs(decor, -51, z)
		shrubs(decor, 51, z)
	end
	for _, x in ipairs({ -48, 48 }) do
		part(decor, "WelcomeArchPost", Vector3.new(2, 17, 2), Vector3.new(x, 8.5, 52), COLORS.wood, false)
	end
	local arch =
		part(decor, "WelcomeArch", Vector3.new(100, 5, 2), Vector3.new(0, 16, 52), COLORS.mint, false)
	textLabel(
		billboard(arch, "Welcome", 520, 65, Vector3.zero, 180),
		"Title",
		"STEAL A GOOFY EGG",
		COLORS.white
	)
	sign(
		decor,
		"HowTo",
		Vector3.new(-65, 0, 41),
		"STEAL → ESCAPE → HATCH\nBring eggs to your base!",
		COLORS.ink,
		23,
		80
	)
	sign(
		decor,
		"Route",
		Vector3.new(65, 0, 41),
		"FOLLOW THE PATH\nSneak past the guardians!",
		COLORS.ink,
		23,
		80
	)
	for _, z in ipairs({ 86, 232, 389 }) do
		local arrow = part(
			decor,
			"RouteArrow",
			Vector3.new(0.35, 0.06, 4),
			Vector3.new(0, 0.21, z),
			COLORS.white,
			false
		)
		arrow.Transparency = 0.1
		for _, side in ipairs({ -1, 1 }) do
			part(
				decor,
				"ArrowTip",
				Vector3.new(0.35, 0.06, 2.6),
				Vector3.new(side * 0.85, 0.21, z + 1.05),
				COLORS.white,
				false,
				nil,
				CFrame.Angles(0, math.rad(side * -43), 0)
			)
		end
	end
end

local function buildBase(config, parent, id, position)
	local baseModel = model("Base_" .. id, parent)
	baseModel:SetAttribute("BaseId", id)
	baseModel:SetAttribute("OwnerUserId", 0)
	local center = Vector3.new(position.x, 0, position.z)
	local color = BASE_COLORS[id] or COLORS.mint
	part(baseModel, "Foundation", Vector3.new(64, 0.9, 56), center + Vector3.new(0, 0.05, 0), color, true)
	part(baseModel, "Floor", Vector3.new(61, 0.12, 53), center + Vector3.new(0, 0.56, 0), COLORS.edge, true)
	part(baseModel, "BackRail", Vector3.new(64, 2, 1), center + Vector3.new(0, 1.45, -27.5), color, true)
	for _, side in ipairs({ -1, 1 }) do
		part(
			baseModel,
			"SideRail",
			Vector3.new(1, 2, 56),
			center + Vector3.new(side * 31.5, 1.45, 0),
			color,
			true
		)
		part(
			baseModel,
			"EntrancePost",
			Vector3.new(1.5, 6, 1.5),
			center + Vector3.new(side * 12, 3, 27),
			color,
			false
		)
	end
	local ownerSign =
		sign(baseModel, "OwnerSign", center + Vector3.new(0, 0, -26), "UNCLAIMED BASE", color, 25, 125)
	local hatchFolder = folder("Hatches", baseModel)
	local animalFolder = folder("Animals", baseModel)
	local slots = {}
	for index = 1, config.hatchSlots do
		local x = (index - (config.hatchSlots + 1) / 2) * 18
		local slot =
			disc(baseModel, "HatchSlot_" .. index, 9.3, 0.3, center + Vector3.new(x, 0.78, -12), color, false)
		slot:SetAttribute("SlotIndex", index)
		slots[index] = slot
		local gui = billboard(slot, "SlotLabel", 120, 25, Vector3.new(0, 0.55, 0), 46)
		textLabel(gui, "Title", "HATCH " .. index, COLORS.ink).TextStrokeTransparency = 1
	end
	local animalSpots = {}
	for index = 1, config.maxAnimals do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local x = (column - 1.5) * 12
		local z = 5 + row * 9
		disc(
			baseModel,
			"AnimalSpot_" .. index,
			6.6,
			0.18,
			center + Vector3.new(x, 0.73, z),
			color:Lerp(COLORS.white, 0.55),
			false
		)
		animalSpots[index] = CFrame.new(center + Vector3.new(x, 0.85, z)) * CFrame.Angles(0, math.pi, 0)
	end
	local deposit =
		disc(baseModel, "DepositPad", 9, 0.25, center + Vector3.new(0, 0.79, 0), COLORS.mint, false)
	local depositPrompt = prompt(deposit, "DepositEgg", "Hatch egg", "Your hatchery", 0.35)
	local depositGui = billboard(deposit, "DepositLabel", 170, 42, Vector3.new(0, 2.5, 0), 50)
	textLabel(depositGui, "Title", "BRING EGG HERE", COLORS.white)
	local shop =
		part(baseModel, "SpeedShop", Vector3.new(5, 3, 4), center + Vector3.new(-24, 2.1, 20), color, false)
	part(
		baseModel,
		"ShopTop",
		Vector3.new(6, 0.45, 5),
		center + Vector3.new(-24, 3.85, 20),
		COLORS.ink,
		false
	)
	local shopGui = billboard(shop, "ShopLabel", 160, 52, Vector3.new(0, 3.4, 0), 65)
	textLabel(shopGui, "Title", "SPEED SHOP\nRun a little faster", COLORS.white)
	local upgradePrompt = prompt(shop, "UpgradeSpeed", "Upgrade speed", "Speed shop", 0.35)
	return {
		id = id,
		center = center,
		spawn = CFrame.lookAt(center + Vector3.new(0, 4, 19), center + Vector3.new(0, 4, 35)),
		model = baseModel,
		slots = slots,
		animalSpots = animalSpots,
		sign = ownerSign,
		depositPrompt = depositPrompt,
		upgradePrompt = upgradePrompt,
		hatchFolder = hatchFolder,
		animalFolder = animalFolder,
		hatches = {},
	}
end

local function buildZone(parent, zone)
	local zoneModel = model("Zone_" .. zone.id, parent)
	zoneModel:SetAttribute("ZoneId", zone.id)
	local color = colorFrom(zone.color)
	local center = Vector3.new(zone.position.x, 0, zone.position.z)
	part(
		zoneModel,
		"ZoneCourt",
		Vector3.new(85, 0.15, 86),
		center + Vector3.new(0, 0.15, 0),
		color:Lerp(COLORS.white, 0.65),
		true
	)
	for _, side in ipairs({ -1, 1 }) do
		part(
			zoneModel,
			"ZoneEdge",
			Vector3.new(1.2, 0.6, 86),
			center + Vector3.new(side * 43, 0.3, 0),
			color,
			false
		)
		shrubs(zoneModel, center.X + side * 55, center.Z - 23, color:Lerp(COLORS.leaf, 0.6))
	end
	local levelText = zone.requiredLevel > 1 and (" · LEVEL " .. zone.requiredLevel) or " · START HERE"
	sign(
		zoneModel,
		"ZoneSign",
		center + Vector3.new(-26, 0, -35),
		string.upper(zone.name) .. levelText,
		color,
		26,
		110
	)
	local eggPosition = center + Vector3.new(0, 2.5, 0)
	disc(zoneModel, "EggPlinth", 9, 1.1, center + Vector3.new(0, 0.75, 0), COLORS.edge, true)
	disc(zoneModel, "EggRing", 10, 0.15, center + Vector3.new(0, 0.32, 0), color, false)
	local egg = AnimalFactory.egg(zone.color, "WildEgg")
	egg:SetAttribute("ZoneId", zone.id)
	egg:SetAttribute("Available", true)
	egg:PivotTo(CFrame.new(eggPosition))
	egg.Parent = zoneModel
	local stealPrompt = prompt(egg.PrimaryPart, "StealEgg", "Steal egg", zone.name, 0.65)
	local eggGui = billboard(egg.PrimaryPart, "EggBillboard", 190, 43, Vector3.new(0, 3, 0), 72)
	textLabel(eggGui, "Title", "GOOFY EGG\nGrab it. Run!", COLORS.white)
	local homePosition = center + Vector3.new(zone.guardianOffset or 20, 0.3, 0)
	local home = CFrame.lookAt(homePosition, Vector3.new(center.X, homePosition.Y, center.Z))
	local guardian = AnimalFactory.create(zone.guardian, zone.color, "Guardian")
	guardian:SetAttribute("VisualRole", "Guardian")
	guardian:SetAttribute("ZoneId", zone.id)
	guardian:SetAttribute("State", "Idle")
	guardian:SetAttribute("HomeX", homePosition.X)
	guardian:SetAttribute("HomeY", homePosition.Y)
	guardian:SetAttribute("HomeZ", homePosition.Z)
	guardian:ScaleTo(1.65)
	guardian:PivotTo(home)
	guardian.Parent = zoneModel
	local guardianGui = billboard(
		guardian.PrimaryPart,
		"GuardianBillboard",
		180,
		48,
		Vector3.new(0, zone.guardian == "rabbit" and 7.5 or 4.5, 0),
		85
	)
	textLabel(guardianGui, "Title", string.upper(zone.guardian) .. " GUARDIAN", COLORS.white, 0, 0.56)
	textLabel(guardianGui, "State", "Protecting the egg", COLORS.white, 0.6, 0.4)
	return {
		config = zone,
		home = home,
		egg = egg,
		prompt = stealPrompt,
		guardian = guardian,
		model = zoneModel,
	}
end

function World.build(config)
	local previous = workspace:FindFirstChild("GoofyEggWorld")
	if previous then
		previous:Destroy()
	end
	local root = folder("GoofyEggWorld", workspace)
	local self = setmetatable({ config = config, root = root, bases = {}, zones = {} }, World)
	buildGround(root)
	local basesFolder = folder("Bases", root)
	for id, position in ipairs(config.basePositions) do
		self.bases[id] = buildBase(config, basesFolder, id, position)
	end
	local zonesFolder = folder("Zones", root)
	for _, zone in ipairs(config.zones) do
		self.zones[zone.id] = buildZone(zonesFolder, zone)
	end
	return self
end

function World:setBaseOwner(baseId, player)
	local base = self.bases[baseId]
	if not base then
		return
	end
	base.model:SetAttribute("OwnerUserId", player and player.UserId or 0)
	base.sign.Text = player and (player.DisplayName .. "'S BASE") or "UNCLAIMED BASE"
	base.depositPrompt.ObjectText = player and (player.DisplayName .. "'s hatchery") or "Unclaimed hatchery"
	if not player then
		for index = 1, self.config.hatchSlots do
			self:clearHatch(baseId, index)
		end
		self:setAnimals(baseId, {})
	end
end

function World:showHatch(baseId, slotIndex, zoneId, readyAt)
	local base = self.bases[baseId]
	local zone = self.zones[zoneId]
	if not base or not base.slots[slotIndex] or not zone then
		return
	end
	self:clearHatch(baseId, slotIndex)
	local egg = AnimalFactory.egg(zone.config.color, "Hatch_" .. slotIndex)
	egg:SetAttribute("VisualRole", "HatchingEgg")
	egg:SetAttribute("ReadyAt", readyAt)
	egg:SetAttribute("ZoneId", zoneId)
	egg:SetAttribute("BaseId", baseId)
	egg:SetAttribute("SlotIndex", slotIndex)
	egg:PivotTo(CFrame.new(base.slots[slotIndex].Position + Vector3.new(0, 2, 0)))
	egg.Parent = base.hatchFolder
	local gui = billboard(egg.PrimaryPart, "HatchBillboard", 190, 64, Vector3.new(0, 3.4, 0), 85)
	textLabel(gui, "Title", zone.config.name, COLORS.white, 0, 0.5)
	textLabel(
		gui,
		"Countdown",
		math.max(0, math.ceil(readyAt - workspace:GetServerTimeNow())) .. "s",
		COLORS.mint,
		0.53,
		0.47
	)
	base.hatches[slotIndex] = egg
end

function World:clearHatch(baseId, slotIndex)
	local base = self.bases[baseId]
	if not base then
		return
	end
	local egg = base.hatches[slotIndex]
	if egg then
		egg:Destroy()
		base.hatches[slotIndex] = nil
	end
end

function World:setAnimals(baseId, animals)
	local base = self.bases[baseId]
	if not base then
		return
	end
	base.animalFolder:ClearAllChildren()
	for index, owned in ipairs(animals) do
		local animalConfig = self.config.animals[owned.id]
		local spot = base.animalSpots[index]
		if animalConfig and spot then
			local animal = AnimalFactory.create(animalConfig.species, animalConfig.color, animalConfig.name)
			animal:SetAttribute("AnimalId", owned.id)
			animal:SetAttribute("BaseId", baseId)
			animal:SetAttribute("SlotIndex", index)
			animal:SetAttribute("Personality", animalConfig.personality)
			animal:PivotTo(spot)
			animal.Parent = base.animalFolder
			local rarity = self.config.rarities[animalConfig.rarity]
			local rarityColor = rarity and colorFrom(rarity.color) or COLORS.white
			local gui = billboard(animal.PrimaryPart, "AnimalBillboard", 148, 59, Vector3.new(0, 4.6, 0), 65)
			textLabel(gui, "Title", animalConfig.name, COLORS.white, 0, 0.36)
			textLabel(gui, "Rarity", animalConfig.rarity, rarityColor, 0.38, 0.27)
			textLabel(gui, "Income", "$" .. animalConfig.income .. "/s", COLORS.mint, 0.7, 0.3)
		end
	end
end

function World:setEggAvailable(zoneId, available)
	local zone = self.zones[zoneId]
	if not zone then
		return
	end
	zone.egg:SetAttribute("Available", available)
	zone.prompt.Enabled = available
	for _, descendant in ipairs(zone.egg:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant:GetAttribute("OriginalTransparency") == nil then
				descendant:SetAttribute("OriginalTransparency", descendant.Transparency)
			end
			descendant.Transparency = available and descendant:GetAttribute("OriginalTransparency") or 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = available
		end
	end
end

function World:destroy()
	self.root:Destroy()
	self.bases = {}
	self.zones = {}
end

return World
