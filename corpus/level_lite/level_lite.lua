local dispatcher = require("crit.dispatcher")
local h_init_level_lite = hash("init_level_lite")
local h_init_level = hash("init_level")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_level_lite
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level_lite then
		dispatcher.dispatch(h_init_level, message)
	end
end
