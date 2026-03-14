local dispatcher = require("crit.dispatcher")
local h_scene_transition_start = hash("scene_transition_start")
local h_scene_transition_midpoint = hash("scene_transition_midpoint")
local h_scene_transition_midpoint_continue = hash("scene_transition_midpoint_continue")
local h_scene_transition_end = hash("scene_transition_end")

function _env:init()
	dispatcher.subscribe({
		h_scene_transition_start,
		h_scene_transition_midpoint_continue
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_scene_transition_start then
		if not message.transition then
			dispatcher.dispatch(h_scene_transition_midpoint)
		end
	elseif message_id == h_scene_transition_midpoint_continue and not message.transition then
		dispatcher.dispatch(h_scene_transition_end)
	end
end
