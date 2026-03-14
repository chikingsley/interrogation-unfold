local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local animation_sfx = require("interludes.backgrounds.interrogation_room.animation_sfx")
local h_play_episode8_sfx = hash("play_episode8_sfx")
local h_scene_transition_start = hash("scene_transition_start")
local h_transition_started = hash("transition_started")
local h_elias_final_stage = hash("elias_final_stage")
local h_play_animation_sfx = hash("play_animation_sfx")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_episode8_init = hash("episode8_init")
local h_start_game = hash("start_game")
local h_interludes_show_character = hash("interludes_show_character")
local h_play_room_noise_sfx = hash("play_room_noise_sfx")
local h_elias_idle4_cut = hash("elias_idle4_cut")
local h_elias_idle3_grab = hash("elias_idle3_grab")

function _env:init()
	self.bank_common = sound_util.load_bank("All Levels.bank")
	self.bank_music = sound_util.load_bank("Level episode8.bank")
	self.phase = 1
	self.event_music = fmod and fmod.studio.system:get_event("event:/Level Music/episode8")
	self.event_room_noise = fmod and fmod.studio.system:get_event("event:/Ambiances/Room Noise")
	self.event_bring_them_in = fmod and fmod.studio.system:get_event("event:/Interrogation/Bring Them In")
	self.sub_id = dispatcher.subscribe({
		h_play_episode8_sfx,
		h_play_animation_sfx,
		h_interludes_show_character,
		h_start_game,
		h_transition_started,
		h_elias_final_stage,
		h_pause,
		h_resume,
		h_episode8_init,
		h_play_room_noise_sfx
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)

	if self.music then
		sound_util.stop_event(self.music, self.bank_music)
	end

	if self.ambience then
		sound_util.stop_event(self.ambience, self.bank_common)
	end

	sound_util.release_bank(self.bank_common)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_play_animation_sfx then
		local animation_id = message.id

		if (animation_id == h_elias_idle4_cut or animation_id == h_elias_idle3_grab) and self.music then
			timer.delay(animation_sfx[animation_id].delay, false, function ()
				self.music:set_parameter_by_name("Hurt", 1, false)
				timer.delay(1, false, function ()
					self.music:set_parameter_by_name("Hurt", 0, false)
				end)
			end)
		end

		if self.animation_sfx_timer then
			timer.cancel(self.animation_sfx_timer)

			self.animation_sfx_timer = nil
		end

		local sfx = animation_sfx[animation_id]

		if sfx and fmod then
			local delay = sfx.delay
			local event_name = sfx.sfx
			local event = fmod.studio.system:get_event("event:/Episode 8/" .. event_name)
			self.animation_sfx_timer = timer.delay(delay, false, function ()
				event:create_instance():start()
			end)
		end
	elseif message_id == h_start_game then
		if self.event_music then
			local music = self.event_music:create_instance()

			music:start()

			self.music = music
		end

		if self.ambience then
			self.ambience:set_parameter_by_name("FadeVolume", 0, false)
		end
	elseif message_id == h_pause then
		if self.music then
			self.music = sound_util.pause_event(self.music)
		end

		if self.ambience then
			self.ambience = sound_util.pause_event(self.ambience)
		end
	elseif message_id == h_resume then
		if self.music then
			self.music:set_paused(false)
		end

		if self.ambience then
			self.ambience:set_paused(false)
		end
	elseif message_id == h_elias_final_stage then
		self.phase = self.phase + 1

		if self.music then
			self.music:set_parameter_by_name("Phase", self.phase, false)
		end
	elseif message_id == h_transition_started then
		self.phase = self.phase + 1

		if self.music then
			self.music:set_parameter_by_name("Phase", self.phase, false)
		end
	elseif message_id == h_scene_transition_start then
		if self.music then
			sound_util.stop_event(self.music, self.bank_music)

			self.music = nil
		end

		if self.ambience then
			sound_util.stop_event(self.ambience, self.bank_common)

			self.ambience = nil
		end
	elseif message_id == h_interludes_show_character then
		if message.character == "elias" and self.event_bring_them_in then
			self.event_bring_them_in:create_instance():start()
		end
	elseif message_id == h_play_room_noise_sfx then
		if self.event_room_noise then
			local ambience = self.event_room_noise:create_instance()

			ambience:start()

			self.ambience = ambience
		end
	elseif message_id == h_play_episode8_sfx then
		local event = "event_" .. message.sfx
		local instance = self[event]:create_instance()

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
