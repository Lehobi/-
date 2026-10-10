-- Original garden ranches and guardian courtyards, made entirely from parts.
-- World lettering is attached to physical signs: it never turns with the camera.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimalFactory =
	require(ReplicatedStorage:WaitForChild("GoofyEgg"):WaitForChild("Shared"):WaitForChild("AnimalFactory"))

local World = {}
World.__index = World

local COLORS = {
	grass = Color3.fromRGB(88, 133, 77),
	lawn = Color3.fromRGB(105, 148, 82),
	path = Color3.fromRGB(177, 151, 112),
	stone = Color3.fromRGB(100, 110, 106),
	stoneLight = Color3.fromRGB(139, 147, 135),
	ink = Color3.fromRGB(34, 52, 47),
	wood = Color3.fromRGB(115, 78, 50),
	woodLight = Color3.fromRGB(158, 112, 69),
	leaf = Color3.fromRGB(58, 109, 69),
	leafLight = Color3.fromRGB(113, 153, 76),
	mint = Color3.fromRGB(113, 184, 137),
	cream = Color3.fromRGB(232, 218, 179),
	gold = Color3.fromRGB(210, 161, 72),
	red = Color3.fromRGB(204, 60, 57),
}

local BASE_COLORS = {
	Color3.fromRGB(87, 147, 160),
	Color3.fromRGB(190, 133, 79),
	Color3.fromRGB(145, 122, 177),
	Color3.fromRGB(179, 112, 130),
	Color3.fromRGB(128, 161, 88),
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

local function part(parent, name, size, position, color, collidable, shape, rotation, material)
	local result = Instance.new("Part")
	result.Name = name
	result.Size = size
	result.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	result.Color = color
	result.Material = material or Enum.Material.SmoothPlastic
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

local function disc(parent, name, diameter, thickness, position, color, collidable, material)
	return part(
		parent,
		name,
		Vector3.new(thickness, diameter, diameter),
		position,
		color,
		collidable,
		Enum.PartType.Cylinder,
		CFrame.Angles(0, 0, math.pi / 2),
		material
	)
end

local function surface(board, name, maxDistance, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Adornee = board
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 44
	gui.LightInfluence = 0.15
	gui.Brightness = 1
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 48
	gui.Parent = board
	return gui
end

local function textLabel(parent, name, text, color, y, height, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(0.94, height or 0.9)
	label.Position = UDim2.fromScale(0.03, y or 0.05)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or COLORS.cream
	label.TextStrokeTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = textSize or 34
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

local function plaque(parent, name, position, text, color, width, height, rotation, maxDistance, textSize)
	local facing = rotation or CFrame.identity
	part(
		parent,
		name .. "Frame",
		Vector3.new(width + 0.5, height + 0.5, 0.5),
		position + facing:VectorToWorldSpace(Vector3.new(0, 0, 0.14)),
		COLORS.wood,
		false,
		nil,
		facing,
		Enum.Material.Wood
	)
	local board = part(parent, name, Vector3.new(width, height, 0.35), position, color, false, nil, facing)
	local gui = surface(board, name .. "Lettering", maxDistance)
	return textLabel(gui, "Title", text, COLORS.cream, nil, nil, textSize), board
end

local function sign(parent, name, position, text, color, width, maxDistance, rotation)
	for _, side in ipairs({ -1, 1 }) do
		part(
			parent,
			name .. "Post",
			Vector3.new(0.65, 4.8, 0.65),
			position + Vector3.new(side * (width or 12) * 0.37, 2.4, 0),
			COLORS.wood,
			false,
			nil,
			nil,
			Enum.Material.Wood
		)
	end
	return plaque(
		parent,
		name,
		position + Vector3.new(0, 4.4, 0),
		text,
		color or COLORS.ink,
		width or 12,
		3,
		rotation,
		maxDistance or 48
	)
end

local function tree(parent, x, z, scale)
	local base = Vector3.new(x, 0, z)
	local treeModel = model("GardenTree", parent)
	part(
		treeModel,
		"Trunk",
		Vector3.new(2, 9, 2) * scale,
		base + Vector3.new(0, 4.5 * scale, 0),
		COLORS.wood,
		false,
		nil,
		nil,
		Enum.Material.Wood
	)
	part(
		treeModel,
		"Branch",
		Vector3.new(1, 5, 1) * scale,
		base + Vector3.new(1.4 * scale, 8 * scale, 0),
		COLORS.wood,
		false,
		nil,
		CFrame.Angles(0, 0, -0.55),
		Enum.Material.Wood
	)
	for index, offset in ipairs({
		Vector3.new(0, 11, 0),
		Vector3.new(-3, 10, 0.8),
		Vector3.new(3, 11.3, 0),
		Vector3.new(0.6, 14, -0.5),
	}) do
		part(
			treeModel,
			"Canopy",
			Vector3.new(9, 6.5, 8) * scale,
			base + offset * scale,
			index % 2 == 0 and COLORS.leafLight or COLORS.leaf,
			false,
			Enum.PartType.Ball
		)
	end
end

local function shrubs(parent, x, z, color, scale)
	scale = scale or 1
	for index = 1, 3 do
		part(
			parent,
			"Shrub",
			Vector3.new(3.8, 2.8, 3.5) * scale,
			Vector3.new(x + (index - 2) * 2.4 * scale, 1.2 * scale, z),
			color or COLORS.leaf,
			false,
			Enum.PartType.Ball
		)
	end
end

local function planter(parent, position, accent)
	part(
		parent,
		"Planter",
		Vector3.new(7, 1.1, 3),
		position + Vector3.new(0, 0.55, 0),
		COLORS.wood,
		false,
		nil,
		nil,
		Enum.Material.WoodPlanks
	)
	part(
		parent,
		"Soil",
		Vector3.new(6.6, 0.2, 2.6),
		position + Vector3.new(0, 1.12, 0),
		Color3.fromRGB(76, 63, 47),
		false
	)
	for index = 1, 5 do
		part(
			parent,
			"FlowerLeaves",
			Vector3.new(0.8, 1.1, 0.8),
			position + Vector3.new((index - 3) * 1.2, 1.65, 0),
			COLORS.leaf,
			false,
			Enum.PartType.Ball
		)
		part(
			parent,
			"Flower",
			Vector3.new(0.8, 0.5, 0.8),
			position + Vector3.new((index - 3) * 1.2, 2.25, 0),
			index % 2 == 0 and COLORS.cream or accent,
			false,
			Enum.PartType.Ball
		)
	end
end

local function lamp(parent, position)
	local lantern = model("GardenLantern", parent)
	part(
		lantern,
		"Foot",
		Vector3.new(2, 0.7, 2),
		position + Vector3.new(0, 0.35, 0),
		COLORS.stone,
		false,
		nil,
		nil,
		Enum.Material.Slate
	)
	part(
		lantern,
		"Post",
		Vector3.new(0.6, 7.5, 0.6),
		position + Vector3.new(0, 4, 0),
		COLORS.ink,
		false,
		nil,
		nil,
		Enum.Material.Metal
	)
	local glass = part(
		lantern,
		"WarmGlass",
		Vector3.new(1.5, 1.65, 1.5),
		position + Vector3.new(0, 8.1, 0),
		COLORS.cream,
		false
	)
	part(lantern, "LanternCap", Vector3.new(2, 0.4, 2), position + Vector3.new(0, 9.05, 0), COLORS.ink, false)
	part(
		lantern,
		"LanternBase",
		Vector3.new(1.9, 0.35, 1.9),
		position + Vector3.new(0, 7.2, 0),
		COLORS.ink,
		false
	)
	local glow = Instance.new("PointLight")
	glow.Name = "WarmLight"
	glow.Color = COLORS.cream
	glow.Brightness = 0.4
	glow.Range = 12
	glow.Shadows = false
	glow.Parent = glass
end

local function trail(parent, name, center, size)
	part(
		parent,
		name .. "Edging",
		size + Vector3.new(1.5, 0, 1.5),
		center,
		COLORS.stone,
		true,
		nil,
		nil,
		Enum.Material.Slate
	)
	part(
		parent,
		name,
		size + Vector3.new(0, 0.04, 0),
		center + Vector3.new(0, 0.04, 0),
		COLORS.path,
		true,
		nil,
		nil,
		Enum.Material.Cobblestone
	)
end

local function buildGround(root)
	local map = folder("Landscape", root)
	part(
		map,
		"Meadow",
		Vector3.new(360, 2, 760),
		Vector3.new(0, -1, 85),
		COLORS.grass,
		true,
		nil,
		nil,
		Enum.Material.Grass
	)
	trail(map, "VillageWalk", Vector3.new(0, 0.1, -53), Vector3.new(20, 0.2, 222))
	trail(map, "LobbyPlaza", Vector3.new(0, 0.1, 28), Vector3.new(232, 0.2, 31))
	trail(map, "GardenLane", Vector3.new(0, 0.1, -70), Vector3.new(195, 0.2, 16))
	trail(map, "GuardianWalk", Vector3.new(0, 0.1, 228.5), Vector3.new(26, 0.2, 353))
	for _, x in ipairs({ -179, 179 }) do
		part(
			map,
			"BoundaryHedge",
			Vector3.new(2, 5, 760),
			Vector3.new(x, 2.5, 85),
			COLORS.leaf,
			true,
			nil,
			nil,
			Enum.Material.Grass
		)
	end
	for _, z in ipairs({ -294, 464 }) do
		part(
			map,
			"BoundaryHedge",
			Vector3.new(360, 5, 2),
			Vector3.new(0, 2.5, z),
			COLORS.leaf,
			true,
			nil,
			nil,
			Enum.Material.Grass
		)
	end

	local walls = folder("GuardianRouteWalls", root)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 49
		part(
			walls,
			"StoneWall",
			Vector3.new(2.5, 8.5, 353),
			Vector3.new(x, 4.25, 228.5),
			COLORS.stone,
			true,
			nil,
			nil,
			Enum.Material.Cobblestone
		)
		part(
			walls,
			"TimberTop",
			Vector3.new(2.7, 2, 353),
			Vector3.new(x, 9.5, 228.5),
			COLORS.wood,
			true,
			nil,
			nil,
			Enum.Material.WoodPlanks
		)
		part(
			walls,
			"WallCap",
			Vector3.new(3.4, 0.6, 354),
			Vector3.new(x, 10.8, 228.5),
			COLORS.woodLight,
			true,
			nil,
			nil,
			Enum.Material.Wood
		)
		for index = 0, 7 do
			local z = 52 + index * 50
			part(
				walls,
				"Buttress",
				Vector3.new(3.6, 11.3, 3.3),
				Vector3.new(x, 5.65, z),
				COLORS.stoneLight,
				true,
				nil,
				nil,
				Enum.Material.Slate
			)
			part(
				walls,
				"ButtressCap",
				Vector3.new(4, 0.6, 3.8),
				Vector3.new(x, 11.6, z),
				COLORS.wood,
				false,
				nil,
				nil,
				Enum.Material.Wood
			)
		end
	end
	part(
		walls,
		"EndWall",
		Vector3.new(100, 10.5, 2.5),
		Vector3.new(0, 5.25, 405),
		COLORS.stone,
		true,
		nil,
		nil,
		Enum.Material.Cobblestone
	)
	part(
		walls,
		"EndWallCap",
		Vector3.new(101, 0.7, 3.4),
		Vector3.new(0, 10.85, 405),
		COLORS.woodLight,
		true,
		nil,
		nil,
		Enum.Material.Wood
	)

	local decor = folder("Decorations", root)
	for index = 1, 10 do
		local z = -255 + index * 67
		tree(decor, -146 - (index % 3) * 6, z, 1 + (index % 3) * 0.18)
		tree(decor, 143 + (index % 2) * 9, z + 21, 1.15 + (index % 2) * 0.2)
	end
	for _, z in ipairs({ 77, 220, 385 }) do
		for _, side in ipairs({ -1, 1 }) do
			tree(decor, side * 65, z, 1.2)
			shrubs(decor, side * 38, z, nil, 1.05)
			lamp(decor, Vector3.new(side * 41, 0, z - 8))
		end
	end
	for _, z in ipairs({ -150, -57, 24 }) do
		for _, side in ipairs({ -1, 1 }) do
			lamp(decor, Vector3.new(side * 16, 0, z))
		end
	end
	for _, x in ipairs({ -36, 36 }) do
		part(
			decor,
			"WelcomeArchPost",
			Vector3.new(2.3, 14.5, 2.3),
			Vector3.new(x, 7.25, 52),
			COLORS.wood,
			true,
			nil,
			nil,
			Enum.Material.Wood
		)
		part(
			decor,
			"WelcomeFoot",
			Vector3.new(3.5, 2.5, 3.5),
			Vector3.new(x, 1.25, 52),
			COLORS.stoneLight,
			true,
			nil,
			nil,
			Enum.Material.Slate
		)
		planter(decor, Vector3.new(x, 0, 47), COLORS.gold)
	end
	part(
		decor,
		"WelcomeArchBeam",
		Vector3.new(77, 1.8, 2.5),
		Vector3.new(0, 14, 52),
		COLORS.wood,
		false,
		nil,
		nil,
		Enum.Material.Wood
	)
	plaque(
		decor,
		"Welcome",
		Vector3.new(0, 12.5, 50.4),
		"STEAL A GOOFY EGG",
		COLORS.ink,
		28,
		3.2,
		nil,
		65,
		43
	)
	sign(
		decor,
		"HowTo",
		Vector3.new(-27, 0, 40),
		"STEAL • ESCAPE • HATCH\nBring an egg home",
		COLORS.ink,
		16,
		45
	)
	sign(
		decor,
		"Route",
		Vector3.new(27, 0, 40),
		"GUARDIAN GARDENS\nFollow the stone path",
		COLORS.ink,
		16,
		45
	)
	for _, z in ipairs({ 65, 210, 230, 383 }) do
		for _, side in ipairs({ -1, 1 }) do
			part(
				decor,
				"RouteChevron",
				Vector3.new(0.6, 0.08, 3.8),
				Vector3.new(side * 1.1, 0.27, z),
				COLORS.cream,
				false,
				nil,
				CFrame.Angles(0, side * -0.62, 0)
			)
		end
	end
	-- A distant planted end to the route, rather than another empty white slab.
	for _, x in ipairs({ -33, -22, 22, 33 }) do
		shrubs(decor, x, 397, nil, 1.35)
	end
	sign(decor, "GardenEnd", Vector3.new(0, 0, 399), "MORE GARDENS COMING SOON", COLORS.ink, 25, 45)
end

local function fence(parent, center, color)
	part(
		parent,
		"BackStoneEdge",
		Vector3.new(64, 1.3, 1.5),
		center + Vector3.new(0, 0.65, -27.5),
		COLORS.stone,
		true,
		nil,
		nil,
		Enum.Material.Slate
	)
	for _, side in ipairs({ -1, 1 }) do
		part(
			parent,
			"SideStoneEdge",
			Vector3.new(1.5, 1.3, 56),
			center + Vector3.new(side * 31.5, 0.65, 0),
			COLORS.stone,
			true,
			nil,
			nil,
			Enum.Material.Slate
		)
		for _, y in ipairs({ 2, 3.4 }) do
			part(
				parent,
				"SideFenceRail",
				Vector3.new(0.5, 0.65, 56),
				center + Vector3.new(side * 31.5, y, 0),
				COLORS.woodLight,
				true,
				nil,
				nil,
				Enum.Material.Wood
			)
			part(
				parent,
				"FrontFenceRail",
				Vector3.new(19.5, 0.65, 0.5),
				center + Vector3.new(side * 21.5, y, 27.5),
				COLORS.woodLight,
				true,
				nil,
				nil,
				Enum.Material.Wood
			)
		end
		for _, z in ipairs({ -27, -13.5, 0, 13.5, 27 }) do
			part(
				parent,
				"FencePost",
				Vector3.new(1, 4.5, 1),
				center + Vector3.new(side * 31.5, 2.25, z),
				COLORS.wood,
				true,
				nil,
				nil,
				Enum.Material.Wood
			)
		end
		part(
			parent,
			"EntrancePost",
			Vector3.new(1.6, 5, 1.6),
			center + Vector3.new(side * 12, 2.5, 27.5),
			COLORS.wood,
			true,
			nil,
			nil,
			Enum.Material.Wood
		)
		part(
			parent,
			"EntranceCap",
			Vector3.new(2, 0.5, 2),
			center + Vector3.new(side * 12, 5.2, 27.5),
			color,
			false
		)
	end
end

local function buildBase(config, parent, id, position)
	local baseModel = model("Base_" .. id, parent)
	baseModel:SetAttribute("BaseId", id)
	baseModel:SetAttribute("OwnerUserId", 0)
	local center = Vector3.new(position.x, 0, position.z)
	local color = BASE_COLORS[id] or COLORS.mint
	part(
		baseModel,
		"Foundation",
		Vector3.new(64, 0.7, 56),
		center + Vector3.new(0, 0.25, 0),
		COLORS.stone,
		true,
		nil,
		nil,
		Enum.Material.Slate
	)
	part(
		baseModel,
		"LivingLawn",
		Vector3.new(60, 0.2, 52),
		center + Vector3.new(0, 0.7, 0),
		COLORS.lawn,
		true,
		nil,
		nil,
		Enum.Material.Grass
	)
	fence(baseModel, center, color)
	trail(baseModel, "EntranceWalk", center + Vector3.new(0, 0.2, 31), Vector3.new(13, 0.25, 13))
	part(
		baseModel,
		"EntranceStep",
		Vector3.new(13, 0.45, 4),
		center + Vector3.new(0, 0.42, 26),
		COLORS.path,
		true,
		nil,
		nil,
		Enum.Material.Sandstone
	)
	for _, side in ipairs({ -1, 1 }) do
		planter(baseModel, center + Vector3.new(side * 24, 0.6, 24), color)
		shrubs(baseModel, center.X + side * 27, center.Z - 22, COLORS.leaf, 0.8)
	end

	-- The covered rear hatch nook keeps the central lawn open for roaming pets.
	part(
		baseModel,
		"HatchDeck",
		Vector3.new(56, 0.45, 17),
		center + Vector3.new(0, 0.97, -16.5),
		COLORS.woodLight,
		true,
		nil,
		nil,
		Enum.Material.WoodPlanks
	)
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -24, -9 }) do
			part(
				baseModel,
				"HatchPergolaPost",
				Vector3.new(1, 7.5, 1),
				center + Vector3.new(side * 27, 4.6, z),
				COLORS.wood,
				true,
				nil,
				nil,
				Enum.Material.Wood
			)
		end
	end
	for _, z in ipairs({ -24, -9 }) do
		part(
			baseModel,
			"HatchPergolaBeam",
			Vector3.new(58, 0.9, 1.3),
			center + Vector3.new(0, 8.1, z),
			COLORS.wood,
			false,
			nil,
			nil,
			Enum.Material.Wood
		)
	end
	for x = -24, 24, 8 do
		part(
			baseModel,
			"PergolaSlat",
			Vector3.new(1, 0.5, 18),
			center + Vector3.new(x, 8.5, -16.5),
			COLORS.woodLight,
			false,
			nil,
			nil,
			Enum.Material.Wood
		)
	end
	local ownerSign = plaque(
		baseModel,
		"OwnerSign",
		center + Vector3.new(0, 6.1, -25),
		"AVAILABLE RANCH",
		color:Lerp(COLORS.ink, 0.55),
		25,
		2.8,
		CFrame.Angles(0, math.pi, 0),
		60,
		37
	)
	local hatchFolder = folder("Hatches", baseModel)
	local animalFolder = folder("Animals", baseModel)
	local slots = {}
	for index = 1, config.hatchSlots do
		local x = (index - (config.hatchSlots + 1) / 2) * 17
		disc(
			baseModel,
			"NestRim_" .. index,
			7.8,
			0.6,
			center + Vector3.new(x, 1.43, -15),
			COLORS.wood,
			false,
			Enum.Material.Wood
		)
		local slot = disc(
			baseModel,
			"HatchSlot_" .. index,
			6.9,
			0.16,
			center + Vector3.new(x, 1.77, -15),
			COLORS.gold,
			false,
			Enum.Material.Fabric
		)
		slot:SetAttribute("SlotIndex", index)
		slots[index] = slot
		for twig = 1, 6 do
			local angle = twig * math.pi / 3
			part(
				baseModel,
				"NestStraw",
				Vector3.new(0.2, 0.16, 3),
				center + Vector3.new(x + math.cos(angle) * 2.4, 1.89, -15 + math.sin(angle) * 2.4),
				COLORS.cream:Lerp(COLORS.gold, 0.5),
				false,
				nil,
				CFrame.Angles(0, -angle, 0)
			)
		end
		plaque(
			baseModel,
			"HatchNumber_" .. index,
			center + Vector3.new(x, 2.05, -10.2),
			"NEST " .. index,
			COLORS.ink,
			5.5,
			1.3,
			CFrame.Angles(0, math.pi, 0),
			35,
			29
		)
	end
	local animalSpots = {}
	for index = 1, config.maxAnimals do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		animalSpots[index] = CFrame.new(center + Vector3.new((column - 1.5) * 11, 0.85, 4 + row * 10))
			* CFrame.Angles(0, math.pi, 0)
	end
	local deposit = disc(
		baseModel,
		"DepositPad",
		8,
		0.14,
		center + Vector3.new(0, 0.89, 0),
		COLORS.path,
		false,
		Enum.Material.Sandstone
	)
	disc(
		baseModel,
		"DepositInlay",
		6.8,
		0.05,
		center + Vector3.new(0, 0.99, 0),
		color:Lerp(COLORS.cream, 0.3),
		false
	)
	local depositPrompt = prompt(deposit, "DepositEgg", "Hatch egg", "Your hatchery", 0.35)
	plaque(
		baseModel,
		"DepositDirections",
		center + Vector3.new(0, 3.1, -8.1),
		"BRING YOUR EGG HERE",
		COLORS.ink,
		13,
		1.5,
		CFrame.Angles(0, math.pi, 0),
		40,
		28
	)

	local shopPosition = center + Vector3.new(-27, 0, -3.5)
	local shop = part(
		baseModel,
		"SpeedShop",
		Vector3.new(5, 3, 4.5),
		shopPosition + Vector3.new(0, 2.3, 0),
		COLORS.woodLight,
		false,
		nil,
		nil,
		Enum.Material.WoodPlanks
	)
	part(
		baseModel,
		"ShopCounter",
		Vector3.new(6, 0.4, 5.2),
		shopPosition + Vector3.new(0, 4, 0),
		COLORS.wood,
		false,
		nil,
		nil,
		Enum.Material.Wood
	)
	for _, side in ipairs({ -1, 1 }) do
		part(
			baseModel,
			"KioskPost",
			Vector3.new(0.4, 5.7, 0.4),
			shopPosition + Vector3.new(side * 2.5, 3.55, 1.7),
			COLORS.wood,
			false,
			nil,
			nil,
			Enum.Material.Wood
		)
	end
	part(
		baseModel,
		"KioskAwning",
		Vector3.new(6.2, 0.45, 5.8),
		shopPosition + Vector3.new(0, 6.5, 0),
		color,
		false,
		nil,
		CFrame.Angles(0.12, 0, 0)
	)
	plaque(
		baseModel,
		"SpeedShopSign",
		shopPosition + Vector3.new(0, 5.3, 2.55),
		"SPEED",
		COLORS.ink,
		5.6,
		1.5,
		CFrame.Angles(0, math.pi, 0),
		40,
		31
	)
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
	local halfWidth = zone.arenaHalfWidth or 46
	local halfDepth = zone.arenaHalfDepth or 55
	local courtColor = zone.guardian == "turtle" and Color3.fromRGB(112, 142, 85)
		or Color3.fromRGB(137, 133, 117)
	part(
		zoneModel,
		"ZoneCourt",
		Vector3.new(halfWidth * 2, 0.16, halfDepth * 2),
		center + Vector3.new(0, 0.18, 0),
		courtColor,
		true,
		nil,
		nil,
		Enum.Material.Grass
	)
	part(
		zoneModel,
		"CourtWalk",
		Vector3.new(24, 0.15, halfDepth * 2),
		center + Vector3.new(0, 0.29, 0),
		COLORS.path,
		true,
		nil,
		nil,
		Enum.Material.Cobblestone
	)
	-- These visible strips match the server's rectangular chase boundary exactly.
	for _, side in ipairs({ -1, 1 }) do
		part(
			zoneModel,
			"RedSideBoundary",
			Vector3.new(0.9, 0.12, halfDepth * 2),
			center + Vector3.new(side * halfWidth, 0.34, 0),
			COLORS.red,
			false
		)
		part(
			zoneModel,
			"RedEscapeLine",
			Vector3.new(halfWidth * 2, 0.12, 1.4),
			center + Vector3.new(0, 0.44, side * halfDepth),
			COLORS.red,
			false
		)
		for stripe = -4, 4 do
			part(
				zoneModel,
				"BoundaryDash",
				Vector3.new(3, 0.08, 0.45),
				center + Vector3.new(stripe * 9, 0.47, side * halfDepth + side * 1.5),
				COLORS.cream,
				false
			)
		end
		shrubs(zoneModel, center.X + side * 39, center.Z + 25, color:Lerp(COLORS.leaf, 0.75), 1.2)
		shrubs(zoneModel, center.X + side * 39, center.Z - 18, nil, 0.95)
		for rock = 1, 3 do
			part(
				zoneModel,
				"GardenRock",
				Vector3.new(3 + rock, 2 + rock * 0.5, 3.5),
				center + Vector3.new(side * (35 + rock * 2), 0.8, 35 + rock * 2),
				COLORS.stoneLight,
				false,
				Enum.PartType.Ball,
				CFrame.Angles(0, rock, 0)
			)
		end
	end
	local levelText = zone.requiredLevel > 0 and ("SPEED LEVEL " .. zone.requiredLevel) or "YOUR FIRST HEIST"
	sign(
		zoneModel,
		"ZoneSign",
		center + Vector3.new(-27, 0, -halfDepth - 4),
		string.upper(zone.name) .. "\n" .. levelText,
		color:Lerp(COLORS.ink, 0.65),
		24,
		60
	)
	sign(
		zoneModel,
		"EscapeSign",
		center + Vector3.new(27, 0, -halfDepth - 4),
		"CROSS RED LINE TO ESCAPE\nGuardians stay in this garden",
		COLORS.ink,
		24,
		55
	)
	-- The back face is useful while running home with an egg.
	plaque(
		zoneModel,
		"EscapeReturnSign",
		center + Vector3.new(27, 4.4, -halfDepth - 3.5),
		"CROSS RED LINE\nSAFE BEYOND THIS GARDEN",
		COLORS.ink,
		24,
		3,
		CFrame.Angles(0, math.pi, 0),
		55,
		34
	)
	disc(
		zoneModel,
		"EggPlinth",
		8.5,
		0.75,
		center + Vector3.new(0, 0.65, 0),
		COLORS.stoneLight,
		true,
		Enum.Material.Slate
	)
	disc(
		zoneModel,
		"EggNest",
		7,
		0.25,
		center + Vector3.new(0, 1.15, 0),
		COLORS.woodLight,
		false,
		Enum.Material.Wood
	)
	disc(
		zoneModel,
		"EggStraw",
		5.5,
		0.15,
		center + Vector3.new(0, 1.36, 0),
		COLORS.gold,
		false,
		Enum.Material.Fabric
	)
	for twig = 1, 8 do
		local angle = twig * math.pi / 4
		part(
			zoneModel,
			"WildNestTwig",
			Vector3.new(0.3, 0.3, 2.8),
			center + Vector3.new(math.cos(angle) * 3.1, 1.46, math.sin(angle) * 3.1),
			COLORS.wood,
			false,
			nil,
			CFrame.Angles(0, -angle, 0)
		)
	end
	local egg = AnimalFactory.egg(zone.color, "WildEgg")
	egg:SetAttribute("ZoneId", zone.id)
	egg:SetAttribute("Available", true)
	egg:PivotTo(CFrame.new(center + Vector3.new(0, 2.9, 0)))
	egg.Parent = zoneModel
	local stealPrompt = prompt(egg.PrimaryPart, "StealEgg", "Steal egg", zone.name, 0.65)
	local homePosition = center + Vector3.new(zone.guardianOffset or 20, 0.3, 0)
	local home = CFrame.lookAt(homePosition, Vector3.new(center.X, homePosition.Y, center.Z))
	local guardian = AnimalFactory.create(zone.guardian, zone.color, "Guardian")
	guardian:SetAttribute("VisualRole", "Guardian")
	guardian:SetAttribute("ZoneId", zone.id)
	guardian:SetAttribute("State", "Idle")
	guardian:SetAttribute("HomeX", homePosition.X)
	guardian:SetAttribute("HomeY", homePosition.Y)
	guardian:SetAttribute("HomeZ", homePosition.Z)
	guardian:ScaleTo(zone.guardian == "rabbit" and 2.2 or 2.1)
	guardian:SetAttribute("RigScale", guardian:GetScale())
	guardian:PivotTo(home)
	guardian.Parent = zoneModel
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
	base.sign.Text = player and (player.DisplayName .. "'S RANCH") or "AVAILABLE RANCH"
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
	local slotPosition = base.slots[slotIndex].Position
	egg:PivotTo(CFrame.new(slotPosition + Vector3.new(0, 1.65, 0)))
	-- A separate fixed board is a child of the egg for countdown discovery/cleanup.
	-- It is never attached to the moving shell or turned toward the camera.
	local _, board = plaque(
		egg,
		"HatchStatus",
		slotPosition + Vector3.new(0, 2, -5.1),
		zone.config.name,
		COLORS.ink,
		9,
		2.6,
		CFrame.Angles(0, math.pi, 0),
		40,
		29
	)
	local gui = board:FindFirstChild("HatchStatusLettering")
	local title = gui and gui:FindFirstChild("Title")
	if title then
		title.Size = UDim2.fromScale(0.94, 0.45)
		title.Position = UDim2.fromScale(0.03, 0.05)
	end
	textLabel(
		gui,
		"Countdown",
		math.max(0, math.ceil(readyAt - workspace:GetServerTimeNow())) .. "s",
		COLORS.mint,
		0.52,
		0.42,
		36
	)
	egg.Parent = base.hatchFolder
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
			animal:SetAttribute("VisualRole", "Animal")
			animal:SetAttribute("RoamCenterX", base.center.X)
			animal:SetAttribute("RoamCenterY", 0.85)
			animal:SetAttribute("RoamCenterZ", base.center.Z + 8.5)
			animal:SetAttribute("RoamHalfX", 23)
			animal:SetAttribute("RoamHalfZ", 10.5)
			animal:SetAttribute("RoamSeed", baseId * 100 + index)
			animal:ScaleTo(1.3)
			animal:SetAttribute("RigScale", animal:GetScale())
			animal:PivotTo(spot)
			animal.Parent = base.animalFolder
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
		end
	end
end

function World:destroy()
	self.root:Destroy()
	self.bases = {}
	self.zones = {}
end

return World
