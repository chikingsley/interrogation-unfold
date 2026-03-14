local M = {}
local h_size = hash("size")
local no_padding = {
	top = 0,
	bottom = 0,
	left = 0,
	right = 0
}

function M.pick_sprite(url, x, y, padding)
	local transform = go.get_world_transform(url)
	local pos = vmath.inv(transform) * vmath.vector4(x, y, 0, 1)
	y = pos.y
	x = pos.x
	local size = go.get(url, h_size)
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

	return true
end

return M
