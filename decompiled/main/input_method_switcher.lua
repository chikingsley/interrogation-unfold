local dispatcher = require("crit.dispatcher")
local input_state = require("crit.input_state")
local Button = require("crit.button")
local analog_to_digital = require("crit.analog_to_digital")
local cursor = require("lib.cursor")
local h_click = hash("click")
local h_switch_input_method = hash("switch_input_method")
local gamepad_actions = {
	[hash("gamepad_lpad_left")] = true,
	[hash("gamepad_lpad_right")] = true,
	[hash("gamepad_lpad_up")] = true,
	[hash("gamepad_lpad_down")] = true,
	[hash("gamepad_rpad_left")] = true,
	[hash("gamepad_rpad_right")] = true,
	[hash("gamepad_rpad_up")] = true,
	[hash("gamepad_rpad_down")] = true,
	[hash("gamepad_start")] = true,
	[hash("gamepad_back")] = true,
	[hash("gamepad_guide")] = true,
	[hash("gamepad_rshoulder")] = true,
	[hash("gamepad_lshoulder")] = true,
	[hash("gamepad_ltrigger")] = true,
	[hash("gamepad_rtrigger")] = true,
	[hash("gamepad_lstick_click")] = true,
	[hash("gamepad_lstick_digital_left")] = true,
	[hash("gamepad_lstick_digital_right")] = true,
	[hash("gamepad_lstick_digital_up")] = true,
	[hash("gamepad_lstick_digital_down")] = true,
	[hash("gamepad_rstick_click")] = true,
	[hash("gamepad_rstick_digital_left")] = true,
	[hash("gamepad_rstick_digital_right")] = true,
	[hash("gamepad_rstick_digital_up")] = true,
	[hash("gamepad_rstick_digital_down")] = true
}
local h_key_h = hash("key_h")
local h_key_j = hash("key_j")
local h_key_k = hash("key_k")
local h_key_l = hash("key_l")
local h_key_w = hash("key_w")
local h_key_a = hash("key_a")
local h_key_s = hash("key_s")
local h_key_d = hash("key_d")
local input_map = Button.input_map
input_map[h_key_k] = Button.KEYBOARD_UP
input_map[h_key_j] = Button.KEYBOARD_DOWN
input_map[h_key_h] = Button.KEYBOARD_LEFT
input_map[h_key_l] = Button.KEYBOARD_RIGHT
input_map[h_key_w] = Button.KEYBOARD_UP
input_map[h_key_s] = Button.KEYBOARD_DOWN
input_map[h_key_a] = Button.KEYBOARD_LEFT
input_map[h_key_d] = Button.KEYBOARD_RIGHT

local function switch_input_method(method, nav_action)
	if input_state.input_method ~= method then
		input_state.input_method = method

		dispatcher.dispatch(h_switch_input_method, {
			input_method = method,
			nav_action = nav_action
		})

		local cursor_visible = nil

		if method == input_state.INPUT_METHOD_GAMEPAD then
			cursor_visible = false
		end

		cursor.set_visible(cursor_visible, cursor.PRIORITY_INPUT_METHOD)
	end
end

input_state.switch_input_method = switch_input_method

local function on_input_(_, action_id, action)
	if action_id == nil or action_id == h_click then
		switch_input_method(input_state.INPUT_METHOD_MOUSE)
	elseif gamepad_actions[action_id] and action.pressed and input_state.input_method ~= input_state.INPUT_METHOD_GAMEPAD then
		local nav_action = Button.action_id_to_navigation_action(action_id)

		if nav_action == Button.NAVIGATE_CONFIRM then
			nav_action = nil
		end

		switch_input_method(input_state.INPUT_METHOD_GAMEPAD, nav_action)
	end
end

local function on_input(action_id, action)
	return analog_to_digital.convert_action(nil, action_id, action, on_input_)
end

return on_input
