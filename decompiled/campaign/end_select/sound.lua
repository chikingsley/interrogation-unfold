local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local h_play_sfx = hash("play_sfx")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_fast_forward = hash("fast_forward")
local h_show_newspaper = hash("show_newspaper")

function _env:init()
	self.bank = sound_util.load_bank("Cutscene Final.bank")

	if fmod then
		self.event_gun_shot = fmod.studio.system:get_event("event:/Cutscenes/Cutscene Final/Gun Shot")
		self.event_cartridge = fmod.studio.system:get_event("event:/Cutscenes/Cutscene Final/Cartridge")
		self.event_load_gun = fmod.studio.system:get_event("event:/Cutscenes/Cutscene Final/Load Gun")
		self.event_rising_woosh = fmod.studio.system:get_event("event:/Cutscenes/Cutscene Final/Rising Woosh")
		self.event_panel_hover = fmod.studio.system:get_event("event:/Cutscenes/Cutscene Final/Panel Hover")
		self.event_newspaper_slide = fmod.studio.system:get_event("event:/Cutscenes/Cutscene Final/Newspaper Slide")
	end

	self.sub_id = dispatcher.subscribe({
		h_play_sfx,
		h_spine_cutscene_event
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
	elseif message_id == h_spine_cutscene_event then
		local event_id = message.event_id
		local integer = message.integer

		if event_id == h_fast_forward then
			self.event_rising_woosh:create_instance():start()
		elseif event_id == h_show_newspaper and integer ~= 1 then
			timer.delay(0.2, false, function ()
				self.event_newspaper_slide:create_instance():start()
			end)
		end
	end
end
