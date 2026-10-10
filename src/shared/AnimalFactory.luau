-- Original, asset-free toy animals. Models face local -Z and stand at local Y = 0.
local AnimalFactory = {}

local WHITE = Color3.fromRGB(255, 252, 237)
local INK = Color3.fromRGB(32, 36, 57)
local PINK = Color3.fromRGB(255, 141, 172)
local ORANGE = Color3.fromRGB(255, 175, 68)

local ANIMATION_ROLES = {
	Foot = "Foot",
	Ear = "Ear",
	InnerEar = "Ear",
	HeadTuft = "Ear",
	Wing = "Wing",
	Flipper = "Wing",
	TinyArm = "Arm",
	Tail = "Tail",
	CottonTail = "Tail",
	TailSpike = "Tail",
}

local function colorFrom(value)
	if typeof(value) == "Color3" then
		return value
	end
	value = value or {}
	return Color3.fromRGB(value.r or value[1] or 140, value.g or value[2] or 210, value.b or value[3] or 140)
end

local function piece(model, name, size, position, color, shape, rotation)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	part.Color = color
	part.Shape = shape or Enum.PartType.Ball
	part.Material = Enum.Material.SmoothPlastic
	part.Reflectance = 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local animationRole = ANIMATION_ROLES[name] or "Body"
	if animationRole then
		part:SetAttribute("AnimationRole", animationRole)
		part:SetAttribute("AnimationSide", if position.X < 0 then -1 else 1)
		-- A turtle's diagonal feet step together; other pets alternate left/right.
		part:SetAttribute("AnimationPhase", if position.Z > 0.5 then math.pi else 0)
	end
	part.Parent = model
	return part
end

local function newModel(name)
	local model = Instance.new("Model")
	model.Name = name
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local root = piece(model, "Root", Vector3.new(0.2, 0.2, 0.2), Vector3.zero, WHITE)
	root.Transparency = 1
	root.CastShadow = false
	model.PrimaryPart = root
	return model
end

local function eyes(model, y, z, spacing, scale)
	scale = scale or 1
	for _, side in ipairs({ -1, 1 }) do
		local x = side * spacing
		piece(model, "Eye", Vector3.new(0.43, 0.49, 0.32) * scale, Vector3.new(x, y, z), WHITE)
		piece(
			model,
			"Pupil",
			Vector3.new(0.2, 0.28, 0.13) * scale,
			Vector3.new(x + 0.045 * scale, y - 0.01, z - 0.16 * scale),
			INK
		)
		piece(
			model,
			"EyeShine",
			Vector3.new(0.07, 0.09, 0.05) * scale,
			Vector3.new(x + 0.01, y + 0.055 * scale, z - 0.23 * scale),
			WHITE
		)
	end
end

local function feet(model, color, x, z, size)
	for _, side in ipairs({ -1, 1 }) do
		piece(model, "Foot", size or Vector3.new(0.7, 0.35, 0.85), Vector3.new(side * x, 0.19, z), color)
	end
end

local function cheeks(model, x, y, z)
	for _, side in ipairs({ -1, 1 }) do
		piece(model, "Cheek", Vector3.new(0.28, 0.15, 0.09), Vector3.new(side * x, y, z), PINK)
	end
end

local builders = {}

function builders.turtle(model, color)
	piece(model, "Shell", Vector3.new(2.5, 1.35, 2.65), Vector3.new(0, 0.95, 0.25), color)
	piece(
		model,
		"ShellCrown",
		Vector3.new(1.35, 0.35, 1.5),
		Vector3.new(0, 1.59, 0.25),
		color:Lerp(WHITE, 0.3)
	)
	for _, side in ipairs({ -1, 1 }) do
		piece(
			model,
			"ShellPlate",
			Vector3.new(0.65, 0.25, 1.02),
			Vector3.new(side * 0.72, 1.4, 0.28),
			color:Lerp(INK, 0.12),
			nil,
			CFrame.Angles(0, 0, math.rad(side * -28))
		)
	end
	piece(
		model,
		"ShellBelly",
		Vector3.new(2.25, 0.4, 2.3),
		Vector3.new(0, 0.48, 0.25),
		Color3.fromRGB(245, 219, 142)
	)
	local skin = color:Lerp(Color3.fromRGB(154, 231, 120), 0.6)
	piece(model, "Head", Vector3.new(1.4, 1.05, 1.2), Vector3.new(0, 0.92, -1.12), skin)
	feet(model, skin, 0.97, -0.57, Vector3.new(0.65, 0.45, 0.8))
	feet(model, skin, 0.97, 1.04, Vector3.new(0.65, 0.45, 0.8))
	piece(model, "Tail", Vector3.new(0.38, 0.32, 0.7), Vector3.new(0, 0.5, 1.64), skin)
	eyes(model, 1.13, -1.6, 0.36, 0.82)
	cheeks(model, 0.5, 0.8, -1.57)
	piece(model, "Smile", Vector3.new(0.33, 0.08, 0.09), Vector3.new(0, 0.75, -1.71), INK)
end

