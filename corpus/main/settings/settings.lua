local Layout = require("crit.layout")
local Button = require("crit.button")
local ScrollBar = require("crit.scrollbar")
local dispatcher = require("crit.dispatcher")
local save_file = require("lib.save_file")
local button_sound = require("sound.button")
local env = require("lib.environment")
local input_state = require("crit.input_state")
local FocusGiver = require("crit.focus_giver")
local caret = require("lib.caret")
local analog_to_digital = require("crit.analog_to_digital")
local intl = require("crit.intl")
local KeyPrompt = require("lib.key_prompt")
local twitch = require("main.twitch.twitch")
local read_licenses = require("main.settings.read_licenses")
local sys_config = require("lib.sys_config")
local iap_utils = require("lib.iap_utils")
local difficulty_utils = require("main.settings.difficulty_utils")
local large_ui = require("lib.large_ui")
local h_window_change_size = hash("window_change_size")
local h_key_escape = hash("key_escape")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_colorw = hash("color.w")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_switch_input_method = hash("switch_input_method")
local h_settings_init = hash("settings_init")
local h_settings_acquire_input_focus = hash("settings_acquire_input_focus")
local h_settings_exit = hash("settings_exit")
local h_slider = hash("slider")
local h_slider_rail = hash("slider_rail")
local h_slider_knob = hash("slider_knob")
local h_picker = hash("picker")
local h_picker_label = hash("picker_label")
local h_picker_next = hash("picker_next")
local h_picker_previous = hash("picker_previous")
local h_button = hash("button")
local h_button_label = hash("button_label")
local h_brightcon_setting_update = hash("brightcon_setting_update")
local h_twitch_login = hash("twitch_login")
local h_twitch_stop = hash("twitch_stop")
local h_settings_confirm_difficulty_change = hash("settings_confirm_difficulty_change")
local h_settings_change_grip = hash("settings_change_grip")
local make_picker, make_button, make_slider, exit_settings, on_focus_change = nil
local config = save_file.config
local control_spacing = (not env.bundled or env.debug) and 65 or 80

local function volume_to_factor(x)
	if x == 0 then
		return 0
	end

	local db_value = (x - 1) * 30

	return math.pow(10, db_value / 20)
end

local function factor_to_volume(x)
	if x == 0 then
		return 0
	end

	local db_value = 20 * math.log10(x)

	return db_value / 30 + 1
end

local max_gamma = 1.1
local min_gamma = 0.9

local function gamma_to_slider(x)
	return (x - min_gamma) / (max_gamma - min_gamma)
end

local function slider_to_gamma(x)
	return x * (max_gamma - min_gamma) + min_gamma
end

local default_iap_full_game_id = iap_utils.FULL_GAME

