local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local h_table_set_position = hash("table_set_position")
local h_init_level = hash("init_level")
local h_tintw = hash("tint.w")
local original_background_pos, original_fx_pos = nil

function _env:init()
	self.go = msg.url(".")
	self.sprite = msg.url("#sprite")
	self.dust_fx = msg.url("dust#dust_particles")
	original_background_pos = go.get_position(self.go)

	go.set(self.sprite, h_tintw, self.on_record_alpha)

	self.sub_id = dispatcher.subscribe({
		h_table_set_position,
		h_init_level
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_table_set_position then
		local x = state.table_position.x
		local offset = state.offset

		go.set_position(vmath.vector3(x, 0, 0) + original_background_pos, self.go)
		go.set(self.sprite, h_tintw, self.on_record_alpha * offset + self.off_record_alpha * (1 - offset))
	elseif message_id == h_init_level then
		particlefx.play(self.dust_fx)
	end
end
