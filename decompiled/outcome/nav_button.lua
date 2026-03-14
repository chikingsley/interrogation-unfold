local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")
local h_sprite = hash("sprite")
local h_label = hash("label")
local h_tint = hash("tint")
local h_tintw = hash("tint.w")
local h_color = hash("color")
local h_colorw = hash("color.w")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_show_button = hash("show_button")

local function button_set_enabled(self, enabled)
	self.button_enabled = enabled

	self.button:set_enabled(enabled)
	self.key_prompt:set_enabled(enabled)
end

local function show_button(self, delay, show)
	if show then
		msg.post(self.button_node, h_enable)
		go.cancel_animations(self.button_node_sprite, h_tintw)
		go.cancel_animations(self.button_node_label, h_colorw)
		go.animate(self.button_node_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.7, delay, function ()
			button_set_enabled(self, true)

			self.button.faded_nodes = {
				self.button_node_sprite
			}
			self.button.faded_labels = {
				self.button_node_label
			}
		end)
		go.animate(self.button_node_label, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.7, delay)
	else
		self.button.faded_nodes = {}
		self.button.faded_labels = {}

		button_set_enabled(self, false)
		go.cancel_animations(self.button_node_sprite, h_tintw)
		go.cancel_animations(self.button_node_label, h_colorw)
		go.animate(self.button_node_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.7, delay, function ()
			msg.post(self.button_node, h_disable)
		end)
		go.animate(self.button_node_label, h_colorw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.7, delay)
	end
end

function _env:init()
	self.button_node = msg.url()
	self.button_node_sprite = msg.url(self.button_node.socket, self.button_node.path, h_sprite)
	self.button_node_label = msg.url(self.button_node.socket, self.button_node.path, h_label)

	intl.translate_label(self.button_node_label)

	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(self.button_node)

	self.button = Button.new(self.button_node_sprite, {
		keyboard_focus = true,
		is_sprite = true,
		gamepad_focus = true,
		shortcut_actions = {
			h_gamepad_rpad_up
		},
		faded_labels = {},
		faded_nodes = {},
		on_state_change = button_sound.with_sound(),
		action = function ()
			dispatcher.dispatch(self.action_message)
		end
	})
	self.key_prompt = KeyPrompt.new(msg.url("#prompt"), {
		is_sprite = true,
		action_id = h_gamepad_rpad_up,
		halo = msg.url("#prompt_halo")
	})

	button_set_enabled(self, false)
	msg.post(self.button_node, h_disable)
	go.set(self.button_node_sprite, h_tint, vmath.vector4(1, 1, 1, 0))
	go.set(self.button_node_label, h_color, vmath.vector4(1, 1, 1, 0))

	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_switch_input_method,
		h_outcome_enable_transcript,
		h_outcome_disable_transcript
	})

	msg.post(".", "acquire_input_focus")

	if self.show_auto then
		self.is_active = true

		show_button(self, self.delay, true)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
		self.button:switch_input_method()
	elseif message_id == h_show_button then
		self.is_active = true

		show_button(self, self.delay, true)
	elseif message_id == h_outcome_enable_transcript then
		if self.is_active then
			button_set_enabled(self, false)
			show_button(self, 0, false)
		end
	elseif message_id == h_outcome_disable_transcript and self.is_active then
		button_set_enabled(self, true)
		show_button(self, 0, true)
	end
end

function _env:on_input(action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.button_enabled and self.button:on_input(action_id, action) then
		return true
	end
end
