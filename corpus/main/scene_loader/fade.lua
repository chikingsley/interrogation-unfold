local dispatcher = require("crit.dispatcher")
local h_scene_transition_start = hash("scene_transition_start")
local h_scene_transition_midpoint = hash("scene_transition_midpoint")
local h_scene_transition_midpoint_continue = hash("scene_transition_midpoint_continue")
local h_scene_transition_end = hash("scene_transition_end")
local h_colorx = hash("color.x")
local h_colory = hash("color.y")
local h_colorz = hash("color.z")
local h_colorw = hash("color.w")
local h_zoom = hash("zoom")
local h_fade = hash("fade")
local black = vmath.vector4(0, 0, 0, 0)

function _env:init()
	self.box = gui.get_node("box")

	gui.set_color(self.box, black)
	gui.set_enabled(self.box, false)
	gui.set_render_order(13)

	self.fade_in_duration = 0.5
	self.fade_out_duration = 0.5

	dispatcher.subscribe({
		h_scene_transition_start,
		h_scene_transition_midpoint_continue
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_scene_transition_start then
		local transition = message.transition

		gui.cancel_animation(self.box, h_colorx)
		gui.cancel_animation(self.box, h_colory)
		gui.cancel_animation(self.box, h_colorz)
		gui.cancel_animation(self.box, h_colorw)

		local current_color = gui.get_color(self.box)
		local target_color = message.fade_color or black
		target_color = vmath.vector4(target_color.x, target_color.y, target_color.z, current_color.w)

		if current_color.w == 0 then
			gui.set_color(self.box, target_color)
		else
			local color_duration = message.fade_color_duration or 0.5

			gui.animate(self.box, h_colorx, target_color.x, gui.EASING_LINEAR, color_duration)
			gui.animate(self.box, h_colory, target_color.y, gui.EASING_LINEAR, color_duration)
			gui.animate(self.box, h_colorz, target_color.z, gui.EASING_LINEAR, color_duration)
		end

		if transition == h_zoom or transition == h_fade then
			gui.set_enabled(self.box, true)

			local fade_duration = message.in_duration or self.fade_in_duration

			gui.animate(self.box, h_colorw, 1, gui.EASING_LINEAR, fade_duration, 0, function ()
				dispatcher.dispatch(h_scene_transition_midpoint, {
					wait_frames = 5
				})
			end)
		else
			gui.set_enabled(self.box, false)
			gui.set_color(self.box, vmath.vector4(0, 0, 0, 0))
		end
	elseif message_id == h_scene_transition_midpoint_continue then
		local transition = message.transition

		if transition == h_zoom or transition == h_fade then
			gui.set_enabled(self.box, true)
			gui.cancel_animation(self.box, h_colorw)

			local fade_duration = message.out_duration or self.fade_out_duration

			gui.animate(self.box, h_colorw, 0, gui.EASING_LINEAR, fade_duration, 0, function ()
				gui.set_enabled(self.box, false)
				dispatcher.dispatch(h_scene_transition_end)
			end)
		end
	end
end
