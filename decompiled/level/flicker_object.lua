local dispatcher = require("crit.dispatcher")
local light_flicker = require("level.light_flicker")
local h_light_flicker_animate = hash("light_flicker_animate")
local h_init_level = hash("init_level")
local h_tint = hash("tint")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_light_flicker_animate
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		self.sprites = light_flicker.animated_sprites[self.collection_name]
		self.sprite_urls = {}

		for i, sprite in ipairs(self.sprites) do
			local sprite_url = msg.url(sprite)
			self.sprite_urls[i] = sprite_url

			if message.level ~= "episode0" then
				go.cancel_animations(sprite_url, h_tint)
				go.set(sprite_url, h_tint, light_flicker.default_object_tint_dark)
			end
		end
	elseif message_id == h_light_flicker_animate then
		for i, sprite_url in pairs(self.sprite_urls) do
			go.cancel_animations(sprite_url, h_tint)

			local is_background_sprite = self.is_background and (sprite_url == msg.url("#sprite") or sprite_url == msg.url("waterboard#sprite"))
			local tint = is_background_sprite and message.background_tint or message.object_tint

			go.animate(sprite_url, h_tint, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, message.duration, message.delay)
		end
	end
end
