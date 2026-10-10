-- Pure session state: synchronous mutations make deposits/hatches exactly-once in this server.
-- Persistence and paid products intentionally belong to later phases.
local Session = {}
Session.__index = Session

function Session.new(baseId, config, economy)
	return setmetatable({
		baseId = baseId,
		cash = config.startCash,
		speedLevel = 0,
		carrying = nil,
		escaped = false,
		hatches = {},
		animals = {},
		discovered = {},
		config = config,
		economy = economy,
	}, Session)
end

function Session:freeSlot()
	for slot = 1, self.config.hatchSlots do
		if self.hatches[slot] == nil then
			return slot
		end
	end
	return nil
end

function Session:steal(zoneId)
	local zone = self.economy.getZone(zoneId)
	if not zone then
		return false, "Unknown zone."
	elseif self.carrying then
		return false, "Take your egg home first!"
	elseif self.speedLevel < zone.requiredLevel then
		return false, "Reach speed level " .. zone.requiredLevel .. " for this zone."
	elseif not self:freeSlot() then
		return false, "Your hatch slots are full. Wait for an egg to hatch."
	end
	self.carrying = zoneId
	self.escaped = false
	return true
end

function Session:markEscaped(zoneId)
	if self.carrying ~= zoneId or self.escaped then
		return false
	end
	self.escaped = true
	return true
end

function Session:deposit(now)
	local slot = self:freeSlot()
	if not self.carrying or not slot then
		return nil
	end
	local zone = self.economy.getZone(self.carrying)
	local hatch = { slot = slot, zoneId = zone.id, readyAt = now + zone.hatchSeconds }
	self.hatches[slot] = hatch
	self.carrying = nil
	self.escaped = false
	return hatch
end

function Session:loseCarry()
	local previous = self.carrying
	self.carrying = nil
	self.escaped = false
	return previous
end

function Session:finishHatch(slot, now, rarityRoll, animalRoll)
	local hatch = self.hatches[slot]
	if not hatch or now < hatch.readyAt then
		return nil
	end
	local animalId = self.economy.rollAnimal(hatch.zoneId, rarityRoll, animalRoll)
	local animals, replacedId, kept = self.economy.addAnimal(self.animals, animalId)
	-- Remove the hatch in the same non-yielding transaction that grants its reward.
	self.hatches[slot] = nil
	self.animals = animals
	self.discovered[animalId] = true
	return { animalId = animalId, replacedId = replacedId, kept = kept }
end

function Session:upgrade()
	local cost = self.economy.upgradeCost(self.speedLevel)
	if not cost then
		return false, "Your speed is already at the maximum!"
	elseif self.cash < cost then
		return false, "You need $" .. cost .. " for the next speed level."
	end
	self.cash -= cost
	self.speedLevel += 1
	return true
end

function Session:earn(seconds)
	assert(seconds >= 0 and seconds % 1 == 0 and seconds < math.huge, "Whole elapsed seconds required")
	self.cash += self.economy.income(self.animals) * seconds
end

function Session:snapshot()
	local hatches = {}
	for slot = 1, self.config.hatchSlots do
		local hatch = self.hatches[slot]
		if hatch then
			table.insert(hatches, table.clone(hatch))
		end
	end
	local animals = {}
	for _, animal in self.animals do
		table.insert(animals, { id = animal.id })
	end
	local nextZone = "All current zones unlocked!"
	for _, zone in self.config.zones do
		if self.speedLevel < zone.requiredLevel then
			nextZone = zone.name .. " unlocks at speed level " .. zone.requiredLevel
			break
		end
	end
	return {
		cash = self.cash,
		income = self.economy.income(self.animals),
		speedLevel = self.speedLevel,
		walkSpeed = self.economy.walkSpeed(self.speedLevel),
		upgradeCost = self.economy.upgradeCost(self.speedLevel),
		baseId = self.baseId,
		carrying = self.carrying,
		escaped = self.escaped,
		hatches = hatches,
		animals = animals,
		discovered = table.clone(self.discovered),
		nextZone = nextZone,
		tutorial = if self.carrying and not self.escaped
			then "Run across the red boundary to escape the guardian!"
			elseif self.carrying then "You escaped! Bring the egg to your own nest."
			elseif
				#self.animals == 0
			then "Take an egg in Turtle Meadow. Cross the red line, then bring it home!"
			else "Your animals earn cash every second. Upgrade speed and try Rabbit Ridge!",
		sessionOnly = true,
	}
end

return Session
