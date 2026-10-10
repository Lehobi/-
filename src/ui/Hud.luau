--!nonstrict
-- Original interface artwork uses Roblox UI primitives; gameplay remains server-authoritative.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Hud = {}
Hud.__index = Hud

local C = {
	ink = Color3.fromRGB(37, 49, 45),
	muted = Color3.fromRGB(105, 119, 109),
	paper = Color3.fromRGB(251, 248, 238),
	blue = Color3.fromRGB(91, 153, 255),
	lilac = Color3.fromRGB(187, 156, 255),
	mint = Color3.fromRGB(161, 213, 170),
	yellow = Color3.fromRGB(240, 204, 111),
	pink = Color3.fromRGB(228, 144, 121),
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
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function border(parent, color, thickness)
	return make("UIStroke", {
		Color = color or C.ink,
		Thickness = thickness or 1,
		Transparency = 0.82,
		-- Contextual mode strokes TextButton letters, making the text illegible.
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function label(parent, text, size, color, position, dimensions, bold)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = if bold then Enum.Font.GothamMedium else Enum.Font.Gotham,
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

function Hud:_sound(cue)
	if self.sfxEnabled and self.callbacks.sound then
		self.callbacks.sound(cue)
	end
end

function Hud:_button(parent, text, color, position, dimensions, callback)
	local button = make("TextButton", {
		Text = text,
		TextColor3 = C.ink,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = position,
		Size = dimensions,
		AutoButtonColor = true,
	}, parent)
	round(button, 11)
	border(button)
	self:_connect(button.Activated, function()
		if self.destroyed then
			return
		end
		self:_sound("ui")
		callback()
	end)
	return button
end

function Hud:_action(action)
	if not self.state then
		self:notice({ text = "Finding your garden. One moment!", kind = "info" })
		return
	end
	local now = os.clock()
	if now - self.lastAction < 0.3 then
		return
	end
	self.lastAction = now
	-- Prices, distance checks, and rewards always belong to the server.
	self.callbacks.action(action)
end

function Hud:_closeMenu()
	self.modal.Visible = false
	self.activePanel = nil
end

function Hud:_open(name)
	if self.activePanel == name and self.modal.Visible then
		self:_closeMenu()
		return
	end
	self.activePanel = name
	self.modal.Visible = true
	self.modalTitle.Text = name
	for key, page in pairs(self.pages) do
		page.Visible = key == name
	end
end

-- Small original geometric icons. Labels remain available beside every icon.
local function navigationIcon(parent, kind)
	local icon = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 13),
		Size = UDim2.fromOffset(18, 18),
	}, parent)
	local function shape(x, y, w, h, color)
		local piece = make("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
		}, icon)
		round(piece, 3)
		return piece
	end
	if kind == "Collection" then
		for row = 0, 1 do
			for col = 0, 1 do
				shape(col * 10, row * 10, 7, 7, C.ink)
			end
		end
	elseif kind == "Shop" then
		local coin = shape(1, 1, 16, 16, C.yellow)
		round(coin, 8)
		border(coin, C.ink, 1.5)
		shape(7, 5, 3, 8, C.ink)
	else
		for row = 0, 2 do
			shape(1, 2 + row * 6, 16, 2, C.muted)
			shape(if row == 1 then 10 else 4, row * 6, 4, 6, C.ink)
		end
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
	self.sfxEnabled = (config.audio or {}).enabled ~= false
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

	self.wallet = panel(self.root, "Wallet", C.paper, UDim2.fromOffset(12, 10), UDim2.fromOffset(214, 48))
	local coin = make("Frame", {
		BackgroundColor3 = C.yellow,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(11, 13),
		Size = UDim2.fromOffset(22, 22),
	}, self.wallet)
	round(coin, 11)
	local coinMark = label(coin, "$", 13, C.ink, UDim2.new(), UDim2.fromScale(1, 1), true)
	coinMark.TextXAlignment = Enum.TextXAlignment.Center
	self.cashLabel =
		label(self.wallet, "$0", 18, C.ink, UDim2.fromOffset(41, 5), UDim2.new(1, -50, 0, 22), true)
	self.incomeLabel =
		label(self.wallet, "+$0 / sec", 12, C.muted, UDim2.fromOffset(42, 27), UDim2.new(1, -50, 0, 15))
	self.speedChip = panel(self.root, "Speed", C.paper, UDim2.fromOffset(234, 10), UDim2.fromOffset(102, 48))
	label(self.speedChip, "SPEED", 10, C.muted, UDim2.fromOffset(13, 7), UDim2.new(1, -20, 0, 14), true)
	self.speedLabel =
		label(self.speedChip, "Level 0", 15, C.ink, UDim2.fromOffset(13, 23), UDim2.new(1, -20, 0, 20), true)

	self.mission = panel(self.root, "NextStep", C.paper, UDim2.fromOffset(12, 66), UDim2.fromOffset(336, 40))
	self.mission.BackgroundTransparency = 0.08
	self.missionDot = make("Frame", {
		BackgroundColor3 = C.mint,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 16),
		Size = UDim2.fromOffset(8, 8),
	}, self.mission)
	round(self.missionDot, 4)
	self.missionText = label(
		self.mission,
		"Finding your garden...",
		13,
		C.ink,
		UDim2.fromOffset(28, 4),
		UDim2.new(1, -39, 1, -8)
	)
	self.missionText.TextWrapped = true

	self.hatching = make("Frame", {
		Name = "OccupiedNests",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 114),
		Size = UDim2.fromOffset(336, 30),
		Visible = false,
	}, self.root)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.hatching)
	for index = 1, config.hatchSlots do
		local chip = panel(self.hatching, "Nest" .. index, C.paper, UDim2.new(), UDim2.fromOffset(105, 30))
		chip.LayoutOrder = index
		chip.Visible = false
		round(chip, 9)
		local slot = label(chip, "", 11, C.ink, UDim2.fromOffset(9, 0), UDim2.new(1, -18, 1, 0), true)
		self.slotLabels[index] = slot
	end

	self.actionBar = make("Frame", {
		Name = "ContextAction",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.fromOffset(210, 44),
	}, self.root)
	self.upgrade = self:_button(
		self.actionBar,
		"Speed up  ·  ...",
		C.mint,
		UDim2.new(),
		UDim2.fromScale(1, 1),
		function()
			self:_action("UpgradeSpeed")
		end
	)
	self.deposit = self:_button(
		self.actionBar,
		"Nest egg at home",
		C.yellow,
		UDim2.new(),
		UDim2.fromScale(1, 1),
		function()
			self:_action("DepositEgg")
		end
	)
	self.deposit.Visible = false

	self.navigation = make("Frame", {
		Name = "Navigation",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(340, 44),
	}, self.root)
	for index, name in ipairs({ "Collection", "Shop", "Settings" }) do
		local button = self:_button(
			self.navigation,
			"",
			C.paper,
			UDim2.new((index - 1) / 3, 0, 0, 0),
			UDim2.new(1 / 3, -5, 1, 0),
			function()
				self:_open(name)
			end
		)
		button.Name = name
		navigationIcon(button, name)
		label(button, name, 12, C.ink, UDim2.fromOffset(36, 0), UDim2.new(1, -40, 1, 0), true)
	end

	self.noticeFrame = panel(self.root, "Notice", C.yellow, self.mission.Position, self.mission.Size)
	self.noticeFrame.ZIndex = 80
	self.noticeFrame.Visible = false
	self.noticeText =
		label(self.noticeFrame, "", 13, C.ink, UDim2.fromOffset(12, 4), UDim2.new(1, -24, 1, -8), true)
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
		panel(self.modal, "MenuCard", C.paper, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(610, 490))
	self.modalPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	self.modalTitle = label(
		self.modalPanel,
		"Collection",
		22,
		C.ink,
		UDim2.fromOffset(20, 16),
		UDim2.new(1, -95, 0, 36),
		true
	)
	self:_button(
		self.modalPanel,
		"×",
		C.paper,
		UDim2.new(1, -58, 0, 12),
		UDim2.fromOffset(44, 44),
		function()
			self:_closeMenu()
		end
	)
	self.pages = {}
	for _, name in ipairs({ "Collection", "Shop", "Settings" }) do
		self.pages[name] = make("ScrollingFrame", {
			Name = name,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(18, 66),
			Size = UDim2.new(1, -36, 1, -82),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = C.mint:Lerp(C.ink, 0.2),
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
	self:notice({ text = "Welcome! This session's progress resets when you leave.", kind = "info" })
	self.noticeUntil = os.clock() + 6
	return self
end

function Hud:_layout()
	local size = self.gui.AbsoluteSize
	local width, height = math.max(size.X, 280), math.max(size.Y, 240)
	local portrait = width < 700
	local short = height < 440
	local margin = 12
	local available = width - margin * 2
	local walletWidth = if portrait then available - 110 else 214
	self.wallet.Size = UDim2.fromOffset(walletWidth, 48)
	self.speedChip.Position = UDim2.fromOffset(margin + walletWidth + 8, 10)
	self.mission.Size = UDim2.fromOffset(if portrait then available else 336, 40)
	self.navigation.AnchorPoint = Vector2.new(if portrait then 0 else 1, 0)
	self.navigation.Position = if portrait
		then UDim2.fromOffset(margin, 114)
		else UDim2.new(1, -margin, 0, 12)
	self.navigation.Size = UDim2.fromOffset(if portrait then available + 5 else 340, 44)
	self.hatching.Position = UDim2.fromOffset(margin, if portrait then 166 else 114)
	self.hatching.Size = UDim2.fromOffset(if portrait then available else 336, 30)
	for _, slot in ipairs(self.slotLabels) do
		slot.Parent.Size =
			UDim2.fromOffset(math.floor((math.min(available, 336) - 12) / self.config.hatchSlots), 30)
	end
	-- No global UIScale: phone tap targets stay 44px, text stays legible.
	-- The lower corners are reserved for Roblox's thumbstick and jump button.
	self.actionBar.Position = UDim2.new(0.5, 0, 1, if portrait and not short then -130 else -18)
	self.modalPanel.Size = UDim2.fromOffset(math.min(610, available), math.min(490, height - 24))
	self.noticeFrame.Position = self.mission.Position
	self.noticeFrame.Size = self.mission.Size
	self.collectionGrid.CellSize = UDim2.new(if width < 510 then 0.5 else 1 / 3, -8, 0, 168)
	self.revealCard.Size = UDim2.fromOffset(math.min(346, available), 144)
	if portrait then
		self.revealCard.AnchorPoint = Vector2.new(0.5, 0)
		self.revealCard.Position = UDim2.new(0.5, 0, 0, 204)
	elseif short then
		self.revealCard.AnchorPoint = Vector2.new(1, 0)
		self.revealCard.Position = UDim2.new(1, -12, 0, 68)
	else
		self.revealCard.AnchorPoint = Vector2.new(0.5, 1)
		self.revealCard.Position = UDim2.new(0.5, 0, 1, -74)
	end
end

function Hud:_buildCollection()
	local page = self.pages.Collection
	self.collectionCount =
		label(page, "Your garden starts with one egg.", 13, C.muted, UDim2.new(), UDim2.new(1, -8, 0, 36))
	self.collectionCount.TextWrapped = true
	local grid = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, page)
	self.collectionGrid = make("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -8, 0, 168),
		CellPadding = UDim2.fromOffset(10, 10),
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
		local card = panel(grid, entry.id, C.paper:Lerp(C.muted, 0.08), UDim2.new(), UDim2.new())
		card.LayoutOrder = index
		local art = eggArt(
			card,
			UDim2.new(0.5, -34, 0, 9),
			UDim2.fromOffset(68, 70),
			C.paper:Lerp(C.muted, 0.2),
			true
		)
		local name =
			label(card, "Mystery friend", 13, C.ink, UDim2.fromOffset(8, 82), UDim2.new(1, -16, 0, 34), true)
		name.TextWrapped = true
		name.TextXAlignment = Enum.TextXAlignment.Center
		local rarity = label(
			card,
			entry.animal.rarity,
			11,
			C.muted,
			UDim2.fromOffset(8, 115),
			UDim2.new(1, -16, 0, 18),
			true
		)
		rarity.TextXAlignment = Enum.TextXAlignment.Center
		local income =
			label(card, "Not discovered", 11, C.muted, UDim2.fromOffset(8, 136), UDim2.new(1, -16, 0, 24))
		income.TextWrapped = true
		income.TextXAlignment = Enum.TextXAlignment.Center
		self.collectionCards[entry.id] =
			{ frame = card, name = name, rarity = rarity, income = income, art = art }
	end
end

function Hud:_buildShop()
	local page = self.pages.Shop
	label(page, "A little faster. A bigger adventure.", 16, C.ink, UDim2.new(), UDim2.new(1, -8, 0, 40), true).TextWrapped =
		true
	self.shopSpeed =
		label(page, "Finding your speed...", 13, C.muted, UDim2.fromOffset(0, 43), UDim2.new(1, -8, 0, 38))
	self.shopSpeed.TextWrapped = true
	self.shopUpgrade = self:_button(
		page,
		"Speed up",
		C.mint,
		UDim2.fromOffset(2, 91),
		UDim2.new(1, -12, 0, 48),
		function()
			self:_action("UpgradeSpeed")
		end
	)
	label(page, "BEYOND THE RED LINE", 11, C.muted, UDim2.fromOffset(0, 163), UDim2.new(1, -8, 0, 24), true)
	self.zoneGuide =
		label(page, "", 13, C.ink, UDim2.fromOffset(0, 197), UDim2.new(1, -8, 0, #self.config.zones * 46))
	self.zoneGuide.TextWrapped = true
	self.zoneGuide.TextYAlignment = Enum.TextYAlignment.Top
	local footer = label(
		page,
		"Guardians stop at their red boundary. Get the egg across, then head home.\n\nUpgrades use earned coins. There are no paid purchases.",
		13,
		C.muted,
		UDim2.fromOffset(0, 214 + #self.config.zones * 46),
		UDim2.new(1, -12, 0, 100)
	)
	footer.TextWrapped = true
	footer.TextYAlignment = Enum.TextYAlignment.Top
end

function Hud:_buildSettings()
	local page = self.pages.Settings
	self.soundButton = self:_button(
		page,
		"Sound effects   ·   On",
		C.paper,
		UDim2.fromOffset(2, 4),
		UDim2.new(1, -12, 0, 48),
		function()
			self.sfxEnabled = not self.sfxEnabled
			self.soundButton.Text = "Sound effects   ·   " .. (if self.sfxEnabled then "On" else "Off")
			if self.sfxEnabled then
				self:_sound("ui")
			end
		end
	)
	self.motionButton = self:_button(
		page,
		"Reduced motion   ·   Off",
		C.paper,
		UDim2.fromOffset(2, 62),
		UDim2.new(1, -12, 0, 48),
		function()
			self.reducedMotion = not self.reducedMotion
			self.motionButton.Text = "Reduced motion   ·   " .. (if self.reducedMotion then "On" else "Off")
			if self.reducedMotion and self.revealTween then
				self.revealTween:Cancel()
				self.revealTween = nil
				self.revealScale.Scale = 1
			end
		end
	)
	self.effectsButton = self:_button(
		page,
		"Visual effects   ·   On",
		C.paper,
		UDim2.fromOffset(2, 120),
		UDim2.new(1, -12, 0, 48),
		function()
			self.effects = not self.effects
			self.effectsButton.Text = "Visual effects   ·   " .. (if self.effects then "On" else "Off")
		end
	)
	local details = label(
		page,
		"Sound effects play for game events; there is no background music.\n\nReduced motion limits decorative movement and hatch animation.\n\nSESSION PROGRESS\nCoins, animals, upgrades, and settings reset when you leave. Saving is not available yet.",
		13,
		C.muted,
		UDim2.fromOffset(3, 190),
		UDim2.new(1, -15, 0, 210)
	)
	details.TextWrapped = true
	details.TextYAlignment = Enum.TextYAlignment.Top
end

function Hud:_buildReveal()
	-- A toast, not a full-screen input blocker: movement and prompts stay available.
	self.revealOverlay = make("Frame", {
		Name = "HatchReveal",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 30,
		Active = false,
	}, self.root)
	self.revealCard =
		panel(self.revealOverlay, "NewFriend", C.paper, UDim2.new(0.5, 0, 1, -74), UDim2.fromOffset(346, 144))
	self.revealCard.AnchorPoint = Vector2.new(0.5, 1)
	self.revealScale = make("UIScale", { Scale = 1 }, self.revealCard)
	self.revealTitle = label(
		self.revealCard,
		"A NEW FRIEND!",
		10,
		C.muted,
		UDim2.fromOffset(91, 12),
		UDim2.new(1, -137, 0, 16),
		true
	)
	self.revealArt =
		eggArt(self.revealCard, UDim2.fromOffset(12, 27), UDim2.fromOffset(65, 78), C.yellow, false)
	self.revealName =
		label(self.revealCard, "", 16, C.ink, UDim2.fromOffset(90, 32), UDim2.new(1, -108, 0, 36), true)
	self.revealName.TextWrapped = true
	self.revealRarity =
		label(self.revealCard, "", 12, C.ink, UDim2.fromOffset(91, 69), UDim2.new(1, -108, 0, 18), true)
	self.revealNote =
		label(self.revealCard, "", 11, C.muted, UDim2.fromOffset(91, 91), UDim2.new(1, -108, 0, 43))
	self.revealNote.TextWrapped = true
	self.revealNote.TextYAlignment = Enum.TextYAlignment.Top
	self:_button(self.revealCard, "×", C.paper, UDim2.new(1, -45, 0, 0), UDim2.fromOffset(44, 44), function()
		self.revealOverlay.Visible = false
	end)
end

function Hud:update(state)
	if self.destroyed or type(state) ~= "table" then
		return
	end
	self.state = state
	self.cashLabel.Text = "$" .. cash(state.cash)
	self.incomeLabel.Text = "+$" .. cash(state.income) .. " / sec"
	self.speedLabel.Text = "Level " .. tostring(state.speedLevel or 0)
	local cost = state.upgradeCost
	local upgradeText = if cost then "Speed up  ·  $" .. cash(cost) else "Maximum speed"
	self.upgrade.Text = upgradeText
	self.shopUpgrade.Text = upgradeText
	self.upgrade.BackgroundColor3 = if cost and (state.cash or 0) >= cost then C.mint else C.paper
	self.shopUpgrade.BackgroundColor3 = self.upgrade.BackgroundColor3
	self.shopSpeed.Text = string.format(
		"Level %d of %d  ·  Run speed %d",
		state.speedLevel or 0,
		self.config.speed.maxLevel,
		state.walkSpeed or self.config.speed.base
	)
	self.deposit.Visible = state.carrying ~= nil
	self.upgrade.Visible = state.carrying == nil
	if state.carrying then
		local pursued = state.escaped ~= true
		self.missionText.Text = if pursued
			then "Run! Cross the red line to lose the guardian."
			else "Egg secured! Take it to garden " .. tostring(state.baseId or "?") .. "."
		self.missionDot.BackgroundColor3 = if pursued then C.pink else C.yellow
		self.mission.BackgroundColor3 = if pursued
			then C.pink:Lerp(C.paper, 0.68)
			else C.yellow:Lerp(C.paper, 0.7)
	else
		local hatches = #(state.hatches or {})
		local animals = #(state.animals or {})
		self.missionText.Text = if hatches > 0
			then "Eggs are warming. Explore while they hatch!"
			elseif animals == 0 then "Follow the path. Hold the egg prompt to steal!"
			else "Garden " .. tostring(state.baseId or "?") .. "  ·  Grow your crew. Upgrade. Explore."
		self.missionDot.BackgroundColor3 = C.mint
		self.mission.BackgroundColor3 = C.paper
	end
	local lines = {}
	for _, zone in ipairs(self.config.zones) do
		local unlocked = (state.speedLevel or 0) >= zone.requiredLevel
		table.insert(
			lines,
			(if unlocked then "Open   " else "Level " .. tostring(zone.requiredLevel) .. "   ") .. zone.name
		)
	end
	self.zoneGuide.Text = table.concat(lines, "\n\n")
	local owned = {}
	for _, animal in ipairs(state.animals or {}) do
		owned[animal.id] = (owned[animal.id] or 0) + 1
	end
	local found, total = 0, 0
	for id, card in pairs(self.collectionCards) do
		total += 1
		local discovered = (state.discovered or {})[id] == true
		local animal = self.config.animals[id]
		local rarityColor = tint(self.config.rarities[animal.rarity].color)
		if discovered then
			found += 1
		end
		card.name.Text = if discovered then animal.name else "Mystery friend"
		card.income.Text = if discovered
			then "$" .. cash(animal.income) .. "/s  ·  Owned " .. tostring(owned[id] or 0)
			else "Not discovered"
		card.rarity.TextColor3 = if discovered then rarityColor:Lerp(C.ink, 0.62) else C.muted
		card.frame.BackgroundColor3 = if discovered
			then rarityColor:Lerp(C.paper, 0.87)
			else C.paper:Lerp(C.muted, 0.08)
		if discovered and not card.discovered then
			card.art:Destroy()
			card.art = animalArt(card.frame, UDim2.new(0.5, -34, 0, 9), UDim2.fromOffset(68, 70), animal)
			card.discovered = true
		end
	end
	self.collectionCount.Text = string.format(
		"%d / %d discovered   ·   %d / %d in your garden",
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
	self.mission.Visible = not self.noticeFrame.Visible
	if self.revealOverlay.Visible and now >= self.revealUntil then
		self.revealOverlay.Visible = false
	end
	local bySlot = {}
	for _, hatch in ipairs(if self.state then self.state.hatches or {} else {}) do
		bySlot[hatch.slot] = hatch
	end
	local occupied = false
	local serverNow = Workspace:GetServerTimeNow()
	for index, slot in ipairs(self.slotLabels) do
		local hatch = bySlot[index]
		slot.Parent.Visible = hatch ~= nil
		if hatch then
			occupied = true
			local remaining = math.max(0, math.ceil(hatch.readyAt - serverNow))
			slot.Text = if remaining > 0
				then "Nest " .. index .. "  ·  " .. remaining .. "s"
				else "Hatching!"
		end
	end
	self.hatching.Visible = occupied
end

function Hud:notice(payload)
	if self.destroyed or type(payload) ~= "table" then
		return
	end
	self.noticeText.Text = tostring(payload.text or "")
	self.noticeFrame.BackgroundColor3 = if payload.kind == "error"
		then C.pink:Lerp(C.paper, 0.35)
		elseif payload.kind == "success" then C.mint
		else C.yellow:Lerp(C.paper, 0.3)
	self.noticeUntil = os.clock() + 4
	self.noticeFrame.Visible = true
	self.mission.Visible = false
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
	self.revealTitle.Text = if payload.kept == false then "DISCOVERED!" else "A NEW FRIEND!"
	self.revealName.Text = animal.name
	self.revealRarity.Text = animal.rarity .. "  ·  $" .. cash(payload.income or animal.income) .. "/s"
	self.revealRarity.TextColor3 = tint(rarity.color):Lerp(C.ink, 0.62)
	self.revealNote.Text = if payload.kept == false
		then "Collection updated. Your stronger earners kept their garden spots."
		elseif payload.replacedName then "Moved in for " .. payload.replacedName .. "."
		else animal.personality or "Your newest garden friend!"
	self.revealCard.BackgroundColor3 = tint(rarity.color):Lerp(C.paper, 0.89)
	self.revealArt:Destroy()
	self.revealArt = animalArt(self.revealCard, UDim2.fromOffset(12, 27), UDim2.fromOffset(65, 78), animal)
	self.revealOverlay.Visible = true
	self.revealUntil = os.clock() + 3
	if self.revealTween then
		self.revealTween:Cancel()
		self.revealTween = nil
	end
	if not self.reducedMotion and self.effects then
		self.revealScale.Scale = 0.94
		self.revealTween = TweenService:Create(
			self.revealScale,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
