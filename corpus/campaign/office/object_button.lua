local Button = require("crit.button")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local sound_util = require("sound.util")
local object_focus_map = require("campaign.office.object_focus_map")
local object_focus_context = require("campaign.office.object_focus_context")
local office = require("campaign.office")
local h_office_object_select = hash("office_object_select")
local h_office_object_select_attempt = hash("office_object_select_attempt")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_object_deselected = hash("office_object_deselected")
local h_office_object_acquire_focus = hash("office_object_acquire_focus")
local h_switch_input_method = hash("switch_input_method")
local h_office_object_focus = hash("office_object_focus")
local h_office_object_on_hover_sound = hash("office_object_on_hover_sound")
local h_scale = hash("scale")
local h_outer_glow = hash("outer_glow")
local h_shadow = hash("shadow")
local h_contrast = hash("contrast")
local outer_glow_default = vmath.vector4(1, 1, 1, 0)
local outer_glow_hover = vmath.vector4(1, 1, 1, 0.6)
local shadow_enabled = vmath.vector4(0, 0, 0, 0.5)
local shadow_disabled = vmath.vector4(0, 0, 0, 0)
local object_contrast = vmath.vector4(1, 0, 0, 0)
local STATE_HOVER = Button.STATE_HOVER
local STATE_PRESSED = Button.STATE_PRESSED
local STATE_DISABLED = Button.STATE_DISABLED

local function focus_object(self, nav_action)
	local next_focused_object = self.focus_map[self.object_id][nav_action]

	if next_focused_object then
		dispatcher.dispatch(h_office_object_focus, {
			object_id = next_focused_object
		})

		return true
	end

	return false
end

local function fade_out_outer_glow_on_select(self, is_selected)
	local sprite_url = self.sprite_url

	if is_selected then
		go.cancel_animations(sprite_url, h_outer_glow)
		go.cancel_animations(sprite_url, h_shadow)
		go.animate(sprite_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow_default, go.EASING_LINEAR, 0.3)
		go.animate(sprite_url, h_shadow, go.PLAYBACK_ONCE_FORWARD, shadow_disabled, go.EASING_LINEAR, 0.3)
	else
		go.cancel_animations(sprite_url, h_shadow)
		go.animate(sprite_url, h_shadow, go.PLAYBACK_ONCE_FORWARD, shadow_enabled, go.EASING_LINEAR, 0.3)
	end
end

local function object_on_hover(self, state, is_selected)
	if not is_selected then
		local scale_factor = 1
		local shadow = shadow_enabled
		local outer_glow = outer_glow_default
		local scale_duration = 0.2

		if state == STATE_HOVER then
			scale_factor = self.hover_scale
		elseif state == STATE_PRESSED then
			scale_factor = self.pressed_scale
		elseif state == STATE_DISABLED and self.is_selected then
			scale_factor = self.selected_scale
		end

		if state == STATE_HOVER or state == STATE_PRESSED then
			outer_glow = outer_glow_hover
			shadow = shadow_disabled
			scale_duration = 0.3
			local old_state = self.button.state

			if old_state ~= STATE_HOVER and old_state ~= STATE_PRESSED then
				dispatcher.dispatch(h_office_object_on_hover_sound, {
					object_id = self.object_id
				})
			end
		end

		local this_go = self.this_go
		local scale = self.original_scale
		local sprite_url = self.sprite_url
		local target_scale = vmath.vector3(scale.x * scale_factor, scale.y * scale_factor, scale.z)

		go.cancel_animations(this_go, h_scale)
		go.cancel_animations(sprite_url, h_outer_glow)
		go.cancel_animations(sprite_url, h_shadow)
		go.animate(this_go, h_scale, go.PLAYBACK_ONCE_FORWARD, target_scale, go.EASING_LINEAR, scale_duration)
		go.animate(sprite_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_LINEAR, 0.3)
		go.animate(sprite_url, h_shadow, go.PLAYBACK_ONCE_FORWARD, shadow, go.EASING_LINEAR, 0.3)
	end
end

function _env:init()
	local this_go = msg.url(".")
	self.this_go = this_go
	self.original_scale = go.get_scale(this_go)
	self.is_selected = false
	self.bank = sound_util.load_bank("All Campaign.bank")
	local padding = self.hitbox_padding
	local sprite_url = self.sprite_url

	go.set(sprite_url, h_shadow, shadow_enabled)
	go.set(sprite_url, h_contrast, object_contrast)

	self.focus_map = object_focus_map[office.focus_map]
	self.button = Button.new(sprite_url, {
		focus_simulates_hover = true,
		is_sprite = true,
		gamepad_focus = true,
		keyboard_focus = true,
		focus_context = object_focus_context,
		on_state_change = button_sound.with_sound({
			release = false,
			press = false,
			hover = false
		}, function (button, state)
			object_on_hover(self, state, self.is_selected)
		end),
		action = function ()
			local message = self.select_attempt and h_office_object_select_attempt or h_office_object_select

			dispatcher.dispatch(message, {
				object_id = self.object_id
			})
		end,
		on_pass_focus = function (button, nav_action)
			return focus_object(self, nav_action)
		end,
		padding_left = padding.x,
		padding_top = padding.y,
		padding_right = padding.z,
		padding_bottom = padding.w
	})
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect,
		h_office_object_deselected,
		h_switch_input_method,
		h_office_object_focus
	})

	if self.should_acquire_focus then
		dispatcher.dispatch(h_office_object_acquire_focus, {
			z = go.get_position().z
		})
	end
end

function _env:final()
	if self.button.focused then
		self.button:cancel_focus()
	end

	dispatcher.unsubscribe(self.sub_id)
	sound_util:release_bank(self.bank)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		self.something_is_selected = true

		if message.object_id == self.object_id then
			self.is_selected = true
			self.expo = not not message.expo

			fade_out_outer_glow_on_select(self, true)
		end

		self.button:set_enabled(false)
	elseif message_id == h_office_object_deselect then
		self.something_is_selected = false

		self.button:set_enabled(true)

		if self.is_selected and (not self.expo or self.keep_focus_on_expo) then
			self.button:focus()
		end

		if message.object_id == self.object_id then
			fade_out_outer_glow_on_select(self, false)
		end
	elseif message_id == h_office_object_deselected then
		self.is_selected = false

		if self.button.focused then
			object_on_hover(self, Button.STATE_HOVER, self.is_selected)
		end
	elseif message_id == h_switch_input_method then
		if self.button.focused then
			self.button:switch_input_method()
		end

		if self.button.state == Button.STATE_HOVER then
			self.button:cancel_touch()
		end
	elseif message_id == h_office_object_focus and message.object_id == self.object_id then
		self.button:focus()
	end
end

function _env:on_input(action_id, action)
	if not self.something_is_selected and self.button:on_input(action_id, action) then
		return true
	end
end
