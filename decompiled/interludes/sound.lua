local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_play_sfx = hash("play_sfx")
local h_play_sfx_advance = hash("play_sfx_advance")
local h_interludes_choice_picked = hash("interludes_choice_picked")
local h_update_insanity_question = hash("update_insanity_question")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	self.sub_id = dispatcher.subscribe({
		h_play_sfx,
		h_play_sfx_advance,
		h_interludes_choice_picked,
		h_update_insanity_question
	})
	self.event_interludes_advance = fmod and fmod.studio.system:get_event("event:/Campaign/Interludes Advance")
	self.event_interludes_choice = fmod and fmod.studio.system:get_event("event:/Campaign/Interludes Choice")
	self.event_insanity_ringing = fmod and fmod.studio.system:get_event("event:/Interrogation/Insanity Ringing")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
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
	elseif message_id == h_play_sfx_advance then
		if self.event_interludes_advance then
			self.event_interludes_advance:create_instance():start()
		end
	elseif message_id == h_interludes_choice_picked then
		if self.event_interludes_choice then
			self.event_interludes_choice:create_instance():start()
		end
	elseif message_id == h_update_insanity_question then
		local insanity_amount = 0.6
		local music = sound_util.music
		local is_shown = message.shown

		if music then
			pcall(function ()
				music:set_parameter_by_name("Insanity", is_shown and insanity_amount, false)
			end)
		end

		if is_shown then
			if not self.insanity_ringing then
				if self.event_insanity_ringing then
					local insanity_ringing = self.event_insanity_ringing:create_instance()

					insanity_ringing:set_parameter_by_name("Insanity", insanity_amount, false)
					insanity_ringing:start()

					self.insanity_ringing = insanity_ringing
				end
			else
				self.insanity_ringing:set_parameter_by_name("Insanity", insanity_amount, false)
			end
		elseif self.insanity_ringing then
			self.insanity_ringing:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)

			self.insanity_ringing = nil
		end
	end
end
