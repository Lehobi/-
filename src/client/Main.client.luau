--!nonstrict
-- Presentation only. The server owns cash, movement levels, catches, and hatch results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local connections = {}
local animated = {}
local countdowns = {}
local guardians = {}
local closed = false
local receivedState = false
local hud
local sound
local PetMotion

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function required(parent, name)
	local child = parent:WaitForChild(name, 25)
	assert(child, "Missing " .. parent:GetFullName() .. "." .. name)
	return child
end

local function showBootstrapError()
	local screen = Instance.new("ScreenGui")
	screen.Name = "GoofyEggStartupError"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui
	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = UDim2.new(0.5, 0, 0, 70)
	text.Size = UDim2.new(0.9, 0, 0, 94)
	text.BackgroundColor3 = Color3.fromRGB(255, 216, 105)
	text.TextColor3 = Color3.fromRGB(39, 37, 63)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 17
	text.TextWrapped = true
	text.Text =
		"Your goofy world could not finish loading. Rejoin to try again.\nIn Studio, check Output for the missing setup item."
	text.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = text
end

local ok, problem = pcall(function()
	local packageFolder = required(ReplicatedStorage, "GoofyEgg")
	local config = require(required(required(packageFolder, "Shared"), "Config"))
	PetMotion = require(required(required(packageFolder, "Shared"), "PetMotion"))
	local SoundEffects = require(required(script.Parent, "SoundEffects"))
	sound = SoundEffects.new(config)
	local Hud = require(required(required(playerGui, "GoofyUI"), "Hud"))
	local remotes = required(packageFolder, "Remotes")
	local stateRemote = required(remotes, "State")
	local actionRemote = required(remotes, "Action")
	local noticeRemote = required(remotes, "Notice")
	local hatchRemote = required(remotes, "Hatch")
	local getState = required(remotes, "GetState")

	hud = Hud.new(config, {
		sound = function(cue)
			if not closed then
				sound:setEnabled(not hud or hud.sfxEnabled ~= false)
				sound:play(cue)
			end
		end,
		action = function(action)
			if not closed and (action == "UpgradeSpeed" or action == "DepositEgg") then
				actionRemote:FireServer(action)
			end
		end,
	})
	-- Subscribe first so a live server update cannot be missed during the initial request.
	connect(stateRemote.OnClientEvent, function(state)
		if not closed and type(state) == "table" then
			receivedState = true
			hud:update(state)
		end
	end)
	connect(noticeRemote.OnClientEvent, function(payload)
		if not closed then
			hud:notice(payload)
			if type(payload) == "table" and type(payload.sound) == "string" then
				sound:setEnabled(hud.sfxEnabled ~= false)
				sound:play(payload.sound)
			end
		end
	end)
	connect(hatchRemote.OnClientEvent, function(payload)
		if not closed then
			hud:reveal(payload)
			sound:setEnabled(hud.sfxEnabled ~= false)
			sound:play("hatch")
		end
	end)

	task.spawn(function()
		local success, initial = pcall(function()
			return getState:InvokeServer()
		end)
		if closed then
			return
		end
		if success and type(initial) == "table" then
			-- A periodic live update may have arrived while InvokeServer was in flight.
			if not receivedState then
				receivedState = true
				hud:update(initial)
			end
		elseif not receivedState then
			hud:notice({ text = "Your base is still loading. Waiting for the server...", kind = "info" })
		end
	end)
	task.delay(15, function()
		if not closed and not receivedState then
			hud:notice({
				text = "Still waiting for a base. If this continues, rejoin the server.",
				kind = "error",
			})
		end
	end)
end)

if not ok then
	warn("Goofy Egg client setup failed: " .. tostring(problem))
	if hud then
		hud:destroy()
	end
	if sound then
		sound:destroy()
	end
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	closed = true
	showBootstrapError()
	return
end