function builders.rabbit(model, color)
	piece(model, "Body", Vector3.new(1.8, 1.75, 1.45), Vector3.new(0, 1.02, 0.16), color)
	piece(model, "Belly", Vector3.new(1.05, 1.17, 0.28), Vector3.new(0, 0.94, -0.53), WHITE)
	piece(model, "Head", Vector3.new(1.8, 1.5, 1.5), Vector3.new(0, 1.99, -0.22), color)
	for _, side in ipairs({ -1, 1 }) do
		local tilt = CFrame.Angles(0, 0, math.rad(side * -12))
		piece(
			model,
			"Ear",
			Vector3.new(0.56, 1.58, 0.44),
			Vector3.new(side * 0.47, 3.08, -0.12),
			color,
			nil,
			tilt
		)
		piece(
			model,
			"InnerEar",
			Vector3.new(0.28, 1.12, 0.12),
			Vector3.new(side * 0.47, 3.1, -0.35),
			PINK,
			nil,
			tilt
		)
	end
	feet(model, color, 0.57, -0.45, Vector3.new(0.73, 0.38, 1))
	piece(model, "CottonTail", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 0.94, 0.9), WHITE)
	eyes(model, 2.13, -0.91, 0.44, 0.84)
	piece(model, "Nose", Vector3.new(0.27, 0.2, 0.17), Vector3.new(0, 1.83, -1), PINK)
	piece(
		model,
		"GoofyTooth",
		Vector3.new(0.2, 0.22, 0.1),
		Vector3.new(0.06, 1.61, -0.95),
		WHITE,
		Enum.PartType.Block
	)
end

function builders.duck(model, color)
	piece(model, "Body", Vector3.new(2.1, 1.8, 1.85), Vector3.new(0, 1.07, 0.2), color)
	piece(model, "Head", Vector3.new(1.57, 1.47, 1.47), Vector3.new(0, 2.04, -0.28), color)
	for _, side in ipairs({ -1, 1 }) do
		piece(
			model,
			"Wing",
			Vector3.new(0.5, 1.1, 1.22),
			Vector3.new(side * 0.98, 1.1, 0.23),
			color:Lerp(WHITE, 0.18)
		)
	end
	piece(model, "Beak", Vector3.new(1.06, 0.34, 0.92), Vector3.new(0, 1.83, -1.02), ORANGE)
	feet(model, ORANGE, 0.51, -0.26, Vector3.new(0.75, 0.3, 0.95))
	eyes(model, 2.26, -0.92, 0.39, 0.83)
	piece(
		model,
		"HeadTuft",
		Vector3.new(0.35, 0.65, 0.42),
		Vector3.new(0.04, 2.88, -0.1),
		color,
		nil,
		CFrame.Angles(0, 0, math.rad(-22))
	)
end

function builders.frog(model, color)
	piece(model, "Body", Vector3.new(2, 1.6, 1.65), Vector3.new(0, 0.94, 0.1), color)
	piece(model, "Belly", Vector3.new(1.3, 0.98, 0.3), Vector3.new(0, 0.78, -0.67), color:Lerp(WHITE, 0.7))
	piece(model, "Head", Vector3.new(2.32, 1.24, 1.55), Vector3.new(0, 1.66, -0.15), color)
	for _, side in ipairs({ -1, 1 }) do
		piece(model, "EyeBump", Vector3.new(0.89, 0.94, 0.82), Vector3.new(side * 0.65, 2.11, -0.34), color)
	end
	eyes(model, 2.13, -0.73, 0.65, 1.15)
	feet(model, color, 0.89, -0.38, Vector3.new(1, 0.35, 1.06))
	piece(model, "Smile", Vector3.new(0.75, 0.09, 0.1), Vector3.new(0, 1.45, -0.93), INK)
	piece(model, "Tongue", Vector3.new(0.28, 0.22, 0.11), Vector3.new(0.22, 1.34, -0.94), PINK)
	cheeks(model, 0.91, 1.55, -0.78)
end

function builders.cat(model, color)
	piece(model, "Body", Vector3.new(1.73, 1.67, 1.5), Vector3.new(0, 1.03, 0.18), color)
	piece(model, "Head", Vector3.new(2, 1.6, 1.48), Vector3.new(0, 2.04, -0.15), color)
	for _, side in ipairs({ -1, 1 }) do
		piece(
			model,
			"Ear",
			Vector3.new(0.65, 0.98, 0.55),
			Vector3.new(side * 0.65, 2.85, -0.04),
			color,
			nil,
			CFrame.Angles(0, 0, math.rad(side * -24))
		)
		piece(model, "InnerEar", Vector3.new(0.31, 0.5, 0.12), Vector3.new(side * 0.65, 2.92, -0.3), PINK)
	end
	piece(model, "Muzzle", Vector3.new(0.9, 0.49, 0.32), Vector3.new(0, 1.75, -0.82), WHITE)
	piece(model, "Nose", Vector3.new(0.25, 0.18, 0.16), Vector3.new(0, 1.88, -1), PINK)
	for _, side in ipairs({ -1, 1 }) do
		for index = 1, 2 do
			piece(
				model,
				"Whisker",
				Vector3.new(0.46, 0.035, 0.035),
				Vector3.new(side * 0.76, 1.73 + index * 0.13, -0.87),
				INK,
				Enum.PartType.Block,
				CFrame.Angles(0, 0, side * (index - 1.5) * 0.24)
			)
		end
	end
	feet(model, WHITE, 0.48, -0.34)
	piece(
		model,
		"Tail",
		Vector3.new(0.42, 1.78, 0.48),
		Vector3.new(0.78, 1.14, 0.99),
		color,
		nil,
		CFrame.Angles(0, 0, math.rad(-29))
	)
	eyes(model, 2.19, -0.82, 0.47, 0.83)
