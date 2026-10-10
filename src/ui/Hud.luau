--!nonstrict
-- All artwork is made from Roblox UI primitives. No image or audio assets are required.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Hud = {}
Hud.__index = Hud

local C = {
	ink = Color3.fromRGB(39, 37, 63),
	muted = Color3.fromRGB(113, 110, 132),
	paper = Color3.fromRGB(255, 253, 248),
	blue = Color3.fromRGB(91, 153, 255),
	lilac = Color3.fromRGB(187, 156, 255),
	mint = Color3.fromRGB(151, 231, 175),
	yellow = Color3.fromRGB(255, 216, 105),
	pink = Color3.fromRGB(255, 151, 171),
}

local function make(class, properties, parent)
	local instance = Instance.new(class)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function round(parent, radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 16) }, parent)
end

local function border(parent, color, thickness)
	return make(
		"UIStroke",
		{ Color = color or C.ink, Thickness = thickness or 2, Transparency = 0.08 },
		parent
	)
end

local function label(parent, text, size, color, position, dimensions, bold)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
		TextSize = size,
		TextColor3 = color or C.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Position = position or UDim2.new(),
		Size = dimensions or UDim2.fromScale(1, 1),
	}, parent)
end

local function panel(parent, name, color, position, dimensions)
	local frame = make("Frame", {
		Name = name,
		BackgroundColor3 = color or C.paper,
		BorderSizePixel = 0,
		Position = position,
		Size = dimensions,
	}, parent)
	round(frame)
	border(frame)
	return frame
end

local function cash(value)
	value = tonumber(value) or 0
	if value >= 1e9 then
		return string.format("%.1fB", value / 1e9)
	elseif value >= 1e6 then
		return string.format("%.1fM", value / 1e6)
	elseif value >= 1e4 then
		return string.format("%.1fK", value / 1e3)
	end
	local formatted = tostring(math.floor(value))
	while true do
		local changed
		formatted, changed = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if changed == 0 then
			break
		end
	end
	return formatted
end

local function tint(rgb, fallback)
	if type(rgb) ~= "table" then
		return fallback or C.mint
	end
	return Color3.fromRGB(rgb.r or 150, rgb.g or 200, rgb.b or 170)
end

-- A small original egg mascot, also used as the unrevealed collection portrait.
local function eggArt(parent, position, dimensions, color, asleep)
	local art = make("Frame", {
		BackgroundTransparency = 1,
		Position = position,
		Size = dimensions,
	}, parent)
	local egg = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.66, 0.83),
		BackgroundColor3 = color or C.yellow,
		BorderSizePixel = 0,
		Rotation = -7,
	}, art)
	make("UICorner", { CornerRadius = UDim.new(0.48, 0) }, egg)
	border(egg, C.ink, 2)
	for _, x in ipairs({ 0.32, 0.68 }) do
		local eye = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.52),
			Size = UDim2.fromScale(0.085, if asleep then 0.025 else 0.12),
			BackgroundColor3 = C.ink,
			BorderSizePixel = 0,
		}, egg)
		round(eye, 8)
	end
	local smile = label(egg, "v", 18, C.ink, UDim2.fromScale(0.35, 0.57), UDim2.fromScale(0.3, 0.22), true)
	smile.TextXAlignment = Enum.TextXAlignment.Center
	return art
end

