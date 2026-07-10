local Layout = require("crit.layout")
local Button = require("crit.button")
local FocusGiver = require("crit.focus_giver")
local caret = require("lib.caret")
local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local sys_config = require("lib.sys_config")
local env = require("lib.environment")
local button_sound = require("sound.button")
local save_file = require("lib.save_file")
local intl = require("crit.intl")
local iap_utils = require("lib.iap_utils")
local h_window_change_size = hash("window_change_size")
local h_run_progression = hash("run_progression")
local h_colorw = hash("color.w")
local h_debug_misc_key = hash("debug_misc_key")
local h_position = hash("position")
local h_scene_transition_start = hash("scene_transition_start")
local h_switch_input_method = hash("switch_input_method")
local h_menu_show_rewind_list = hash("menu_show_rewind_list")
local h_menu_show_profile_list = hash("menu_show_profile_list")
local h_menu_change_grip = hash("menu_change_grip")
local h_iap_bought_full_game = hash("iap_bought_full_game")
local h_iap_transaction_update = hash("iap_transaction_update")
local button_show_delay = 0.15
local button_show_duration = 0.5
local button_show_initial_delay = 1
local button_show_x_offset = 50

if MenuDebug_buttons_enabled == nil then
	MenuDebug_buttons_enabled = not env.expo
end

local function run_progression(self, id, options)
	dispatcher.dispatch(h_run_progression, {
		id = id,
		options = options
	})

	self.buttons = {}
end

local function on_focus_change(self, button, focused, no_anim)
	local focus_caret = self.focus_caret

	if focused then
		self.focused_button = button

		caret.move_to(focus_caret, nil, gui.get_position(button.node).y, no_anim and 0)
	elseif self.focused_button == button then
		self.focused_button = nil

		caret.hide(focus_caret)
	end
end

