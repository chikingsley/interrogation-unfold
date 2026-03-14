local render_helper = require("lib.render_helper")
local dispatcher = require("crit.dispatcher")
local render_settings = require("main.render.settings")
local h_scene_transition_start = hash("scene_transition_start")
local h_scene_transition_midpoint_continue = hash("scene_transition_midpoint_continue")
local h_camera_zoom = hash("camera_zoom")
local h_zoom = hash("zoom")

function _env:init()
	self.this_url = msg.url("#")
	self.initial_camera_zoom = self.camera_zoom
	self.sub_id = dispatcher.subscribe({
		h_scene_transition_start,
		h_scene_transition_midpoint_continue
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:update(dt)
	local camera_zoom = self.camera_zoom

	if camera_zoom == 1 then
		render_helper.camera_transform = nil
	else
		local scale_matrix = vmath.matrix4()
		scale_matrix.m00 = camera_zoom
		scale_matrix.m11 = camera_zoom
		render_helper.camera_transform = scale_matrix
	end
end

local function on_animation_done(self)
	self.midpoint_zoom = self.initial_camera_zoom * self.zoom_factor
	self.camera_zoom = self.initial_camera_zoom
end

function _env:on_message(message_id, message, sender)
	if message_id == h_scene_transition_start then
		go.cancel_animations(self.this_url, h_camera_zoom)

		if message.transition == h_zoom then
			local duration = message.in_duration or self.zoom_in_duration
			local final_zoom = self.initial_camera_zoom * ((message.no_in_zoom or not render_settings.current.transition_end_zoom) and 1 or self.zoom_factor)

			go.animate(self.this_url, h_camera_zoom, go.PLAYBACK_ONCE_FORWARD, final_zoom, go.EASING_INEXPO, duration, 0, on_animation_done)
		else
			self.camera_zoom = self.initial_camera_zoom
		end
	elseif message_id == h_scene_transition_midpoint_continue and message.transition == h_zoom then
		go.cancel_animations(self.this_url, h_camera_zoom)

		local duration = message.out_duration or self.zoom_out_duration

		if self.midpoint_zoom then
			self.camera_zoom = self.midpoint_zoom
			self.midpoint_zoom = nil
		end

		if message.no_out_zoom then
			self.camera_zoom = self.initial_camera_zoom
		else
			go.animate(self.this_url, h_camera_zoom, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_OUTEXPO, duration)
		end
	end
end
