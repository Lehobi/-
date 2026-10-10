--!strict
-- Exercise the presentation contract without Roblox, physics, or a frame clock.
local Config = require("../src/shared/Config")
local PetMotion = require("../src/shared/PetMotion")

local passed = 0
local function test(name: string, run: () -> ())
	local success, message = pcall(function()
		run()
		return nil
	end)
	assert(success, "FAIL " .. name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end

local function rejects(run: () -> ())
	assert(not pcall(run), "Expected invalid input to be rejected")
end

local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

local function checkSample(sample: PetMotion.Sample)
	for _, value in { sample.x, sample.z, sample.heading, sample.speed, sample.stride } do
		assert(finite(value), "A sampled transform must contain only finite numbers")
	end
	assert(sample.speed >= 0 and sample.stride >= 0)
end

local function sameSample(a: PetMotion.Sample, b: PetMotion.Sample)
	assert(a.x == b.x and a.z == b.z, "Independent clients disagree on position")
	assert(a.heading == b.heading, "Independent clients disagree on heading")
	assert(a.speed == b.speed and a.stride == b.stride and a.walking == b.walking)
end

local function distance(a: PetMotion.Sample, b: PetMotion.Sample): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

local function headingDifference(a: number, b: number): number
	-- Compare rotations, allowing numerically different representations of one turn.
	return math.abs(math.atan2(math.sin(a - b), math.cos(a - b)))
end

test("seed and server time reproduce routes independently of frame history and late joining", function()
	local times = { -700.25, 0, 0.05, 12.875, 9000.5, 1791602574.459 }
	for _, animal in pairs(Config.animals) do
		local original = PetMotion.new(308, 23, 10.5, animal.species)
		local expected: { PetMotion.Sample } = {}
		for _, time in ipairs(times) do
			table.insert(expected, PetMotion.sample(original, time))
		end
		-- A different pet and a newly joined client must not depend on a shared RNG.
		PetMotion.new(909, 8, 3, animal.species)
		local joinedLater = PetMotion.new(308, 23, 10.5, animal.species)
		for index = #times, 1, -1 do
			PetMotion.sample(original, times[index] + 200)
			sameSample(expected[index], PetMotion.sample(original, times[index]))
			sameSample(expected[index], PetMotion.sample(joinedLater, times[index]))
		end
	end
end)

test("different pet seeds produce different roaming routes", function()
	local first = PetMotion.new(101, 23, 10.5, "duck")
	local second = PetMotion.new(102, 23, 10.5, "duck")
	local distinct = false
	for time = 0, 60, 3 do
		if distance(PetMotion.sample(first, time), PetMotion.sample(second, time)) > 1 then
			distinct = true
		end
	end
	assert(distinct, "Pets with distinct seeds should not all follow the same route")
end)

test("every species stays finite and inside its lawn over repeated complete cycles", function()
	local bounds = { { x = 23, z = 10.5 }, { x = 0.05, z = 0.02 }, { x = 7, z = 41 } }
	for _, animal in pairs(Config.animals) do
		for _, seed in { -87, 0, 101, 508 } do
			for _, bound in ipairs(bounds) do
				local plan = PetMotion.new(seed, bound.x, bound.z, animal.species)
				assert(finite(plan.duration) and plan.duration > 0)
				assert(finite(plan.phase) and plan.phase >= 0 and plan.phase < plan.duration)
				assert(finite(plan.speed) and plan.speed > 0)
				for tick = -500, 1500 do
					local sample = PetMotion.sample(plan, tick / 500 * plan.duration)
					checkSample(sample)
					assert(math.abs(sample.x) <= bound.x and math.abs(sample.z) <= bound.z)
					assert(sample.speed <= plan.speed + 1e-9, "Walking must respect the species speed cap")
				end
			end
		end
	end
end)

test("actual displacement respects planned speed through movement and route wraparound", function()
	for _, animal in pairs(Config.animals) do
		for _, seed in { 101, 305, 508 } do
			local plan = PetMotion.new(seed, 23, 10.5, animal.species)
			local dt = plan.duration / 2000
			local previous = PetMotion.sample(plan, -plan.phase)
			for tick = 1, 4000 do
				local sample = PetMotion.sample(plan, tick * dt - plan.phase)
				assert(
					distance(previous, sample) <= plan.speed * dt + 1e-8,
					"Pet teleported or exceeded its cap"
				)
				previous = sample
			end
		end
	end
end)

test("position and heading are continuous across starts, pause endings, and the cycle seam", function()
	local epsilon = 1e-5
	for _, animal in pairs(Config.animals) do
		for _, seed in { 101, 305, 508 } do
			local plan = PetMotion.new(seed, 23, 10.5, animal.species)
			local boundaries: { number } = { plan.duration }
			for _, leg in ipairs(plan.legs) do
				table.insert(boundaries, leg.start)
				table.insert(boundaries, leg.start + leg.pause)
			end
			for _, boundary in ipairs(boundaries) do
				local time = boundary - plan.phase
				local before = PetMotion.sample(plan, time - epsilon)
				local at = PetMotion.sample(plan, time)
				local after = PetMotion.sample(plan, time + epsilon)
				assert(distance(before, at) <= plan.speed * epsilon + 1e-8)
				assert(distance(at, after) <= plan.speed * epsilon + 1e-8)
				assert(headingDifference(before.heading, at.heading) < 1e-5, "Heading snapped at a boundary")
				assert(
					headingDifference(at.heading, after.heading) < 1e-5,
					"Heading snapped after a boundary"
				)
				assert(math.abs(before.speed - after.speed) < 1e-3, "Walking speed must ease through stops")
			end
		end
	end
end)

test("each route includes stationary pauses and forward walking", function()
	for _, animal in pairs(Config.animals) do
		local plan = PetMotion.new(208, 23, 10.5, animal.species)
		for _, leg in ipairs(plan.legs) do
			local pauseStart = PetMotion.sample(plan, leg.start + leg.pause * 0.25 - plan.phase)
			local pauseEnd = PetMotion.sample(plan, leg.start + leg.pause * 0.75 - plan.phase)
			assert(
				distance(pauseStart, pauseEnd) < 1e-10,
				"A paused pet should stay still while looking around"
			)
			assert(pauseStart.speed == 0 and pauseEnd.speed == 0)
			assert(not pauseStart.walking and not pauseEnd.walking)
			local midWalk = PetMotion.sample(plan, leg.start + leg.pause + leg.travel * 0.5 - plan.phase)
			assert(midWalk.walking and midWalk.speed > 0.05 and midWalk.stride > 0)
			assert(distance(pauseEnd, midWalk) > 0, "A walking pet must change position")
		end
	end
end)

test("the same route repeats without drift over many cycles", function()
	local plan = PetMotion.new(407, 23, 10.5, "cat")
	for _, fraction in { 0, 0.125, 0.5, 0.875 } do
		local time = fraction * plan.duration - plan.phase
		local expected = PetMotion.sample(plan, time)
		for _, cycles in { -10, -1, 1, 5, 100 } do
			local repeated = PetMotion.sample(plan, time + cycles * plan.duration)
			assert(distance(expected, repeated) < 1e-8)
			assert(headingDifference(expected.heading, repeated.heading) < 1e-8)
			assert(math.abs(expected.speed - repeated.speed) < 1e-8)
		end
	end
end)

test("non-integer or non-finite seeds and invalid bounds are rejected", function()
	for _, seed in { 0.5, -2.1, math.huge, -math.huge, 0 / 0 } do
		rejects(function()
			PetMotion.new(seed, 23, 10.5, "duck")
		end)
	end
	for _, bound in { 0, -1, math.huge, -math.huge, 0 / 0 } do
		rejects(function()
			PetMotion.new(101, bound, 10.5, "duck")
		end)
		rejects(function()
			PetMotion.new(101, 23, bound, "duck")
		end)
	end
end)

test("non-finite animation times are rejected", function()
	local plan = PetMotion.new(101, 23, 10.5, "duck")
	for _, time in { math.huge, -math.huge, 0 / 0 } do
		rejects(function()
			PetMotion.sample(plan, time)
		end)
	end
end)

print(string.format("%d pet motion tests passed", passed))
