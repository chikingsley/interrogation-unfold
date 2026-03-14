local dispatcher = require("crit.dispatcher")
local h_lore_card_advance = hash("lore_card_advance")
local h_tintw = hash("tint.w")
local h_position = hash("position")
local h_scale = hash("scale")
local init_x_offset = 200
local animation_duration = 1

function _env:init()
	local this_go = msg.url(".")
	local this_sprite = msg.url("#sprite")
	local original_pos = go.get(this_go, h_position)

	go.set(this_sprite, h_tintw, 0)
	go.set(this_go, h_scale, vmath.vector3(self.scale, self.scale, 1))
	go.set(this_go, h_position, vmath.vector3(original_pos.x + init_x_offset, original_pos.y, original_pos.z))
	go.animate(this_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, animation_duration)
	go.animate(this_go, h_position, go.PLAYBACK_ONCE_FORWARD, original_pos, go.EASING_OUTCUBIC, animation_duration)

	self.this_go = this_go
	self.this_sprite = this_sprite
	self.original_pos = original_pos
	self.sub_id = dispatcher.subscribe({
		h_lore_card_advance
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_lore_card_advance then
		local original_pos = self.original_pos

		go.animate(self.this_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, animation_duration, 0, function ()
			go.delete()
		end)

		local pos_to = vmath.vector3(original_pos.x + init_x_offset, original_pos.y, original_pos.z)

		go.animate(self.this_go, h_position, go.PLAYBACK_ONCE_FORWARD, pos_to, go.EASING_INCUBIC, animation_duration)
	end
end
