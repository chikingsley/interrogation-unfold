local sound_util = require("sound.util")
local env = require("lib.environment")
local save_file = require("lib.save_file")
local button_sound = require("sound.button")
local dispatcher = require("crit.dispatcher")
local h_sound_delayed_bank_release = hash("sound_delayed_bank_release")
local config = save_file.config
local banks_to_release = sound_util._banks_to_release
local set_volumes = nil

function _env:init()
	local ok, error = pcall(function ()
		sound_util.load_bank("Master Bank.bank")
		sound_util.load_bank("Master Bank.strings.bank")
	end)

	if not ok then
		print(error)

		fmod = nil
	end

	if fmod then
		self.master_bus = fmod.studio.system:get_bus("bus:/")
		self.music_vca = fmod.studio.system:get_vca("vca:/Music")
		self.sfx_vca = fmod.studio.system:get_vca("vca:/SFX")
	end

	set_volumes(self)
	button_sound.init()

	self.sub_id = dispatcher.subscribe({
		h_sound_delayed_bank_release
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	button_sound.final()
end

function _env:update(dt)
	set_volumes(self)
end

function _env:on_message(message_id, message)
	if message_id == h_sound_delayed_bank_release then
		local id = message.bank_id
		local bank = banks_to_release[id]
		banks_to_release[id] = nil

		timer.delay(message.delay, false, function ()
			sound_util.release_bank(bank)
		end)
	end
end

function set_volumes(self)
	local master_volume = (env.mute or sound.is_phone_call_active()) and 0 or config.master_volume
	local music_volume = env.mute_music and 0 or config.music_volume
	local sfx_volume = env.mute_sfx and 0 or config.sfx_volume

	if self.master_bus then
		self.master_bus:set_volume(master_volume)
	end

	if self.music_vca then
		self.music_vca:set_volume(music_volume)
	end

	if self.sfx_vca then
		self.sfx_vca:set_volume(sfx_volume)
	end
end
