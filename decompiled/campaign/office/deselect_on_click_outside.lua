local dispatcher = require("crit.dispatcher")
local pick = require("crit.pick")
local Layout = require("crit.layout")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_object_deselect_attempt = hash("office_object_deselect_attempt")
local h_office_expo_hitbox = hash("office_expo_hitbox")
local h_office_object_acquire_focus = hash("office_object_acquire_focus")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_click = hash("click")

function _env:init()
	self.selected = false
	local padding = self.hitbox_padding
	self.pick_padding = {
		left = padding.x,
		top = padding.y,
		right = padding.z,
		bottom = padding.w
	}
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect
	})
	self.click_is_valid = false

	if self.should_acquire_focus then
		dispatcher.dispatch(h_office_object_acquire_focus, {
			z = go.get_position().z
		})
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if message.object_id == self.object_id then
			if message.expo then
				dispatcher.dispatch(h_office_expo_hitbox, {
					object_id = self.object_id,
					sprite_url = self.sprite_url,
					padding = self.pick_padding
				})
			end

			if not message.cant_close then
				self.selected = true
			end
		end
	elseif message_id == h_office_object_deselect and message.object_id == self.object_id then
		self.click_is_valid = false
		self.selected = false
	end
end

local function deselect(self)
	local message = self.deselect_attempt and h_office_object_deselect_attempt or h_office_object_deselect

	dispatcher.dispatch(message, {
		object_id = self.object_id
	})
end

function _env:on_input(action_id, action)
	if self.selected then
		if action_id == h_gamepad_rpad_right and action.released then
			deselect(self)

			return true
		elseif action_id == h_click and (action.pressed or action.released) then
			local x, y = Layout.action_to_projection(action)

			if not pick.pick_sprite(self.sprite_url, x, y, self.pick_padding) then
				if action.pressed then
					self.click_is_valid = true
				elseif action.released and self.click_is_valid then
					self.click_is_valid = false

					deselect(self)
				end
			end
		end
	end
end
