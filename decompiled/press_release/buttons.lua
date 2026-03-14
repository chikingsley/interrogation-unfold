local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local Layout = require("crit.layout")
local press_release = require("press_release.press_release")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local LongPress = require("lib.long_press")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_press_release_save = hash("press_release_save")
local h_press_release_update = hash("press_release_update")
local h_switch_input_method = hash("switch_input_method")
local h_end_scene = hash("end_scene")
local h_colorw = hash("color.w")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local end_scene_delay = 2

function _env:init()
	intl.translate_text_node(gui.get_node("button_save_text"))

	self.sub_id = dispatcher.subscribe({
		h_press_release_save,
		h_press_release_update,
		h_window_change_size,
		h_switch_input_method
	})
	local save_button_node = gui.get_node("button_save")
	self.prompt_y_node = gui.get_node("prompt_y")
	self.key_prompt = KeyPrompt.new(self.prompt_y_node)

	self.key_prompt:set_enabled(false)

	self.save_button = Button.new(save_button_node, {
		focus_node = gui.get_node("button_save_glow"),
		faded_nodes = {
			save_button_node,
			gui.get_node("button_save_text")
		},
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		action = function ()
			dispatcher.dispatch(h_press_release_save)
		end
	})
	self.long_press_continue = LongPress.new(self.prompt_y_node, {
		gamepad_action_id = h_gamepad_rpad_up,
		button = self.save_button
	})
	self.save_tooltip_button = Button.new(self.save_button.node, {
		hover_from_external_touch = true,
		faded_nodes = {},
		shortcut_actions = {
			h_gamepad_rpad_up
		},
		on_state_change = Tooltip.button_on_state_change({
			id = "save",
			type = h_press_release_save
		}, false)
	})

	self.save_button:set_enabled(false)
	self.save_tooltip_button:set_enabled(false)
	gui.set_color(save_button_node, vmath.vector4(0))
	gui.animate(save_button_node, h_colorw, 1, gui.EASING_LINEAR, 0.3, 1, function ()
		self.save_button:set_enabled(true)
		self.save_tooltip_button:set_enabled(true)
		dispatcher.dispatch(h_press_release_update)
	end)

	self.layout = Layout.new()

	self.layout:add_node(self.save_button.node, {
		grav_y = 0,
		grav_x = 1
	})
	msg.post(".", "acquire_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_press_release_save then
		if press_release.are_all_options_set() then
			self.save_button:set_enabled(false)

			self.exiting = true

			gui.animate(gui.get_node("button_save"), h_colorw, 0, gui.EASING_LINEAR, 0.4)
			timer.delay(end_scene_delay, false, function ()
				dispatcher.dispatch(h_end_scene)
			end)
		end
	elseif message_id == h_press_release_update then
		if press_release.are_all_options_set() then
			self.save_button:set_enabled(true)
			self.key_prompt:set_enabled(true)
		else
			self.save_button:set_enabled(false)
			self.key_prompt:set_enabled(false)
		end
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
	end
end

function _env:on_input(action_id, action)
	if self.long_press_continue:on_input(action_id, action) then
		return true
	end

	if self.save_tooltip_button:on_input(action_id, action) then
		return true
	end

	if self.save_button:on_input(action_id, action) then
		return true
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end
