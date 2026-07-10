local dispatcher = require("crit.dispatcher")
local h_pause_button_acquire_input_focus = hash("pause_button_acquire_input_focus")
local h_acquire_input_focus = hash("acquire_input_focus")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_pause_button_acquire_input_focus
	})
	self.this_go = msg.url(".")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_pause_button_acquire_input_focus then
		msg.post(self.this_go, h_acquire_input_focus)
	end
end
