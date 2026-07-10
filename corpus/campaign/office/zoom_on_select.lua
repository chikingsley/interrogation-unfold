local dispatcher = require("crit.dispatcher")
local large_ui = require("lib.large_ui")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_object_deselected = hash("office_object_deselected")
local h_scale = hash("scale")
local h_position = hash("position")
local h_position_z = hash("position.z")
local h_rotation = hash("rotation")

function _env:init()
	local this_go = msg.url(".")
	self.this_go = this_go
	self.original_scale = go.get_scale(this_go)
	self.original_position = go.get_position(this_go)
	self.original_rotation = go.get_rotation(this_go)
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if message.object_id == self.object_id and not message.no_zoom then
			local this_go = self.this_go

			go.cancel_animations(this_go, h_position)
			go.cancel_animations(this_go, h_rotation)
			go.cancel_animations(this_go, h_scale)

			local position, rotation, scale = nil

			if self.respects_large_ui and large_ui.enabled then
				position = self.large_ui_zoomed_position
				rotation = self.large_ui_zoomed_rotation
				scale = self.large_ui_zoomed_scale
			else
				position = self.zoomed_position
				rotation = self.zoomed_rotation
				scale = self.zoomed_scale
			end

			go.set(this_go, h_position_z, position.z)
			go.animate(this_go, h_position, go.PLAYBACK_ONCE_FORWARD, position, go.EASING_INOUTQUART, self.animation_duration, 0, function ()
				dispatcher.dispatch(h_office_object_selected, {
					object_id = message.object_id,
					position = position,
					rotation = rotation,
					scale = scale
				})
			end)
			go.animate(this_go, h_rotation, go.PLAYBACK_ONCE_FORWARD, rotation, go.EASING_INOUTQUART, self.animation_duration)
			go.animate(this_go, h_scale, go.PLAYBACK_ONCE_FORWARD, scale, go.EASING_INOUTQUART, self.animation_duration)
		end
	elseif message_id == h_office_object_deselect and message.object_id == self.object_id then
		local this_go = self.this_go

		go.cancel_animations(this_go, h_position)
		go.cancel_animations(this_go, h_rotation)
		go.cancel_animations(this_go, h_scale)

		local original_position_keep_z = vmath.vector3(self.original_position.x, self.original_position.y, self.intermediary_z)

		go.set(this_go, h_position_z, self.intermediary_z)
		go.animate(this_go, h_position, go.PLAYBACK_ONCE_FORWARD, original_position_keep_z, go.EASING_INOUTQUART, self.animation_duration, 0, function ()
			dispatcher.dispatch(h_office_object_deselected, {
				object_id = message.object_id
			})
			go.set(this_go, h_position_z, self.original_position.z)
		end)
		go.animate(this_go, h_rotation, go.PLAYBACK_ONCE_FORWARD, self.original_rotation, go.EASING_INOUTQUART, self.animation_duration)
		go.animate(this_go, h_scale, go.PLAYBACK_ONCE_FORWARD, self.original_scale, go.EASING_INOUTQUART, self.animation_duration)
	end
end
