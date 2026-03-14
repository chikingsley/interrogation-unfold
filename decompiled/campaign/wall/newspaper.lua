local dispatcher = require("crit.dispatcher")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_wall_object_loaded = hash("wall_object_loaded")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_newspaper = hash("newspaper")

function _env:init()
	self.factory = msg.url("#factory")
	self.close_button = msg.url("close_button")
	self.zoom_button = msg.url("zoom_button")
	self.sub_id = dispatcher.subscribe({
		h_wall_object_select,
		h_wall_object_deselect,
		h_office_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_wall_object_select then
		if message.object_type == h_newspaper then
			self.newspaper_go = factory.create(self.factory, nil, nil, {
				animation_delay = 0,
				newspaper_index = message.newspaper_index,
				close_button_url = self.close_button,
				zoom_button_url = self.zoom_button
			})
			self.timer = timer.delay(0, false, function ()
				self.timer = timer.delay(0, false, function ()
					self.timer = timer.delay(0, false, function ()
						self.timer = nil

						dispatcher.dispatch(h_office_object_select, {
							object_id = h_newspaper
						})
						dispatcher.dispatch(h_office_object_selected, {
							object_id = h_newspaper
						})
						dispatcher.dispatch(h_wall_object_loaded, message)
					end)
				end)
			end)
		end
	else
		if message_id == h_wall_object_deselect then
			local newspaper_go = self.newspaper_go

			if newspaper_go then
				self.newspaper_go = nil

				if self.timer then
					timer.cancel(self.timer)

					self.timer = nil
				end

				dispatcher.dispatch(h_office_object_deselect, {
					object_id = h_newspaper
				})
				timer.delay(0.6, false, function ()
					go.delete(newspaper_go, true)
				end)
			end

			return
		end

		if message_id == h_office_object_deselect and self.newspaper_go and message.object_id == h_newspaper then
			dispatcher.dispatch(h_wall_object_deselect)
		end
	end
end
