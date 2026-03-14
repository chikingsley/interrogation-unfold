local Button = require("crit.button")
local button_sound = {}
local STATE_DEFAULT = Button.STATE_DEFAULT
local STATE_PRESSED = Button.STATE_PRESSED
local STATE_HOVER = Button.STATE_HOVER

function button_sound.init()
	button_sound.hover_event = fmod and fmod.studio.system:get_event("event:/Button/Hover")
	button_sound.press_event = fmod and fmod.studio.system:get_event("event:/Button/Press")
	button_sound.release_event = fmod and fmod.studio.system:get_event("event:/Button/Release")
end

function button_sound.final()
	button_sound.hover_event = nil
	button_sound.press_event = nil
	button_sound.release_event = nil
end

function button_sound.with_sound(opts, original_on_state_change)
	if type(opts) ~= "table" then
		original_on_state_change = opts
		opts = {}
	end

	if original_on_state_change == nil then
		original_on_state_change = Button.default_on_state_change
	end

	local hover = opts.hover or button_sound.hover_event

	if opts.hover == false then
		hover = nil
	end

	local press = opts.press or button_sound.press_event

	if opts.press == false then
		press = nil
	end

	local release = opts.release or button_sound.release_event

	if opts.release == false then
		release = nil
	end

	return function (button, state, old_state, did_click)
		local event = nil

		if did_click then
			event = release
		elseif state == STATE_PRESSED then
			event = press
		elseif button.state == STATE_DEFAULT and state == STATE_HOVER then
			event = hover
		end

		if event then
			if type(event) == "function" then
				event = event()
			end

			if event then
				event:create_instance():start()
			end
		end

		if original_on_state_change then
			original_on_state_change(button, state, old_state, did_click)
		end
	end
end

function button_sound.with_focus_sound(opts, original_on_focus_change)
	if type(opts) ~= "table" then
		original_on_focus_change = opts
		opts = {}
	end

	if original_on_focus_change == nil then
		original_on_focus_change = Button.default_on_focus_change
	end

	local focus = opts.focus or button_sound.hover_event

	if opts.focus == false then
		focus = nil
	end

	local unfocus = opts.unfocus or nil

	if opts.unfocus == false then
		unfocus = nil
	end

	return function (button, focused)
		if button.focus_context.focus_attempt_caused_by_user then
			local event = nil

			if focused then
				event = focus
			else
				event = unfocus
			end

			if event then
				if type(event) == "function" then
					event = event()
				end

				if event then
					event:create_instance():start()
				end
			end
		end

		if original_on_focus_change then
			original_on_focus_change(button, focused)
		end
	end
end

return button_sound
