local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local input_manager = require("campaign.wall.input_manager")
local env = require("lib.environment")
local h_sprite = hash("sprite")
local h_scale = hash("scale")
local h_wall = hash("wall")
local h_ = hash("")
local h_outer_glow = hash("outer_glow")
local h_shadow = hash("shadow")
local h_tooltip = hash("tooltip")
local h_pass_input = input_manager.h_pass_input
local h_size = hash("size")
local h_script = hash("script")
local h_object_id = hash("object_id")
local h_clickable_cancel_touch = hash("clickable_cancel_touch")
local h_wall_object_select = hash("wall_object_select")
local h_tooltip_update = hash("tooltip_update")
local h_virtual_cursor_action = hash("virtual_cursor_action")
local h_enable_debug_hitboxes = hash("enable_debug_hitboxes")
local h_debug_hitbox_set_properties = hash("debug_hitbox_set_properties")
local h_wall_object_state_change = hash("wall_object_state_change")
local outer_glow_default = vmath.vector4(1, 1, 1, 0)
local outer_glow_hover = vmath.vector4(1, 1, 1, 0.6)
local shadow_enabled = vmath.vector4(0, 0, 0, 0.5)
local shadow_disabled = vmath.vector4(0, 0, 0, 0)
local debug = env.debug or not env.bundled
local on_input_handler = nil

local function button_on_state_change(self, button, state)
	local scale_factor = 1
	local shadow = shadow_enabled
	local outer_glow = outer_glow_default

	if state == Button.STATE_HOVER then
		scale_factor = self.hover_scale
	elseif state == Button.STATE_PRESSED then
		scale_factor = self.pressed_scale
	elseif state == Button.STATE_DISABLED then
		scale_factor = self.selected_scale
	end

	if state == Button.STATE_HOVER or state == button.STATE_PRESSED then
		outer_glow = outer_glow_hover
		shadow = shadow_disabled
	end

	dispatcher.dispatch(h_wall_object_state_change, {
		object_type = self.object_type,
		is_polaroid = self.casefile_subject_name ~= h_,
		state = state
	})

	local this_go = self.this_go
	local this_sprite = msg.url(this_go.socket, this_go.path, h_sprite)
	local scale = self.original_scale

	go.cancel_animations(this_go, h_scale)

	local target_scale = vmath.vector3(scale.x * scale_factor, scale.y * scale_factor, scale.z)

	go.animate(this_go, h_scale, go.PLAYBACK_ONCE_FORWARD, target_scale, go.EASING_INOUTSINE, 0.2)

	if self.has_outer_glow then
		go.cancel_animations(this_sprite, h_outer_glow)
		go.cancel_animations(this_sprite, h_shadow)
		go.animate(this_sprite, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_LINEAR, 0.3)
		go.animate(this_sprite, h_shadow, go.PLAYBACK_ONCE_FORWARD, shadow, go.EASING_LINEAR, 0.3)
	end
end

local function init_hitbox_debugger(self)
	local hitbox_id = nil

	pcall(function ()
		local hitbox_debugger_factory = msg.url("hitbox_debugger#factory")
		hitbox_id = factory.create(hitbox_debugger_factory, vmath.vector3(), vmath.quat())
	end)

	if hitbox_id then
		local hitbox_url = msg.url(nil, hitbox_id, h_script)

		go.set(hitbox_url, h_object_id, self.tooltip_id)
		go.set_parent(hitbox_id, go.get_id(), false)

		local sprite_size = go.get(self.sprite, h_size)

		dispatcher.dispatch(h_debug_hitbox_set_properties, {
			object_id = self.tooltip_id,
			size = sprite_size,
			hitbox_padding = self.hitbox_padding
		})
	end
end

function _env:init()
	self.this_go = msg.url(".")
	self.sprite = msg.url(self.this_go.socket, self.this_go.path, h_sprite)
	self.original_scale = go.get(self.this_go, h_scale)
	self.sub_id = dispatcher.subscribe({
		h_clickable_cancel_touch,
		h_virtual_cursor_action,
		h_enable_debug_hitboxes
	})

	if self.has_outer_glow then
		go.set(self.sprite, h_shadow, shadow_enabled)
	end

	local padding = self.hitbox_padding
	self.button = Button.new(self.sprite, {
		is_sprite = true,
		keep_hover = true,
		on_state_change = Tooltip.button_on_state_change({
			keep_text = true,
			id = self.tooltip_id,
			type = h_wall,
			payload = function ()
				if self.tooltip_id == h_ then
					return Tooltip.DISCARD_TOOLTIP
				end
			end
		}, function (button, state)
			button_on_state_change(self, button, state)
		end),
		action = function ()
			if self.object_type ~= h_ and self.object_type ~= h_tooltip then
				dispatcher.dispatch(h_wall_object_select, {
					object_type = self.object_type,
					newspaper_index = self.newspaper_index,
					casefile_episode_index = self.casefile_episode_index,
					casefile_subject_name = self.casefile_subject_name,
					custom_object_id = self.custom_object_id
				})
			end
		end,
		padding_left = padding.x,
		padding_top = padding.y,
		padding_right = padding.z,
		padding_bottom = padding.w
	})

	if self.should_acquire_focus then
		input_manager.add_to_input_stack()
	end
end

function _env:final()
	self.button:cancel_touch()
	dispatcher.unsubscribe(self.sub_id)
	input_manager.remove_from_input_stack()
end

function _env:update(dt)
	local should_update_tooltip = self.tooltip_id ~= h_ and self.button.state == Button.STATE_HOVER

	if should_update_tooltip then
		local bounding_box = Tooltip.get_button_bounding_box(self.button)

		dispatcher.dispatch(h_tooltip_update, {
			id = self.tooltip_id,
			bounding_box = bounding_box
		})
	end
end

function on_input_handler(self, action_id, action)
	if self.button:on_input(action_id, action) then
		return
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_virtual_cursor_action then
		on_input_handler(self, message.action_id, message.action)
	elseif message_id == h_pass_input then
		if not on_input_handler(self, message.action_id, message.action) then
			input_manager.pass_input(message)
		end
	elseif message_id == h_clickable_cancel_touch then
		self.button:cancel_touch()
	elseif debug and message_id == h_enable_debug_hitboxes then
		init_hitbox_debugger(self)
	end
end
