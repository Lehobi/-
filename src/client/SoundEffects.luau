-- Local, short interaction cues using sounds shipped with Roblox itself.
-- No external audio IDs, uploads, looping tracks, or background music.
-- Edit profiles here for owned/licensed custom SoundIds later; volume is in Config.audio.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local SoundEffects = {}
SoundEffects.__index = SoundEffects

local SPRING = "rbxasset://sounds/action_get_up.mp3"
local WHOOSH = "rbxasset://sounds/action_jump.mp3"
local TAP = "rbxasset://sounds/action_jump_land.mp3"
local SPLASH = "rbxasset://sounds/impact_water.mp3"

-- Sound profiles are brief mechanical/animal-like cues, not a musical soundtrack.
local CUES = {
	ui = { { id = TAP, pitch = 1.9, volume = 0.22, lifetime = 0.16 } },
	steal = { { id = WHOOSH, pitch = 0.85, volume = 0.65, lifetime = 0.55 } },
	escape = { { id = SPRING, pitch = 1.45, volume = 0.6, lifetime = 0.5 } },
	catch = { { id = TAP, pitch = 0.65, volume = 0.85, lifetime = 0.7 } },
	deposit = { { id = TAP, pitch = 1.2, volume = 0.48, lifetime = 0.45 } },
	upgrade = {
		{ id = WHOOSH, pitch = 1.25, volume = 0.48, lifetime = 0.4 },
		{ id = SPRING, pitch = 1.75, volume = 0.5, lifetime = 0.4, delay = 0.1 },
	},
	denied = { { id = TAP, pitch = 0.85, volume = 0.35, lifetime = 0.28 } },
	hatch = {
		{ id = SPLASH, pitch = 1.5, volume = 0.6, lifetime = 0.65 },
		{ id = SPRING, pitch = 1.65, volume = 0.7, lifetime = 0.5, delay = 0.13 },
	},
}

function SoundEffects.new(config)
	local audio = config.audio or {}
	local self = setmetatable({
		enabled = audio.enabled ~= false,
		volume = math.clamp(audio.volume or 0.4, 0, 1),
		destroyed = false,
		active = {},
		lastPlayed = {},
		generation = 0,
	}, SoundEffects)
	self.folder = Instance.new("Folder")
	self.folder.Name = "GoofyEggLocalSFX"
	self.folder.Parent = SoundService
	-- Preloading is optional and never blocks player input or game startup.
	task.spawn(function()
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ SPRING, WHOOSH, TAP, SPLASH })
		end)
		if not ok and not self.destroyed then
			warn("Goofy Egg: sound preloading was unavailable; cues will load on demand.")
		end
	end)
	return self
end

function SoundEffects:_voice(profile, generation)
	if self.destroyed or not self.enabled or self.generation ~= generation then
		return
	end
	-- Bound simultaneous voices even if notices arrive in a burst.
	local count = 0
	for voice in self.active do
		if voice.Parent then
			count += 1
		end
	end
	if count >= 6 then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "InteractionCue"
	sound.SoundId = profile.id
	sound.Volume = self.volume * profile.volume
	sound.PlaybackSpeed = profile.pitch
	sound.Looped = false
	sound.Parent = self.folder
	self.active[sound] = true
	sound:Play()
	task.delay(profile.lifetime, function()
		self.active[sound] = nil
		sound:Destroy()
	end)
end

function SoundEffects:play(cue)
	if self.destroyed or not self.enabled then
		return
	end
	local profiles = CUES[cue]
	if not profiles then
		return
	end
	local now = os.clock()
	if now - (self.lastPlayed[cue] or -math.huge) < 0.12 then
		return
	end
	self.lastPlayed[cue] = now
	local generation = self.generation
	for _, profile in profiles do
		if profile.delay then
			task.delay(profile.delay, function()
				self:_voice(profile, generation)
			end)
		else
			self:_voice(profile, generation)
		end
	end
end

function SoundEffects:setEnabled(enabled)
	self.enabled = enabled == true
	if not self.enabled then
		self.generation += 1
		for sound in self.active do
			sound:Destroy()
		end
		table.clear(self.active)
	end
end

function SoundEffects:destroy()
	if self.destroyed then
		return
	end
	self:setEnabled(false)
	self.destroyed = true
	self.folder:Destroy()
end

return SoundEffects
