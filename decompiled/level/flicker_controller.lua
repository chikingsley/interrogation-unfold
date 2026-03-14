local LightFlicker = require("level.light_flicker")
local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local h_init_level = hash("init_level")

function _env:init()
	local collections = {
		hash("background"),
		hash("table")
	}
	local sprites = {
		{
			"#sprite",
			"table_scaled#light",
			"light_glow#sprite",
			"waterboard#sprite"
		},
		{
			"#table",
			"#chair",
			"recorder#sprite",
			"casefile#highlight_sprite_stand_in"
		}
	}
	local object_tint = {
		self.object_tint_dark,
		self.object_tint_light
	}
	local background_tint = {
		self.background_tint_dark,
		self.background_tint_light
	}
	self.sub_id = dispatcher.subscribe({
		h_init_level
	})
	self.light_flicker = LightFlicker.new({
		initial_delay = self.initial_delay,
		duration = self.duration,
		collections = collections,
		sprites = sprites,
		object_tint = object_tint,
		background_tint = background_tint,
		flicker_duration = self.flicker_duration,
		flicker_interval = self.flicker_interval
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:update(dt)
	self.light_flicker:update(dt)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level and store.level_id ~= "episode0" then
		timer.delay(0, false, function ()
			self.light_flicker:start()
		end)
	end
end
