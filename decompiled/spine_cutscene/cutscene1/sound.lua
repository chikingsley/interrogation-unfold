local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_play_sfx = hash("play_sfx")
local h_stop_sfx = hash("stop_sfx")
local h_sfx_set_parameters = hash("sfx_set_parameters")
local h_sfx_set_master_volume = hash("sfx_set_master_volume")
local h_enable_sfx = hash("enable_sfx")
local h_all_sfx = hash("all_sfx")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_scene_transition_start = hash("scene_transition_start")

function _env:init()
	self.enable_sfx = true
	self.instances = {}
	self.volume = 1
	self.bank = sound_util.load_bank("Cutscene 1.bank")

	if fmod then
		self.event_explosion = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Explosion")
		self.event_camera_shutter = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Camera Shutter")
		self.event_city_sirens = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/City Sirens")
		self.event_light_rain = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Light Rain")
		self.event_crowd = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Crowd")
		self.event_crowd_screams = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Crowd Screams")
		self.event_car_engines = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Car Engines")
		self.event_music = fmod.studio.system:get_event("event:/Cutscenes/Cutscene1/Music")
	end

	self.sub_id = dispatcher.subscribe({
		h_play_sfx,
		h_enable_sfx,
		h_stop_sfx,
		h_sfx_set_parameters,
		h_pause,
		h_resume,
		h_scene_transition_start,
		h_sfx_set_master_volume
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_enable_sfx then
		self.enable_sfx = message.enable_sfx
	elseif message_id == h_pause then
		for event, instance_table in pairs(self.instances) do
			for index, instance in pairs(instance_table) do
				local playback_state = instance:get_playback_state()

				if playback_state == fmod.STUDIO_PLAYBACK_STOPPED or playback_state == fmod.STUDIO_PLAYBACK_STOPPING then
					instance_table[index] = nil
				else
					instance_table[index] = sound_util.pause_event(instance)
				end
			end
		end
	elseif message_id == h_resume then
		for event, instance_table in pairs(self.instances) do
			for index, instance in pairs(instance_table) do
				instance:set_paused(false)
			end
		end
	elseif self.enable_sfx then
		if message_id == h_play_sfx then
			local event_id = "event_" .. message.sfx
			local event = self[event_id]

			if not event then
				return
			end

			local instance = event:create_instance()

			instance:set_volume(self.volume)

			if message.parameters then
				for parameter, value in pairs(message.parameters) do
					instance:set_parameter_by_name(parameter, value, false)
				end
			end

			if instance then
				instance:start()

				if not self.instances[event_id] then
					self.instances[event_id] = {}
				end

				table.insert(self.instances[event_id], instance)
			end
		elseif message_id == h_stop_sfx or message_id == h_scene_transition_start then
			local sfx = message.sfx

			if not sfx or sfx == h_all_sfx then
				for event_id, instance_table in pairs(self.instances) do
					for index, instance in pairs(instance_table) do
						instance:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)
					end

					self.instances[event_id] = nil
				end
			else
				local event_id = "event_" .. sfx

				if self.instances[event_id] then
					for i, instance in pairs(self.instances[event_id]) do
						instance:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)
					end
				end

				self.instances[event_id] = nil
			end
		elseif message_id == h_sfx_set_parameters then
			local sfx = message.sfx
			local instance_index = message.instance_index
			local event_id = "event_" .. sfx

			if instance_index then
				for parameter, value in pairs(message.parameters) do
					self.instances[event_id][instance_index]:set_parameter_by_name(parameter, value, false)
				end
			else
				local current_event_instances = self.instances[event_id]

				if current_event_instances then
					for i, instance in pairs(current_event_instances) do
						for parameter, value in pairs(message.parameters) do
							instance:set_parameter_by_name(parameter, value, false)
						end
					end
				end
			end
		elseif message_id == h_sfx_set_master_volume then
			self.volume = message.volume

			for event, instance_table in pairs(self.instances) do
				for index, instance in pairs(instance_table) do
					instance:set_volume(self.volume)
				end
			end
		end
	end
end
