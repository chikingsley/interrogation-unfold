local dispatcher = require("crit.dispatcher")
local h_position = hash("position")
local h_rotation = hash("rotation")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local camera_shake, plus_minus_random = nil

function _env:init()
	self.camera_go = msg.url(".")
	self.camera = msg.url("#camera")

	msg.post(self.camera, "acquire_camera_focus")

	self.animation_pos_finished = true
	self.animation_rot_finished = true
	self.sub_id = dispatcher.subscribe({
		h_spine_cutscene_event
	})
end

function _env:final()
	msg.post(self.camera, "release_camera_focus")
	dispatcher.unsubscribe(self.sub_id)
end

function _env:update(dt)
	camera_shake(self, dt)
end

function plus_minus_random(val)
	return (math.random() - 0.5) * 2 * val
end

function camera_shake(self, dt)
	if self.animation_pos_finished then
		self.animation_pos_finished = false
		local pos_x = plus_minus_random(self.position_max_offset)
		local pos_y = plus_minus_random(self.position_max_offset)
		local position = vmath.vector3(pos_x, pos_y, 0)
		local duration = math.random() * self.position_timing.y + self.position_timing.x

		go.cancel_animations(self.camera_go, h_position)
		go.animate(self.camera_go, h_position, go.PLAYBACK_ONCE_FORWARD, position, go.EASING_INOUTBACK, duration, 0, function ()
			self.animation_pos_finished = true
		end)
	elseif self.animation_rot_finished then
		self.animation_rot_finished = false
		local rotation = vmath.quat_rotation_z(math.pi / 180 * plus_minus_random(self.rotation_max_offset))
		local duration = math.random() * self.rotation_timing.y + self.rotation_timing.x

		go.cancel_animations(self.camera_go, h_rotation)
		go.animate(self.camera_go, h_rotation, go.PLAYBACK_ONCE_FORWARD, rotation, go.EASING_INOUTQUART, duration, 0, function ()
			self.animation_rot_finished = true
		end)
	end
end
