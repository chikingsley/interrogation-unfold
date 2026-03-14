local dispatcher = require("crit.dispatcher")
local ConfirmModal = require("lib.confirm_modal")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_menu_confirm_rewind = hash("menu_confirm_rewind")
local h_run_progression = hash("run_progression")

function _env:init()
	gui.set_render_order(10)

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
			dispatcher.dispatch(h_run_progression, {
				id = "campaign",
				options = {
					rewind = self.rewind_index
				}
			})
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_menu_confirm_rewind,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_menu_confirm_rewind then
		local rewind_index = message.rewind_index
		local checkpoint_name = message.checkpoint_name
		self.rewind_index = rewind_index
		local text = nil

		if rewind_index == 0 then
			text = intl("menu.rewind.confirm_new_game")
		else
			text = intl("menu.rewind.confirm_checkpoint", {
				checkpoint_name = checkpoint_name
			})
		end

		self.modal:show(text)
		msg.post(".", "acquire_input_focus")
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
