local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_pause = hash("pause")
local h_resume = hash("resume")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_pause,
		h_resume
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_pause then
		if sound_util.music then
			sound_util.music = sound_util.pause_event(sound_util.music)
		end
	elseif message_id == h_resume and sound_util.music and not message.quitting then
		sound_util.music:set_paused(false)
	end
end
