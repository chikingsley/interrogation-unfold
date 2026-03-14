local dispatcher = require("crit.dispatcher")
local office = require("campaign.office")
local Scroll = require("crit.scroll")
local Layout = require("crit.layout")
local pick = require("crit.pick")
local analog_to_digital = require("crit.analog_to_digital")
local intl = require("crit.intl")
local save_file = require("lib.save_file")
local large_ui = require("lib.large_ui")
local ZoomPan = require("lib.zoom_and_pan")
local gesture = require("in.gesture")
local Directional = require("lib.directional")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_position = hash("position")
local h_size = hash("size")
local h_scale = hash("scale")
local h_sprite = hash("sprite")
local h_click = hash("click")
local h_newspaper = hash("newspaper")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_window_change_size = hash("window_change_size")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_office_object_zoom = hash("office_object_zoom")
local h_office_object_set_zoom = hash("office_object_set_zoom")
local set_zoom = nil
local min = math.min
local max = math.max
local default_zoom_positions = {
	newspaper1 = vmath.vector3(460, 800, 0),
	newspaper2 = vmath.vector3(460, -550, 0),
	newspaper3 = vmath.vector3(460, -600, 0),
	newspaper4 = vmath.vector3(460, -620, 0),
	newspaper5 = vmath.vector3(460, 755, 0),
	newspaper6 = vmath.vector3(460, 810, 0),
	newspaper7 = vmath.vector3(460, -655, 0),
	newspaper8 = vmath.vector3(460, -2515, 0)
}

local function directional_scroll(self, dx, dy)
	local zoom_pan = self.zoom_pan

	if zoom_pan.animating then
		return
	end

	if self.scroll_enabled then
		local scroll = self.scroll

		scroll:set_offset(scroll.offset - dy)

		return
	end

	if self.zoomed then
		zoom_pan.pan(-dx, -dy)
	end
end

local function calculate_zoom_bounds(self)
	local paper_size = self.paper_size
	local top_padding = Layout.projection_height * 0.5 - self.final_position.y
	local bottom_padding = top_padding * 0.5
	self.zoom_pan.content = {
		right = paper_size.x * 0.5,
		left = -paper_size.x * 0.5,
		top = paper_size.y * 0.5 + top_padding,
		bottom = -paper_size.y * 0.5 - bottom_padding
	}
	self.zoom_pan.viewport = {
		right = paper_size.x * 0.5,
		left = -paper_size.x * 0.5,
		top = Layout.projection_height * 0.5,
		bottom = -Layout.projection_height * 0.5
	}

	self.zoom_pan.force_layout()
end

local function on_window_change_size(self)
	local height = Layout.projection_height
	local paper_height = self.paper_size.y
	local top_padding = height * 0.5 - self.final_position.y
	local bottom_padding = top_padding * 0.5

	self.scroll:set_view_height(height)

	local content_height = paper_height + top_padding + bottom_padding

	self.scroll:set_content_height(content_height)
	calculate_zoom_bounds(self)
end

function _env:init()
	local newspaper_name = self.newspaper_index >= 0 and "newspaper" .. self.newspaper_index or office.newspaper
	self.newspaper_name = newspaper_name
	local factory_url = intl.select(function (lang)
		local ok, factory_url = pcall(function ()
			local paper_factory_url = msg.url("#" .. newspaper_name .. "." .. lang)

			factory.get_status(paper_factory_url)

			return paper_factory_url
		end)

		if not ok then
			return nil
		end

		return factory_url
	end)

	if not factory_url then
		error("No newspaper factory found for " .. newspaper_name)
	end

	self.factory_url = factory_url
	local paper_node = factory.create(factory_url)

	msg.post(paper_node, h_disable)

	self.paper_node = paper_node
	local paper_node_url = msg.url(paper_node)
	local paper_node_sprite = msg.url(paper_node_url.socket, paper_node_url.path, h_sprite)
	self.paper_sprite = paper_node_sprite
	self.paper_size = go.get(paper_node_sprite, h_size) * go.get(paper_node, h_scale).x
	self.paper_offset = vmath.vector3(0, -self.paper_size.y * 0.5, 0)

	go.set(paper_node, h_position, self.initial_position + self.paper_offset)

	self.scroll_enabled = false
	self.scroll = Scroll.new({
		is_go = true,
		on_capture_touch = function ()
			return
		end
	})
	local close_button_url = self.close_button_url
	local close_button_position = go.get(close_button_url, h_position)
	local close_button_offset = close_button_position - (self.final_position + self.paper_offset)
	local zoom_button_url = self.zoom_button_url
	local zoom_button_position = go.get(zoom_button_url, h_position)
	local zoom_button_offset = zoom_button_position - close_button_position
	local max_buttons_y = close_button_position.y
	local min_buttons_x = -Layout.design_width * 0.5 + 100

	local function set_buttons_position(position)
		position = vmath.vector3(max(position.x, min_buttons_x), min(position.y, max_buttons_y), position.z)

		go.set_position(position, close_button_url)
		go.set_position(position + zoom_button_offset, zoom_button_url)
	end

	self.scroll:add_offset_listener(function ()
		set_buttons_position(close_button_position + vmath.vector3(0, self.scroll.offset, 0))
	end)

	self.interactive = false
	self.zoomed = false
	self.gesture = gesture.create({
		multi_touch = true,
		action_id = h_click
	})

	local function scale_xy(offset, zoom)
		return vmath.vector3(offset.x * zoom, offset.y * zoom, offset.z)
	end

	local paper_z = self.final_position.z
	self.zoom_pan = ZoomPan.new({
		min_zoom = 1,
		max_zoom = 2,
		on_change = function (zoom, position)
			local vscale = vmath.vector3(zoom, zoom, 1)
			position = vmath.vector3(position.x, position.y, paper_z)

			go.set_position(position, paper_node)
			go.set_scale(vscale, paper_node)
			set_buttons_position(scale_xy(close_button_offset, zoom) + position)
		end
	})

	self.zoom_pan.set_enabled(false)
	calculate_zoom_bounds(self)

	self.directional = Directional.new({
		keyboard = true,
		gamepad = true,
		pan_speed = self.gamepad_pan_speed,
		on_pan = function (dx, dy)
			directional_scroll(self, dx, dy)
		end,
		on_begin = function ()
			self.zoom_pan.on_cancel_touch()
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect,
		h_window_change_size,
		h_office_object_zoom
	})

	on_window_change_size(self)
