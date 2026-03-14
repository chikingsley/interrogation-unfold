local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local h_set_position = hash("table_set_position")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_set_position
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_set_position then
		if self.respect_position then
			go.set_position(state.table_position)
		end

		if self.respect_scale then
			local scale = state.table_scale

			go.set_scale(vmath.vector3(scale, scale, 1))
		end
	end
end
