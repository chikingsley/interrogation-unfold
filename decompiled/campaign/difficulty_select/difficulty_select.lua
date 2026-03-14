local Layout = require("crit.layout")
local Button = require("crit.button")
local FocusGiver = require("crit.focus_giver")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local intl = require("crit.intl")
local difficulty_utils = require("main.settings.difficulty_utils")
local h_window_change_size = hash("window_change_size")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_switch_input_method = hash("switch_input_method")
local h_end_scene = hash("end_scene")

function _env:init()
	intl.translate_text_node(gui.get_node("challenge_button_label"))
	intl.translate_text_node(gui.get_node("challenge_tagline"))
	intl.translate_text_node(gui.get_node("challenge_description"))
	intl.translate_text_node(gui.get_node("narrative_button_label"))
	intl.translate_text_node(gui.get_node("narrative_tagline"))
	intl.translate_text_node(gui.get_node("narrative_description"))
	intl.translate_text_node(gui.get_node("vn_button_label"))
	intl.translate_text_node(gui.get_node("vn_tagline"))
	intl.translate_text_node(gui.get_node("vn_description"))

	self.challenge_button = Button.new(gui.get_node("challenge_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("challenge_button"),
			gui.get_node("challenge_button_label")
		},
		action = function ()
			difficulty_utils.set_difficulty("challenge")
			dispatcher.dispatch(h_end_scene)
		end,
		focus_node = gui.get_node("challenge_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_LEFT then
				return self.narrative_button:focus()
			end
		end
	})
	self.narrative_button = Button.new(gui.get_node("narrative_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("narrative_button"),
			gui.get_node("narrative_button_label")
		},
		action = function ()
			difficulty_utils.set_difficulty("narrative")
			dispatcher.dispatch(h_end_scene)
		end,
		focus_node = gui.get_node("narrative_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_RIGHT then
				return self.challenge_button:focus()
			elseif nav_action == Button.NAVIGATE_LEFT then
				return self.vn_button:focus()
			end
		end
	})
	self.vn_button = Button.new(gui.get_node("vn_button"), {
		keyboard_focus = true,
		gamepad_focus = true,
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		on_focus_change = button_sound.with_focus_sound(),
		faded_nodes = {
			gui.get_node("vn_button"),
			gui.get_node("vn_button_label")
		},
		action = function ()
			difficulty_utils.set_difficulty("vn")
			dispatcher.dispatch(h_end_scene)
		end,
		focus_node = gui.get_node("vn_button_glow"),
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_RIGHT then
				return self.narrative_button:focus()
			end
		end
	})
	self.focus_giver = FocusGiver.new({
		on_pass_focus = function (focus_giver, nav_action)
			if nav_action == Button.NAVIGATE_RIGHT then
				return self.vn_button:focus()
			elseif nav_action == Button.NAVIGATE_LEFT then
				return self.challenge_button:focus()
			end

			return self.narrative_button:focus()
		end
	})
	self.layout = Layout.new()

	self.layout:add_node(gui.get_node("container"), {
		grav_y = 0.5,
		grav_x = 0.5
	})
	msg.post(".", h_acquire_input_focus)
	self.focus_giver:try_focus_first()

	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	self.challenge_button:cancel_focus()
	self.narrative_button:cancel_focus()
	self.vn_button:cancel_focus()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.challenge_button:switch_input_method()
		self.narrative_button:switch_input_method()
		self.vn_button:switch_input_method()
		self.focus_giver:try_focus_first(message.nav_action)
	end
end

function _env:on_input(action_id, action)
	if self.challenge_button:on_input(action_id, action) then
		return true
	end

	if self.narrative_button:on_input(action_id, action) then
		return true
	end

	if self.vn_button:on_input(action_id, action) then
		return true
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end
end
