local custom_pick = {}
local h_size = hash("size")
local no_padding = {
	top = 0,
	bottom = 0,
	left = 0,
	right = 0
}

function custom_pick.pick_sprite(url, x, y, padding)
	local position = go.get_world_position(url)
	local scale = go.get_world_scale(url)
	local rotation = go.get_rotation(url)
	local size = go.get(url, h_size)
	x = x - position.x
	y = y - position.y
	local direction = vmath.rotate(rotation, vmath.vector3(1, 0, 0))
	local sin = -direction.y
	local cos = direction.x
	y = y * cos + x * sin
	x = x * cos - y * sin
	x = x / scale.x
	y = y / scale.y
	padding = padding or no_padding
	local half_width = size.x * 0.5
	local left = -half_width - padding.left
	local right = half_width + padding.right

	if x < left or right < x then
		return false
	end

	local half_height = size.y * 0.5
	local top = half_height + padding.top
	local bottom = -half_height - padding.bottom

	if y < bottom or top < y then
		return false
	end

	local intersect = {
		left = half_width - x,
		right = half_width + x,
		top = half_height + y,
		bottom = half_height - y
	}

	return true, intersect
end

return custom_pick
