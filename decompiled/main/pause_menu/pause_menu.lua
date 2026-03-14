local Layout = require("crit.layout")
local Button = require("crit.button")
local FocusGiver = require("crit.focus_giver")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local input_state = require("crit.input_state")
local pause_menu = require("main.pause_menu.pause_menu")
local intl = require("crit.intl")
local cursor = require("lib.cursor")
local env = require("lib.environment")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_attempt_pause = hash("attempt_pause")
local h_attempt_resume = hash("attempt_resume")
local h_colorw = hash("color.w")
local h_key_escape = hash("key_escape")
local h_gamepad_start = hash("gamepad_start")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_window_change_size = hash("window_change_size")
local h_run_progression = hash("run_progression")
local h_settings_show = hash("settings_show")
local h_scene_input_blocker_init = hash("scene_input_blocker_init")
local h_pause_menu_init = hash("pause_menu_init")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_scene_set_time_step = hash("scene_set_time_step")
local h_scene_transition_start = hash("scene_transition_start")
local h_scene_transition_end = hash("scene_transition_end")
local h_switch_input_method = hash("switch_input_method")
local h_level_restart = hash("level_restart")

function _env:init()
	local focus_context = input_state.new_focus_context()

	intl.translate_text_node(gui.get_node("caption"))
	intl.translate_text_node(gui.get_node("resume_button_label"))
	intl.translate_text_node(gui.get_node("settings_button_label"))
	intl.translate_text_node(gui.get_node("restart_button_label"))
	intl.translate_text_node(gui.get_node("quit_button_label"))

	self.resume_button = Button.new(gui.get_node("resume_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("resume_button"),
			gui.get_node("resume_button_label")
		},
		action = function ()
			dispatcher.dispatch(h_attempt_resume)
		end,
		focus_context = focus_context,
		focus_node = gui.get_node("resume_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_DOWN then
				return self.settings_button:focus()
			end
		end
	})
	self.settings_button = Button.new(gui.get_node("settings_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("settings_button"),
			gui.get_node("settings_button_label")
		},
		action = function ()
			dispatcher.dispatch(h_settings_show)
		end,
		focus_context = focus_context,
		focus_node = gui.get_node("settings_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_UP then
				return self.resume_button:focus()
			elseif nav_action == Button.NAVIGATE_DOWN then
				if pause_menu.has_restart_button then
					return self.restart_button:focus()
				else
					return self.quit_button:focus()
				end
			end
		end
	})
	self.restart_button = Button.new(gui.get_node("restart_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("restart_button"),
			gui.get_node("restart_button_label")
		},
		action = function ()
			dispatcher.dispatch(h_attempt_resume, {
				quitting = true
			})
			dispatcher.dispatch(h_level_restart)
		end,
		focus_context = focus_context,
		focus_node = gui.get_node("restart_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_UP then
				return self.settings_button:focus()
			elseif nav_action == Button.NAVIGATE_DOWN then
				return self.quit_button:focus()
			end
		end
	})
	self.quit_button = Button.new(gui.get_node("quit_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("quit_button"),
			gui.get_node("quit_button_label")
		},
		action = function ()
			dispatcher.dispatch(h_attempt_resume, {
				quitting = true
			})
			dispatcher.dispatch(h_run_progression, {
				id = "menu"
			})
		end,
		focus_context = focus_context,
		focus_node = gui.get_node("quit_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_UP then
				if pause_menu.has_restart_button then
					return self.restart_button:focus()
				else
					return self.settings_button:focus()
				end
			end
		end
	})
	local debug_node = gui.get_node("debug_button")

	if not env.bundled or env.debug then
		self.debug_button = Button.new(debug_node, {
			action = function ()
				dispatcher.dispatch("debug_hub_toggle")
			end
		})
	else
		gui.delete_node(debug_node)
	end

	self.restart_position = gui.get_position(self.restart_button.node)
	self.quit_position = gui.get_position(self.quit_button.node)
	self.container = gui.get_node("container")

	gui.set_color(self.container, vmath.vector4(0))
	gui.set_enabled(self.container, false)

	self.background = gui.get_node("background")

	gui.set_color(self.background, vmath.vector4(0))
	gui.set_enabled(self.background, false)

	self.is_transition_playing = false
	self.cursor_visible = true
	self.layout = Layout.new()
	self.container_layout_spec = self.layout:add_node(self.container)
	self.container_position = self.container_layout_spec.position

	self.layout:add_node(self.background, {
		resize_y = true,
		resize_x = true
	})

	self.focus_giver = FocusGiver.new({
		focus_context = focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if not nav_action or nav_action == Button.NAVIGATE_DOWN then
				return self.resume_button:focus()
			elseif nav_action == Button.NAVIGATE_UP then
				return self.quit_button:focus()
			end
		end
	})

	gui.set_render_order(14)

	self.sub_id = dispatcher.subscribe({
		h_attempt_pause,
		h_attempt_resume,
		h_window_change_size,
		h_scene_input_blocker_init,
		h_scene_transition_start,
		h_scene_transition_end,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_attempt_pause and not self.is_transition_playing and not pause_menu.pause_menu_blocked then
		self.enabled = true

		cursor.set_visible(true, cursor.PRIORITY_PAUSE_MENU)

		local has_restart_button = pause_menu.has_restart_button

		gui.set_enabled(self.restart_button.node, has_restart_button)

		local container_position = self.container_position

		if has_restart_button then
			gui.set_position(self.quit_button.node, self.quit_position)
		else
			gui.set_position(self.quit_button.node, self.restart_position)

			container_position = container_position + (self.quit_position - self.restart_position) * 0.5
		end

		self.container_layout_spec.position = container_position

		self.layout:place()
		self.focus_giver:try_focus_first()
		gui.set_enabled(self.container, true)
		gui.set_enabled(self.background, true)
		gui.cancel_animation(self.container, h_colorw)
		gui.cancel_animation(self.background, h_colorw)
		gui.animate(self.container, h_colorw, 1, gui.EASING_LINEAR, 0.3)
		gui.animate(self.background, h_colorw, 1, gui.EASING_LINEAR, 0.3)
		dispatcher.dispatch(h_scene_set_time_step, {
			factor = 0
		})
		dispatcher.dispatch(h_pause, message)
	elseif message_id == h_attempt_resume and not self.is_transition_playing then
		self.enabled = false

		cursor.set_visible(nil, cursor.PRIORITY_PAUSE_MENU)
		gui.set_enabled(self.container, true)
		gui.set_enabled(self.background, true)
		gui.cancel_animation(self.container, h_colorw)
		gui.cancel_animation(self.background, h_colorw)
		gui.animate(self.container, h_colorw, 0, gui.EASING_LINEAR, 0.3)
		gui.animate(self.background, h_colorw, 0, gui.EASING_LINEAR, 0.3, 0, function ()
			gui.set_enabled(self.container, false)
			self.resume_button:cancel_focus()
			self.settings_button:cancel_focus()
			self.restart_button:cancel_focus()
			self.quit_button:cancel_focus()
		end)
		dispatcher.dispatch(h_scene_set_time_step, {
			factor = 1
		})
		dispatcher.dispatch(h_resume, message)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.resume_button:switch_input_method()
		self.settings_button:switch_input_method()
		self.restart_button:switch_input_method()
		self.quit_button:switch_input_method()
		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_scene_transition_start then
		self.is_transition_playing = true
	elseif message_id == h_scene_transition_end then
		self.is_transition_playing = false
	elseif message_id == h_scene_input_blocker_init then
		msg.post(".", h_acquire_input_focus)
		dispatcher.dispatch(h_pause_menu_init)
	end
end

function _env:on_input(action_id, action)
	if not self.enabled then
		return
	end

	if action.pressed and (action_id == h_key_escape or action_id == h_gamepad_start or action_id == h_gamepad_rpad_right) then
		dispatcher.dispatch(h_attempt_resume)

		return true
	end

	if self.resume_button:on_input(action_id, action) then
		return true
	end

	if self.quit_button:on_input(action_id, action) then
		return true
	end

	if self.settings_button:on_input(action_id, action) then
		return true
	end

	if pause_menu.has_restart_button and self.restart_button:on_input(action_id, action) then
		return true
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end

	if self.debug_button and self.debug_button:on_input(action_id, action) then
		return true
	end

	return true
end
