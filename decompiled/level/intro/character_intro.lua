local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local h_position = hash("position")
local h_positiony = hash("position.y")
local h_torture = hash("torture")
local h_torture_animation = hash("torture_animation")
local h_sizey = hash("size.y")
local h_colorw = hash("color.w")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_game_over = hash("game_over")
local h_timeout_flash = hash("timeout_flash")
local flash_duration = 0.5
local total_duration = 1.5
local timeout_duration = 4
local close_duration = 0.5
local initial_size, flash_color, flash = nil

function _env:init()
	self.flash = gui.get_node("flash")
	self.fade = gui.get_node("fade")
	self.stencil = gui.get_node("stencil")
	self.image = gui.get_node("image")
	self.padding_left = gui.get_node("padding_left")
	self.padding_right = gui.get_node("padding_right")
	self.padding_top = gui.get_node("padding_top")
	self.padding_bottom = gui.get_node("padding_bottom")
	self.border_top = gui.get_node("border_top")
	self.border_bottom = gui.get_node("border_bottom")

	gui.set_render_order(11)
	gui.set_enabled(self.stencil, false)
	gui.set_enabled(self.flash, false)
	gui.set_enabled(self.fade, false)

	initial_size = gui.get_size(self.stencil)
	flash_color = gui.get_color(self.flash)
	self.go_url = msg.url()
	self.sub_id = dispatcher.subscribe({
		h_torture_animation,
		h_game_over
	})

	timer.delay(4, true, function ()
		flash(self, "pixel_solid", 1, 3)
	end)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_input(action_id, action)
	return true
end

function flash(self, image_id, y_scale, duration, on_done)
	gui.set_enabled(self.stencil, true)
	gui.set_enabled(self.flash, true)
	msg.post(self.go_url, h_acquire_input_focus)

	local position = vmath.vector3(Layout.viewport_width * 0.5, Layout.viewport_height * 0.5, 0)
	local offset = vmath.vector3(Layout.viewport_width * 0.03, 0, 0)
	local scale = Layout.viewport_height / Layout.design_height

	gui.set_position(self.border_top, vmath.vector3(0, initial_size.y * 0.5, 0))
	gui.set_position(self.border_bottom, vmath.vector3(0, -initial_size.y * 0.5, 0))
	gui.set_color(self.flash, flash_color)
	gui.set_size(self.flash, vmath.vector3(Layout.viewport_width, Layout.viewport_height, 0))
	gui.set_size(self.stencil, initial_size)
	gui.set_scale(self.stencil, vmath.vector3(scale))
	gui.set_position(self.stencil, position - offset * 0.5)
	gui.play_flipbook(self.image, image_id)

	local image_size = gui.get_size(self.image)
	local image_scale = y_scale * initial_size.y / image_size.y
	local image_width = image_size.x * image_scale
	local half_image_width = image_width * 0.5
	local half_image_height = image_size.y * image_scale * 0.5
	local vertical_padding = initial_size.y * 0.5 - half_image_height

	gui.set_scale(self.image, vmath.vector3(image_scale))
	gui.set_position(self.padding_left, vmath.vector3(-half_image_width, 0, 0))
	gui.set_position(self.padding_right, vmath.vector3(half_image_width, 0, 0))
	gui.set_position(self.padding_top, vmath.vector3(0, half_image_height, 0))
	gui.set_position(self.padding_bottom, vmath.vector3(0, -half_image_height, 0))
	gui.set_size(self.padding_top, vmath.vector3(image_width, vertical_padding, 0))
	gui.set_size(self.padding_bottom, vmath.vector3(image_width, vertical_padding, 0))
	gui.animate(self.flash, h_colorw, 0, gui.EASING_LINEAR, flash_duration)
	gui.animate(self.stencil, h_position, position + offset, gui.EASING_LINEAR, duration, 0, function ()
		gui.set_enabled(self.stencil, false)
		gui.set_enabled(self.flash, false)
		msg.post(self.go_url, h_release_input_focus)

		if on_done then
			on_done()
		end
	end)

	local close_delay = duration - close_duration

	gui.animate(self.stencil, h_sizey, 0, gui.EASING_INEXPO, close_duration, close_delay)
	gui.animate(self.border_top, h_positiony, 0, gui.EASING_INEXPO, close_duration, close_delay)
	gui.animate(self.border_bottom, h_positiony, 0, gui.EASING_INEXPO, close_duration, close_delay)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_torture_animation then
		flash(self, hash("torture_flash" .. message.torture_id), 1, total_duration, function ()
			dispatcher.dispatch(h_torture, message)
		end)
	elseif message_id == h_game_over and message.reason == "timeout" then
		gui.set_enabled(self.fade, true)
		gui.set_size(self.fade, vmath.vector3(Layout.viewport_width, Layout.viewport_height, 0))
		gui.set_color(self.fade, vmath.vector4(0))
		gui.animate(self.fade, h_colorw, 1, gui.EASING_OUTEXPO, timeout_duration)
		flash(self, h_timeout_flash, 0.36428571428571427, timeout_duration)
	end
end
