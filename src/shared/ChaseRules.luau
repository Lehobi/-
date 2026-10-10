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

function ChaseRules.clampPosition(zone: Arena, x: number, z: number): (number?, number?)
	if not validArena(zone) or not finite(x) or not finite(z) then
		return nil, nil
	end
	return math.clamp(x, zone.position.x - zone.arenaHalfWidth, zone.position.x + zone.arenaHalfWidth),
		math.clamp(z, zone.position.z - zone.arenaHalfDepth, zone.position.z + zone.arenaHalfDepth)
end

return ChaseRules
