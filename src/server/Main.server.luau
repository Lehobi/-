-- All rewards, balances, egg ownership, upgrades, and chase decisions live on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("GoofyEgg"):WaitForChild("Shared")
local remotes = ReplicatedStorage.GoofyEgg.Remotes
local Config = require(shared.Config)
local Economy = require(shared.Economy)
local AnimalFactory = require(shared.AnimalFactory)
local Session = require(script.Parent.Session)
local World = require(script.Parent.World)

Economy.validateConfig()
local world = World.build(Config)
local rng = Random.new()
local sessions = {}
local owners = {}
local guardians = {}
local connections = {}
local lastAction = {}
local lastRead = {}
local motion = {}
local characterConnections = {}
local carryModels = {}
local shuttingDown = false
local checkMotion

local function clock()
	return Workspace:GetServerTimeNow()
end

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function notice(player, text, kind)
	remotes.Notice:FireClient(player, { text = text, kind = kind or "info" })
end

local function body(player)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

local function flatDistance(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function near(player, position, distance)
	if checkMotion and not checkMotion(player, clock()) then
		return false
	end
	local root = body(player)
	return root ~= nil and (root.Position - position).Magnitude <= distance
end

local function send(player)
	local session = sessions[player]
	if not session then
		return
	end
	local snapshot = session:snapshot()
	local leaderboard = player:FindFirstChild("leaderstats")
	if leaderboard then
		leaderboard.Cash.Value = math.floor(snapshot.cash)
		leaderboard.Speed.Value = snapshot.speedLevel
	end
	remotes.State:FireClient(player, snapshot)
end

local function clearCarry(player)
	local model = carryModels[player]
	if model then
		model:Destroy()
		carryModels[player] = nil
	end
end

local function showCarry(player, zone)
	clearCarry(player)
	local root = body(player)
	if not root then
		return
	end
	local model = AnimalFactory.egg(zone.color, "CarriedEgg")
	model:PivotTo(root.CFrame * CFrame.new(0, 1, -2.8))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
		end
	end
	model.Parent = player.Character
	carryModels[player] = model
end

local function endChase(player)
	for _, guardian in guardians do
		if guardian.target == player then
			guardian.target = nil
			guardian.state = "Returning"
			guardian.world.guardian:SetAttribute("Chasing", false)
		end
	end
end

local function resetMotion(player)
	local root = body(player)
	motion[player] = if root then { position = root.Position, time = clock(), credit = 8 } else nil
end

local function returnHome(player)
	local session = sessions[player]
	local root = body(player)
	if session and root then
		player.Character:PivotTo(world.bases[session.baseId].spawn)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		resetMotion(player)
	end
end

local function loseEgg(player, message, teleport)
	local session = sessions[player]
	if not session then
		return
	end
	local hadEgg = session:loseCarry() ~= nil
	clearCarry(player)
	endChase(player)
	if teleport then
		returnHome(player)
	end
	if message and hadEgg then
		notice(player, message, "warning")
	end
	send(player)
end

local function deposit(player)
	local session = sessions[player]
	if not session or not session.carrying then
		return
	end
	local base = world.bases[session.baseId]
	if not near(player, base.depositPrompt.Parent.Position, 14) then
		return
	end
	local hatch = session:deposit(clock())
	if not hatch then
		notice(player, "All hatch slots are busy!", "warning")
		return
	end
	clearCarry(player)
	endChase(player)
	world:showHatch(session.baseId, hatch.slot, hatch.zoneId, hatch.readyAt)
	notice(player, "Safe at home! Your egg is hatching.", "success")
	send(player)
end

local function upgrade(player)
	local session = sessions[player]
	if not session or not body(player) then
		return
	end
	local ok, reason = session:upgrade()
	if ok then
		local _, humanoid = body(player)
		humanoid.WalkSpeed = Economy.walkSpeed(session.speedLevel)
		notice(player, "Speed level " .. session.speedLevel .. "!", "success")
	else
		notice(player, reason, "warning")
	end
	send(player)
end

local function permitted(player)
	local now = clock()
	if now - (lastAction[player] or -math.huge) < 0.25 then
		return false
	end
	lastAction[player] = now
	return sessions[player] ~= nil
end

for _, zone in Config.zones do
	local zoneWorld = world.zones[zone.id]
	local guardian = { world = zoneWorld, state = "Idle", target = nil, readyAt = 0, startedAt = 0 }
	guardians[zone.id] = guardian
	connect(zoneWorld.prompt.Triggered, function(player)
		if not permitted(player) or guardian.state ~= "Idle" then
			return
		end
		-- Triggered can be forged by exploit clients; check actual alive character and egg distance.
		if not near(player, zoneWorld.egg:GetPivot().Position, 13) then
			return
		end
		local session = sessions[player]
		local ok, reason = session:steal(zone.id)
		if not ok then
			notice(player, reason, "warning")
			return
		end
		guardian.state = "Chasing"
		guardian.target = player
		guardian.startedAt = clock()
		guardian.world.guardian:SetAttribute("Chasing", true)
		world:setEggAvailable(zone.id, false)
		showCarry(player, zone)
		notice(
			player,
			"The " .. zone.guardian .. " woke up! Run to base " .. session.baseId .. "!",
			"warning"
		)
		send(player)
	end)
end

for _, base in world.bases do
	connect(base.depositPrompt.Triggered, function(player)
		local session = sessions[player]
		if session and session.baseId == base.id and permitted(player) then
			deposit(player)
		end
	end)
	connect(base.upgradePrompt.Triggered, function(player)
		local session = sessions[player]
		if
			session
			and session.baseId == base.id
			and permitted(player)
			and near(player, base.upgradePrompt.Parent.Position, 13)
		then
			upgrade(player)
		end
	end)
end

connect(remotes.Action.OnServerEvent, function(player, action, ...)
	-- Only fixed intents cross this boundary. Never accept prices, results, level, or target users.
	if typeof(action) ~= "string" or select("#", ...) ~= 0 or not permitted(player) then
		return
	end
	if action == "UpgradeSpeed" then
		upgrade(player)
	elseif action == "DepositEgg" then
		deposit(player)
	end
end)

remotes.GetState.OnServerInvoke = function(player, ...)
	if select("#", ...) ~= 0 then
		return nil
	end
	local now = clock()
	if now - (lastRead[player] or -math.huge) < 0.5 then
		return nil
	end
	lastRead[player] = now
	return if sessions[player] then sessions[player]:snapshot() else nil
end

local function onCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or not sessions[player] or character ~= player.Character then
		return
	end
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end
	humanoid.WalkSpeed = Economy.walkSpeed(sessions[player].speedLevel)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 40
	returnHome(player)
	characterConnections[player] = humanoid.Died:Connect(function()
		loseEgg(player, "Oops! Your egg was lost. Your animals are safe.", false)
	end)
	send(player)
end

local function addPlayer(player)
	if sessions[player] or shuttingDown then
		return
	end
	local baseId
	for id = 1, #world.bases do
		if not owners[id] then
			baseId = id
			break
		end
	end
	if not baseId then
		player:Kick("All five bases are occupied. Please join another server.")
		return
	end
	owners[baseId] = player
	sessions[player] = Session.new(baseId, Config, Economy)
	world:setBaseOwner(baseId, player)
	local leaderboard = Instance.new("Folder")
	leaderboard.Name = "leaderstats"
	for _, name in { "Cash", "Speed" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = leaderboard
	end
	leaderboard.Parent = player
	-- Keep per-player connections separate so leaving players are not retained by closures.
	local added = player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	local removing = player.CharacterRemoving:Connect(function()
		loseEgg(player, nil, false)
		motion[player] = nil
	end)
	sessions[player].connections = { added, removing }
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

local function removePlayer(player)
	lastAction[player] = nil
	lastRead[player] = nil
	local session = sessions[player]
	if not session then
		return
	end
	clearCarry(player)
	endChase(player)
	for _, connection in session.connections do
		connection:Disconnect()
	end
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end
	world:setBaseOwner(session.baseId, nil)
	owners[session.baseId] = nil
	sessions[player] = nil
	lastAction[player] = nil
	lastRead[player] = nil
	motion[player] = nil
	characterConnections[player] = nil
end

-- Conservative displacement budget: limits obvious teleports/speed edits during egg runs.
-- This supplements server distance/ownership checks; Studio latency testing is still required.
checkMotion = function(player, now)
	local root, humanoid = body(player)
	local session = sessions[player]
	if not root or not session then
		return false
	end
	local speed = Economy.walkSpeed(session.speedLevel)
	humanoid.WalkSpeed = speed
	local previous = motion[player]
	if not previous then
		resetMotion(player)
		return true
	end
	local elapsed = now - previous.time
	local distance = flatDistance(root.Position, previous.position)
	local available = previous.credit + speed * 1.2 * elapsed
	local invalid = distance ~= distance
		or distance == math.huge
		or distance > available
		or root.Position.Y > 40
		or root.Position.Y < -20
	if invalid then
		loseEgg(player, "Your egg run reset after unexpected movement. Your animals are safe.", true)
		return false
	else
		previous.credit = math.min(8, available - distance)
		previous.position = root.Position
		previous.time = now
	end
	return true
end

local function moveGuardian(guardian, targetPosition, speed, dt, now)
	local model = guardian.world.guardian
	local from = model:GetPivot().Position
	local destination = Vector3.new(targetPosition.X, guardian.world.home.Position.Y, targetPosition.Z)
	local delta = destination - Vector3.new(from.X, destination.Y, from.Z)
	local distance = delta.Magnitude
	if distance > 0.05 then
		local position = Vector3.new(from.X, destination.Y, from.Z)
			+ delta.Unit * math.min(distance, speed * dt)
		-- Tiny procedural bounce makes the original part animal waddle without physics overhead.
		position += Vector3.new(0, math.abs(math.sin(now * 9)) * 0.18, 0)
		model:PivotTo(CFrame.lookAt(position, position + delta.Unit))
	end
	return distance
end

local lastEconomy = clock()
local accumulated = 0
connect(RunService.Heartbeat, function(dt)
	if shuttingDown then
		return
	end
	accumulated += dt
	if accumulated < 0.1 then
		return
	end
	local step = math.min(accumulated, 0.25)
	accumulated = 0
	local now = clock()
	for player, session in sessions do
		checkMotion(player, now)
		if session.carrying then
			deposit(player)
		end
	end
	for zoneId, guardian in guardians do
		local zone = guardian.world.config
		if guardian.state == "Chasing" then
			local player = guardian.target
			local session = sessions[player]
			local root = player and body(player)
			if not root or not session or session.carrying ~= zoneId then
				guardian.target = nil
				guardian.state = "Returning"
				guardian.world.guardian:SetAttribute("Chasing", false)
			elseif now - guardian.startedAt > 60 then
				loseEgg(player, "The guardian reclaimed its egg. Try a quicker route!", true)
			else
				moveGuardian(guardian, root.Position, zone.guardianSpeed, step, now)
				if flatDistance(guardian.world.guardian:GetPivot().Position, root.Position) < 4.5 then
					loseEgg(player, "Caught! Your egg is gone, but your animals are safe.", true)
				end
			end
		elseif guardian.state == "Returning" then
			if
				moveGuardian(guardian, guardian.world.home.Position, zone.guardianSpeed * 1.5, step, now) < 1
			then
				guardian.world.guardian:PivotTo(guardian.world.home)
				guardian.state = "Cooldown"
				guardian.readyAt = now + zone.cooldownSeconds
			end
		elseif guardian.state == "Cooldown" and now >= guardian.readyAt then
			guardian.state = "Idle"
			world:setEggAvailable(zoneId, true)
		end
	end
	local seconds = math.floor(now - lastEconomy)
	if seconds < 1 then
		return
	end
	lastEconomy += seconds
	for player, session in sessions do
		session:earn(seconds)
		for slot = 1, Config.hatchSlots do
			local result = session:finishHatch(slot, now, rng:NextNumber(), rng:NextNumber())
			if result then
				world:clearHatch(session.baseId, slot)
				world:setAnimals(session.baseId, session.animals)
				local animal = Config.animals[result.animalId]
				remotes.Hatch:FireClient(player, {
					animalId = result.animalId,
					rarity = animal.rarity,
					income = animal.income,
					kept = result.kept,
					replacedName = result.replacedId and Config.animals[result.replacedId].name or nil,
				})
				if not result.kept then
					notice(
						player,
						"Discovered " .. animal.name .. "! Your eight higher earners stayed on display.",
						"info"
					)
				end
			end
		end
		send(player)
	end
end)

connect(Players.PlayerAdded, addPlayer)
connect(Players.PlayerRemoving, removePlayer)
for _, player in Players:GetPlayers() do
	addPlayer(player)
end

game:BindToClose(function()
	shuttingDown = true
	remotes.GetState.OnServerInvoke = nil
	for _, connection in connections do
		connection:Disconnect()
	end
	for player in sessions do
		removePlayer(player)
	end
	world:destroy()
end)

print("Steal a Goofy Egg: Phase 1 initialized (five bases, session-only progress, no music).")
