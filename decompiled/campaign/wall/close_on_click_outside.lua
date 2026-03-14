local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local pick = require("crit.pick")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_click = hash("click")

function _env:init()
	self.this_go = msg.url(".")

	msg.post(self.this_go, h_acquire_input_focus)

	self.sub_id = dispatcher.subscribe({
		h_wall_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_wall_object_deselect then
		msg.post(self.this_go, h_release_input_focus)
	end
end

function _env:on_input(action_id, action)
	if action_id == h_click and action.released then
		local x, y = Layout.action_to_projection(action)

		if not pick.pick_sprite(self.sprite, x, y) then
			dispatcher.dispatch(h_wall_object_deselect)

			return true
		end
	end
end
