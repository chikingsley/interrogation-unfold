local dispatcher = require("crit.dispatcher")
local env = require("lib.environment")
local debug = env.debug or not env.bundled
local h_play_animation_sfx = hash("play_animation_sfx")

function _env:init()
	self.time_elapsed = 0
	self.sub_id = dispatcher.subscribe({
		h_play_animation_sfx
	})

	if not debug or not self.enabled then
		go.delete(".", true)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:update(dt)
	local time_elapsed = self.time_elapsed
	time_elapsed = time_elapsed + dt
	local text = math.floor(time_elapsed * 100) / 100

	label.set_text(msg.url("#timer"), text)

	self.time_elapsed = time_elapsed
end

function _env:on_message(message_id, message, sender)
	if message_id == h_play_animation_sfx then
		self.time_elapsed = 0
	end
end
