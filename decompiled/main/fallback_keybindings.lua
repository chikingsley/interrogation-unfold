local dispatcher = require("crit.dispatcher")
local h_pause_menu_init = hash("pause_menu_init")
local h_settings_init = hash("settings_init")
local h_settings_hide = hash("settings_hide")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_attempt_pause = hash("attempt_pause")
local h_attempt_resume = hash("attempt_resume")
local h_key_escape = hash("key_escape")
local current_scene = require("main.scene_loader.current_scene")
local h_after_init = hash("after_init")
local h_fallback_keybindings_init = hash("fallback_keybindings_init")

function _env:init()
	self.alt_down = false
	self.shift_down = false
	self.ctrl_down = false
	self.paused = false
	self.shows_settings = false
	self.sub_id = dispatcher.subscribe({
		h_pause_menu_init,
		h_settings_init,
		h_settings_hide,
		h_pause,
		h_resume
	})

	msg.post(".", "acquire_input_focus")
	msg.post(".", h_after_init)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_settings_init then
		self.shows_settings = true
	elseif message_id == h_settings_hide then
		self.shows_settings = false
	elseif message_id == h_pause then
		self.paused = true
	elseif message_id == h_resume then
		self.paused = false
	elseif message_id == h_after_init then
		dispatcher.dispatch(h_fallback_keybindings_init)
	end
end

function _env:on_input(action_id, action)
	if action_id == h_key_escape and action.pressed and not self.shows_settings and current_scene.scene ~= "menu" then
		dispatcher.dispatch(self.paused and h_attempt_resume or h_attempt_pause)

		return true
	end
end
