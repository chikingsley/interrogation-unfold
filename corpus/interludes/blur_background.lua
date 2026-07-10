local dispatcher = require("crit.dispatcher")
local slots = require("interludes.slots")
local h_interludes_show_character = hash("interludes_show_character")
local h_interludes_hide_character = hash("interludes_hide_character")
local h_interludes_hide_all_characters = hash("interludes_hide_all_characters")
local h_interludes_blur_enable = hash("interludes_blur_enable")
local h_interludes_blur_disable = hash("interludes_blur_disable")

function _env:init()
	self.enabled = false
	self.sub_id = dispatcher.subscribe({
		h_interludes_show_character,
		h_interludes_hide_character,
		h_interludes_hide_all_characters
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_interludes_show_character or message_id == h_interludes_hide_character or message_id == h_interludes_hide_all_characters then
		local scene_should_blur = not not next(slots.char_in_slot)

		if scene_should_blur == self.enabled then
			return
		end

		self.enabled = scene_should_blur

		dispatcher.dispatch(scene_should_blur and h_interludes_blur_enable or h_interludes_blur_disable)
	end
end
