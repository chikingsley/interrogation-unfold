local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local intl = require("crit.intl")
local input_state = require("crit.input_state")
local INPUT_METHOD_GAMEPAD = input_state.INPUT_METHOD_GAMEPAD
local sys_config = require("lib.sys_config")
local h_window_change_size = hash("window_change_size")
local h_zoom_in_started = hash("zoom_in_started")
local h_zoom_out_started = hash("zoom_out_started")
local h_wall_object_loaded = hash("wall_object_loaded")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_switch_input_method = hash("switch_input_method")
local h_colorw = hash("color.w")
local h_zoom = hash("zoom")
local h_pan = hash("pan")
local h_zoom_touch = hash("zoom_touch")
local h_pan_touch = hash("pan_touch")
local h_zoom_gamepad = hash("zoom_gamepad")
local h_pan_gamepad = hash("pan_gamepad")
local set_active_guide = nil
local gamepad_ids = {
	[h_zoom] = h_zoom_gamepad,
	[h_pan] = h_pan_gamepad
}
local touch_ids = {
	[h_zoom] = h_zoom_touch,
	[h_pan] = h_pan_touch
}

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_zoom_out_started,
		h_zoom_in_started,
		h_wall_object_loaded,
		h_wall_object_deselect,
		h_window_change_size,
		h_switch_input_method
	})
	local nodes = {
		[h_zoom] = gui.get_node(h_zoom),
		[h_pan] = gui.get_node(h_pan),
		[h_zoom_touch] = gui.get_node(h_zoom_touch),
		[h_pan_touch] = gui.get_node(h_pan_touch),
		[h_zoom_gamepad] = gui.get_node(h_zoom_gamepad),
		[h_pan_gamepad] = gui.get_node(h_pan_gamepad)
	}

	intl.translate_text_node("zoom_label")
	intl.translate_text_node("pan_label")
	intl.translate_text_node("zoom_touch_label")
	intl.translate_text_node("pan_touch_label")
	intl.translate_text_node("zoom_gamepad_label")
	intl.translate_text_node("pan_gamepad_label")

	self.layout = Layout.new()

	for id, node in pairs(nodes) do
		gui.set_enabled(node, false)
		gui.set_color(node, vmath.vector4(1, 1, 1, 0))
		self.layout:add_node(node, {
			grav_y = 0,
			grav_x = 0
		})
	end

	self.layout:place()

	self.nodes = nodes

	set_active_guide(self, h_zoom)

	self.default_guide = h_zoom
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function set_active_guide(self, id)
	self.active_guide = id
	local resolved_id = id

	if input_state.input_method == INPUT_METHOD_GAMEPAD then
		resolved_id = gamepad_ids[id]
	elseif sys_config.is_mobile then
		resolved_id = touch_ids[id]
	end

	local node = resolved_id and self.nodes[resolved_id]
	local old_node = self.active_node

	if old_node and not gui.is_enabled(old_node) then
		self.active_node = nil
	end

	if old_node and old_node ~= node then
		gui.cancel_animation(old_node, h_colorw)
		gui.animate(old_node, h_colorw, 0, gui.EASING_LINEAR, 0.3, 0, function ()
			gui.set_enabled(old_node, false)

			self.active_node = nil

			set_active_guide(self, id)
		end)
	else
		self.active_node = node

		if node then
			gui.set_enabled(node, true)
			gui.cancel_animation(node, h_colorw)
			gui.animate(node, h_colorw, 1, gui.EASING_LINEAR, 0.3)
		end
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_zoom_in_started then
		set_active_guide(self, h_pan)

		self.default_guide = h_pan
	elseif message_id == h_zoom_out_started then
		set_active_guide(self, h_zoom)

		self.default_guide = h_zoom
	elseif message_id == h_wall_object_loaded then
		set_active_guide(self, nil)
	elseif message_id == h_wall_object_deselect then
		set_active_guide(self, self.default_guide)
	elseif message_id == h_switch_input_method then
		set_active_guide(self, self.active_guide)
	end
end
