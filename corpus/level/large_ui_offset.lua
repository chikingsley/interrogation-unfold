local dispatcher = require("crit.dispatcher")
local large_ui = require("lib.large_ui")
local h_window_change_size = hash("window_change_size")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_window_change_size
	})
	self.moved = large_ui.enabled

	if large_ui.enabled then
		go.set_position(go.get_position() + self.offset)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message)
	if message_id == h_window_change_size then
		local enabled = large_ui.enabled

		if enabled ~= self.moved then
			self.moved = enabled
			local new_position = go.get_position()

			if enabled then
				new_position = new_position + self.offset
			else
				new_position = new_position - self.offset
			end

			go.set_position(new_position)
		end
	end
end