-- Flat animal portraits echo the procedural world models without external artwork.
local function animalArt(parent, position, dimensions, animal)
	local art = make("Frame", { BackgroundTransparency = 1, Position = position, Size = dimensions }, parent)
	local color = tint(animal.color)
	local function shape(x, y, w, h, fill, radius)
		local piece = make("Frame", {
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(w, h),
			BackgroundColor3 = fill,
			BorderSizePixel = 0,
		}, art)
		make("UICorner", { CornerRadius = UDim.new(radius or 0.5, 0) }, piece)
		return piece
	end
	local species = animal.species
	if species == "rabbit" then
		shape(0.25, 0.02, 0.16, 0.49, color)
		shape(0.59, 0.02, 0.16, 0.49, color)
		shape(0.3, 0.06, 0.06, 0.3, C.pink)
		shape(0.64, 0.06, 0.06, 0.3, C.pink)
	elseif species == "cat" then
		local left = shape(0.2, 0.14, 0.26, 0.31, color, 0.18)
		left.Rotation = -20
		local right = shape(0.54, 0.14, 0.26, 0.31, color, 0.18)
		right.Rotation = 20
	elseif species == "dinosaur" then
		shape(0.43, 0.12, 0.16, 0.29, C.mint, 0.2)
	end
	local head = shape(0.12, 0.29, 0.76, 0.61, color)
	border(head, C.ink, 1.5)
	if species == "penguin" then
		shape(0.28, 0.45, 0.44, 0.38, C.paper)
	elseif species == "turtle" then
		shape(0.3, 0.78, 0.4, 0.12, color:Lerp(C.ink, 0.2))
	end
	if species == "frog" then
		shape(0.22, 0.22, 0.23, 0.25, color)
		shape(0.55, 0.22, 0.23, 0.25, color)
	end
	local eyeY = if species == "frog" then 0.28 else 0.48
	shape(0.31, eyeY, 0.075, 0.1, C.ink)
	shape(0.62, eyeY, 0.075, 0.1, C.ink)
	if species == "duck" or species == "penguin" then
		shape(0.37, 0.61, 0.28, 0.14, C.yellow:Lerp(C.pink, 0.25))
	else
		local smile =
			label(art, "v", 17, C.ink, UDim2.fromScale(0.38, 0.59), UDim2.fromScale(0.24, 0.21), true)
		smile.TextXAlignment = Enum.TextXAlignment.Center
	end
	return art
end

function Hud:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

function Hud:_button(parent, text, color, position, dimensions, callback)
	local button = make("TextButton", {
		Text = text,
		TextColor3 = C.ink,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = position,
		Size = dimensions,
		AutoButtonColor = true,
	}, parent)
	round(button, 12)
	border(button, C.ink, 1.5)
	-- Activated works for mouse, touch, and gamepad selection.
	self:_connect(button.Activated, function()
		if self.destroyed then
			return
		end
		callback()
	end)
	return button
end

function Hud:_action(action)
	if not self.state then
		self:notice({ text = "Your base is still loading. One moment!", kind = "info" })
		return
	end
	local now = os.clock()
	if now - self.lastAction < 0.3 then
		return
	end
	self.lastAction = now
	-- The UI only requests an action. Price, distance, and rewards are server decisions.
	self.callbacks.action(action)
end

function Hud:_open(name)
	if self.activePanel == name and self.modal.Visible then
		self.modal.Visible = false
		self.activePanel = nil
		return
	end
	self.activePanel = name
	self.modal.Visible = true
	self.modalTitle.Text = name
	for key, page in pairs(self.pages) do
		page.Visible = key == name
	end
end

