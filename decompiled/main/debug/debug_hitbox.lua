local dispatcher = require("crit.dispatcher")
local h_scalex = hash("scale.x")
local h_scaley = hash("scale.y")
local h_tint = hash("tint")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_position = hash("position")
local h_debug_hitbox_set_properties = hash("debug_hitbox_set_properties")

function _env:init()
	self.this_go = msg.url(".")
	local this_sprite = msg.url("#sprite")

	go.set(this_sprite, h_tint, vmath.vector4(0, 1, 0, 0.4))
	msg.post(self.this_go, h_disable)

	self.sub_id = dispatcher.subscribe({
		h_debug_hitbox_set_properties
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_debug_hitbox_set_properties and message.object_id == self.object_id then
		msg.post(self.this_go, h_enable)

		local padding = message.hitbox_padding

		go.set(self.this_go, h_scalex, message.size.x + padding.x + padding.z)
		go.set(self.this_go, h_scaley, message.size.y + padding.y + padding.w)

		local pos_offset_x = (padding.z - padding.x) / 2
		local pos_offset_y = (padding.y - padding.w) / 2
		local offset_position = vmath.vector3(pos_offset_x, pos_offset_y, 0.7)

		go.set(self.this_go, h_position, offset_position)
	end
end
