local h_shadow = hash("shadow")
local shaky_text = {}

local function get_node_positions(nodes)
	local positions = {}

	for i, node in pairs(nodes) do
		positions[node] = gui.get_position(node)
	end

	return positions
end

local function random(batshit)
	return batshit and math.random(-4, 4) or math.random(-1, 1)
end

local function adjusted_position(position, batshit)
	return vmath.vector3(position.x + random(batshit), position.y + random(batshit), position.z)
end

function shaky_text.shake_nodes(nodes, batshit)
	local positions = get_node_positions(nodes)

	local function animation_callback()
		for i, node in ipairs(nodes) do
			gui.set_position(node, adjusted_position(positions[node], batshit))
		end

		if nodes[1] then
			gui.animate(nodes[1], h_shadow, vmath.vector3(), gui.EASING_LINEAR, 0.0001, 0, animation_callback)
		end
	end

	animation_callback()
end

return shaky_text
