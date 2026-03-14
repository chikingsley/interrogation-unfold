local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local h_play_sfx = hash("play_sfx")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")

	if fmod then
		self.event_get_shot = fmod.studio.system:get_event("event:/Campaign/Get Shot")
		self.event_newspaper_slide = fmod.studio.system:get_event("event:/Campaign/Newspaper Slide")
	end

	self.sub_id = dispatcher.subscribe({
		h_play_sfx
	})
end

function _env:final()
	sound_util.release_bank(self.bank)
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_play_sfx then
		local event = self["event_" .. message.sfx]

		if not event then
			return
		end

		local instance = event:create_instance()

		if message.parameters then
			for parameter, value in pairs(message.parameters) do
				instance:set_parameter_by_name(parameter, value, false)
			end
		end

		if instance then
			instance:start()
		end
	end
end
