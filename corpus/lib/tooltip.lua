local Button = require("crit.button")
local Layout = require("crit.layout")
local Bubble = require("lib.bubble")
local dispatcher = require("crit.dispatcher")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_size = hash("size")
local STATE_HOVER = Button.STATE_HOVER
local STATE_PRESSED = Button.STATE_PRESSED
local DISCARD_TOOLTIP = {}
local Tooltip = {
	POSITION_BOTTOM = 3,
	POSITION_LEFT = 2,
	POSITION_TOP = 4,
	POSITION_RIGHT = 1,
	__index = {},
	DISCARD_TOOLTIP = DISCARD_TOOLTIP
}

local function vmul(a, b)
	return vmath.vector3(a.x * b.x, a.y * b.y, a.z * b.z)
end

function Tooltip.new(container_id, text_id, bubble_options)
	local self = {
		container_id = hash(container_id),
		text_id = hash(text_id),
		bubble_options = bubble_options,
		instances = {}
	}
	local container_node = gui.get_node(self.container_id)
	self.container_node = container_node

	gui.set_enabled(container_node, false)

	self.original_scale = gui.get_scale(container_node)

	setmetatable(self, Tooltip)

	return self
end

local function Tooltip__get_position(bounding_box, tooltip_size, desired_position, padding)
	local pad = (padding or 20) * Layout.viewport_width / Layout.design_width
	local total_offset = (bounding_box.size + tooltip_size) * 0.5 + vmath.vector3(pad, pad, 0)
	local offset_attempts = {
		vmath.vector3(total_offset.x, 0, 0),
		vmath.vector3(-total_offset.x, 0, 0),
		vmath.vector3(0, -total_offset.y, 0),
		vmath.vector3(0, total_offset.y, 0)
	}

	if desired_position then
		offset_attempts = {
			offset_attempts[desired_position]
		}
	end

	local center = bounding_box.center
	local half_size_with_padding = tooltip_size * 0.5 + vmath.vector3(pad, pad, 0)

	for i, offset in ipairs(offset_attempts) do
		local position = center + offset
		local top_right = position + half_size_with_padding
		local bottom_left = position - half_size_with_padding

		if top_right.x <= Layout.viewport_width and top_right.y <= Layout.viewport_height and bottom_left.x >= 0 and bottom_left.y >= 0 then
			return position
		end
	end

	return center + offset_attempts[1]
end

function Tooltip.__index:show_tooltip(message, text, is_rich)
	local instance = self.instances[message.id]

	if instance then
		if message.keep_text then
			instance:display_bubble(Bubble.KEEP_TEXT)
		else
			instance:display_bubble(text, is_rich)
		end

		return
	end

	local cloned_tree = gui.clone_tree(self.container_node)
	local container_node = cloned_tree[self.container_id]
	local text_node = cloned_tree[self.text_id]
	local scale = self.original_scale * Layout.viewport_width / Layout.design_width

	gui.set_scale(container_node, scale)

	instance = Bubble.new(container_node, text_node, self.bubble_options)

	instance:hide_bubble(0)

	self.instances[message.id] = instance

	gui.set_enabled(container_node, true)
	instance:display_bubble(text, is_rich, 0.1)

	local tooltip_size = instance.original_container_scale * (instance.animating_container_size or instance.container_size)
	local position = Tooltip__get_position(message.bounding_box, tooltip_size, message.position, message.padding)

	if message.fixed_x_pos then
		local position_x = message.fixed_x_pos * Layout.viewport_width / Layout.design_width
		position = vmath.vector3(position_x, position.y, position.z)
	end

	if message.fixed_y_pos then
		local position_y = message.fixed_y_pos * Layout.viewport_height / Layout.design_height
		position = vmath.vector3(position.x, position_y, position.z)
	end

	gui.set_position(container_node, position)
end

function Tooltip.__index:hide_tooltip(message)
	local id = message.id
	local instance = self.instances[id]

	if not instance then
		return
	end

	instance:hide_bubble(0.1, function ()
		gui.delete_node(instance.container_node)

		self.instances[id] = nil
	end)
end

function Tooltip.__index:hide_all()
	for id, instance in pairs(self.instances) do
		self:hide_tooltip({
			id = id
		})
	end
end

function Tooltip.get_sprite_bounding_box(sprite, padding)
	local position = go.get_world_position(sprite)
	local scale = go.get_world_scale(sprite)
	local size = go.get(sprite, h_size)

	if padding then
		size = size + vmath.vector3(padding.right + padding.left, padding.bottom + padding.top, 0)
		position = position + vmul(vmath.vector3((padding.right - padding.left) * 0.5, (padding.top - padding.bottom) * 0.5, 0), scale)
	end

	size = vmul(size, scale)
	size.x = size.x * Layout.projection_to_viewport_scale_x
	size.y = size.y * Layout.projection_to_viewport_scale_y
	position.x, position.y = Layout.projection_to_viewport(position.x, position.y)

	return {
		center = position,
		size = size
	}
end

