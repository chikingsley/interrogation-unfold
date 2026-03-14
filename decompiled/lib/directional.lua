local Directional = {}
local h_gamepad_rstick_up = hash("gamepad_rstick_up")
local h_gamepad_rstick_down = hash("gamepad_rstick_down")
local h_gamepad_rstick_left = hash("gamepad_rstick_left")
local h_gamepad_rstick_right = hash("gamepad_rstick_right")
local h_gamepad_lstick_up = hash("gamepad_lstick_up")
local h_gamepad_lstick_down = hash("gamepad_lstick_down")
local h_gamepad_lstick_left = hash("gamepad_lstick_left")
local h_gamepad_lstick_right = hash("gamepad_lstick_right")
local h_gamepad_lpad_up = hash("gamepad_lpad_up")
local h_gamepad_lpad_down = hash("gamepad_lpad_down")
local h_gamepad_lpad_left = hash("gamepad_lpad_left")
local h_gamepad_lpad_right = hash("gamepad_lpad_right")
local h_key_up = hash("key_up")
local h_key_down = hash("key_down")
local h_key_left = hash("key_left")
local h_key_right = hash("key_right")
local rstick_directions = {
	[h_gamepad_rstick_up] = {
		y = 1
	},
	[h_gamepad_rstick_down] = {
		y = -1
	},
	[h_gamepad_rstick_right] = {
		x = 1
	},
	[h_gamepad_rstick_left] = {
		x = -1
	}
}
local lstick_directions = {
	[h_gamepad_lstick_up] = {
		y = 1
	},
	[h_gamepad_lstick_down] = {
		y = -1
	},
	[h_gamepad_lstick_right] = {
		x = 1
	},
	[h_gamepad_lstick_left] = {
		x = -1
	}
}
local dpad_directions = {
	[h_gamepad_lpad_up] = {
		y = 1
	},
	[h_gamepad_lpad_down] = {
		y = -1
	},
	[h_gamepad_lpad_right] = {
		x = 1
	},
	[h_gamepad_lpad_left] = {
		x = -1
	}
}
local keyboard_directions = {
	[h_key_up] = {
		y = 1
	},
	[h_key_down] = {
		y = -1
	},
	[h_key_right] = {
		x = 1
	},
	[h_key_left] = {
		x = -1
	}
}

local function nop()
	return
end

function Directional.new(options)
	local on_pan = options.on_pan or nop
	local on_begin = options.on_begin or nop
	local on_end = options.on_end or nop
	local pan_speed = options.pan_speed or 1000
	local gamepad_lstick = options.gamepad or options.gamepad_lstick
	local gamepad_rstick = options.gamepad or options.gamepad_rstick
	local gamepad_dpad = options.gamepad or options.gamepad_dpad
	local keyboard = options.keyboard
	local panning = false
	local value_x = 0
	local value_y = 0

	local function reset()
		value_x = 0
		value_y = 0

		if panning then
			panning = false

			on_end()
		end
	end

	local function on_input(action_id, action)
		local direction = nil

		if gamepad_lstick then
			direction = direction or lstick_directions[action_id]
		end

		if gamepad_rstick then
			direction = direction or rstick_directions[action_id]
		end

		if gamepad_dpad then
			direction = direction or dpad_directions[action_id]
		end

		if keyboard then
			direction = direction or keyboard_directions[action_id]
		end

		if direction then
			if not panning then
				panning = true

				on_begin()
			end

			local x = direction.x
			local y = direction.y

			if x then
				value_x = x * action.value
			end

			if y then
				value_y = y * action.value
			end

			if panning and value_x == 0 and value_y == 0 then
				panning = false

				on_end()
			end
		end

		return not not direction
	end

	local function update(dt)
		if value_x ~= 0 or value_y ~= 0 then
			on_pan(value_x * pan_speed * dt, value_y * pan_speed * dt)
		end
	end

	return {
		update = update,
		on_input = on_input,
		reset = reset
	}
end

return Directional
