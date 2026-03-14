local render_settings = require("main.render.settings")
local dispatcher = require("crit.dispatcher")
local h_ = hash("")

local function push_settings(self)
	if self.id then
		return
	end

	self.id = render_settings.push_settings({
		min_aspect_ratio = self.min_aspect_ratio,
		max_aspect_ratio = self.max_aspect_ratio,
		transition_end_zoom = self.transition_end_zoom
	})
end

function _env:init()
	if self.trigger_message == h_ then
		push_settings(self)
	else
		self.sub_id = dispatcher.subscribe({
			self.trigger_message
		})
	end
end

function _env:on_message(message_id, message)
	if message_id == self.trigger_message then
		push_settings(self)
	end
end

function _env:final()
	if self.id then
		render_settings.pop_settings(self.id)
	end

	if self.sub_id then
		dispatcher.unsubscribe(self.sub_id)
	end
end
