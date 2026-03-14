local dispatcher = require("crit.dispatcher")
local ConfirmModal = require("lib.confirm_modal")
local intl = require("crit.intl")
local difficulty_utils = require("main.settings.difficulty_utils")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_settings_confirm_difficulty_change = hash("settings_confirm_difficulty_change")
local h_settings_show_difficulty_backup_list = hash("settings_show_difficulty_backup_list")
local h_settings_acquire_input_focus = hash("settings_acquire_input_focus")

function _env:init()
	gui.set_render_order(15)

	self.rewind_index = nil

	intl.translate_text_node(gui.get_node("modal_button_cancel_text"))
	intl.translate_text_node(gui.get_node("modal_button_confirm_text"))

	self.modal = ConfirmModal.new({
		cancel_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
		end,
		confirm_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
			dispatcher.dispatch(h_settings_show_difficulty_backup_list, {
				difficulty = self.difficulty
			})
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_settings_confirm_difficulty_change,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_settings_confirm_difficulty_change then
		local old_difficulty = difficulty_utils.get_difficulty_in_current_profile()
		local difficulty = difficulty_utils.easier[old_difficulty]

		if not difficulty then
			return
		end

		self.difficulty = difficulty

		self.modal:show(intl("settings.difficulty.prompt", {
			difficulty = intl("difficulty_select." .. difficulty .. ".button_label"),
			old_difficulty = intl("difficulty_select." .. old_difficulty .. ".button_label")
		}))
		msg.post(".", "acquire_input_focus")
		dispatcher.dispatch(h_settings_acquire_input_focus)
	elseif message_id == h_window_change_size then
		self.modal:window_change_size()
	elseif message_id == h_switch_input_method then
		self.modal:switch_input_method(message)
	end
end

function _env:on_input(action_id, action)
	if self.modal:on_input(action_id, action) then
		return true
	end
end
