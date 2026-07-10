local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local analog_to_digital = require("crit.analog_to_digital")
local PHASE_RUNNING = state.PHASE_RUNNING
local h_gamepad_lshoulder = hash("gamepad_lshoulder")
local h_gamepad_rshoulder = hash("gamepad_rshoulder")
local h_set_subject = hash("set_subject")
on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
	if action.pressed then
		local nav_action, is_gamepad = Button.action_id_to_navigation_action(action_id)

		if nav_action == Button.NAVIGATE_LEFT and not is_gamepad or action_id == h_gamepad_lshoulder then
			if state.phase == PHASE_RUNNING and state.on_record then
				local prev_subject_id = store.prev_subject_id(state.current_subject)

				if prev_subject_id then
					dispatcher.dispatch(h_set_subject, {
						subject_id = prev_subject_id
					})
				end
			end
		elseif (nav_action == Button.NAVIGATE_RIGHT and not is_gamepad or action_id == h_gamepad_rshoulder) and state.phase == PHASE_RUNNING and state.on_record then
			local next_subject_id = store.next_subject_id(state.current_subject)

			if next_subject_id then
				dispatcher.dispatch(h_set_subject, {
					subject_id = next_subject_id
				})
			end
		end
	end
end)