function Hud.new(config, callbacks)
	local self = setmetatable({}, Hud)
	self.config = config
	self.callbacks = callbacks
	self.connections = {}
	self.state = nil
	self.lastAction = 0
	self.noticeUntil = 0
	self.revealUntil = 0
	self.reducedMotion = false
	self.effects = true
	self.destroyed = false
	self.collectionCards = {}
	self.slotLabels = {}
	self.zoneById = {}
	for _, zone in ipairs(config.zones) do
		self.zoneById[zone.id] = zone
	end

	self.gui = make("ScreenGui", {
		Name = "GoofyEggHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.root = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, self.gui)
	self.scale = make("UIScale", { Scale = 1 }, self.root)

	self.brand =
		label(self.root, "GOOFY EGG", 21, C.paper, UDim2.fromOffset(18, 12), UDim2.fromOffset(190, 30), true)
	make("UIStroke", { Color = C.ink, Thickness = 2 }, self.brand)
	self.sessionLabel = label(
		self.root,
		"PROTOTYPE · progress resets when you leave",
		11,
		C.paper,
		UDim2.fromOffset(18, 41),
		UDim2.fromOffset(370, 22),
		true
	)
	make("UIStroke", { Color = C.ink, Thickness = 1.2 }, self.sessionLabel)

	self.stats = make(
		"Frame",
		{ BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 73), Size = UDim2.fromOffset(410, 62) },
		self.root
	)
	local statNames = { "CASH", "PER SECOND", "SPEED" }
	local statColors = { C.yellow, C.mint, C.lilac }
	self.statValues = {}
	for index, title in ipairs(statNames) do
		local stat = panel(
			self.stats,
			title,
			statColors[index],
			UDim2.new((index - 1) / 3, 3, 0, 0),
			UDim2.new(1 / 3, -8, 1, 0)
		)
		label(stat, title, 11, C.ink, UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 17), true)
		self.statValues[index] =
			label(stat, "...", 22, C.ink, UDim2.fromOffset(12, 26), UDim2.new(1, -20, 0, 27), true)
	end

	self.mission = panel(self.root, "Mission", C.paper, UDim2.fromOffset(18, 145), UDim2.fromOffset(350, 97))
	self.missionHeading = label(
		self.mission,
		"LET'S GET GOOFY",
		12,
		C.muted,
		UDim2.fromOffset(14, 9),
		UDim2.new(1, -28, 0, 18),
		true
	)
	self.missionText = label(
		self.mission,
		"Setting up your base...",
		15,
		C.ink,
		UDim2.fromOffset(14, 30),
		UDim2.new(1, -28, 0, 53),
		true
	)
	self.missionText.TextWrapped = true
	self.missionText.TextYAlignment = Enum.TextYAlignment.Top

	self.hatching =
		panel(self.root, "Hatching", C.paper, UDim2.fromOffset(18, 252), UDim2.fromOffset(350, 69))
	label(self.hatching, "YOUR NEST", 11, C.muted, UDim2.fromOffset(13, 7), UDim2.new(1, -26, 0, 18), true)
	for index = 1, config.hatchSlots do
		local slot = label(
			self.hatching,
			"○ Empty",
			12,
			C.muted,
			UDim2.new((index - 1) / config.hatchSlots, 12, 0, 30),
			UDim2.new(1 / config.hatchSlots, -18, 0, 28),
			true
		)
		self.slotLabels[index] = slot
	end

	self.upgrade = self:_button(
		self.root,
		"SPEED UP · ...",
		C.lilac,
		UDim2.fromOffset(18, 333),
		UDim2.fromOffset(232, 48),
		function()
			self:_action("UpgradeSpeed")
		end
	)
	self.deposit = self:_button(
		self.root,
		"DEPOSIT EGG",
		C.yellow,
		UDim2.fromOffset(18, 391),
		UDim2.fromOffset(232, 46),
		function()
			self:_action("DepositEgg")
		end
	)
	self.deposit.Visible = false

	self.navigation = make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 74),
		Size = UDim2.fromOffset(142, 172),
	}, self.root)
	for index, definition in ipairs({
		{ "Collection", C.mint },
		{ "Shop", C.yellow },
		{ "Settings", C.paper },
	}) do
		local name = definition[1]
		self:_button(
			self.navigation,
			name,
			definition[2],
			UDim2.fromOffset(0, (index - 1) * 58),
			UDim2.fromOffset(142, 48),
			function()
				self:_open(name)
			end
		)
	end

	self.noticeFrame =
		panel(self.root, "Notice", C.yellow, UDim2.new(0.5, 0, 0, 18), UDim2.fromOffset(430, 54))
	self.noticeFrame.AnchorPoint = Vector2.new(0.5, 0)
	self.noticeFrame.ZIndex = 80
	self.noticeFrame.Visible = false
	self.noticeText =
		label(self.noticeFrame, "", 15, C.ink, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 1, -12), true)
	self.noticeText.TextWrapped = true

	self.modal = make("Frame", {
		Name = "Menus",
		BackgroundColor3 = C.ink,
		BackgroundTransparency = 0.4,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 40,
		Active = true,
	}, self.root)
	self.modalPanel =
		panel(self.modal, "Card", C.paper, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(570, 450))
	self.modalPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	self.modalTitle = label(
		self.modalPanel,
		"Collection",
		25,
		C.ink,
		UDim2.fromOffset(22, 16),
		UDim2.new(1, -100, 0, 39),
		true
	)
	self:_button(self.modalPanel, "X", C.pink, UDim2.new(1, -60, 0, 16), UDim2.fromOffset(40, 40), function()
		self.modal.Visible = false
		self.activePanel = nil
	end)
	self.pages = {}
	for _, name in ipairs({ "Collection", "Shop", "Settings" }) do
		self.pages[name] = make("ScrollingFrame", {
			Name = name,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(18, 68),
			Size = UDim2.new(1, -36, 1, -84),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 5,
			ScrollBarImageColor3 = C.lilac,
			Visible = false,
		}, self.modalPanel)
	end
	self:_buildCollection()
	self:_buildShop()
	self:_buildSettings()
	self:_buildReveal()

	self:_connect(self.gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:_layout()
	end)
	self:_layout()
	local elapsed = 0
	self:_connect(RunService.Heartbeat, function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		self:_tick()
	end)
	return self
