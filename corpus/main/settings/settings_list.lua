local dispatcher = require("crit.dispatcher")
local ListModal = require("menu.rewind.list_modal")
local save_file = require("lib.save_file")
local checkpoint_names = require("main.progression.checkpoint_names")
local intl = require("crit.intl")
local difficulty_utils = require("main.settings.difficulty_utils")
local scenes = require("main.progression.scenes")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_settings_show_difficulty_backup_list = hash("settings_show_difficulty_backup_list")
local h_settings_exit = hash("settings_exit")
local h_attempt_resume = hash("attempt_resume")

function _env:init()
	gui.set_render_order(15)
	intl.translate_text_node(gui.get_node("template/label"))

	self.modal = ListModal.new({
		cancel_action = function ()
			self.modal:hide()
			msg.post(".", "release_input_focus")
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_settings_show_difficulty_backup_list,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end

local function confirm(self, difficulty, backup_profile)
	self.modal:hide()
	msg.post(".", "release_input_focus")
	difficulty_utils.set_difficulty_in_current_profile(difficulty, backup_profile)
	scenes.run_progression("menu")
	dispatcher.dispatch(h_settings_exit)
	dispatcher.dispatch(h_attempt_resume)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_settings_show_difficulty_backup_list then
		local buttons = {}
		local difficulty = message.difficulty
		local profiles = save_file.get_all_profiles()

		for i, profile in ipairs(profiles) do
			local is_this_slot = i == (save_file.config.profile or 1)
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

				if not is_this_slot then
					name = intl("settings.copy_old_save.overwrite", {
						name = name
					})
				end
			end

			if is_this_slot then
				name = intl("settings.copy_old_save.current", {
					name = name
				})
			end

			local backup_profile = profile
			buttons[#buttons + 1] = {
				label = name,
				color = is_this_slot and vmath.vector4(0.5, 0.5, 0.5, 1),
				action = function ()
					if is_this_slot then
						return
					end

					confirm(self, difficulty, backup_profile)
				end
			}
		end

		buttons[#buttons + 1] = {
			label = intl("settings.copy_old_save.cancel"),
			action = function ()
				confirm(self, difficulty)
			end
		}

		self.modal:show(buttons)
		msg.post(".", "acquire_input_focus")

		return
	end

	if message_id == h_window_change_size then
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
