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
	local Hud = require(required(required(playerGui, "GoofyUI"), "Hud"))
	local remotes = required(packageFolder, "Remotes")
	local stateRemote = required(remotes, "State")
	local actionRemote = required(remotes, "Action")
	local noticeRemote = required(remotes, "Notice")
	local hatchRemote = required(remotes, "Hatch")
	local getState = required(remotes, "GetState")

	hud = Hud.new(config, {
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
		end
	end)
	connect(hatchRemote.OnClientEvent, function(payload)
		if not closed then
			hud:reveal(payload)
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
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	closed = true
	showBootstrapError()
	return
end

local function observe(instance)
	if not instance:IsA("Model") then
		return
	end
	if instance:GetAttribute("VisualRole") == "Animal" then
		-- Only static collection models bob. Never move a server-controlled guardian here.
		animated[instance] =
			{ origin = instance:GetPivot(), phase = math.random() * math.pi * 2, moved = false }
	elseif instance:GetAttribute("VisualRole") == "Guardian" then
		guardians[instance] = true
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
		local active = hud.effects and not hud.reducedMotion
		local now = os.clock()
		local camera = Workspace.CurrentCamera
		for model, entry in pairs(animated) do
			if not model.Parent then
				animated[model] = nil
			elseif active and camera and (entry.origin.Position - camera.CFrame.Position).Magnitude < 160 then
				local wave = math.sin(now * 2.1 + entry.phase)
				model:PivotTo(
					entry.origin * CFrame.new(0, wave * 0.12, 0) * CFrame.Angles(0, 0, wave * 0.035)
				)
				entry.moved = true
			elseif entry.moved then
				model:PivotTo(entry.origin)
				entry.moved = false
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
		end
	end
	table.clear(animated)
	table.clear(countdowns)
	table.clear(guardians)
	hud:destroy()
end)
