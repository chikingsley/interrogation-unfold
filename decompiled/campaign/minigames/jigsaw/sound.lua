local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_init_jigsaw = hash("init_jigsaw")
local h_play_sfx = hash("play_sfx")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")

	if fmod then
		self.event_jigsaw_connect = fmod.studio.system:get_event("event:/Button/Hover Subject")
		self.event_jigsaw_drop_piece = fmod.studio.system:get_event("event:/Button/Hover Polaroid")
		self.event_jigsaw_pick_up_piece = fmod.studio.system:get_event("event:/Button/Hover Polaroid")
		self.event_jigsaw_complete = fmod.studio.system:get_event("event:/Campaign/Perk Cue")
		self.event_jigsaw_slide_in = fmod.studio.system:get_event("event:/Campaign/Paper Slide")
	end

	self.sub_id = dispatcher.subscribe({
		h_init_jigsaw,
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

		instance:start()
	end
end
