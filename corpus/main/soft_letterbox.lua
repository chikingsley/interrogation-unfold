local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local h_window_change_size = hash("window_change_size")
local h_enable = hash("enable")
local h_disable = hash("disable")

local function layout(self)
	local ar = Layout.projection_width / Layout.projection_height

	msg.post(self.sprite, ar < self.min_aspect_ratio and h_enable or h_disable)
end

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_window_change_size
	})

	layout(self)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		layout(self)
	end
end
