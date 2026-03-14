local dispatcher = require("crit.dispatcher")
local pick = require("crit.pick")
local Layout = require("crit.layout")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_expo_hitbox = hash("office_expo_hitbox")
local h_click = hash("click")
local h_expo = hash("expo")

function _env:init()
	self.selected = false
	self.sprites = {}
	self.sub_id = dispatcher.subscribe({
		h_office_object_selected,
		h_office_object_deselect,
		h_office_expo_hitbox
	})

	msg.post(".", "acquire_input_focus")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_selected then
		if message.object_id == h_expo then
			self.selected = true
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_expo then
			self.selected = false
		end
	elseif message_id == h_office_expo_hitbox then
		self.sprites[message.object_id] = {
			sprite_url = message.sprite_url,
			padding = message.padding
		}
	end
end

function _env:on_input(action_id, action)
	if self.selected and action_id == h_click and action.released then
		local x, y = Layout.action_to_projection(action)

		for i, sprite in pairs(self.sprites) do
			if pick.pick_sprite(sprite.sprite_url, x, y, sprite.padding) then
				return
			end
		end

		dispatcher.dispatch(h_office_object_deselect, {
			object_id = h_expo
		})

		return true
	end
end
