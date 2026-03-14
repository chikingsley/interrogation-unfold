local h_key_left = hash("key_left")
local h_key_right = hash("key_right")
local h_position = hash("position")
local h_rotation = hash("rotation")

function _env:init()
	msg.post(".", "acquire_input_focus")

	self.moving_right = false
	self.moving_left = false
	self.background = msg.url(".")
	self.rain = msg.url("rain")
	self.indicator = msg.url("indicator")

	msg.post(self.indicator, hash("disable"))

	self.speed_x = 0
end

function _env:final()
	return
end

function _env:update(dt)
	local current_pos = go.get(self.background, h_position)

	if self.moving_right then
		self.speed_x = self.speed_x - dt * 50
	elseif self.moving_left then
		self.speed_x = self.speed_x + dt * 50
	elseif self.speed_x < 2 then
		self.speed_x = self.speed_x + dt * 100
	elseif self.speed_x > 2 then
		self.speed_x = self.speed_x - dt * 100
	else
		self.speed_x = 0
	end

	local rotation = vmath.quat_rotation_z(self.speed_x / 100 - math.pi / 5 + math.pi / 10 * math.random())

	go.set(self.background, h_position, vmath.vector3(current_pos.x + self.speed_x, current_pos.y, current_pos.z))
	go.set(self.rain, h_rotation, rotation)
end

function _env:on_message(message_id, message, sender)
	return
end

function _env:on_input(action_id, action)
	if action_id == h_key_left then
		if action.pressed then
			self.moving_left = true
		elseif action.released then
			self.moving_left = false
		end
	elseif action_id == h_key_right then
		if action.pressed then
			self.moving_right = true
		elseif action.released then
			self.moving_right = false
		end
	end
end
