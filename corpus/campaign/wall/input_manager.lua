local input_manager = require("campaign.wall.input_manager")
local h_after_init = hash("after_init")
local h_acquire_input_focus = hash("acquire_input_focus")

function _env:init()
	msg.post(".", h_acquire_input_focus)
	msg.post(".", h_after_init)
end

function _env:final()
	input_manager.instances = {}
end

local function compare(a, b)
	return b.z < a.z
end

function _env:on_message(message_id, message)
	if message_id == h_after_init then
		table.sort(input_manager.instances, compare)
	end
end

function _env:on_input(action_id, action)
	input_manager.pass_input({
		index = 0,
		action_id = action_id,
		action = action
	})
end