local pivot_to_x = {
	[gui.PIVOT_CENTER] = 0.5,
	[gui.PIVOT_N] = 0.5,
	[gui.PIVOT_NE] = 1,
	[gui.PIVOT_E] = 1,
	[gui.PIVOT_SE] = 1,
	[gui.PIVOT_S] = 0.5,
	[gui.PIVOT_SW] = 0,
	[gui.PIVOT_W] = 0,
	[gui.PIVOT_NW] = 0
}
local pivot_to_y = {
	[gui.PIVOT_CENTER] = 0.5,
	[gui.PIVOT_N] = 1,
	[gui.PIVOT_NE] = 1,
	[gui.PIVOT_E] = 0.5,
	[gui.PIVOT_SE] = 0,
	[gui.PIVOT_S] = 0,
	[gui.PIVOT_SW] = 0,
	[gui.PIVOT_W] = 0.5,
	[gui.PIVOT_NW] = 1
}

function Tooltip.get_gui_node_bounding_box(node)
	local size = gui.get_size(node)
	local position = vmath.vector3()
	local pivot = gui.get_pivot(node)

	while node do
		local scale = gui.get_scale(node)
		size = vmul(size, scale)
		position = vmul(position, scale)
		position = position + gui.get_position(node)
		node = gui.get_parent(node)
	end

	return {
		center = position + vmath.vector3((0.5 - pivot_to_x[pivot]) * size.x, (0.5 - pivot_to_y[pivot]) * size.y, 0),
		size = size
	}
end

function Tooltip.__index:update_position(message)
	local id = message.id
	local bounding_box = message.bounding_box
	local desired_position = message.desired_position
	local padding = message.padding
	local fixed_x_pos = message.fixed_x_pos
	local fixed_y_pos = message.fixed_y_pos
	local instance = self.instances[id]

	if not instance then
		return
	end

	local container_node = instance.container_node
	local tooltip_size = instance.original_container_scale * (instance.animating_container_size or instance.container_size)
	local position = Tooltip__get_position(bounding_box, tooltip_size, desired_position, padding)

	if fixed_x_pos then
		local position_x = fixed_x_pos * Layout.viewport_width / Layout.design_width
		position = vmath.vector3(position_x, position.y, position.z)
	end

	if fixed_y_pos then
		local position_y = fixed_y_pos * Layout.viewport_height / Layout.design_height
		position = vmath.vector3(position.x, position_y, position.z)
	end

	gui.set_position(container_node, position)
end

function Tooltip.get_button_bounding_box(button)
	if button.is_sprite then
		return Tooltip.get_sprite_bounding_box(button.node, button.padding)
	end

	return Tooltip.get_gui_node_bounding_box(button.node)
end

local huge = math.huge

function Tooltip.merge_bounding_boxes(boxes)
	local min_x = huge
	local max_x = -huge
	local min_y = huge
	local max_y = -huge

	for i, box in ipairs(boxes) do
		local center = box.center
		local size = box.size
		local half_w = size.x * 0.5
		local half_h = size.y * 0.5
		local x = center.x
		local y = center.y
		local bmin_x = x - half_w
		local bmax_x = x + half_w
		local bmin_y = y - half_h
		local bmax_y = y + half_h

		if bmin_x < min_x then
			min_x = bmin_x
		end

		if max_x < bmax_x then
			max_x = bmax_x
		end

		if bmin_y < min_y then
			min_y = bmin_y
		end

		if max_y < bmax_y then
			max_y = bmax_y
		end
	end

	return {
		center = vmath.vector3((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, 0),
		size = vmath.vector3(max_x - min_x, max_y - min_y, 0)
	}
end

function Tooltip.button_on_state_change(options, original_on_state_change)
	local id = options.id
	local tooltip_type = options.type
	local payload = options.payload
	local is_payload_function = type(payload) == "function"
	local position = options.position
	local padding = options.padding
	local get_button_bounding_box = options.get_button_bounding_box or Tooltip.get_button_bounding_box
	local fixed_x_pos = options.fixed_x_pos
	local fixed_y_pos = options.fixed_y_pos

	if original_on_state_change == nil then
		original_on_state_change = Button.default_on_state_change
	end

	return function (button, state, old_state, did_click)
		if original_on_state_change then
			original_on_state_change(button, state, old_state, did_click)
		end

		local was_hover = old_state == STATE_HOVER or old_state == STATE_PRESSED
		local is_hover = state == STATE_HOVER or state == STATE_PRESSED

		if was_hover == is_hover then
			return
		end

		if is_hover then
			local sent_payload = payload

			if is_payload_function then
				sent_payload = payload()
			end

			if sent_payload ~= DISCARD_TOOLTIP then
				dispatcher.dispatch(h_tooltip_show, {
					id = id,
					type = tooltip_type,
					payload = sent_payload,
					bounding_box = get_button_bounding_box(button),
					position = position,
					padding = padding,
					keep_text = options.keep_text,
					fixed_x_pos = fixed_x_pos,
					fixed_y_pos = fixed_y_pos
				})
			end
		else
			dispatcher.dispatch(h_tooltip_hide, {
				id = id,
				type = tooltip_type
			})
		end
	end
end

return Tooltip