end

function Hud:_layout()
	local size = self.gui.AbsoluteSize
	local scale = if size.X < 480 then 0.82 elseif size.X < 780 then 0.9 else 1
	if size.Y < 450 then
		scale = math.min(scale, 0.82)
	end
	self.scale.Scale = scale
	self.root.Size = UDim2.fromScale(1 / scale, 1 / scale)
	local width, height = size.X / scale, size.Y / scale
	local compact = width < 650
	self.brand.Position = UDim2.fromOffset(18, 8)
	self.sessionLabel.Position = UDim2.fromOffset(18, 37)
	self.stats.Size = UDim2.fromOffset(math.min(410, width - 36), 62)
	self.stats.Position = UDim2.fromOffset(15, 69)
	self.mission.Size = UDim2.fromOffset(if compact then math.max(210, width - 192) else 350, 97)
	self.mission.Position = UDim2.fromOffset(18, 141)
	self.hatching.Size = UDim2.fromOffset(if compact then math.max(210, width - 192) else 350, 69)
	self.hatching.Position = UDim2.fromOffset(18, 249)
	self.navigation.Position = UDim2.new(1, -18, 0, if compact then 141 else 69)
	self.upgrade.Position = UDim2.fromOffset(18, 329)
	self.upgrade.Size = UDim2.fromOffset(if compact then math.max(210, width - 192) else 232, 48)
	self.deposit.Position = UDim2.fromOffset(18, 387)
	self.deposit.Size = self.upgrade.Size
	-- Landscape phones keep controls above the movement/jump touch controls.
	if height < 510 and not compact then
		self.mission.Position = UDim2.fromOffset(18, 141)
		self.hatching.Position = UDim2.fromOffset(18, 249)
		self.upgrade.Position = UDim2.new(1, -274, 0, 255)
		self.deposit.Position = UDim2.new(1, -274, 0, 311)
		self.mission.Size = UDim2.fromOffset(350, 97)
	end
	self.modalPanel.Size = UDim2.fromOffset(math.min(570, width - 30), math.min(450, height - 30))
	self.noticeFrame.Size = UDim2.fromOffset(math.min(430, width - 36), 62)
	self.revealCard.Size = UDim2.fromOffset(math.min(400, width - 38), math.min(400, height - 30))
	self.collectionGrid.CellSize = UDim2.new(0.5, -8, 0, 103)
end

function Hud:_buildCollection()
	local page = self.pages.Collection
	self.collectionCount = label(
		page,
		"Discover a friend. Start a collection!",
		14,
		C.muted,
		UDim2.new(),
		UDim2.new(1, -8, 0, 30)
	)
	local grid = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, page)
	self.collectionGrid = make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -8, 0, 103),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	make(
		"UIPadding",
		{ PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 2) },
		grid
	)
	local entries = {}
	for id, animal in pairs(self.config.animals) do
		table.insert(entries, { id = id, animal = animal })
	end
	table.sort(entries, function(a, b)
		local aOrder = self.config.rarities[a.animal.rarity].order
		local bOrder = self.config.rarities[b.animal.rarity].order
		return if aOrder == bOrder then a.id < b.id else aOrder < bOrder
	end)
	for index, entry in ipairs(entries) do
		local card = panel(grid, entry.id, Color3.fromRGB(243, 240, 247), UDim2.new(), UDim2.new())
		card.LayoutOrder = index
		local art = eggArt(card, UDim2.fromOffset(9, 19), UDim2.fromOffset(49, 64), C.lilac, true)
		local name = label(card, "???", 14, C.ink, UDim2.fromOffset(65, 12), UDim2.new(1, -71, 0, 32), true)
		name.TextWrapped = true
		local rarity = label(
			card,
			entry.animal.rarity,
			11,
			C.muted,
			UDim2.fromOffset(65, 47),
			UDim2.new(1, -71, 0, 19),
			true
		)
		local income =
			label(card, "Not discovered", 10, C.muted, UDim2.fromOffset(65, 68), UDim2.new(1, -71, 0, 23))
		income.TextWrapped = true
		self.collectionCards[entry.id] =
			{ frame = card, name = name, rarity = rarity, income = income, art = art }
	end