end

function _env:final()
	if self.sub_id then
		dispatcher.unsubscribe(self.sub_id)
	end

	if self.factory_url then
		factory.unload(self.factory_url)
	end

	if self.paper_node then
		go.delete(self.paper_node, true)
	end
end

function set_zoom(self, zoom_in, origin_x, origin_y, duration, callback)
	if not large_ui.enabled and not self.zoomed then
		return
	end

	local zoom_pan = self.zoom_pan

	if zoom_in then
		self.scroll_enabled = false

		self.scroll:release_control()

		zoom_pan.position = go.get_position(self.paper_node)
		zoom_pan.zoom = go.get_scale(self.paper_node).x

		zoom_pan.set_enabled(true)
	end

	local zoom = zoom_in and zoom_pan.max_zoom or zoom_pan.min_zoom
	local position = nil

	if origin_x or origin_y then
		position = vmath.vector3(origin_x or 0, origin_y or 0, 0)
		position = zoom_pan.zoom_around(zoom, position)
	elseif zoom_in then
		position = default_zoom_positions[self.newspaper_name] or vmath.vector3(0, 0, 0)
	else
		position = zoom_pan.zoom_around(zoom, zoom_pan.position)
	end

	local function after_zoom()
		if not zoom_in then
			zoom_pan.set_enabled(false)

			self.scroll_enabled = true

			self.scroll:set_offset(zoom_pan.position.y - (self.final_position.y + self.paper_offset.y))
		end

		if callback then
			callback()
		end
	end

	self.zoomed = zoom_in

	dispatcher.dispatch(h_office_object_set_zoom, {
		value = zoom_in,
		object_id = h_newspaper
	})

	duration = duration or 0.5

	if duration == 0 then
		zoom_pan.set_zoom_pan(zoom, position)
		after_zoom()
	else
		zoom_pan.animate_zoom_pan(zoom, position, duration or 0.5, after_zoom)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select and message.object_id == h_newspaper then
		msg.post(self.paper_node, h_enable)
		go.cancel_animations(self.paper_node, h_position)
		self.scroll:set_offset(0)
		msg.post(".", h_acquire_input_focus)
		msg.post(self.zoom_button_url, h_release_input_focus)
		msg.post(self.zoom_button_url, h_acquire_input_focus)
		msg.post(self.close_button_url, h_release_input_focus)
		msg.post(self.close_button_url, h_acquire_input_focus)
		go.animate(self.paper_node, h_position, go.PLAYBACK_ONCE_FORWARD, self.final_position + self.paper_offset, go.EASING_INOUTEXPO, self.animation_duration, self.animation_delay, function ()
			self.interactive = true
			self.scroll_enabled = true

			self.scroll:add_node(self.paper_node, self.final_position + self.paper_offset)
		end)
		save_file.set_global("read_" .. self.newspaper_name, true)
	elseif message_id == h_office_object_deselect and message.object_id == h_newspaper then
		go.cancel_animations(self.paper_node, h_position)
		go.cancel_animations(self.paper_node, h_scale)

		self.zoomed = false
		self.interactive = false
		self.scroll_enabled = false

		self.scroll:remove_node(self.paper_node)
		self.zoom_pan.set_enabled(false)
		msg.post(".", h_release_input_focus)
		go.animate(self.paper_node, h_scale, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(1), go.EASING_INOUTEXPO, self.animation_duration)
		go.animate(self.paper_node, h_position, go.PLAYBACK_ONCE_FORWARD, self.initial_position + self.paper_offset, go.EASING_INOUTEXPO, self.animation_duration, 0, function ()
			msg.post(self.paper_node, h_disable)
			self.scroll:set_offset(0)
		end)
	elseif message_id == h_office_object_zoom and message.object_id == h_newspaper then
		set_zoom(self, not self.zoomed)
	elseif message_id == h_window_change_size then
		on_window_change_size(self)
	end
end

on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
	if self.interactive then
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

	self.directional.on_input(action_id, action)

	if self.scroll_enabled and self.scroll:on_input(action_id, action) then
		return true
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

	if action_id == h_click and action.released then
		local x, y = Layout.action_to_projection(action)

		if not pick.pick_sprite(self.paper_sprite, x, y) then
			dispatcher.dispatch(h_office_object_deselect, {
				object_id = h_newspaper
			})

			return true
		end
	end
end)

function _env:update(dt)
	self.directional.update(dt)

	if self.scroll_enabled then
		self.scroll:update(dt)
	end

	self.zoom_pan.update(dt)
end
