local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local dispatcher = require("crit.dispatcher")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_deselect = hash("wall_object_deselect")

function _env:init()
	self.this_go = msg.url(".")
	self.sub_id = dispatcher.subscribe({
		h_wall_object_select,
		h_wall_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_wall_object_select then
		msg.post(self.this_go, h_acquire_input_focus)
	elseif message_id == h_wall_object_deselect then
		msg.post(self.this_go, h_release_input_focus)
	end
end

function _env:on_input(action_id, action)
	return true
end
