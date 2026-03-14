local dispatcher = require("crit.dispatcher")
local ListModal = require("menu.rewind.list_modal")
local save_file = require("lib.save_file")
local checkpoint_names = require("main.progression.checkpoint_names")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_menu_show_profile_list = hash("menu_show_profile_list")
local h_run_progression = hash("run_progression")

function _env:init()
	gui.set_render_order(6)
	intl.translate_text_node(gui.get_node("template/label"))

	self.modal = ListModal.new({
		cancel_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_menu_show_profile_list,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_menu_show_profile_list then
		local buttons = {}
		local profiles = save_file.get_all_profiles()

		for i, profile in ipairs(profiles) do
			local data = profile.get()
			local name = nil

			if not data.history.latest then
				name = intl("menu.profiles.empty_slot")
			else
				local checkpoints = data.checkpoints
				local checkpoint = checkpoints[#checkpoints]

				if not checkpoint then
					name = checkpoint_names.prologue or intl("checkpoint.prologue")
				else
					name = checkpoint_names[checkpoint] or checkpoint
				end
			end

			buttons[#buttons + 1] = {
				label = name,
				color = i == (save_file.config.profile or 1) and vmath.vector4(1, 1, 0, 1),
				action = function ()
					save_file.set_current_profile(i)
					dispatcher.dispatch(h_run_progression, {
						id = "menu",
						options = {}
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
