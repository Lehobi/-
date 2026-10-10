--!strict
-- Pure presentation math: every client samples the same pet route from server
-- time. No pathfinding, physics, economic state, or movement remotes are needed.
local PetMotion = {}

export type Leg = {
	x: number,
	z: number,
	dx: number,
	dz: number,
	heading: number,
	previousHeading: number,
	pause: number,
	travel: number,
	start: number,
}
export type Plan = {
	legs: { Leg },
	duration: number,
	phase: number,
	speed: number,
}
export type Sample = {
	x: number,
	z: number,
	heading: number,
	speed: number,
	stride: number,
	walking: boolean,
}

local speeds: { [string]: number } = {
	turtle = 1.8,
	rabbit = 3.7,
	frog = 3.1,
	duck = 2.7,
	penguin = 2.4,
	cat = 3.2,
	dinosaur = 2.6,
}

local function finite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function smooth(value: number): number
	return value * value * (3 - 2 * value)
end

local function angleBetween(a: number, b: number): number
	return (b - a + math.pi) % (math.pi * 2) - math.pi
end

function PetMotion.new(seed: number, halfX: number, halfZ: number, species: string): Plan
	assert(finite(seed) and seed % 1 == 0, "Pet seed must be a finite integer")
	assert(finite(halfX) and finite(halfZ) and halfX > 0 and halfZ > 0, "Pet bounds must be positive")
	-- Park-Miller stays below double-precision's exact integer limit. This avoids
	-- depending on engine RNG state or frame history when a client joins later.
	local state = math.abs(seed) % 2147483646 + 1
	local function random(): number
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
	for _ = 1, 3 do
		random()
	end
	local points: { { x: number, z: number, pause: number } } = {}
	for _ = 1, 9 do
		table.insert(points, {
			x = (random() * 2 - 1) * halfX * 0.86,
			z = (random() * 2 - 1) * halfZ * 0.86,
			pause = 1.3 + random() * (if species == "turtle" then 3.6 else 2.5),
		})
	end
	local speed = speeds[species] or 2.7
	local legs: { Leg } = {}
	local duration = 0
	for index, point in ipairs(points) do
		local nextPoint = points[index % #points + 1]
		local dx, dz = nextPoint.x - point.x, nextPoint.z - point.z
		local distance = math.sqrt(dx * dx + dz * dz)
		-- Cubic interpolation peaks at 1.5 times its average speed.
		local travel = math.max(1.2, distance * 1.5 / speed)
		table.insert(legs, {
			x = point.x,
			z = point.z,
			dx = dx,
			dz = dz,
			heading = math.atan2(-dx, -dz), -- Models face local -Z.
			previousHeading = 0,
			pause = point.pause,
			travel = travel,
			start = duration,
		})
		duration += point.pause + travel
	end
	for index, leg in ipairs(legs) do
		leg.previousHeading = legs[(index - 2) % #legs + 1].heading
	end
	return { legs = legs, duration = duration, phase = random() * duration, speed = speed }
end

function PetMotion.sample(plan: Plan, now: number): Sample
	assert(finite(now), "Pet animation time must be finite")
	local cycle = (now + plan.phase) % plan.duration
	local leg = plan.legs[#plan.legs]
	for _, candidate in ipairs(plan.legs) do
		if cycle < candidate.start + candidate.pause + candidate.travel then
			leg = candidate
			break
		end
	end
	local elapsed = cycle - leg.start
	local progress = math.clamp((elapsed - leg.pause) / leg.travel, 0, 1)
	local distance = math.sqrt(leg.dx * leg.dx + leg.dz * leg.dz)
	local speed = distance * 6 * progress * (1 - progress) / leg.travel
	-- Look around during the pause, then face the next destination before moving.
	local turn = smooth(math.clamp(elapsed / math.min(1.2, leg.pause), 0, 1))
	local heading = leg.previousHeading + angleBetween(leg.previousHeading, leg.heading) * turn
	local fraction = smooth(progress)
	return {
		x = leg.x + leg.dx * fraction,
		z = leg.z + leg.dz * fraction,
		heading = heading,
		speed = speed,
		stride = distance * fraction,
		walking = speed > 0.05,
	}
end

return PetMotion
