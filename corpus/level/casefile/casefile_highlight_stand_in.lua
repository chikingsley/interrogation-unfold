local dispatcher = require("crit.dispatcher")
local h_level_highlight_set_enabled = hash("level_highlight_set_enabled")
local h_level_casefile_stand_in_set_enabled = hash("level_casefile_stand_in_set_enabled")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_casefile = hash("casefile")
local h_highlight_sprite_stand_in = hash("highlight_sprite_stand_in")

function _env:init()
	local sprite_url = msg.url()
	sprite_url = msg.url(sprite_url.socket, sprite_url.path, h_highlight_sprite_stand_in)
	self.sprite = sprite_url
	self.highlight_enabled = false
	self.stand_in_enabled = false

	msg.post(self.sprite, h_disable)

	self.sub_id = dispatcher.subscribe({
		h_level_highlight_set_enabled,
		h_level_casefile_stand_in_set_enabled
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function set_enabled(self)
	local enabled = self.highlight_enabled or self.stand_in_enabled

	msg.post(self.sprite, enabled and h_enable or h_disable)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_level_highlight_set_enabled then
		if message.object_id == h_casefile then
			self.highlight_enabled = message.enabled

			set_enabled(self)
		end
	elseif message_id == h_level_casefile_stand_in_set_enabled then
		self.stand_in_enabled = message.enabled

		set_enabled(self)
	end
end