function _env:init()
	gui.set_render_order(1)

	self.bank = sound_util.load_bank("Menu.bank")
	self.music_tag = "menu_music"

	sound_util.set_music("event:/Menu Music", self.bank, {
		tag = self.music_tag
	})

	self.focus_caret = gui.get_node("focus_caret")

	caret.hide_instantly(self.focus_caret)

	self.focus_giver = FocusGiver.new({
		on_pass_focus = function (focus_giver, nav_action)
			local buttons = self.buttons

			if next(buttons) then
				if not nav_action or nav_action == Button.NAVIGATE_DOWN then
					for i = 1, #buttons do
						if buttons[i]:focus() then
							return true
						end
					end

					return false
				elseif nav_action == Button.NAVIGATE_UP then
					for i = #buttons, 1, -1 do
						if buttons[i]:focus() then
							return true
						end
					end

					return false
				end
			end
		end
	})

	local function go_to(scene, options)
		return function ()
			run_progression(self, scene, options)
		end
	end

	local profile_data = save_file.get_current_profile().get()
	local is_new_game = not profile_data.history.latest
	local button_defs = {}
	local debug_button_defs = {}
	local char_test_button_defs = {}

	if iap_utils.is_demo() then
		table.insert(button_defs, {
			intl("menu.buy_full_game"),
			function (button)
				if iap_utils.buy_full_game_or_direct_to_store() then
					button:set_enabled(false)
				end
			end
		})

		self.iap_button_index = #button_defs
	end

	table.insert(button_defs, {
		is_new_game and intl("menu.new_game") or intl("menu.continue"),
		go_to("campaign")
	})

	if not is_new_game then
		table.insert(button_defs, {
			intl("menu.rewind"),
			function ()
				dispatcher.dispatch(h_menu_show_rewind_list)
			end
		})
	end

	table.insert(button_defs, {
		intl("menu.change_save_profile"),
		function ()
			dispatcher.dispatch(h_menu_show_profile_list)
		end
	})

	if not env.bundled or env.debug then
		table.insert(debug_button_defs, {
			"episode1.json",
			go_to("single_level", "episode1")
		})
		table.insert(debug_button_defs, {
			"episode2.json",
			go_to("single_level", "episode2")
		})
		table.insert(debug_button_defs, {
			"episode3.json",
			go_to("single_level", "episode3")
		})
		table.insert(debug_button_defs, {
			"episode4.json",
			go_to("single_level", "episode4")
		})
		table.insert(debug_button_defs, {
			"episode5.json",
			go_to("single_level", "episode5")
		})
		table.insert(debug_button_defs, {
			"episode6.json",
			go_to("single_level", "episode6")
		})
		table.insert(debug_button_defs, {
			"episode7.json",
			go_to("single_level", "episode7")
		})
		table.insert(debug_button_defs, {
			"Episode 8",
			go_to("test_episode8")
		})
		table.insert(debug_button_defs, {
			"episode9.json",
			go_to("single_level", "episode9")
		})
		table.insert(debug_button_defs, {
			"episode10.json",
			go_to("single_level", "episode10")
		})
		table.insert(debug_button_defs, {
			"Test Campaign",
			go_to("test_campaign", {
				no_expo = true
			})
		})
		table.insert(debug_button_defs, {
			"Test Perks",
			go_to("test_perks")
		})
		table.insert(debug_button_defs, {
			"Test Interludes",
			go_to("test_interludes")
		})
		table.insert(debug_button_defs, {
			"Test Press Release",
			go_to("test_press_release")
		})
		table.insert(debug_button_defs, {
			"Test Cutscene 1",
			go_to("test_cutscene1")
		})
		table.insert(debug_button_defs, {
			"Test Cutscene 2",
			go_to("test_cutscene2")
		})
		table.insert(debug_button_defs, {
			"Test Cutscene Intro",
			go_to("test_cutscene3")
		})
		table.insert(debug_button_defs, {
			"Test Puzzle",
			go_to("test_jigsaw", {
				jigsaw_id = "test_painting"
			})
		})
		table.insert(debug_button_defs, {
			"Open debug hub",
			function ()
				dispatcher.dispatch("debug_hub_toggle")
			end
		})
		table.insert(char_test_button_defs, {
			"Test Actor",
			go_to("single_level", "test_actor")
		})
		table.insert(char_test_button_defs, {
			"Test Peterson",
			go_to("single_level", "test_peterson")
		})
		table.insert(char_test_button_defs, {
			"Test Jerry",
			go_to("single_level", "test_jerry")
		})
		table.insert(char_test_button_defs, {
			"Test Diana",
			go_to("single_level", "test_diana")
		})
		table.insert(char_test_button_defs, {
			"Test Fred",
			go_to("single_level", "test_fred")
		})
		table.insert(char_test_button_defs, {
			"Test Michael",
			go_to("single_level", "test_michael")
		})
		table.insert(char_test_button_defs, {
			"Test Bakil",
			go_to("single_level", "test_bakil")
		})
		table.insert(char_test_button_defs, {
			"Test Samantha",
			go_to("single_level", "test_samantha")
		})
		table.insert(char_test_button_defs, {
			"Test Maya",
			go_to("single_level", "test_maya")
		})
		table.insert(char_test_button_defs, {
			"Test Adams",
			go_to("single_level", "test_adams")
		})
		table.insert(char_test_button_defs, {
			"Test Lucas",
			go_to("single_level", "test_lucas")
		})
		table.insert(char_test_button_defs, {
			"Test Silvia",
			go_to("single_level", "test_silvia")
		})
		table.insert(char_test_button_defs, {
			"Test Helene",
			go_to("single_level", "test_helene")
		})
		table.insert(char_test_button_defs, {
			"Test Lynda",
			go_to("single_level", "test_lynda")
		})
		table.insert(char_test_button_defs, {
			"Test Anton",
			go_to("single_level", "test_anton")
		})
		table.insert(char_test_button_defs, {
			"Test Aaron",
			go_to("single_level", "test_aaron")
		})
		table.insert(char_test_button_defs, {
			"Test Valerie",
			go_to("single_level", "test_valerie")
		})
		table.insert(char_test_button_defs, {
			"Test Reed",
			go_to("single_level", "test_reed")
		})
		table.insert(char_test_button_defs, {
			"Test Dennis",
			go_to("single_level", "test_dennis")
		})
		table.insert(char_test_button_defs, {
			"Test Anaba",
			go_to("single_level", "test_anaba")
		})
		table.insert(char_test_button_defs, {
			"Test Reed",
			go_to("single_level", "test_reed")
		})
		table.insert(char_test_button_defs, {
			"Test Amatis",
			go_to("single_level", "test_amatis")
		})
		table.insert(char_test_button_defs, {
			"Test Alex",
			go_to("single_level", "test_alex")
		})
		table.insert(char_test_button_defs, {
			"Test Reed",
			go_to("single_level", "test_reed")
		})
		table.insert(char_test_button_defs, {
			"Test Steve",
			go_to("single_level", "test_steve")
		})
		table.insert(char_test_button_defs, {
			"Test James",
			go_to("single_level", "test_james")
		})
		table.insert(char_test_button_defs, {
			"Test Tab",
			go_to("single_level", "test_tab")
		})
		table.insert(char_test_button_defs, {
			"Test Elias",
			go_to("test_elias")
		})
	end

	table.insert(button_defs, {
		intl("menu.settings"),
		function ()
			dispatcher.dispatch("settings_show")
		end
	})

	if sys_config.system_name == "Switch" then
		table.insert(button_defs, {
			intl("settings.change_grip"),
			function ()
				dispatcher.dispatch(h_menu_change_grip)
			end
		})
	end

	if not sys_config.is_mobile and sys_config.system_name ~= "HTML5" then
		table.insert(button_defs, {
			intl("menu.quit"),
			function ()
				msg.post("@system:", "exit", {
					code = 0
				})
			end
		})
	end

	local buttons = {}
	local debug_buttons = {}
	local char_test_buttons = {}
	self.buttons = buttons
	self.debug_buttons = debug_buttons
	self.char_test_buttons = char_test_buttons
	self.layout = Layout.new()

	self.layout:add_node(self.focus_caret, {
		grav_y = 0,
		scale_by = "y",
		grav_x = 0
	})

	local button_count = #button_defs
	local button_prototype = gui.get_node("button")
	local button_scale = gui.get_scale(button_prototype).x
	local button_size = gui.get_size(button_prototype) * button_scale
	local button_position = gui.get_position(button_prototype)
	local empty_opts = {}

	for i = button_count, 1, -1 do
		local button_def = button_defs[i]
		local opts = button_def[3] or empty_opts
		local button_node = gui.clone(button_prototype)

		gui.set_text(button_node, button_def[1])

		if opts.large then
			button_position.y = button_position.y + button_size.y * 0.25
		end

		gui.set_position(button_node, button_position)

		button_position.y = button_position.y + button_size.y

		if opts.large then
			button_position.y = button_position.y + button_size.y * 0.25

			gui.set_scale(button_node, vmath.vector3(button_scale * 1.5, button_scale * 1.5, 1))
		end

		local button = Button.new(button_node, {
			keyboard_focus = true,
			gamepad_focus = true,
			action = button_def[2],
			on_state_change = button_sound.with_sound(),
			on_pass_focus = function (button, nav_action)
				if next(buttons) then
					if nav_action == Button.NAVIGATE_UP and i > 1 then
						for j = i - 1, 1, -1 do
							if buttons[j]:focus() then
								return true
							end
						end

						return false
					elseif nav_action == Button.NAVIGATE_DOWN and i < #buttons then
						for j = i + 1, #buttons do
							if buttons[j]:focus() then
								return true
							end
						end

						return false
					end
				end
			end,
			on_focus_change = button_sound.with_focus_sound(function (button, focused)
				on_focus_change(self, button, focused)
			end)
		})

		self.layout:add_node(button_node, {
			grav_y = 0,
			scale_by = "y",
			grav_x = 0
		})

		buttons[i] = button
	end

	gui.delete_node(button_prototype)

	local debug_button_count = #debug_button_defs
	button_prototype = gui.get_node("debug_button")
	button_size = gui.get_size(button_prototype) * gui.get_scale(button_prototype).x
	button_position = gui.get_position(button_prototype)

	for i, button_def in ipairs(debug_button_defs) do
		local button_node = gui.clone(button_prototype)

		gui.set_position(button_node, button_position + vmath.vector3(0, (debug_button_count - i) * button_size.y, 0))
		gui.set_text(button_node, button_def[1])

		local button = Button.new(button_node, {
			action = button_def[2],
			on_state_change = button_sound.with_sound()
		})

		self.layout:add_node(button_node, {
			grav_y = 0,
			scale_by = "y",
			grav_x = 1
		})
		gui.set_enabled(button_node, MenuDebug_buttons_enabled)

		debug_buttons[i] = button
	end

	gui.delete_node(button_prototype)

	local char_test_button_count = #char_test_button_defs
	button_prototype = gui.get_node("char_test_button")
	button_size = gui.get_size(button_prototype) * gui.get_scale(button_prototype).x
	button_position = gui.get_position(button_prototype)

	for i, button_def in ipairs(char_test_button_defs) do
		local button_node = gui.clone(button_prototype)

		gui.set_position(button_node, button_position + vmath.vector3(0, (char_test_button_count - i) * button_size.y, 0))
		gui.set_text(button_node, button_def[1])

		local button = Button.new(button_node, {
			action = button_def[2],
			on_state_change = button_sound.with_sound()
		})

		self.layout:add_node(button_node, {
			grav_y = 0,
			scale_by = "y",
			grav_x = 1
		})
		gui.set_enabled(button_node, MenuDebug_buttons_enabled)

		char_test_buttons[i] = button
	end

	gui.delete_node(button_prototype)

	for i, button in ipairs(buttons) do
		button:set_enabled(false)
		gui.cancel_animation(button.node, h_colorw)
		gui.set_color(button.node, vmath.vector4(1, 1, 1, 0))
	end

	timer.delay(button_show_initial_delay, false, function ()
		local offset = button_show_x_offset * Layout.viewport_height / Layout.design_height

		for i, button in ipairs(buttons) do
			local button_node = button.node
			local delay = button_show_delay * (i - 1)
			local position = gui.get_position(button_node)

			gui.set_position(button_node, position + vmath.vector3(offset, 0, 0))
			gui.animate(button_node, h_position, position, gui.EASING_OUTQUART, button_show_duration, delay)
			gui.animate(button_node, h_colorw, 1, gui.EASING_LINEAR, button_show_duration, delay, function ()
				button:set_enabled(true)

				if i == 1 then
					self.focus_giver:try_focus_first()
				end
			end)
		end
	end)
	msg.post(".", "acquire_input_focus")

	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_debug_misc_key,
		h_scene_transition_start,
		h_switch_input_method,
		h_iap_bought_full_game,
		h_iap_transaction_update
	})
	local fade = gui.get_node("fade")
	local fade_duration = 2

	self.layout:add_node(fade, {
		resize_y = true,
		resize_x = true
	})
	gui.animate(fade, h_colorw, 0, gui.EASING_LINEAR, fade_duration, 0, function ()
		gui.set_enabled(fade, false)
	end)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		for i, button in ipairs(self.buttons) do
			gui.cancel_animation(button.node, h_position)
		end

		self.layout:place()

		if self.focused_button then
			on_focus_change(self, self.focused_button, true, true)
		end
	elseif message_id == h_switch_input_method then
		for i, button in ipairs(self.buttons) do
			button:switch_input_method()
		end

		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_debug_misc_key then
		MenuDebug_buttons_enabled = not MenuDebug_buttons_enabled

		for i, button in ipairs(self.debug_buttons) do
			gui.set_enabled(button.node, MenuDebug_buttons_enabled)
		end

		for i, button in ipairs(self.char_test_buttons) do
			gui.set_enabled(button.node, MenuDebug_buttons_enabled)
		end
	elseif message_id == h_scene_transition_start then
		if sound_util.music_tag == self.music_tag then
			sound_util.set_music(nil)
		end
	elseif message_id == h_iap_transaction_update then
		if message.id == iap_utils.FULL_GAME then
			local index = self.iap_button_index

			if not index then
				return
			end

			local button = self.buttons[index]

			button:set_enabled(message.state ~= "purchasing")
		end
	elseif message_id == h_iap_bought_full_game then
		local index = self.iap_button_index

		if not index then
			return
		end

		self.iap_button_index = nil
		local button = self.buttons[index]

		table.remove(self.buttons, index)

		local node = button.node
		local scale = gui.get_scale(node)

		gui.animate(node, "scale.x", scale.x * 1.2, gui.EASING_OUTCIRC, 0.5, 0, function ()
			gui.delete_node(node)
		end)
		gui.animate(node, "scale.y", scale.y * 1.2, gui.EASING_OUTCIRC, 0.5)
		gui.animate(node, "color.w", 0, gui.EASING_LINEAR, 0.5)
	end
end

function _env:on_input(action_id, action)
	for i, button in ipairs(self.buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end

	if MenuDebug_buttons_enabled then
		for i, button in ipairs(self.debug_buttons) do
			if button:on_input(action_id, action) then
				return true
			end
		end

		for i, button in ipairs(self.char_test_buttons) do
			if button:on_input(action_id, action) then
				return true
			end
		end
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end
end
