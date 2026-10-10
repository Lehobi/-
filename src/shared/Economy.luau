--!strict
local Config = if script then require(script.Parent.Config) else require("./Config")

export type OwnedAnimal = { id: string }

local Economy = {}

local function finite(value: number): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function positiveInteger(value: number): boolean
	return finite(value) and value > 0 and value % 1 == 0
end

local function checkLevel(level: number)
	assert(
		finite(level) and level % 1 == 0 and level >= 0 and level <= Config.speed.maxLevel,
		"Invalid speed level"
	)
end

local function checkRoll(roll: number)
	assert(finite(roll) and roll >= 0 and roll < 1, "Roll must be a finite number in [0, 1)")
end

local function getAnimal(animalId: string)
	local animal = Config.animals[animalId]
	assert(animal ~= nil, "Unknown animal: " .. tostring(animalId))
	return animal
end

local function orderedRarities(): { string }
	local result = {}
	for name in Config.rarities do
		table.insert(result, name)
	end
	table.sort(result, function(a, b)
		return Config.rarities[a].order < Config.rarities[b].order
	end)
	return result
end

function Economy.walkSpeed(level: number): number
	checkLevel(level)
	return Config.speed.base + Config.speed.perLevel * level
end

function Economy.upgradeCost(level: number): number?
	checkLevel(level)
	if level == Config.speed.maxLevel then
		return nil
	end
	return math.floor(Config.speed.baseCost * Config.speed.costGrowth ^ level)
end

function Economy.getZone(zoneId: string): typeof(Config.zones[1])?
	for _, zone in Config.zones do
		if zone.id == zoneId then
			return zone
		end
	end
	return nil
end

function Economy.rollAnimal(zoneId: string, rarityRoll: number, animalRoll: number): string
	checkRoll(rarityRoll)
	checkRoll(animalRoll)
	local zone = Economy.getZone(zoneId)
	assert(zone ~= nil, "Unknown zone: " .. tostring(zoneId))
	local threshold = rarityRoll * 100
	local cumulative = 0
	local selectedRarity: string? = nil
	for _, rarity in orderedRarities() do
		local weight = zone.weights[rarity] or 0
		cumulative += weight
		if weight > 0 and threshold < cumulative then
			selectedRarity = rarity
			break
		end
	end
	assert(selectedRarity ~= nil, "Zone rarity weights do not cover this roll")
	local candidates = {}
	for id, animal in Config.animals do
		if animal.rarity == selectedRarity then
			table.insert(candidates, id)
		end
	end
	table.sort(candidates)
	assert(#candidates > 0, "Selected rarity has no animals")
	return candidates[math.floor(animalRoll * #candidates) + 1]
end

function Economy.income(animals: { OwnedAnimal }): number
	local total = 0
	for _, owned in animals do
		total += getAnimal(owned.id).income
	end
	return total
end

function Economy.addAnimal(animals: { OwnedAnimal }, animalId: string): ({ OwnedAnimal }, string?, boolean)
	local incoming = getAnimal(animalId)
	assert(#animals <= Config.maxAnimals, "Animal capacity already exceeded")
	local result = table.clone(animals)
	local weakestIndex = 1
	local weakestIncome = math.huge
	for index, owned in animals do
		local value = getAnimal(owned.id).income
		if value < weakestIncome then
			weakestIndex = index
			weakestIncome = value
		end
	end
	if #result < Config.maxAnimals then
		table.insert(result, { id = animalId })
		return result, nil, true
	end
	if incoming.income > weakestIncome then
		local replacedId = result[weakestIndex].id
		result[weakestIndex] = { id = animalId }
		return result, replacedId, true
	end
	return result, nil, false
end

function Economy.validateConfig(): boolean
	assert(finite(Config.startCash) and Config.startCash >= 0, "Starting cash must be nonnegative")
	assert(positiveInteger(Config.hatchSlots), "Hatch slots must be a positive integer")
	assert(positiveInteger(Config.maxAnimals), "Animal capacity must be a positive integer")
	assert(Config.hatchSlots <= Config.maxAnimals, "Hatch slots exceed animal capacity")
	assert(#Config.basePositions >= 1, "At least one base is required")
	local positions = {}
	for _, position in Config.basePositions do
		assert(finite(position.x) and finite(position.z), "Base coordinates must be finite")
		local key = tostring(position.x) .. ":" .. tostring(position.z)
		assert(not positions[key], "Duplicate base position")
		positions[key] = true
	end
	assert(finite(Config.speed.base) and Config.speed.base > 0, "Base speed must be positive")
	assert(finite(Config.speed.perLevel) and Config.speed.perLevel > 0, "Speed increase must be positive")
	assert(positiveInteger(Config.speed.maxLevel), "Maximum speed level must be a positive integer")
	assert(positiveInteger(Config.speed.baseCost), "Base upgrade cost must be a positive integer")
	assert(finite(Config.speed.costGrowth) and Config.speed.costGrowth > 1, "Upgrade costs must grow")
	assert(
		finite(Config.speed.baseCost * Config.speed.costGrowth ^ Config.speed.maxLevel),
		"Upgrade cost overflow"
	)

	local orders = {}
	local population: { [string]: number } = {}
	for rarity, definition in Config.rarities do
		assert(
			positiveInteger(definition.order) and not orders[definition.order],
			"Rarity orders must be unique"
		)
		orders[definition.order] = true
		population[rarity] = 0
	end
	for id, animal in Config.animals do
		assert(id == animal.id, "Animal key and ID must match")
		assert(population[animal.rarity] ~= nil, "Unknown animal rarity")
		assert(finite(animal.income) and animal.income > 0, "Animal income must be positive")
		population[animal.rarity] += 1
	end
	assert(#Config.zones > 0, "At least one zone is required")
	local zoneIds = {}
	for _, zone in Config.zones do
		assert(zone.id ~= "" and not zoneIds[zone.id], "Zone IDs must be nonempty and unique")
		zoneIds[zone.id] = true
		assert(finite(zone.position.x) and finite(zone.position.z), "Zone coordinates must be finite")
		assert(finite(zone.guardianOffset) and zone.guardianOffset > 0, "Guardian offset must be positive")
		assert(finite(zone.guardianSpeed) and zone.guardianSpeed > 0, "Guardian speed must be positive")
		checkLevel(zone.requiredLevel)
		assert(finite(zone.hatchSeconds) and zone.hatchSeconds > 0, "Hatch time must be positive")
		assert(finite(zone.cooldownSeconds) and zone.cooldownSeconds >= 0, "Cooldown must be nonnegative")
		local total = 0
		for rarity, weight in zone.weights do
			assert(population[rarity] ~= nil, "Zone has an unknown rarity")
			assert(finite(weight) and weight >= 0, "Rarity weights must be finite and nonnegative")
			assert(weight == 0 or population[rarity] > 0, "Positive rarity weight has no animals")
			total += weight
		end
		assert(math.abs(total - 100) < 1e-9, "Zone rarity weights must sum to 100")
	end
	return true
end

return Economy
