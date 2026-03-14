local dispatcher = require("crit.dispatcher")
local ZoomPan = require("lib.zoom_and_pan")
local Layout = require("crit.layout")
local gesture = require("in.gesture")
local large_ui = require("lib.large_ui")
local Directional = require("lib.directional")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_window_change_size = hash("window_change_size")
local h_click = hash("click")
local h_office_object_set_zoom = hash("office_object_set_zoom")
local h_office_object_zoom = hash("office_object_zoom")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")

local function get_viewport()
	return {
		right = Layout.projection_width * 0.5,
		left = -Layout.projection_width * 0.5,
		top = Layout.projection_height * 0.5,
		bottom = -Layout.projection_height * 0.5
	}
end

function _env:init()
	self.this_go = msg.url(".")
	local content_bounds = self.content_bounds
	self.content_bounds = {
		left = content_bounds.x,
		top = content_bounds.y,
		right = content_bounds.z,
		bottom = content_bounds.w
	}
	self.infinite_bounds = {
		right = math.huge,
		left = -math.huge,
		top = math.huge,
		bottom = -math.huge
	}
	self.zoom_pan = ZoomPan.new({
		viewport = get_viewport(),
		content = self.infinite_bounds,
		on_change = function (zoom, position)
			go.set_position(position)
			go.set_scale(vmath.vector3(zoom, zoom, 1))
		end
	})

	self.zoom_pan.set_enabled(false)

	self.enabled = false
	self.zoomed = false
	self.gesture = gesture.create({
		multi_touch = true,
		action_id = h_click
	})
	self.directional = Directional.new({
		gamepad_lstick = self.pan_gamepad_lstick,
		gamepad_rstick = self.pan_gamepad_rstick,
		gamepad_dpad = self.pan_gamepad_dpad,
		keyboard = self.pan_keyboard,
		pan_speed = self.gamepad_pan_speed,
		on_pan = function (dx, dy)
			if self.zoomed and not self.zoom_pan.animating then
				self.zoom_pan.pan(-dx, -dy)
			end
		end,
		on_begin = function ()
			self.zoom_pan.on_cancel_touch()
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_office_object_selected,
		h_office_object_deselect,
		h_window_change_size,
		h_office_object_zoom
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function set_zoom(self, zoom_in, origin_x, origin_y, duration)
	if not large_ui.enabled and not self.zoomed then
		return
	end

	local zoom_pan = self.zoom_pan

	if zoom_in then
		zoom_pan.content = self.content_bounds

		zoom_pan.set_enabled(true)
	end

	local zoom = zoom_in and zoom_pan.max_zoom or zoom_pan.min_zoom
	local position = nil

	if zoom_in and origin_x or origin_y then
		position = vmath.vector3(origin_x or 0, origin_y or 0, 0)
		position = zoom_pan.zoom_around(zoom, position)
	elseif zoom_in then
		position = vmath.vector3(self.default_zoom_position)
		position.z = self.initial_position.z
	else
		position = self.initial_position
	end

	self.zoomed = zoom_in
	zoom_pan.content = self.infinite_bounds

	dispatcher.dispatch(h_office_object_set_zoom, {
		value = zoom_in,
		object_id = self.object_id
	})

	duration = duration or 0.5

	if duration == 0 then
		zoom_pan.set_zoom_pan(zoom, position)

		if not zoom_in then
			zoom_pan.set_enabled(false)
		end
	else
		zoom_pan.animate_zoom_pan(zoom, position, duration or 0.5, function ()
			zoom_pan.content = self.content_bounds

			if not zoom_in then
				zoom_pan.set_enabled(false)
			end
		end)

		if zoom_in then
			zoom_pan.content = self.infinite_bounds
		end
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_selected and message.object_id == self.object_id then
		self.enabled = true
		local zoom_pan = self.zoom_pan
		local zoom = go.get_scale().x
		zoom_pan.min_zoom = zoom
		zoom_pan.max_zoom = zoom * 2
		zoom_pan.zoom = zoom
		zoom_pan.position = go.get_position()
		self.initial_position = zoom_pan.position
		zoom_pan.content = self.infinite_bounds

		if self.should_acquire_focus then
			msg.post(self.this_go, h_acquire_input_focus)
		end
	elseif message_id == h_office_object_deselect and message.object_id == self.object_id then
		self.zoomed = false
		self.enabled = false

		self.zoom_pan.set_enabled(false)

		if self.should_acquire_focus then
			msg.post(self.this_go, h_release_input_focus)
		end
	elseif message_id == h_window_change_size then
		local zoom_pan = self.zoom_pan
		zoom_pan.viewport = get_viewport()
	elseif message_id == h_office_object_zoom and message.object_id == self.object_id then
		set_zoom(self, not self.zoomed)
	end
end

function _env:on_input(action_id, action)
	if self.enabled then
		local g = self.gesture.on_input(action_id, action)

		if g and not self.zoom_pan.animating and (large_ui.enabled or self.zoomed) then
			if g.double_tap then
				if self.zoomed then
					set_zoom(self, false)
				else
					set_zoom(self, true, Layout.action_to_projection(action))
				end
			elseif g.two_finger.pinch then
				if self.panning then
					self.panning = false

					self.zoom_pan.user_pan_end()
				end

				local ratio = g.two_finger.pinch.ratio

				if self.zoomed then
					if ratio <= 0.8 then
						set_zoom(self, false)
					end
				elseif ratio >= 1.2 then
					local center = g.two_finger.pinch.center

					set_zoom(self, true, Layout.design_to_projection(center.x, center.y))
				end
			end
		end
	end

	if self.zoom_pan.enabled and action_id == h_click then
		local dx, dy = nil

		if action.pressed then
			self.panning = true
			dy = 0
			dx = 0
		else
			dx = action.screen_dx * Layout.viewport_to_projection_scale_x
			dy = action.screen_dy * Layout.viewport_to_projection_scale_y
		end

		if self.panning then
			if not self.zoom_pan.animating then
				self.zoom_pan.user_pan(dx, dy)
			end

			if action.released then
				self.panning = false

				self.zoom_pan.user_pan_end()
			end
		end
	end

	if self.directional.on_input(action_id, action) then
		return true
	end
end

function _env:update(dt)
	self.directional.update(dt)
	self.zoom_pan.update(dt)
end
