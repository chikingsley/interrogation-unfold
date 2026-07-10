local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_play_sfx = hash("play_sfx")
local h_press_release_save = hash("press_release_save")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")

	if fmod then
		self.event_paper_yank = fmod.studio.system:get_event("event:/Typewriter/Paper Yank")
		self.event_typing = fmod.studio.system:get_event("event:/Typewriter/Typing")
		self.event_ac_hum = fmod.studio.system:get_event("event:/Typewriter/AC Hum")
		self.event_ratchet = fmod.studio.system:get_event("event:/Typewriter/Ratchet")
		self.event_return_typehead = fmod.studio.system:get_event("event:/Typewriter/Return Typehead")
		self.event_light_switch = fmod.studio.system:get_event("event:/Campaign/Light Switch")
	end

	timer.delay(1, false, function ()
		if self.event_ac_hum then
			self.instance_ac_hum = self.event_ac_hum:create_instance()

			self.instance_ac_hum:start()
		end
	end)

	self.sub_id = dispatcher.subscribe({
		h_play_sfx,
		h_press_release_save
	})
end

function _env:final()
	if self.instance_ac_hum then
		sound_util.stop_event(self.instance_ac_hum, self.bank)
	end

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
	elseif message_id == h_press_release_save then
		if self.instance_ac_hum then
			self.instance_ac_hum:set_parameter_by_name("IsRunning", 0, false)
		end

		if self.event_paper_yank then
			self.event_paper_yank:create_instance():start()
		end
	end
end
