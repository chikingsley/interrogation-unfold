local dispatcher = require("crit.dispatcher")
local render_helper = require("lib.render_helper")
local env = require("lib.environment")
local h_radius = hash("radius")
local h_tint = hash("tint")
local h_blur_enable = hash("blur_enable")
local h_blur_disable = hash("blur_disable")
local h_blur_refresh = hash("blur_refresh")
local enable_blur = nil

function _env:init()
	self.horiz_model = msg.url("#horiz")
	self.vert_model = msg.url("#vert")
	self.blur_enabled = false

	if self.enabled and self.starts_blurred then
		enable_blur(self, 0)
	end

	self.sub_id = dispatcher.subscribe({
		self.enable_message,
		self.disable_message,
		self.refresh_message
	})
end

function _env:final()
	local blur = render_helper.blur[self.blur_index]
	blur.enabled = false
	blur.cache = nil

	dispatcher.unsubscribe(self.sub_id)
end

local function blur_enabled(self)
	dispatcher.dispatch(self.enabled_message)
end

function enable_blur(self, blur_duration)
	self.blur_enabled = true
	local blur = render_helper.blur[self.blur_index]
	blur.enabled = true
	blur.cacheable = self.static_background
	blur.z_threshold = go.get_position().z
	blur.use_below_blur_predicate = self.use_below_blur_predicate

	if self.enable_will_refresh then
		blur.dirty = true
	end

	local horiz_model = self.horiz_model
	local vert_model = self.vert_model

	go.cancel_animations(horiz_model, h_radius)
	go.cancel_animations(vert_model, h_radius)

	local blur_radius = self.blur_radius
	local target_radius = vmath.vector4(blur_radius)
	local target_tint = self.tint

	if blur_duration == 0 then
		go.set(horiz_model, h_radius, target_radius)
		go.set(vert_model, h_radius, target_radius)
		go.set(vert_model, h_tint, target_tint)
		blur_enabled(self)
	else
		go.animate(horiz_model, h_radius, go.PLAYBACK_ONCE_FORWARD, target_radius, go.EASING_INOUTSINE, blur_duration)
		go.animate(vert_model, h_radius, go.PLAYBACK_ONCE_FORWARD, target_radius, go.EASING_INOUTSINE, blur_duration)
		go.animate(vert_model, h_tint, go.PLAYBACK_ONCE_FORWARD, target_tint, go.EASING_INOUTSINE, blur_duration, 0, blur_enabled)
	end
end

local function blur_disabled(self)
	self.blur_enabled = false
	local blur = render_helper.blur[self.blur_index]
	blur.enabled = false
	blur.cache = nil

	dispatcher.dispatch(self.disabled_message)
end

function _env:on_message(message_id, message, sender)
	if message_id == self.enable_message or message_id == h_blur_enable then
		if env.disable_blur or not self.enabled then
			return
		end

		if message.no_blur then
			return
		end

		enable_blur(self, message.blur_in_duration or self.blur_in_duration)
	elseif message_id == self.disable_message or message_id == h_blur_disable then
		if message.no_blur then
			return
		end

		if not self.blur_enabled then
			return
		end

		local horiz_model = self.horiz_model
		local vert_model = self.vert_model

		go.cancel_animations(horiz_model, h_radius)
		go.cancel_animations(vert_model, h_radius)

		local target_radius = vmath.vector4(0)
		local target_tint = vmath.vector4(1)
		local blur_duration = message.blur_out_duration or self.blur_out_duration

		if blur_duration == 0 then
			go.set(horiz_model, h_radius, target_radius)
			go.set(vert_model, h_radius, target_radius)
			go.set(vert_model, h_tint, target_tint)
			blur_disabled(self)
		else
			go.animate(horiz_model, h_radius, go.PLAYBACK_ONCE_FORWARD, target_radius, go.EASING_LINEAR, blur_duration)
			go.animate(vert_model, h_radius, go.PLAYBACK_ONCE_FORWARD, target_radius, go.EASING_LINEAR, blur_duration)
			go.animate(vert_model, h_tint, go.PLAYBACK_ONCE_FORWARD, target_tint, go.EASING_LINEAR, blur_duration, 0, blur_disabled)
		end
	elseif message_id == self.refresh_message or message_id == h_blur_refresh then
		local blur = render_helper.blur[self.blur_index]

		if blur.enabled and blur.cacheable then
			blur.dirty = true
		end
	end
end
