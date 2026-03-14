local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local h_cutscene_start_music = hash("cutscene_start_music")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_scene_transition_start = hash("scene_transition_start")

function _env:init()
	self.bank = sound_util.load_bank("Cutscene Intro.bank")
	self.sub_id = dispatcher.subscribe({
		h_cutscene_start_music,
		h_pause,
		h_resume,
		h_scene_transition_start
	})
	self.event_music = fmod and fmod.studio.system:get_event("event:/Cutscenes/Cutscene Intro/Music")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_cutscene_start_music then
		if self.event_music then
			self.music = self.event_music:create_instance()

			self.music:start()
		end
	elseif message_id == h_pause then
		if self.music then
			self.music = sound_util.pause_event(self.music)
		end
	elseif message_id == h_resume then
		if self.music then
			self.music:set_paused(false)
		end
	elseif message_id == h_scene_transition_start and self.music then
		sound_util.stop_event(self.music, self.bank)

		self.music = nil
	end
end
