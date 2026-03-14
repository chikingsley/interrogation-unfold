local caret = {}
local h_colorw = hash("color.w")
local h_position = hash("position")

function caret.move_to(focus_caret, pos_x, pos_y, animation_duration)
	gui.cancel_animation(focus_caret, h_colorw)
	gui.cancel_animation(focus_caret, h_position)

	animation_duration = animation_duration or 0.3
	local is_enabled = gui.is_enabled(focus_caret)

	gui.set_enabled(focus_caret, true)

	local duration = (1 - gui.get_color(focus_caret).w) * animation_duration

	gui.animate(focus_caret, h_colorw, 1, gui.EASING_LINEAR, duration)

	local position = gui.get_position(focus_caret)

	if pos_x then
		position.x = pos_x
	end

	if pos_y then
		position.y = pos_y
	end

	if is_enabled then
		gui.animate(focus_caret, h_position, position, gui.EASING_OUTCUBIC, animation_duration)
	else
		gui.set_position(focus_caret, position)
	end
end

function caret.hide(focus_caret)
	local is_enabled = gui.is_enabled(focus_caret)

	if not is_enabled then
		return
	end

	gui.cancel_animation(focus_caret, h_colorw)
	gui.cancel_animation(focus_caret, h_position)

	local duration = gui.get_color(focus_caret).w * 0.3

	gui.animate(focus_caret, h_colorw, 0, gui.EASING_LINEAR, duration, 0, function ()
		gui.set_enabled(focus_caret, false)
	end)
end

function caret.hide_instantly(focus_caret)
	gui.cancel_animation(focus_caret, h_colorw)
	gui.cancel_animation(focus_caret, h_position)
	gui.set_enabled(focus_caret, false)

	local color = gui.get_color(focus_caret)
	color.w = 0

	gui.set_color(focus_caret, color)
end

return caret
