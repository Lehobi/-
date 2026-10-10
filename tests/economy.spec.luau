--!strict
local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")

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

local function rarity(zone: string, roll: number): string
	return Config.animals[Economy.rollAnimal(zone, roll, 0)].rarity
end

test("shipped configuration is internally consistent", function()
	assert(Economy.validateConfig())
	assert(#Config.basePositions == 5)
	assert(Config.hatchSlots == 3)
	assert(Config.maxAnimals == 8)
end)

test("turtle probability boundaries exclude epic and above", function()
	assert(rarity("turtle", 0) == "Common")
	assert(rarity("turtle", 0.779999999) == "Common")
	assert(rarity("turtle", 0.78) == "Uncommon")
	assert(rarity("turtle", 0.979999999) == "Uncommon")
	assert(rarity("turtle", 0.98) == "Rare")
	assert(rarity("turtle", 0.999999999) == "Rare")
	local counts: { [string]: number } = {}
	for sample = 0, 9999 do
		local tier = rarity("turtle", (sample + 0.5) / 10000)
		counts[tier] = (counts[tier] or 0) + 1
	end
	assert(counts.Common == 7800 and counts.Uncommon == 2000 and counts.Rare == 200)
	assert(counts.Epic == nil and counts.Legendary == nil and counts.Mythic == nil and counts.Secret == nil)
end)

test("rabbit probability boundaries retain the small epic chance", function()
	assert(rarity("rabbit", 0) == "Common")
	assert(rarity("rabbit", 0.519999999) == "Common")
	assert(rarity("rabbit", 0.52) == "Uncommon")
	assert(rarity("rabbit", 0.839999999) == "Uncommon")
	assert(rarity("rabbit", 0.84) == "Rare")
	assert(rarity("rabbit", 0.979999999) == "Rare")
	assert(rarity("rabbit", 0.98) == "Epic")
	assert(rarity("rabbit", 0.999999999) == "Epic")
	local counts: { [string]: number } = {}
	for sample = 0, 9999 do
		local tier = rarity("rabbit", (sample + 0.5) / 10000)
		counts[tier] = (counts[tier] or 0) + 1
	end
	assert(counts.Common == 5200 and counts.Uncommon == 3200 and counts.Rare == 1400 and counts.Epic == 200)
	assert(counts.Legendary == nil and counts.Mythic == nil and counts.Secret == nil)
end)

test("animal roll is deterministic at within-tier boundaries", function()
	assert(Economy.rollAnimal("turtle", 0, 0) == "duck")
	assert(Economy.rollAnimal("turtle", 0, 0.499999999) == "duck")
	assert(Economy.rollAnimal("turtle", 0, 0.5) == "frog")
	assert(Economy.rollAnimal("turtle", 0, 0.999999999) == "frog")
	assert(Economy.rollAnimal("turtle", 0.8, 0) == "cat")
	assert(Economy.rollAnimal("turtle", 0.8, 0.5) == "turtle")
	assert(Economy.rollAnimal("rabbit", 0.9, 0) == "penguin")
	assert(Economy.rollAnimal("rabbit", 0.9, 0.5) == "rabbit")
	assert(Economy.rollAnimal("rabbit", 0.99, 0.999999999) == "dinosaur")
end)

test("invalid rolls and unknown zones fail closed", function()
	for _, roll in { -0.01, 1, 1.01, math.huge, -math.huge, 0 / 0 } do
		rejects(function()
			Economy.rollAnimal("turtle", roll, 0)
		end)
		rejects(function()
			Economy.rollAnimal("turtle", 0, roll)
		end)
	end
	assert(Economy.getZone("missing") == nil)
	local rabbitZone = Economy.getZone("rabbit")
	assert(rabbitZone ~= nil and rabbitZone.requiredLevel == 6)
	rejects(function()
		Economy.rollAnimal("missing", 0, 0)
	end)
end)

test("speed upgrade prices increase and stop at the cap", function()
	assert(Economy.walkSpeed(0) == 16)
	assert(Economy.walkSpeed(4) == 24)
	assert(Economy.walkSpeed(12) == 40)
	assert(Economy.upgradeCost(0) == 50)
	assert(Economy.upgradeCost(1) == 82)
	assert(Economy.upgradeCost(2) == 136)
	local previous = 0
	for level = 0, 11 do
		local price = Economy.upgradeCost(level)
		assert(price ~= nil and price > previous and price % 1 == 0)
		previous = price
	end
	assert(Economy.upgradeCost(12) == nil)
	for _, level in { -1, 0.5, 13, math.huge, -math.huge, 0 / 0 } do
		rejects(function()
			Economy.upgradeCost(level)
		end)
		rejects(function()
			Economy.walkSpeed(level)
		end)
	end
end)

test("rabbit entry requires a collection investment beyond starting cash", function()
	local zone = Economy.getZone("rabbit")
	assert(zone and zone.requiredLevel == 6)
	local total = 0
	for level = 0, zone.requiredLevel - 1 do
		local price = Economy.upgradeCost(level)
		assert(price)
		total += price
	end
	assert(total == 1473)
	assert(Economy.upgradeCost(0) > Config.startCash)
	-- Even the best starter-zone reward needs sustained income to unlock the next arena.
	assert(total - Config.startCash > Config.animals.rabbit.income * 40)
	assert(Economy.walkSpeed(zone.requiredLevel) == 28)
end)

test("income sums owned animals including duplicates", function()
	assert(Economy.income({}) == 0)
	assert(Economy.income({ { id = "frog" }, { id = "frog" }, { id = "dinosaur" } }) == 98)
	rejects(function()
		Economy.income({ { id = "missing" } })
	end)
end)

test("adding to an empty slot leaves the input unchanged", function()
	local original = { { id = "frog" } }
	local result, replaced, kept = Economy.addAnimal(original, "dinosaur")
	assert(result ~= original and #result == 2 and #original == 1)
	assert(original[1].id == "frog" and result[1] == original[1])
	assert(result[2].id == "dinosaur" and replaced == nil and kept)
end)

test("a full base replaces only a strictly weaker animal", function()
	local original = {
		{ id = "dinosaur" },
		{ id = "duck" },
		{ id = "turtle" },
		{ id = "cat" },
		{ id = "penguin" },
		{ id = "rabbit" },
		{ id = "frog" },
		{ id = "dinosaur" },
	}
	local upgraded, replaced, kept = Economy.addAnimal(original, "cat")
	assert(#upgraded == 8 and replaced == "frog" and kept)
	assert(original[7].id == "frog" and upgraded[7].id == "cat")
	assert(Economy.income(upgraded) == Economy.income(original) + 8)
	local same, equalReplacement, equalKept = Economy.addAnimal(original, "frog")
	assert(same ~= original and #same == 8 and equalReplacement == nil and not equalKept)
	assert(Economy.income(same) == Economy.income(original))
	local lower, lowerReplacement, lowerKept = Economy.addAnimal(upgraded, "frog")
	assert(#lower == 8 and lowerReplacement == nil and not lowerKept)
	assert(Economy.income(lower) == Economy.income(upgraded))
end)

test("a long hatch sequence preserves the best eight incomes", function()
	local owned = {}
	local allIncomes: { number } = {}
	local sequence = {
		"cat",
		"frog",
		"dinosaur",
		"duck",
		"turtle",
		"rabbit",
		"penguin",
		"frog",
		"dinosaur",
		"cat",
		"duck",
		"rabbit",
		"dinosaur",
		"frog",
		"turtle",
		"penguin",
		"dinosaur",
		"rabbit",
		"dinosaur",
		"frog",
		"dinosaur",
		"dinosaur",
		"dinosaur",
	}
	for _, id in sequence do
		local before = Economy.income(owned)
		local oldCount = #owned
		table.insert(allIncomes, Config.animals[id].income)
		table.sort(allIncomes, function(a, b)
			return a > b
		end)
		local expected = 0
		for index = 1, math.min(8, #allIncomes) do
			expected += allIncomes[index]
		end
		local nextOwned = Economy.addAnimal(owned, id)
		assert(#owned == oldCount and Economy.income(owned) == before)
		owned = nextOwned
		assert(#owned == math.min(8, #allIncomes))
		assert(Economy.income(owned) == expected and Economy.income(owned) >= before)
	end
	assert(Economy.income(owned) == 720)
end)

test("unknown incoming animals and overcapacity inputs are rejected", function()
	rejects(function()
		Economy.addAnimal({}, "missing")
	end)
	local overfull = {}
	for _ = 1, 9 do
		table.insert(overfull, { id = "frog" })
	end
	rejects(function()
		Economy.addAnimal(overfull, "dinosaur")
	end)
end)

test("configuration validation detects probability and roster mistakes", function()
	local zone = Config.zones[1]
	local previous = zone.weights.Common
	zone.weights.Common = 77
	local totalAccepted = pcall(Economy.validateConfig)
	zone.weights.Common = previous
	assert(not totalAccepted, "Bad probability total was accepted")
	zone.weights.Common = 77
	zone.weights.Secret = 1
	local missingAnimalsAccepted = pcall(Economy.validateConfig)
	zone.weights.Common = previous
	zone.weights.Secret = 0
	assert(not missingAnimalsAccepted, "Unpopulated rarity was accepted")
	local previousId = Config.zones[2].id
	Config.zones[2].id = zone.id
	local duplicateAccepted = pcall(Economy.validateConfig)
	Config.zones[2].id = previousId
	assert(not duplicateAccepted, "Duplicate zone ID was accepted")
	assert(Economy.validateConfig())
end)

print(string.format("%d economy tests passed", passed))