function _env:init()
	gui.set_render_order(15)
	intl.translate_text_node(gui.get_node("back_button_label"))

	local version_node = gui.get_node("version")

	gui.set_text(version_node, "v" .. sys.get_config("project.full_version", sys.get_config("project.version", "0.0.0")))

	self.container = gui.get_node("container")
	self.fade = gui.get_node("fade")

	gui.set_layer(self.fade, "fade")

	self.focus_caret = gui.get_node("focus_caret")

	caret.hide_instantly(self.focus_caret)

	local controls = {}
	self.controls = controls
	self.focus_context = input_state:new_focus_context()
	self.focus_giver = FocusGiver.new({
		focus_context = self.focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if not nav_action or nav_action == Button.NAVIGATE_DOWN then
				for i = 1, #controls do
					local control = controls[i]

					if not control.disabled and control.focus() then
						return true
					end
				end

				return false
			elseif nav_action == Button.NAVIGATE_UP then
				for i = #controls, 1, -1 do
					local control = controls[i]

					if not control.disabled and control.focus() then
						return true
					end
				end

				return false
			end
		end
	})
	self.layout = Layout.new()

	self.layout:add_node(self.focus_caret, {
		grav_y = 1,
		grav_x = 0
	})
	self.layout:add_node(version_node, {
		grav_y = 0,
		grav_x = 1
	})

	self.back_button = Button.new(gui.get_node("back_button"), {
		action = function ()
			exit_settings(self)
		end,
		on_state_change = button_sound.with_sound(),
		shortcut_actions = {
			h_key_escape,
			h_gamepad_rpad_right
		}
	})
	self.back_key_prompt = KeyPrompt.new(gui.get_node("prompt_b"), {
		scale_factor = 1.4,
		halo = gui.get_node("prompt_b_halo"),
		action_id = h_gamepad_rpad_right
	})

	self.back_key_prompt:set_enabled(true)
	self.layout:add_node(self.back_button.node, {
		grav_y = 0,
		grav_x = 0
	})

	local label_prototype = gui.get_node("label")
	local slider_prototype = gui.get_node("slider")
	local picker_prototype = gui.get_node("picker")
	local button_prototype = gui.get_node("button")

	gui.set_enabled(label_prototype, false)
	gui.set_enabled(slider_prototype, false)
	gui.set_enabled(picker_prototype, false)
	gui.set_enabled(button_prototype, false)

	local function add_control(label_text, prototype, root_id)
		local tree = gui.clone_tree(prototype)
		local root_node = tree[root_id]

		gui.set_enabled(root_node, true)

		local label = gui.clone(label_prototype)

		gui.set_enabled(label, true)
		gui.set_text(label, label_text)

		local index = #controls + 1

		local function focus_up()
			for i = index - 1, 1, -1 do
				local control = controls[i]

				if not control.disabled and control.focus() then
					return true
				end
			end

			return false
		end

		local function focus_down()
			for i = index + 1, #controls do
				local control = controls[i]

				if not control.disabled and control.focus() then
					return true
				end
			end

			return false
		end

		local label_pos = gui.get_position(label_prototype)
		local root_pos = gui.get_position(prototype)
		local y = label_pos.y - control_spacing * (index - 1)
		label_pos.y = y
		root_pos.y = y

		gui.set_position(label, label_pos)
		gui.set_position(root_node, root_pos)
		self.layout:add_node(label, {
			grav_y = 1,
			grav_x = 0
		})
		self.layout:add_node(root_node, {
			grav_y = 1,
			grav_x = 1
		})

		return tree, index, focus_up, focus_down, label, root_node
	end

	local function add_slider(label_text, on_change)
		local tree, index, focus_up, focus_down, label, root_node = add_control(label_text, slider_prototype, h_slider)
		local slider = make_slider(self, {
			rail = tree[h_slider_rail],
			knob = tree[h_slider_knob],
			focus_up = focus_up,
			focus_down = focus_down,
			on_change = on_change
		})
		controls[index] = slider

		return slider, label, root_node
	end

	local function add_picker(label_text, choices, on_change)
		local tree, index, focus_up, focus_down, label, root_node = add_control(label_text, picker_prototype, h_picker)
		local picker = make_picker(self, {
			label = tree[h_picker_label],
			next = tree[h_picker_next],
			previous = tree[h_picker_previous],
			focus_up = focus_up,
			focus_down = focus_down,
			choices = choices,
			on_change = on_change
		})
		controls[index] = picker

		return picker, label, root_node
	end

	local function add_button(label_text, text, action)
		local tree, index, focus_up, focus_down, label, root_node = add_control(label_text, button_prototype, h_button)
		local picker = make_button(self, {
			label = tree[h_button_label],
			focus_up = focus_up,
			focus_down = focus_down,
			text = text,
			action = action
		})
		controls[index] = picker

		return picker, label, root_node
	end

	self.volume_slider = add_slider(intl("settings.audio_volume"), function (value)
		save_file.config_set("master_volume", volume_to_factor(value))
	end)
	self.music_picker = add_picker(intl("settings.music"), {
		{
			value = false,
			label = intl("common.muted")
		},
		{
			value = true,
			label = intl("common.on")
		}
	}, function (value)
		save_file.config_set("music_volume", value and 1 or 0)
	end)
	self.sfx_picker = add_picker(intl("settings.sfx"), {
		{
			value = false,
			label = intl("common.muted")
		},
		{
			value = true,
			label = intl("common.on")
		}
	}, function (value)
		save_file.config_set("sfx_volume", value and 1 or 0)
	end)
	self.gamma_slider = add_slider(intl("settings.gamma"), function (value)
		save_file.config_set("gamma", slider_to_gamma(value))
		dispatcher.dispatch(h_brightcon_setting_update)
	end)

	if defos then
		self.fullscreen_picker = add_picker(intl("settings.fullscreen"), {
			{
				value = false,
				label = intl("common.off")
			},
			{
				value = true,
				label = intl("common.on")
			}
		}, function (value)
			defos.set_fullscreen(value)
		end)
	end

	if sys_config.system_name ~= "iPhone OS" and sys_config.system_name ~= "Android" and sys_config.system_name ~= "Switch" then
		self.scaling_picker = add_picker(intl("settings.resolution_scaling"), {
			{
				value = 1,
				label = "1x"
			},
			{
				value = 0.75,
				label = "0.75x"
			},
			{
				value = 0.5,
				label = "0.5x"
			},
			{
				value = 0.25,
				label = "0.25x"
			}
		}, function (value)
			save_file.config_set("resolution_scale", value)
		end)
	end

	self.large_ui_override_picker = add_picker(intl("settings.large_ui"), {
		{
			value = false,
			label = intl("settings.large_ui.auto")
		},
		{
			value = large_ui.OVERRIDE_REGULAR,
			label = intl("settings.large_ui.regular")
		},
		{
			value = large_ui.OVERRIDE_LARGE,
			label = intl("settings.large_ui.large")
		}
	}, function (value)
		save_file.config_set("large_ui_override", value)
		msg.post("@render:", "recalculate_projection")
	end)

	if not twitch.unimplemented then
		self.twitch_picker = add_picker(intl("settings.twitch_voting"), {
			{
				value = false,
				label = intl("common.off")
			},
			{
				value = true,
				label = intl("common.on")
			}
		}, function (value)
			dispatcher.dispatch(value and h_twitch_login or h_twitch_stop)
		end)
	end

	local current_difficulty = difficulty_utils.get_difficulty_in_current_profile()
	local current_difficulty_label = intl("settings.difficulty." .. current_difficulty)

	if difficulty_utils.easier[current_difficulty] then
		self.difficulty_picker = add_picker(intl("settings.difficulty"), {
			{
				value = 1,
				label = current_difficulty_label
			},
			{
				value = 2,
				label = current_difficulty_label
			}
		}, function (value)
			dispatcher.dispatch(h_settings_confirm_difficulty_change)
		end)

		self.difficulty_picker.set_value(1)
	else
		add_button(intl("settings.difficulty"), current_difficulty_label, function ()
			return
		end)
	end

	if sys_config.system_name == "Switch" then
		self.change_grip = add_button(intl("settings.change_grip"), intl("settings.change_grip.button"), function ()
			dispatcher.dispatch(h_settings_change_grip)
		end)
	end

	if sys_config.system_name ~= "Switch" then
		self.software_licenses = add_button(intl("settings.software_licenses"), intl("settings.software_licenses.read"), read_licenses)
	end

	if iap_utils.has_iap_demo() then
		self.restore_purchases = add_button(intl("settings.restore_purchases"), intl("settings.restore_purchases.restore"), iap_utils.restore)
	end

	if not env.bundled or env.debug then
		if iap_utils.has_iap_demo() and sys_config.system_name == "Android" then
			self.iap_picker = add_picker("IAP static ID", {
				{
					label = "Disabled",
					value = default_iap_full_game_id
				},
				{
					value = "android.test.purchased",
					label = "Purchased"
				},
				{
					value = "android.test.canceled",
					label = "Canceled"
				},
				{
					value = "android.test.refunded",
					label = "Refunded"
				},
				{
					value = "android.test.item_unavailable",
					label = "Item unavailable"
				},
				{
					label = "Fake",
					value = iap_utils.FAKE_FULL_GAME
				}
			}, function (value)
				iap_utils.FULL_GAME = value
			end)

			self.iap_picker.set_value(iap_utils.FULL_GAME)
		end

		self.commentary_picker = add_picker("Developer commentary", {
			{
				value = false,
				label = "Off"
			},
			{
				value = true,
				label = "On"
			}
		}, function (value)
			save_file.config_set("commentary", value)
		end)
		self.idle_reset_picker = add_picker("Idle auto-reset", {
			{
				value = 0,
				label = "Off"
			},
			{
				value = 60,
				label = "1 min"
			},
			{
				value = 120,
				label = "2 min"
			},
			{
				value = 180,
				label = "3 min"
			},
			{
				value = 300,
				label = "5 min"
			},
			{
				value = 600,
				label = "10 min"
			}
		}, function (value)
			save_file.config_set("idle_reset", value)
		end)
		self.real_time_interrogation_picker = add_picker("Timed interrogations", {
			{
				value = true,
				label = "Real time"
			},
			{
				value = false,
				label = "Turn based"
			}
		}, function (value)
			save_file.config_set("real_time_interrogation", value)
		end)
	end

	msg.post(".", h_acquire_input_focus)

	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_switch_input_method,
		h_settings_exit
	})

	dispatcher.dispatch(h_settings_init)
	dispatcher.dispatch(h_settings_acquire_input_focus)
	gui.set_enabled(self.container, false)
	gui.set_color(self.fade, vmath.vector4(0, 0, 0, 0))
	gui.animate(self.fade, h_colorw, 1, gui.EASING_LINEAR, 0.5, 0, function ()
		gui.set_enabled(self.container, true)
		self.focus_giver:try_focus_first()
		gui.animate(self.fade, h_colorw, 0, gui.EASING_LINEAR, 0.5, 0, function ()
			gui.set_enabled(self.fade, false)
		end)
	end)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function on_focus_change(self, button, focused, no_anim)
	local focus_caret = self.focus_caret

	if focused then
		self.focused_button = button

		caret.move_to(focus_caret, nil, gui.get_position(gui.get_parent(button.node)).y, no_anim and 0)
	elseif self.focused_button == button then
		self.focused_button = nil

		caret.hide(focus_caret)
	end