local function cacheRig(model)
	local origin = model:GetPivot()
	local parts = {}
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") and child ~= model.PrimaryPart then
			table.insert(parts, {
				part = child,
				rest = origin:ToObjectSpace(child.CFrame),
				role = child:GetAttribute("AnimationRole"),
				side = child:GetAttribute("AnimationSide") or 1,
				phase = child:GetAttribute("AnimationPhase") or 0,
			})
		end
	end
	return {
		origin = origin,
		parts = parts,
		species = model:GetAttribute("Species"),
		scale = model:GetScale(),
		seed = model:GetAttribute("RoamSeed") or 0,
		posed = false,
		moved = false,
	}
end

-- All offsets are applied to cached rest poses, never to the previous frame.
-- Root transforms belong to roaming (pets) or the server (guardians).
local function poseRig(entry, pivot, now, speed, stride, active)
	local weight = if active then math.clamp(speed / 1.8, 0, 1) else 0
	local gait = stride * 3.2
	local bob = math.abs(math.sin(gait)) * 0.045 * weight
	local roll = math.sin(gait) * 0.025 * weight
	if entry.species == "rabbit" or entry.species == "frog" then
		bob = math.abs(math.sin(gait)) * 0.28 * weight
	elseif entry.species == "duck" or entry.species == "penguin" then
		roll = math.sin(gait) * 0.065 * weight
	end
	local body = CFrame.new(0, bob * entry.scale, 0) * CFrame.Angles(0, 0, roll)
	local idle = if active then math.sin(now * 1.9 + entry.seed) else 0
	for _, joint in ipairs(entry.parts) do
		if joint.part.Parent then
			local offset = body
			local rotation = CFrame.identity
			if joint.role == "Foot" then
				local step = gait + joint.phase + (if joint.side < 0 then math.pi else 0)
				if entry.species == "frog" or entry.species == "rabbit" then
					step = gait -- These two hop with both feet together.
				end
				offset = CFrame.new(
					0,
					math.max(0, math.sin(step)) * 0.26 * entry.scale * weight,
					math.cos(step) * 0.23 * entry.scale * weight
				)
				rotation = CFrame.Angles(math.sin(step) * 0.22 * weight, 0, 0)
			elseif joint.role == "Wing" or joint.role == "Arm" then
				rotation = CFrame.Angles(
					math.sin(gait) * 0.18 * weight,
					0,
					joint.side * (idle * 0.035 + math.sin(gait) * 0.22 * weight)
				)
			elseif joint.role == "Ear" then
				rotation = CFrame.Angles(-math.sin(gait) * 0.09 * weight, 0, idle * 0.045 * joint.side)
			elseif joint.role == "Tail" then
				rotation = CFrame.Angles(0, idle * 0.18 + math.sin(gait) * 0.1 * weight, idle * 0.05)
			end
			joint.part.CFrame = pivot * offset * joint.rest * rotation
		end
	end
	entry.posed = active
end

local function observe(instance)
	if not instance:IsA("Model") then
		return
	end
	if instance:GetAttribute("VisualRole") == "Animal" then
		if animated[instance] then
			return
		end
		local x, y, z = instance:GetAttribute("RoamCenterX"), instance:GetAttribute("RoamCenterY"), instance:GetAttribute("RoamCenterZ")
		local halfX, halfZ = instance:GetAttribute("RoamHalfX"), instance:GetAttribute("RoamHalfZ")
		if type(x) == "number" and type(y) == "number" and type(z) == "number" and type(halfX) == "number" and type(halfZ) == "number" then
			local entry = cacheRig(instance)
			entry.center = Vector3.new(x, y, z)
			entry.plan = PetMotion.new(entry.seed, halfX, halfZ, entry.species)
			animated[instance] = entry
		end
	elseif instance:GetAttribute("VisualRole") == "Guardian" then
		if not guardians[instance] then
			guardians[instance] = cacheRig(instance)
		end
	end
	if type(instance:GetAttribute("ReadyAt")) == "number" then
		countdowns[instance] = true
	end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
	observe(descendant)
