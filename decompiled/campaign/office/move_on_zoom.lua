local dispatcher = require("crit.dispatcher")
local h_position = hash("position")
local h_office_object_set_zoom = hash("office_object_set_zoom")
local h_office_object_deselect = hash("office_object_deselect")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_office_object_set_zoom,
		h_office_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function set_zoom(self, zoomed)
	if not not self.zoomed == zoomed then
		return
	end

	self.zoomed = zoomed

	if not self.initial_position then
		self.initial_position = go.get_position()
	end

	local target = self.initial_position

	if zoomed then
		target = target + self.offset
	end

	local go_url = msg.url(".")

	go.cancel_animations(go_url, h_position)
	go.animate(go_url, h_position, go.PLAYBACK_ONCE_FORWARD, target, go.EASING_INOUTCUBIC, 0.5)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_set_zoom then
		if message.object_id == self.object_id then
			set_zoom(self, message.value)
		end
	elseif message_id == h_office_object_deselect and message.object_id == self.object_id then
		set_zoom(self, false)
	end
end
