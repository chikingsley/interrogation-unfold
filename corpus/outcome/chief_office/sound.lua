local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_scene_transition_start = hash("scene_transition_start")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	self.event_ambient = fmod and fmod.studio.system:get_event("event:/Ambiances/Fan Noise")

	if self.event_ambient then
		local instance = self.event_ambient:create_instance()
		self.ambient = instance

		instance:start()
	end

	self.sub_id = dispatcher.subscribe({
		h_pause,
		h_resume,
		h_scene_transition_start,
		h_outcome_enable_transcript,
		h_outcome_disable_transcript
	})
end

function _env:final()
	sound_util.release_bank(self.bank)
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_scene_transition_start then
		if self.ambient then
			sound_util.stop_event(self.ambient, self.bank)

			self.ambient = nil
		end
	elseif message_id == h_pause then
		if self.ambient then
			self.ambient = sound_util.pause_event(self.ambient)
		end
	elseif message_id == h_resume then
		if self.ambient then
			self.ambient:set_paused(false)
		end
	elseif message_id == h_outcome_enable_transcript then
		if self.ambient then
			self.ambient:set_parameter_by_name("Dampen", 1, false)
		end
	elseif message_id == h_outcome_disable_transcript and self.ambient then
		self.ambient:set_parameter_by_name("Dampen", 0, false)
	end
end