end

function make_slider(self, options)
	local rail = options.rail
	local knob = options.knob
	local on_change = options.on_change
	local focus_context = self.focus_context
	local focus_up = options.focus_up
	local focus_down = options.focus_down
	local set_value = nil
	local scroll_controller = {
		content_height = 1,
		padding_bottom = 0,
		offset = 0,
		view_height = 0,
		add_offset_listener = function (sc_self, callback)
			function set_value(value)
				sc_self.offset = value

				callback()
			end
		end,
		set_offset = function (sc_self, offset)
			on_change(math.max(0, math.min(1, offset)))
		end,
		acquire_control = function ()
			return true
		end,
		release_control = function ()
			return
		end
	}
	local scrollbar = ScrollBar.new(scroll_controller, knob, {
		knob = true,
		axis = "x"
	})

	scrollbar:set_metrics(scrollbar.top, vmath.vector3(gui.get_size(rail).x, scrollbar.size.y, 0))

	scrollbar.focus_context = focus_context
	local focused = false
	local nudge = 0
	local slider_on_focus_change = button_sound.with_focus_sound(function (button, is_focused)
		on_focus_change(self, button, is_focused)
	end)

	local function focus()
		focus_context.something_is_focused = true
		focused = true
		nudge = 0

		slider_on_focus_change(scrollbar, true)

		return true
	end

	local function unfocus()
		focused = false

		slider_on_focus_change(scrollbar, false)
	end

	local function on_input(action_id, action)
		if focused then
			local nav_action = Button.action_id_to_navigation_action(action_id)

			if nav_action == Button.NAVIGATE_DOWN and (action.pressed or action.repeated) then
				local did_focus = focus_down()

				if did_focus then
					unfocus()
				end

				return did_focus
			elseif nav_action == Button.NAVIGATE_UP and (action.pressed or action.repeated) then
				local did_focus = focus_up()

				if did_focus then
					unfocus()
				end

				return did_focus
			elseif nav_action == Button.NAVIGATE_RIGHT then
				nudge = action.value

				return true
			elseif nav_action == Button.NAVIGATE_LEFT then
				nudge = -action.value

				return true
			end
		end

		if scrollbar:on_input(action_id, action) then
			return true
		end
	end

	local function update(dt)
		if focused then
			local delta = dt * nudge * 1.5

			if delta ~= 0 then
				local value = math.max(0, math.min(1, scroll_controller.offset + delta))

				on_change(value)
			end
		end
	end

	local function switch_input_method()
		if focused and input_state.input_method == input_state.INPUT_METHOD_MOUSE and focused then
			focus_context.something_is_focused = false
			focused = false

			unfocus()
		end
	end

	return {
		on_input = on_input,
		set_value = set_value,
		focus = focus,
		switch_input_method = switch_input_method,
		update = update
	}
