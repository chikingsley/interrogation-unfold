local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local sprites = require("campaign.office.sprites")
local office_animations = require("campaign.office.office_animations")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_sprite_frame_changed = hash("sprite_frame_changed")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_manual = hash("manual")
local h_manual1 = hash("manual1")
local frame_count = #office_animations.animations[h_manual].frames

function _env:init()
	self.sprite = msg.url("manual_container#sprite_animation")
	self.label1 = msg.url("#label1")
	self.label2 = msg.url("#label2")
	self.label3 = msg.url("#label3")

	sprite.play_flipbook(self.label1, intl.select(sprites.manual_label1))
	sprite.play_flipbook(self.label2, intl.select(sprites.manual_label2))
	sprite.play_flipbook(self.label3, intl.select(sprites.manual_label3))

	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_sprite_frame_changed then
		local sent_message_id = message.id == h_manual1 and h_enable or h_disable

		msg.post(self.label1, sent_message_id)
		msg.post(self.label2, sent_message_id)
		msg.post(self.label3, sent_message_id)
	elseif message_id == h_office_object_select then
		if message.object_id == self.object_id then
			msg.post(self.sprite, h_sprite_play_animation, {
				continue = true,
				skip_last_frame = true,
				notify_on_frame_change = true,
				id = h_manual,
				target_frame = frame_count
			})
		end
	elseif message_id == h_office_object_deselect and message.object_id == self.object_id then
		msg.post(self.sprite, h_sprite_play_animation, {
			continue = true,
			notify_on_frame_change = true,
			target_frame = 1,
			id = h_manual
		})
	end
end
