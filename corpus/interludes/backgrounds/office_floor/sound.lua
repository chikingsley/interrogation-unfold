local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_scene_transition_start = hash("scene_transition_start")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	self.ambient_event = fmod and fmod.studio.system:get_event("event:/Ambiances/Office Chatter")

	if self.ambient_event then
		local instance = self.ambient_event:create_instance()
		self.ambient = instance

		instance:start()
	end

	self.sub_id = dispatcher.subscribe({
		h_pause,
		h_resume,
		h_scene_transition_start
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
	elseif message_id == h_resume and self.ambient then
		self.ambient:set_paused(false)
	end
end
