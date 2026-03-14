local dispatcher = require("crit.dispatcher")
local office_animations = require("campaign.office.office_animations")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_agent_files = hash("agent_files")
local frame_count = #office_animations.animations[h_agent_files].frames

function _env:init()
	self.sprite = msg.url("#sprite_animation")
	self.cursor = 1
	self.target_frame = 1
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
		if message.object_id == self.object_id then
			msg.post(self.sprite, h_sprite_play_animation, {
				skip_last_frame = true,
				continue = true,
				id = h_agent_files,
				target_frame = frame_count
			})
		end
	elseif message_id == h_office_object_deselect and message.object_id == self.object_id then
		msg.post(self.sprite, h_sprite_play_animation, {
			continue = true,
			target_frame = 1,
			id = h_agent_files
		})
	end
end
