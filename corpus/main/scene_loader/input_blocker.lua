local dispatcher = require("crit.dispatcher")
local h_scene_loader_init = hash("scene_loader_init")
local h_scene_transition_start = hash("scene_transition_start")
local h_scene_transition_midpoint = hash("scene_transition_midpoint")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_scene_input_blocker_init = hash("scene_input_blocker_init")

function _env:init()
	self.enabled = false

	dispatcher.subscribe({
		h_scene_loader_init,
		h_scene_transition_start,
		h_scene_transition_midpoint
	})
end

function _env:on_input(action_id, action)
	if self.enabled then
		return true
	end
end

function _env:on_message(message_id, message)
	if message_id == h_scene_transition_start then
		self.enabled = true
	elseif message_id == h_scene_transition_midpoint then
		self.enabled = false
	elseif message_id == h_scene_loader_init then
		msg.post(".", h_acquire_input_focus)
		dispatcher.dispatch(h_scene_input_blocker_init)
	end
end