end

function Hud:_buildShop()
	local page = self.pages.Shop
	local text = label(
		page,
		"A little faster. A little goofier.",
		18,
		C.ink,
		UDim2.fromOffset(0, 0),
		UDim2.new(1, -8, 0, 32),
		true
	)
	text.TextWrapped = true
	self.shopSpeed =
		label(page, "Loading your speed...", 14, C.muted, UDim2.fromOffset(0, 40), UDim2.new(1, -8, 0, 42))
	self.shopSpeed.TextWrapped = true
	self.shopUpgrade = self:_button(
		page,
		"UPGRADE SPEED",
		C.lilac,
		UDim2.fromOffset(2, 99),
		UDim2.new(1, -12, 0, 52),
		function()
			self:_action("UpgradeSpeed")
		end
	)
	local progression =
		label(page, "ZONE GUIDE", 12, C.muted, UDim2.fromOffset(0, 172), UDim2.new(1, -8, 0, 22), true)
	progression.Name = "ZoneGuide"
	self.zoneGuide =
		label(page, "", 14, C.ink, UDim2.fromOffset(0, 201), UDim2.new(1, -8, 0, #self.config.zones * 33))
	self.zoneGuide.TextWrapped = true
	self.zoneGuide.TextYAlignment = Enum.TextYAlignment.Top
	local footer = label(
		page,
		"Every upgrade uses earned game cash.\nRobux shop: planned for a future phase; no paid purchases are active.",
		12,
		C.muted,
		UDim2.fromOffset(0, 212 + #self.config.zones * 33),
		UDim2.new(1, -10, 0, 70)
	)
	footer.TextWrapped = true
end

function Hud:_buildSettings()
	local page = self.pages.Settings
	self.motionButton = self:_button(
		page,
		"REDUCED MOTION: OFF",
		C.mint,
		UDim2.fromOffset(2, 5),
		UDim2.new(1, -12, 0, 52),
		function()
			self.reducedMotion = not self.reducedMotion
			self.motionButton.Text = "REDUCED MOTION: " .. (if self.reducedMotion then "ON" else "OFF")
			if self.reducedMotion and self.revealTween then
				self.revealTween:Cancel()
				self.revealTween = nil
				self.revealScale.Scale = 1
			end
		end
	)
	self.effectsButton = self:_button(
		page,
		"VISUAL EFFECTS: ON",
		C.lilac,
		UDim2.fromOffset(2, 72),
		UDim2.new(1, -12, 0, 52),
		function()
			self.effects = not self.effects
			self.effectsButton.Text = "VISUAL EFFECTS: " .. (if self.effects then "ON" else "OFF")
		end
	)
	local details = label(
		page,
		"Reduced motion stops idle bobbing and reveal animation.\n\nVisual effects controls decorative animal motion.\n\nNo background music. This prototype has no audio assets.\n\nSettings and progress last for this session only.",
		14,
		C.muted,
		UDim2.fromOffset(2, 143),
		UDim2.new(1, -12, 0, 186)
	)
	details.TextWrapped = true
	details.TextYAlignment = Enum.TextYAlignment.Top
end

function Hud:_buildReveal()
	self.revealOverlay = make("Frame", {
		Name = "HatchReveal",
		BackgroundColor3 = C.ink,
		BackgroundTransparency = 0.38,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 60,
		Active = true,
	}, self.root)
	self.revealCard =
		panel(self.revealOverlay, "NewFriend", C.paper, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(400, 400))
	self.revealCard.AnchorPoint = Vector2.new(0.5, 0.5)
	self.revealScale = make("UIScale", { Scale = 1 }, self.revealCard)
	local title = label(
		self.revealCard,
		"YOU HATCHED A FRIEND!",
		15,
		C.muted,
		UDim2.new(0, 16, 0, 19),
		UDim2.new(1, -32, 0, 26),
		true
	)
	title.TextXAlignment = Enum.TextXAlignment.Center
	self.revealArt =
		eggArt(self.revealCard, UDim2.new(0.5, -50, 0.17, 0), UDim2.fromOffset(100, 105), C.yellow, false)
	self.revealName =
		label(self.revealCard, "", 24, C.ink, UDim2.new(0, 18, 0.46, 0), UDim2.new(1, -36, 0, 44), true)
	self.revealName.TextWrapped = true
	self.revealName.TextXAlignment = Enum.TextXAlignment.Center
	self.revealRarity =
		label(self.revealCard, "", 15, C.ink, UDim2.new(0, 18, 0.58, 0), UDim2.new(1, -36, 0, 26), true)
	self.revealRarity.TextXAlignment = Enum.TextXAlignment.Center
	self.revealIncome =
		label(self.revealCard, "", 16, C.ink, UDim2.new(0, 18, 0.67, 0), UDim2.new(1, -36, 0, 23), true)
	self.revealIncome.TextXAlignment = Enum.TextXAlignment.Center
	self.revealNote =
		label(self.revealCard, "", 11, C.muted, UDim2.new(0, 18, 0.74, 0), UDim2.new(1, -36, 0, 27))
	self.revealNote.TextWrapped = true
	self.revealNote.TextXAlignment = Enum.TextXAlignment.Center
	self:_button(
		self.revealCard,
		"NICE!",
		C.yellow,
		UDim2.new(0.5, -75, 1, -61),
		UDim2.fromOffset(150, 44),
		function()
			self.revealOverlay.Visible = false
		end
	)
end

function Hud:update(state)
	if self.destroyed or type(state) ~= "table" then
		return
	end
	self.state = state
	self.statValues[1].Text = "$" .. cash(state.cash)
	self.statValues[2].Text = "+$" .. cash(state.income)
	self.statValues[3].Text = "LV " .. tostring(state.speedLevel or 0)
	local cost = state.upgradeCost
	local upgradeText = if cost then "SPEED UP · $" .. cash(cost) else "SPEED MAXED!"
	self.upgrade.Text = upgradeText
	self.shopUpgrade.Text = upgradeText
	self.upgrade.BackgroundColor3 = if cost and (state.cash or 0) >= cost
		then C.lilac
		else Color3.fromRGB(214, 204, 235)
	self.shopUpgrade.BackgroundColor3 = self.upgrade.BackgroundColor3
	self.shopSpeed.Text = string.format(
		"Level %d / %d  ·  Movement speed %d",
		state.speedLevel or 0,
		self.config.speed.maxLevel,
		state.walkSpeed or self.config.speed.base
	)
	self.deposit.Visible = state.carrying ~= nil
	if state.carrying then
		local zone = self.zoneById[state.carrying]
		self.missionHeading.Text = "EGG ON BOARD · RUN HOME!"
		self.missionText.Text = "Bring your "
			.. (if zone then zone.name else "stolen")
			.. " egg to base "
			.. tostring(state.baseId or "")
			.. ". Deposit it at your nest."
		self.mission.BackgroundColor3 = C.yellow
	else
		self.missionHeading.Text = "BASE " .. tostring(state.baseId or "?") .. " · YOUR NEXT ADVENTURE"
		self.missionText.Text = state.tutorial or "Follow the path. Approach an egg and use its steal prompt!"
		self.mission.BackgroundColor3 = C.paper
	end
	local lines = {}
	for _, zone in ipairs(self.config.zones) do
		local unlocked = (state.speedLevel or 0) >= zone.requiredLevel
		table.insert(
			lines,
			(if unlocked then "OPEN  " else "LOCKED  ")
				.. zone.name
				.. " · speed level "
				.. tostring(zone.requiredLevel)
		)
	end
	self.zoneGuide.Text = table.concat(lines, "\n")
	local owned = {}
	for _, animal in ipairs(state.animals or {}) do
		owned[animal.id] = (owned[animal.id] or 0) + 1
	end
	local found, total = 0, 0
	for id, card in pairs(self.collectionCards) do
		total += 1
		local discovered = (state.discovered or {})[id] == true
		local animal = self.config.animals[id]
		if discovered then
			found += 1
		end
		card.name.Text = if discovered then animal.name else "???"
		card.income.Text = if discovered
			then "$" .. cash(animal.income) .. "/s · owned " .. tostring(owned[id] or 0)
			else "Not discovered"
		card.frame.BackgroundColor3 = if discovered
			then tint(self.config.rarities[animal.rarity].color):Lerp(C.paper, 0.76)
			else Color3.fromRGB(243, 240, 247)
		if discovered and not card.discovered then
			card.art:Destroy()
			card.art = animalArt(card.frame, UDim2.fromOffset(7, 19), UDim2.fromOffset(52, 64), animal)
			card.discovered = true
		end
	end
	self.collectionCount.Text = string.format(
		"%d / %d discovered · %d / %d animal spaces",
		found,
		total,
		#(state.animals or {}),
		self.config.maxAnimals
	)
	self:_tick()
end

function Hud:_tick()
	if self.destroyed then
		return
	end
	local now = os.clock()
	self.noticeFrame.Visible = now < self.noticeUntil
	if self.revealOverlay.Visible and now >= self.revealUntil then
		self.revealOverlay.Visible = false
	end
	local bySlot = {}
	for _, hatch in ipairs(if self.state then self.state.hatches or {} else {}) do
		bySlot[hatch.slot] = hatch
	end
	local serverNow = Workspace:GetServerTimeNow()
	for index, slot in ipairs(self.slotLabels) do
		local hatch = bySlot[index]
		if hatch then
			local remaining = math.max(0, math.ceil(hatch.readyAt - serverNow))
			slot.Text = if remaining > 0 then "EGG · " .. tostring(remaining) .. "s" else "Hatching!"
			slot.TextColor3 = C.ink
		else
			slot.Text = "○ Empty"
			slot.TextColor3 = C.muted
		end
	end
end

function Hud:notice(payload)
	if self.destroyed or type(payload) ~= "table" then
		return
	end
	self.noticeText.Text = tostring(payload.text or "")
	self.noticeFrame.BackgroundColor3 = if payload.kind == "error"
		then C.pink
		elseif payload.kind == "success" then C.mint
		else C.yellow
	self.noticeUntil = os.clock() + 4
	self.noticeFrame.Visible = true
end

function Hud:reveal(payload)
	if self.destroyed or type(payload) ~= "table" then
		return
	end
	local animal = self.config.animals[payload.animalId]
	if not animal then
		return
	end
	local rarity = self.config.rarities[animal.rarity]
	self.revealName.Text = animal.name
	self.revealRarity.Text = string.upper(animal.rarity)
	self.revealRarity.TextColor3 = tint(rarity.color):Lerp(C.ink, 0.28)
	self.revealIncome.Text = "$" .. cash(payload.income or animal.income) .. "/s animal income"
	self.revealNote.Text = if payload.kept == false
		then "Discovered! Your eight higher earners stayed on display."
		elseif payload.replacedName then "Replaced " .. payload.replacedName .. " in your full collection."
		else animal.personality or "Your newest nest mate!"
	self.revealCard.BackgroundColor3 = tint(rarity.color):Lerp(C.paper, 0.87)
	self.revealArt:Destroy()
	self.revealArt =
		animalArt(self.revealCard, UDim2.new(0.5, -50, 0.17, 0), UDim2.fromOffset(100, 105), animal)
	self.revealOverlay.Visible = true
	self.revealUntil = os.clock() + 8
	if self.revealTween then
		self.revealTween:Cancel()
		self.revealTween = nil
	end
	if not self.reducedMotion and self.effects then
		self.revealScale.Scale = 0.84
		self.revealTween = TweenService:Create(
			self.revealScale,
			TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		self.revealTween:Play()
	else
		self.revealScale.Scale = 1
	end
end

function Hud:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = {}
	if self.revealTween then
		self.revealTween:Cancel()
	end
	self.gui:Destroy()
end

return Hud
