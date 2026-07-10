local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local Tooltip = require("lib.tooltip")
local store = require("level.store")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")
local h_sprite = hash("sprite")
local h_tint = hash("tint")
local h_tintw = hash("tint.w")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_gamepad_rpad_left = hash("gamepad_rpad_left")
local h_show_button = hash("show_button")
local h_outcome_transcript = hash("outcome_transcript")
local h_position = hash("position")
local h_position_x = hash("position.x")

local function button_set_enabled(self, enabled)
	self.button_enabled = enabled

	self.button:set_enabled(enabled)
	self.key_prompt:set_enabled(enabled)
end

local function show_button(self, delay, show)
	if show then
		msg.post(self.button_node, h_enable)
		go.cancel_animations(self.button_node_sprite, h_tintw)
		go.animate(self.button_node_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.7, delay, function ()
			button_set_enabled(self, true)

			self.button.faded_nodes = {
				self.button_node_sprite
			}
		end)
	else
		self.button.faded_nodes = {}

		button_set_enabled(self, false)
		go.cancel_animations(self.button_node_sprite, h_tintw)
		go.animate(self.button_node_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.7, delay, function ()
			msg.post(self.button_node, h_disable)
		end)
	end
end

local function move_to_edge(self, move_forward)
	local position = move_forward and self.edge_position_x or self.original_position.x

	go.cancel_animations(self.button_node, h_position_x)
	go.animate(self.button_node, h_position_x, go.PLAYBACK_ONCE_FORWARD, position, go.EASING_INOUTCIRC, 0.3, 0, function ()
		self.layout:add_node(self.button_node)
	end)
end

function _env:init()
	if not next(store.history) then
		go.delete(".", true)

		return
	end

	self.transcript_enabled = false
	self.button_node = msg.url(".")
	self.button_node_sprite = msg.url(self.button_node.socket, self.button_node.path, h_sprite)
	self.original_position = go.get(self.button_node, h_position)
	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(self.button_node)

	self.button = Button.new(self.button_node_sprite, {
		keyboard_focus = true,
		is_sprite = true,
		gamepad_focus = true,
		shortcut_actions = {
			h_gamepad_rpad_left
		},
		faded_labels = {},
		faded_nodes = {},
		on_state_change = button_sound.with_sound(Tooltip.button_on_state_change({
			id = "outcome_transcript",
			type = h_outcome_transcript,
			position = Tooltip.POSITION_LEFT
		})),
		action = function ()
			if not self.transcript_enabled then
				dispatcher.dispatch(h_outcome_enable_transcript)
			else
				dispatcher.dispatch(h_outcome_disable_transcript)
			end
		end
	})
	self.key_prompt = KeyPrompt.new(msg.url("#prompt"), {
		is_sprite = true,
		action_id = h_gamepad_rpad_left,
		halo = msg.url("#prompt_halo")
	})

	self.button:set_enabled(false)
	self.key_prompt:set_enabled(false)

	self.button_enabled = false

	msg.post(self.button_node, h_disable)
	go.set(self.button_node_sprite, h_tint, vmath.vector4(1, 1, 1, 0))

	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_switch_input_method,
		h_outcome_enable_transcript,
		h_outcome_disable_transcript
	})

	msg.post(".", "acquire_input_focus")

	if self.show_auto then
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
		show_button(self, self.delay, true)
	elseif message_id == h_outcome_enable_transcript then
		self.transcript_enabled = true

		move_to_edge(self, true)
	elseif message_id == h_outcome_disable_transcript then
		self.transcript_enabled = false

		move_to_edge(self, false)
	end
end

function _env:on_input(action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.button_enabled and self.button:on_input(action_id, action) then
		return true
	end
end
