local Layout = require("crit.layout")
local save_file = require("lib.save_file")
local height_limit_inch = 5
local default_text_scale = 1.2
local OVERRIDE_LARGE = 1
local OVERRIDE_REGULAR = 2
local M = {
	enabled = false,
	OVERRIDE_LARGE = OVERRIDE_LARGE,
	OVERRIDE_REGULAR = OVERRIDE_REGULAR,
	default_text_scale = default_text_scale,
	enabled = false
}

function M.set_dpi(dpi)
	local window_width = Layout.window_width
	local window_height = Layout.window_height
	local aspect = window_width / window_height
	local design_ar = Layout.design_width / Layout.design_height

	if aspect < design_ar then
		window_height = math.ceil(window_width / design_ar)
	end

	local window_height_inch = window_height / dpi
	M.enabled = window_height_inch <= height_limit_inch
	local override = save_file.config.large_ui_override

	if override == OVERRIDE_LARGE then
		M.enabled = true
	elseif override == OVERRIDE_REGULAR then
		M.enabled = false
	end
end

function M.rescale_text_node(node, scale, node_scale, node_size)
	node_size = node_size or gui.get_size(node)
	node_scale = node_scale or gui.get_scale(node)

	gui.set_scale(node, vmath.vector3(node_scale.x * scale, node_scale.y * scale, node_scale.z))
	gui.set_size(node, vmath.vector3(node_size.x / scale, node_size.y / scale, node_size.z))
end

function M.adjust_text_node(node, scale)
	if not M.enabled then
		return
	end

	scale = scale or default_text_scale

	M.rescale_text_node(node, scale)
end

function M.adjust_height(id, y_offset)
	if not M.enabled then
		return
	end

	local position = go.get_position(id)
	position.y = position.y + y_offset

	go.set_position(position, id)
end

function M.adjust_height_gui(node, y_offset)
	if not M.enabled then
		return
	end

	local position = gui.get_position(node)
	position.y = position.y + y_offset

	gui.set_position(node, position)
end

return M