end

function make_picker(self, options)
	local label = options.label
	local choices = options.choices
	local current_choice_index = 1
	local current_choice = choices[1]
	local on_change = options.on_change

	local function update_choice()
		gui.set_text(label, current_choice.label)
		gui.set_color(label, current_choice.color or vmath.vector4(1))
	end

	update_choice()

	local function next()
		current_choice_index = current_choice_index + 1

		if current_choice_index > #choices then
			current_choice_index = 1
		end

		current_choice = choices[current_choice_index]

		on_change(current_choice.value)
		update_choice()
	end

	local function previous()
		current_choice_index = current_choice_index - 1

		if current_choice_index < 1 then
			current_choice_index = #choices
		end

		current_choice = choices[current_choice_index]

		on_change(current_choice.value)
		update_choice()
	end

	local function set_value(value)
		if current_choice.value == value then
			return
		end

		for i, choice in ipairs(choices) do
			if choice.value == value then
				current_choice_index = i
				current_choice = choice

				update_choice()

				return
			end
		end

		current_choice_index = 0
		current_choice = {
			value = value,
			label = tostring(value)
		}

		update_choice()
	end

	local button = Button.new(label, {
		keyboard_focus = true,
		gamepad_focus = true,
		action = next,
		on_state_change = button_sound.with_sound(),
		focus_context = self.focus_context,
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_DOWN then
				return options.focus_down()
			elseif nav_action == Button.NAVIGATE_UP then
				return options.focus_up()
			elseif nav_action == Button.NAVIGATE_LEFT then
				previous()
				button_sound.press_event:create_instance():start()

				return false
			elseif nav_action == Button.NAVIGATE_RIGHT then
				next()
				button_sound.press_event:create_instance():start()

				return false
			end
		end,
		on_focus_change = button_sound.with_focus_sound(function (button, focused)
			on_focus_change(self, button, focused)
		end)
	})
	local next_button = Button.new(options.next, {
		action = next,
		on_state_change = button_sound.with_sound()
	})
	local previous_button = Button.new(options.previous, {
		action = previous,
		on_state_change = button_sound.with_sound()
	})

	local function on_input(action_id, action)
		if previous_button:on_input(action_id, action) then
			return true
		end

		if button:on_input(action_id, action) then
			return true
		end

		if next_button:on_input(action_id, action) then
			return true
		end
	end

	local function focus()
		return button:focus()
	end

	local function switch_input_method()
		previous_button:switch_input_method()
		button:switch_input_method()
		next_button:switch_input_method()
	end

	return {
		on_input = on_input,
		set_value = set_value,
		focus = focus,
		switch_input_method = switch_input_method
	}
