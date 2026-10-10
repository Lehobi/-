-- The arena geometry and difficulty checks exercise the actual shared rules without Roblox.
local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")
local ChaseRules = require("../src/shared/ChaseRules")

local passed = 0
local function test(name, run)
	local success, message = pcall(run)
	assert(success, "FAIL " .. name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end

test("each red edge remains dangerous until the player's center crosses it", function()
	for _, zone in Config.zones do
		local x, z = zone.position.x, zone.position.z
		local width, depth = zone.arenaHalfWidth, zone.arenaHalfDepth
		assert(ChaseRules.inside(zone, x, z))
		for _, sign in { -1, 1 } do
			assert(ChaseRules.inside(zone, x + sign * width, z))
			assert(ChaseRules.inside(zone, x, z + sign * depth))
			assert(not ChaseRules.inside(zone, x + sign * (width + 0.001), z))
			assert(not ChaseRules.inside(zone, x, z + sign * (depth + 0.001)))
		end
	end
end)

test("corners and each zone's translated rectangle have exact boundaries", function()
	for _, zone in Config.zones do
		for _, xSign in { -1, 1 } do
			for _, zSign in { -1, 1 } do
				local x = zone.position.x + xSign * zone.arenaHalfWidth
				local z = zone.position.z + zSign * zone.arenaHalfDepth
				assert(ChaseRules.inside(zone, x, z))
				assert(not ChaseRules.inside(zone, x + xSign * 0.001, z))
				assert(not ChaseRules.inside(zone, x, z + zSign * 0.001))
			end
		end
	end
	assert(not ChaseRules.inside(Config.zones[1], 0, Config.zones[2].position.z))
	assert(not ChaseRules.inside(Config.zones[2], 0, Config.zones[1].position.z))
	local translated = { position = { x = 123, z = -500 }, arenaHalfWidth = 10, arenaHalfDepth = 20 }
	assert(ChaseRules.inside(translated, 113, -480))
	assert(not ChaseRules.inside(translated, 112.999, -480))
end)

test("guardian targets clamp to every perimeter while in-arena movement stays unchanged", function()
	for _, zone in Config.zones do
		local centerX, centerZ = zone.position.x, zone.position.z
		local homeX = centerX + zone.guardianOffset
		local x, z = ChaseRules.clampPosition(zone, homeX, centerZ)
		assert(x == homeX and z == centerZ)
		for _, xOffset in { -1000, -10, 0, 10, 1000 } do
			for _, zOffset in { -1000, -10, 0, 10, 1000 } do
				local boundedX, boundedZ =
					ChaseRules.clampPosition(zone, centerX + xOffset, centerZ + zOffset)
				assert(boundedX and boundedZ and ChaseRules.inside(zone, boundedX, boundedZ))
				assert(boundedX == centerX + math.clamp(xOffset, -zone.arenaHalfWidth, zone.arenaHalfWidth))
				assert(boundedZ == centerZ + math.clamp(zOffset, -zone.arenaHalfDepth, zone.arenaHalfDepth))
			end
		end
	end
end)

test("invalid positions and arena numbers fail closed", function()
	for _, invalid in { math.huge, -math.huge, 0 / 0 } do
		for _, zone in Config.zones do
			assert(not ChaseRules.inside(zone, invalid, zone.position.z))
			assert(not ChaseRules.inside(zone, zone.position.x, invalid))
			local x, z = ChaseRules.clampPosition(zone, invalid, zone.position.z)
			assert(x == nil and z == nil)
			x, z = ChaseRules.clampPosition(zone, zone.position.x, invalid)
			assert(x == nil and z == nil)
		end
	end
	for _, invalid in { -1, 0, math.huge, 0 / 0 } do
		local bad = { position = { x = 0, z = 0 }, arenaHalfWidth = invalid, arenaHalfDepth = 55 }
		assert(not ChaseRules.inside(bad, 0, 0))
		assert(ChaseRules.clampPosition(bad, 0, 0) == nil)
	end
	local badOrigin = { position = { x = 0 / 0, z = 0 }, arenaHalfWidth = 46, arenaHalfDepth = 55 }
	assert(not ChaseRules.inside(badOrigin, 0, 0))
	assert(ChaseRules.clampPosition(badOrigin, 0, 0) == nil)
end)

-- Mirrors the server's 10 Hz straight-line chase step to catch impossible baseline tuning.
-- This is a geometry check, not a replacement for Studio movement/latency playtesting.
local function simulateRun(zone, playerSpeed, running)
	local x, z = zone.position.x, zone.position.z
	local guardianX, guardianZ = x + zone.guardianOffset, z
	for tick = 1, 600 do
		local elapsed = tick * 0.1
		local playerZ = z - (if running then playerSpeed * elapsed else 0)
		if not ChaseRules.inside(zone, x, playerZ) then
			return "escaped"
		end
		if elapsed >= zone.wakeSeconds then
			local dx, dz = x - guardianX, playerZ - guardianZ
			local distance = math.sqrt(dx * dx + dz * dz)
			if distance > 0 then
				local step = math.min(distance, zone.guardianSpeed * 0.1)
				guardianX += dx / distance * step
				guardianZ += dz / distance * step
			end
			if math.sqrt((x - guardianX) ^ 2 + (playerZ - guardianZ) ^ 2) < 4.5 then
				return "caught"
			end
		end
	end
	return "timeout"
end

test("faster guardians punish standing still but allow immediate starter escapes", function()
	for _, zone in Config.zones do
		local speed = Economy.walkSpeed(zone.requiredLevel)
		assert(zone.guardianSpeed > speed, "Minimum-level players must not simply outrun the guardian")
		assert(simulateRun(zone, speed, false) == "caught")
		assert(
			simulateRun(zone, speed, true) == "escaped",
			"Prompt release needs a viable route at minimum level"
		)
	end
end)

print(string.format("%d chase tests passed", passed))