end

function builders.penguin(model, color)
	piece(model, "Body", Vector3.new(1.85, 2.3, 1.75), Vector3.new(0, 1.42, 0.1), color)
	piece(model, "Belly", Vector3.new(1.34, 1.85, 0.4), Vector3.new(0, 1.28, -0.66), WHITE)
	piece(model, "Head", Vector3.new(1.7, 1.45, 1.56), Vector3.new(0, 2.39, -0.06), color)
	for _, side in ipairs({ -1, 1 }) do
		piece(
			model,
			"Flipper",
			Vector3.new(0.37, 1.56, 0.78),
			Vector3.new(side * 0.99, 1.38, 0.09),
			color,
			nil,
			CFrame.Angles(0, 0, math.rad(side * 23))
		)
	end
	feet(model, ORANGE, 0.48, -0.42, Vector3.new(0.74, 0.31, 0.95))
	eyes(model, 2.54, -0.78, 0.4, 0.86)
	piece(model, "Beak", Vector3.new(0.61, 0.34, 0.5), Vector3.new(0, 2.22, -0.91), ORANGE)
	cheeks(model, 0.61, 2.22, -0.76)
end

function builders.dinosaur(model, color)
	piece(model, "Body", Vector3.new(1.83, 1.95, 1.75), Vector3.new(0, 1.22, 0.17), color)
	piece(model, "Belly", Vector3.new(1.15, 1.35, 0.32), Vector3.new(0, 1.1, -0.66), color:Lerp(WHITE, 0.58))
	piece(model, "Head", Vector3.new(1.94, 1.5, 1.65), Vector3.new(0, 2.39, -0.16), color)
	piece(model, "Snout", Vector3.new(1.76, 0.87, 1.15), Vector3.new(0, 2.14, -0.9), color)
	for _, side in ipairs({ -1, 1 }) do
		piece(model, "TinyArm", Vector3.new(0.4, 0.65, 0.55), Vector3.new(side * 0.93, 1.43, -0.35), color)
		piece(model, "Nostril", Vector3.new(0.12, 0.12, 0.08), Vector3.new(side * 0.4, 2.34, -1.43), INK)
	end
	feet(model, color, 0.6, -0.31, Vector3.new(0.81, 0.45, 1.13))
	piece(model, "Tail", Vector3.new(0.76, 0.76, 1.71), Vector3.new(0, 0.74, 1.48), color)
	piece(model, "BackSpike", Vector3.new(0.62, 0.75, 0.43), Vector3.new(0, 2.4, 0.64), ORANGE)
	piece(model, "TailSpike", Vector3.new(0.5, 0.5, 0.4), Vector3.new(0, 1.25, 1.34), ORANGE)
	eyes(model, 2.68, -0.81, 0.52, 0.86)
	piece(
		model,
		"GoofyTooth",
		Vector3.new(0.22, 0.26, 0.12),
		Vector3.new(0.42, 1.76, -1.32),
		WHITE,
		Enum.PartType.Block
	)
end

function AnimalFactory.create(species, color, name)
	local model = newModel(name or species)
	model:SetAttribute("Species", species)
	model:SetAttribute("VisualRole", "Animal")
	local builder = builders[species] or builders.frog
	builder(model, colorFrom(color))
	local count = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			-- Replicate the unscaled authored pose, so late clients never cache a partial moving rig.
			part:SetAttribute("AnimationRest", model:GetPivot():ToObjectSpace(part.CFrame))
			count += 1
		end
	end
	model:SetAttribute("RigPartCount", count)
	return model
end

function AnimalFactory.egg(color, name)
	local model = newModel(name or "GoofyEgg")
	local tint = colorFrom(color)
	piece(model, "Shell", Vector3.new(2.3, 3, 2.3), Vector3.zero, tint:Lerp(WHITE, 0.65))
	piece(model, "Spot", Vector3.new(0.66, 0.82, 0.13), Vector3.new(-0.45, 0.18, -1.01), tint)
	piece(model, "Spot", Vector3.new(0.46, 0.5, 0.13), Vector3.new(0.57, -0.47, -0.93), tint)
	piece(model, "Spot", Vector3.new(0.41, 0.54, 0.13), Vector3.new(0.39, 0.88, -0.8), tint)
	piece(model, "Spot", Vector3.new(0.13, 0.68, 0.56), Vector3.new(1.02, -0.25, 0.35), tint)
	model:SetAttribute("VisualRole", "Egg")
	return model
end

return AnimalFactory
