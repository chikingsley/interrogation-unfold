local Button = require("crit.button")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local large_ui = require("lib.large_ui")
local KeyPrompt = require("lib.key_prompt")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_tintw = hash("tint.w")
local h_office_object_zoom = hash("office_object_zoom")
local h_office_object_set_zoom = hash("office_object_set_zoom")
local h_switch_input_method = hash("switch_input_method")
local h_window_change_size = hash("window_change_size")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_key_z = hash("key_z")
local on_state_change = nil

function _env:init()
	self.close_sprite = msg.url("#sprite")
	self.close_label = msg.url("#label")
	self.close_go = msg.url(".")
	self.button = Button.new(self.close_sprite, {
		is_sprite = true,
		disabled_opacity = 0,
		faded_nodes = {
			self.close_label
		},
		shortcut_actions = {
			h_gamepad_rpad_up,
			h_key_z
		},
		on_state_change = button_sound.with_sound({
			release = false,
			press = false
		}, function (button, state)
			on_state_change(self, button, state)
		end),
		action = function ()
			dispatcher.dispatch(h_office_object_zoom, {
				object_id = self.object_id
			})
		end
	})

	self.button:set_enabled(false)
	msg.post(self.close_sprite, h_disable)
	msg.post(self.close_label, h_disable)

	self.prompt_sprite = msg.url("#prompt")
	self.prompt_halo = msg.url("#prompt_halo")
	self.key_prompt = KeyPrompt.new(self.prompt_sprite, {
		is_sprite = true,
		halo = self.prompt_halo,
		action_id = h_gamepad_rpad_up
	})

	self.key_prompt:set_enabled(false)
	msg.post(self.prompt_sprite, h_disable)
	msg.post(self.prompt_halo, h_disable)

	self.enabled = false
	self.zoomed = false
	self.selected = false
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_selected,
		h_office_object_deselect,
		h_switch_input_method,
		h_window_change_size,
		h_office_object_set_zoom
	})

	self.button:switch_input_method()
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function on_state_change(self, button, state)
	Button.default_on_state_change(button, state)

	local was_disabled = button.state == Button.STATE_DISABLED
	local is_disabled = state == Button.STATE_DISABLED

	if was_disabled == is_disabled then
		return
	end

	if was_disabled then
		msg.post(self.close_sprite, h_enable)
		msg.post(self.close_label, h_enable)
		msg.post(self.prompt_sprite, h_enable)
		msg.post(self.prompt_halo, h_enable)
	end

	local target_opacity = is_disabled and 0 or 1

	go.cancel_animations(self.close_sprite, h_tintw)
	go.cancel_animations(self.close_label, h_tintw)
	go.animate(self.close_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, target_opacity, go.EASING_LINEAR, 0.3)
	go.animate(self.close_label, h_tintw, go.PLAYBACK_ONCE_FORWARD, target_opacity, go.EASING_LINEAR, 0.3, 0, function ()
		if is_disabled then
			msg.post(self.close_sprite, h_disable)
			msg.post(self.close_label, h_disable)
			msg.post(self.prompt_sprite, h_disable)
			msg.post(self.prompt_halo, h_disable)
		end
	end)
end

local function update_button(self)
	local enabled = self.selected and (large_ui.enabled or self.zoomed)

	if self.enabled == enabled then
		return
	end

	self.enabled = enabled

	self.button:set_enabled(enabled)
	self.key_prompt:set_enabled(enabled)
	msg.post(self.close_go, enabled and h_acquire_input_focus or h_release_input_focus)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_selected then
		if message.object_id == self.object_id then
			self.selected = true

			update_button(self)
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == self.object_id then
			self.selected = false
			self.zoomed = false

			update_button(self)
		end
	elseif message_id == h_office_object_set_zoom then
		if message.object_id == self.object_id then
			self.zoomed = message.value

			update_button(self)
		end
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
		self.button:switch_input_method()
	elseif message_id == h_window_change_size then
		update_button(self)
	end
end

function _env:on_input(action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.button:on_input(action_id, action) then
		return true
	end
end