end
connect(Workspace.DescendantAdded, function(instance)
	-- Builders set model attributes and parents in the same task; defer until they finish.
	task.defer(function()
		if not closed and instance.Parent then
			observe(instance)
		end
	end)
end)
connect(Workspace.DescendantRemoving, function(instance)
	animated[instance] = nil
	countdowns[instance] = nil
	guardians[instance] = nil
end)

local accumulated = 0
local countdownElapsed = 0
connect(RunService.Heartbeat, function(dt)
	if closed then
		return
	end
	accumulated += dt
	countdownElapsed += dt
	-- Decorative world updates are capped at 20Hz, keeping mobile cost predictable.
	if accumulated >= 0.05 then
		accumulated = 0
		local active = hud.effects
		local gaitEnabled = active and not hud.reducedMotion
		local now = Workspace:GetServerTimeNow()
		local camera = Workspace.CurrentCamera
		for model, entry in pairs(animated) do
			if not model.Parent then
				animated[model] = nil
			elseif active and camera and (entry.center - camera.CFrame.Position).Magnitude < 160 then
				local sample = PetMotion.sample(entry.plan, now)
				local pivot = CFrame.new(entry.center + Vector3.new(sample.x, 0, sample.z))
					* CFrame.Angles(0, sample.heading, 0)
				model:PivotTo(pivot)
				poseRig(entry, pivot, now, sample.speed, sample.stride, gaitEnabled)
				entry.moved = true
			elseif entry.posed then
				poseRig(entry, model:GetPivot(), now, 0, 0, false)
			end
		end
		for model, entry in pairs(guardians) do
			if not model.Parent then
				guardians[model] = nil
			elseif camera and (model:GetPivot().Position - camera.CFrame.Position).Magnitude < 160 then
				local moving = model:GetAttribute("Chasing") or model:GetAttribute("State") == "Returning"
				local speed = if moving then 3 else 0
				poseRig(entry, model:GetPivot(), now, speed, now * speed, gaitEnabled)
			elseif entry.posed then
				poseRig(entry, model:GetPivot(), now, 0, 0, false)
			end
		end
	end
	if countdownElapsed >= 0.25 then
		countdownElapsed = 0
		local serverNow = Workspace:GetServerTimeNow()
		for model in pairs(countdowns) do
			local readyAt = model:GetAttribute("ReadyAt")
			if not model.Parent or type(readyAt) ~= "number" then
				countdowns[model] = nil
			else
				local countdown = model:FindFirstChild("Countdown", true)
				if countdown and countdown:IsA("TextLabel") then
					local remaining = math.max(0, math.ceil(readyAt - serverNow))
					countdown.Text = if remaining > 0 then "Hatching · " .. remaining .. "s" else "Hatching!"
				end
			end
		end
		for model in pairs(guardians) do
			if not model.Parent then
				guardians[model] = nil
			else
				local stateLabel = model:FindFirstChild("State", true)
				if stateLabel and stateLabel:IsA("TextLabel") then
					stateLabel.Text = if model:GetAttribute("Chasing")
						then "HEY! THAT'S MY EGG!"
						else "Keeping one eye on the nest..."
				end
			end
		end
	end
end)

connect(script.Destroying, function()
	closed = true
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	for model, entry in pairs(animated) do
		if model.Parent and entry.moved then
			model:PivotTo(entry.origin)
			poseRig(entry, entry.origin, 0, 0, 0, false)
		end
	end
	for model, entry in pairs(guardians) do
		if model.Parent then
			poseRig(entry, model:GetPivot(), 0, 0, 0, false)
		end
	end
	table.clear(animated)
	table.clear(countdowns)
	table.clear(guardians)
	hud:destroy()
	sound:destroy()
end)
