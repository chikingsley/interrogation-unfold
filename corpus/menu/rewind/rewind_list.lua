local dispatcher = require("crit.dispatcher")
local ListModal = require("menu.rewind.list_modal")
local save_file = require("lib.save_file")
local checkpoint_names = require("main.progression.checkpoint_names")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_menu_show_rewind_list = hash("menu_show_rewind_list")
local h_menu_confirm_rewind = hash("menu_confirm_rewind")

function _env:init()
	gui.set_render_order(5)
	intl.translate_text_node(gui.get_node("template/label"))

	self.modal = ListModal.new({
		cancel_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_menu_show_rewind_list,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_menu_show_rewind_list then
		local buttons = {}
		local checkpoints = save_file.get_current_profile().get().checkpoints

		for i = #checkpoints, 0, -1 do
			local name = nil

			if i ~= 0 then
				local checkpoint = checkpoints[i]
				name = checkpoint_names[checkpoint] or checkpoint
			else
				name = intl("menu.new_game")
			end

			buttons[#buttons + 1] = {
				label = name,
				action = function ()
					dispatcher.dispatch(h_menu_confirm_rewind, {
						rewind_index = i,
						checkpoint_name = name
					})
				end
			}
		end

		self.modal:show(buttons)
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
