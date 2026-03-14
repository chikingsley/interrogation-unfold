local dispatcher = require("crit.dispatcher")
local h_set_time_step = hash("set_time_step")
local h_scene_set_time_step = hash("scene_set_time_step")
local h_proxy_loaded = hash("proxy_loaded")
local h_init = hash("init")
local h_enable = hash("enable")
local h_load = hash("load")

function _env:init()
	self.proxy_url = msg.url("#progression")
	self.sub_id = dispatcher.subscribe({
		h_scene_set_time_step
	})

	msg.post(self.proxy_url, h_load)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message)
	if message_id == h_scene_set_time_step then
		msg.post(self.proxy_url, h_set_time_step, {
			mode = 0,
			factor = message.factor
		})
	elseif message_id == h_proxy_loaded then
		msg.post(self.proxy_url, h_init)
		msg.post(self.proxy_url, h_enable)
	end
end
