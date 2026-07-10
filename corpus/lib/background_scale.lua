local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local h_window_change_size = hash("window_change_size")
local h_background_parallax = hash("background_parallax")
local h_size = hash("size")
local h_positiony = hash("position.y")
local on_window_change_size = nil

function _env:init()
	local url = msg.url()
	url = msg.url(url.socket, url.path, self.sprite_hash)
	self.bg_size = go.get(url, h_size)
	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_background_parallax
	})

	on_window_change_size(self)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function on_window_change_size(self)
	local size = self.bg_size
	local scale_x = Layout.projection_width / size.x
	local scale_y = Layout.projection_height / size.y
	local scale = math.max(scale_x, scale_y) * 1.1

	go.set_scale(vmath.vector3(scale, scale, 1))
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		on_window_change_size(self)
	elseif message_id == h_background_parallax then
		go.set(msg.url("."), h_positiony, message.overscroll / 8)
	end
end