end

function make_button(self, options)
	local label = options.label
	local text = options.text
	local on_action = options.action

	gui.set_text(label, text)

	local button = Button.new(label, {
		keyboard_focus = true,
		gamepad_focus = true,
		action = on_action,
		on_state_change = button_sound.with_sound(),
		focus_context = self.focus_context,
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_DOWN then
				return options.focus_down()
			elseif nav_action == Button.NAVIGATE_UP then
				return options.focus_up()
			end
		end,
		on_focus_change = button_sound.with_focus_sound(function (button, focused)
			on_focus_change(self, button, focused)
		end)
	})

	local function on_input(action_id, action)
		if button:on_input(action_id, action) then
			return true
		end
	end

	local function focus()
		return button:focus()
	end

	local function switch_input_method()
		button:switch_input_method()
	end

	return {
		on_input = on_input,
		focus = focus,
		switch_input_method = switch_input_method
	}
end

function exit_settings(self)
	self.exiting = true

	gui.set_enabled(self.fade, true)
	gui.cancel_animation(self.fade, h_colorw)
	gui.animate(self.fade, h_colorw, 1, gui.EASING_LINEAR, 0.5, 0, function ()
		gui.set_enabled(self.container, false)
		gui.animate(self.fade, h_colorw, 0, gui.EASING_LINEAR, 0.5, 0, function ()
			dispatcher.dispatch("settings_hide")
		end)
	end)
