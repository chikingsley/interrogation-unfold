local Button = require("crit.button")
local LongPress = {
	__index = {}
}
local h_fill_angle = hash("fill_angle")
local h_colorw = hash("color.w")
local h_tintw = hash("tint.w")
local h_scale = hash("scale")
local h_pie_x = hash("pie.x")
local h_pie = hash("pie")
local h_center = hash("center")
local inner_radius = 0.8
local initial_scale = vmath.vector3(0.9)
local initial_scale_duration = 0.2
local outward_scale = vmath.vector3(1.5)
local outward_scale_duration = 0.5
local auto_reset_duration = 0.3
local auto_reset_delay = 0.5
local LongPress_cancel = nil

function LongPress.new(node, opts)
	opts = opts or {}
	local self = {
		enabled = true,
		started = false,
		node = node,
		button = opts.button,
		hold_duration = opts.hold_duration or 0.5,
		action = opts.action,
		gamepad_action_id = opts.gamepad_action_id,
		is_sprite = opts.is_sprite or false,
		is_instant = opts.is_instant or false,
		auto_reset = opts.auto_reset or false,
		on_state_change = opts.on_state_change
	}

	setmetatable(self, LongPress)

	return self
end

function LongPress.__index:set_enabled(enabled)
	self.enabled = enabled

	if not enabled and self.started then
		LongPress_cancel(self)
	end
end

function LongPress.__index:set_auto_reset(auto_reset)
	self.auto_reset = auto_reset
end

local function LongPress__simulate_button_on_state_change(self, state, old_state, did_click)
	local button = self.button

	if button then
		button:cancel_touch()
		button:on_state_change(state, old_state, did_click)
	end

	local on_state_change = self.on_state_change

	if on_state_change then
		on_state_change(self, state, old_state, did_click)
	end
end

local function LongPress_trigger_action(self)
	if self.action then
		self:action()
	elseif self.button then
		local did_click = true

		LongPress__simulate_button_on_state_change(self, Button.STATE_DEFAULT, Button.STATE_PRESSED, did_click)
		self.button:action()
	end

	self.action_triggered = true

	if self.auto_reset then
		self.auto_reset_timer = timer.delay(auto_reset_delay, false, function ()
			self.auto_reset_timer = nil

			self:reset(true)
		end)
	end
end

local function LongPress_gui_start(self)
	local node = self.node

	gui.set_fill_angle(node, 0)
	gui.set_inner_radius(node, inner_radius * gui.get_size(node).x * 0.5)
	gui.cancel_animation(node, h_fill_angle)
	gui.animate(node, h_scale, initial_scale, gui.EASING_INOUTBOUNCE, initial_scale_duration)
	gui.animate(node, h_fill_angle, 360, gui.EASING_LINEAR, self.hold_duration, 0, function ()
		gui.animate(node, h_colorw, 0, gui.EASING_LINEAR, outward_scale_duration)
		gui.animate(node, h_scale, outward_scale, gui.EASING_LINEAR, outward_scale_duration)
		LongPress_trigger_action(self)
	end)
end

local function LongPress_gui_cancel(self)
	local node = self.node

	LongPress__simulate_button_on_state_change(self, Button.STATE_DEFAULT, Button.STATE_PRESSED)
	gui.animate(node, h_scale, vmath.vector3(1), gui.EASING_OUTBACK, 0.3)
	gui.set_fill_angle(node, 360)
	gui.set_inner_radius(node, 0)
	gui.cancel_animation(node, h_fill_angle)
end

local function LongPress_sprite_start(self)
	local node = self.node

	go.cancel_animations(node, h_pie_x)
	go.cancel_animations(node, h_scale)
	sprite.set_constant(node, h_pie, vmath.vector4(0, inner_radius, 1, 0))

	local forward = go.PLAYBACK_ONCE_FORWARD

	go.animate(node, h_scale, forward, initial_scale, go.EASING_INOUTBOUNCE, initial_scale_duration)
	go.animate(node, h_pie_x, forward, math.pi * 2, go.EASING_LINEAR, self.hold_duration, 0, function ()
		go.animate(node, h_tintw, forward, 0, go.EASING_LINEAR, outward_scale_duration)
		go.animate(node, h_scale, forward, outward_scale, go.EASING_LINEAR, outward_scale_duration)
		LongPress_trigger_action(self)
	end)
end

local function LongPress_sprite_cancel(self)
	local node = self.node

	LongPress__simulate_button_on_state_change(self, Button.STATE_DEFAULT, Button.STATE_PRESSED)
	go.cancel_animations(node, h_pie_x)
	go.cancel_animations(node, h_scale)
	go.animate(node, h_scale, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(1), gui.EASING_OUTBACK, 0.3)
	sprite.set_constant(node, h_pie, vmath.vector4(math.pi * 2, 0, 1, 0))
end

local function LongPress_start(self)
	if self.started then
		LongPress_cancel(self)
	end

	self.started = true

	LongPress__simulate_button_on_state_change(self, Button.STATE_PRESSED, Button.STATE_DEFAULT)

	if self.is_sprite then
		LongPress_sprite_start(self)
	else
		LongPress_gui_start(self)
	end
end

function LongPress_cancel(self)
	if not self.started then
		return
	end

	self.started = false

	LongPress__simulate_button_on_state_change(self, Button.STATE_DEFAULT, Button.STATE_PRESSED)

	if self.is_sprite then
		LongPress_sprite_cancel(self)
	else
		LongPress_gui_cancel(self)
	end
end

function LongPress.__index:set_instant(instant)
	self.is_instant = instant
end

function LongPress.__index:on_input(action_id, action)
	if self.enabled and not self.action_triggered and action_id == self.gamepad_action_id then
		if action.pressed then
			if self.is_instant and self.action then
				self:action()
			end

			LongPress_start(self)

			return true
		elseif action.released then
			LongPress_cancel(self)

			return true
		end
	end
end

function LongPress.__index:reset(animated)
	self.action_triggered = false

	if self.auto_reset_timer then
		timer.cancel(self.auto_reset_timer)

		self.auto_reset_timer = nil
	end

	local node = self.node

	if self.is_sprite then
		go.cancel_animations(node, h_pie_x)
		go.cancel_animations(node, h_scale)
		go.cancel_animations(node, h_tintw)
		sprite.set_constant(node, h_pie, vmath.vector4(math.pi * 2, 0, 1, 0))
		go.set(node, h_scale, vmath.vector3(1))

		if animated then
			go.animate(node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, auto_reset_duration)
		else
			go.set(node, h_tintw, 1)
		end
	else
		gui.cancel_animation(node, h_scale)
		gui.cancel_animation(node, h_fill_angle)
		gui.cancel_animation(node, h_colorw)
		gui.set_scale(node, vmath.vector3(1))
		gui.set_fill_angle(node, 360)
		gui.set_inner_radius(node, 0)

		if animated then
			gui.animate(node, h_colorw, 1, gui.EASING_LINEAR, auto_reset_duration)
		else
			gui.set_color(node, vmath.vector3(1, 1, 1, 1))
		end
	end
end

function LongPress.__index:update()
	if self.is_sprite then
		local node = self.node
		local pos = go.get_world_position(node)

		sprite.set_constant(node, h_center, vmath.vector4(pos.x, pos.y, pos.z, 0))
	end
end

return LongPress
