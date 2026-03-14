local Button = require("crit.button")
local NAVIGATE_DOWN = Button.NAVIGATE_DOWN
local NAVIGATE_UP = Button.NAVIGATE_UP
local NAVIGATE_RIGHT = Button.NAVIGATE_RIGHT

local function distance_in_direction(from, to, nav_action)
	from = from or nav_action == NAVIGATE_DOWN and vmath.vector3(0, 100000, 0) or nav_action == NAVIGATE_UP and vmath.vector3(0, -100000, 0) or nav_action == NAVIGATE_RIGHT and vmath.vector3(-100000, 0, 0) or vmath.vector3(100000, 0, 0)
	local diff = to - from
	local x, y = nil

	if nav_action == Button.NAVIGATE_DOWN then
		y = diff.x
		x = -diff.y
	elseif nav_action == Button.NAVIGATE_UP then
		y = diff.x
		x = diff.y
	elseif nav_action == Button.NAVIGATE_RIGHT then
		y = diff.y
		x = diff.x
	else
		y = diff.y
		x = -diff.x
	end

	local len = math.sqrt(x * x + y * y)

	return len * len / x
end

local function get_item_in_direction(position, nav_action, items, position_getter, excluded_item)
	local min_positive_distance = math.huge
	local min_positive_distance_item = nil
	local min_distance = math.huge
	local min_distance_item = nil

	for i, item in ipairs(items) do
		if item ~= excluded_item then
			local to_position = position_getter(item)

			if to_position then
				local distance = distance_in_direction(position, to_position, nav_action)

				if distance < min_distance then
					min_distance = distance
					min_distance_item = item
				end

				if distance > 0 and distance < min_positive_distance then
					min_positive_distance = distance
					min_positive_distance_item = item
				end
			end
		end
	end

	return min_positive_distance_item, min_distance_item
end

return {
	distance_in_direction = distance_in_direction,
	get_item_in_direction = get_item_in_direction
}
