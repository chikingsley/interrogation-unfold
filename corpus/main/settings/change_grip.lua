local dispatcher = require("crit.dispatcher")
local ConfirmModal = require("lib.confirm_modal")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_settings_change_grip = hash("settings_change_grip")
local h_settings_acquire_input_focus = hash("settings_acquire_input_focus")
local h_key_escape = hash("key_escape")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")

function _env:init()
	gui.set_render_order(15)
	intl.translate_text_node(gui.get_node("modal_button_cancel_text"))
	intl.translate_text_node(gui.get_node("modal_button_confirm_text"))

	self.modal = ConfirmModal.new({
		no_shortcuts = true,
		cancel_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
			misc.change_controller_grip(false)
		end,
		confirm_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
			misc.change_controller_grip(true)
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_settings_change_grip,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_settings_change_grip then
		self.modal:show(intl("settings.change_grip.prompt"))
		msg.post(".", "acquire_input_focus")
		dispatcher.dispatch(h_settings_acquire_input_focus)
	elseif message_id == h_window_change_size then
		self.modal:window_change_size()
	elseif message_id == h_switch_input_method then
		self.modal:switch_input_method(message)
	end
end

function _env:on_input(action_id, action)
	if self.modal.shown and action.pressed and (action_id == h_key_escape or action_id == h_gamepad_rpad_right) then
		self.modal:hide()
		msg.post(".", "release_input_focus")

		return true
	end

	if self.modal:on_input(action_id, action) then
		return true
	end
end