end

function _env:update(dt)
	self.volume_slider.update(dt)
	self.volume_slider.set_value(factor_to_volume(config.master_volume))
	self.gamma_slider.update(dt)
	self.gamma_slider.set_value(gamma_to_slider(config.gamma))
	self.music_picker.set_value(config.music_volume ~= 0)
	self.sfx_picker.set_value(config.sfx_volume ~= 0)

	if self.fullscreen_picker then
		self.fullscreen_picker.set_value(config.full_screen)
	end

	if self.scaling_picker then
		self.scaling_picker.set_value(config.resolution_scale)
	end

	if self.twitch_picker then
		self.twitch_picker.set_value(twitch.get_state() == twitch.STATE_READY)
	end

	if self.commentary_picker then
		self.commentary_picker.set_value(config.commentary)
	end

	if self.idle_reset_picker then
		self.idle_reset_picker.set_value(config.idle_reset)
	end

	if self.real_time_interrogation_picker then
		self.real_time_interrogation_picker.set_value(config.real_time_interrogation)
	end

	if self.large_ui_override_picker then
		self.large_ui_override_picker.set_value(config.large_ui_override)
	end
end

on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
	self.back_key_prompt:on_input(action_id, action)

	if self.exiting then
		return true
	end

	if self.back_button:on_input(action_id, action) then
		return true
	end

	for i, control in ipairs(self.controls) do
		if control.on_input(action_id, action) then
			return true
		end
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end

	return true
end)

function _env:on_message(message_id, message)
	if message_id == h_window_change_size then
		local size = vmath.vector3(Layout.viewport_width, Layout.viewport_height, 0)

		gui.set_size(self.container, size)
		gui.set_size(self.fade, size)
		self.layout:place()

		if self.focused_button then
			on_focus_change(self, self.focused_button, true, true)
		end
	elseif message_id == h_switch_input_method then
		for i, control in ipairs(self.controls) do
			control.switch_input_method()
		end

		self.back_key_prompt:switch_input_method()
		self.back_button:switch_input_method()
		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_settings_exit then
		exit_settings(self)
	end
end
