local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local KeyPrompt = require("lib.key_prompt")
local LongPress = require("lib.long_press")
local Tooltip = require("lib.tooltip")
local button_sound = require("sound.button")
local intl = require("crit.intl")
local Layout = require("crit.layout")
local h_switch_input_method = hash("switch_input_method")
local h_perks_display_continue = hash("perks_display_continue")
local h_perks_enable_continue = hash("perks_enable_continue")
local h_perks_disable_continue = hash("perks_disable_continue")
local h_end_scene = hash("end_scene")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_perks_continue = hash("perks_continue")
local h_window_change_size = hash("window_change_size")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")

function _env:init()
	self.this_go = msg.url("nav_button")
	local button_sprite = msg.url("nav_button#sprite")
	local button_label = msg.url("nav_button#label")
	local prompt_y = msg.url("prompt_y#prompt")
	local prompt_y_halo = msg.url("prompt_y#prompt_halo")

	intl.translate_label(button_label, "common.continue")

	self.enabled = false
	self.tooltip_button = Button.new(button_sprite, {
		is_sprite = true,
		hover_from_external_touch = true,
		on_state_change = Tooltip.button_on_state_change({
			id = h_perks_continue,
			type = h_perks_continue,
			payload = function ()
				return self.enabled
			end,
			position = Tooltip.POSITION_LEFT
		}, false)
	})
	self.button = Button.new(button_sprite, {
		is_sprite = true,
		faded_labels = {
			button_label
		},
		shortcut_actions = {
			h_gamepad_rpad_up
		},
		on_state_change = button_sound.with_sound(),
		action = function ()
			dispatcher.dispatch(h_end_scene)
		end
	})
	self.key_prompt = KeyPrompt.new(prompt_y, {
		is_sprite = true,
		enabled = false,
		halo = prompt_y_halo
	})
	self.long_press = LongPress.new(prompt_y, {
		is_sprite = true,
		gamepad_action_id = h_gamepad_rpad_up,
		button = self.button
	})

	self.button:set_enabled(false)
	msg.post(self.this_go, h_disable)

	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(button_sprite, {
		grav_y = 0.05,
		grav_x = 0.5
	})

	self.sub_id = dispatcher.subscribe({
		h_switch_input_method,
		h_perks_enable_continue,
		h_perks_disable_continue,
		h_perks_display_continue,
		h_window_change_size
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:update(dt)
	self.long_press:update()
end

function _env:on_message(message_id, message, sender)
	if message_id == h_perks_display_continue then
		msg.post(self.this_go, h_enable)
		msg.post(".", "acquire_input_focus")
	elseif message_id == h_perks_enable_continue then
		self.enabled = true

		self.button:set_enabled(true)
		self.key_prompt:set_enabled(true)
	elseif message_id == h_perks_disable_continue then
		self.enabled = false

		self.button:set_enabled(false)
		self.key_prompt:set_enabled(false)
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
		self.tooltip_button:switch_input_method()
		self.button:switch_input_method()
	elseif message_id == h_window_change_size then
		self.layout:place()
	end
end

function _env:on_input(action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.long_press:on_input(action_id, action) then
		return false
	end

	if self.tooltip_button:on_input(action_id, action) then
		return true
	end

	if self.button:on_input(action_id, action) then
		return true
	end
end

function _env:update()
	self.long_press:update()
end
