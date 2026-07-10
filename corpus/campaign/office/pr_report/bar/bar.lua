local h_bars_set = hash("bars_set")
local h_bars_expo_reset = hash("bars_expo_reset")
local h_bars_expo_animate = hash("bars_expo_animate")
local h_constants = hash("constants")
local h_center = hash("center")
local h_tint = hash("tint")
local update_center = nil

function _env:init()
	self.sprite = msg.url("#graphic")

	sprite.set_constant(self.sprite, h_tint, vmath.vector4(0, 0, 0, 0.874))
	update_center(self)
end

function update_center(self)
	local sprite_url = self.sprite
	local pos = go.get_world_position(sprite_url)
	local pos4 = vmath.vector4(pos.x, pos.y, pos.z, 0)

	sprite.set_constant(sprite_url, h_center, pos4)
end

update = update_center

function _env:on_message(message_id, message, sender)
	if message_id == h_bars_set then
		local current = message.current * 0.01
		local previous = message.previous * 0.01
		local solid, full, direction = nil

		if current < previous then
			direction = -1
			full = previous
			solid = current
		else
			direction = 1
			full = current
			solid = previous
		end

		self.direction = direction
		self.full = full
		self.solid = solid

		sprite.set_constant(self.sprite, h_constants, vmath.vector4(solid, full, direction, 0))
	elseif message_id == h_bars_expo_reset then
		local direction = self.direction
		local value = direction > 0 and self.solid or self.full

		sprite.set_constant(self.sprite, h_constants, vmath.vector4(value, value, direction, 0))
	elseif message_id == h_bars_expo_animate then
		local value = vmath.vector4(self.solid, self.full, self.direction, 0)

		go.animate(self.sprite, h_constants, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTEXPO, message.duration, message.delay)
	end
end
