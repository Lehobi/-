--!strict
-- Pure arena geometry shared by server movement and standalone boundary tests.
-- A player's center must cross the red perimeter before a chase is released.
local ChaseRules = {}

export type Arena = {
	position: { x: number, z: number },
	arenaHalfWidth: number,
	arenaHalfDepth: number,
}

local function finite(value: number): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function validArena(zone: Arena): boolean
	return finite(zone.position.x)
		and finite(zone.position.z)
		and finite(zone.arenaHalfWidth)
		and finite(zone.arenaHalfDepth)
		and zone.arenaHalfWidth > 0
		and zone.arenaHalfDepth > 0
end

function ChaseRules.inside(zone: Arena, x: number, z: number): boolean
	return validArena(zone)
		and finite(x)
		and finite(z)
		and math.abs(x - zone.position.x) <= zone.arenaHalfWidth
		and math.abs(z - zone.position.z) <= zone.arenaHalfDepth
end

function ChaseRules.clampPosition(zone: Arena, x: number, z: number, inset: number?): (number?, number?)
	local margin = inset or 0
	if
		not validArena(zone)
		or not finite(x)
		or not finite(z)
		or not finite(margin)
		or margin < 0
		or margin >= math.min(zone.arenaHalfWidth, zone.arenaHalfDepth)
	then
		return nil, nil
	end
	return math.clamp(
		x,
		zone.position.x - zone.arenaHalfWidth + margin,
		zone.position.x + zone.arenaHalfWidth - margin
	),
		math.clamp(
			z,
			zone.position.z - zone.arenaHalfDepth + margin,
			zone.position.z + zone.arenaHalfDepth - margin
		)
end

return ChaseRules
