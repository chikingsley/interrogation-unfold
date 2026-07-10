local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_outcome_enable_transcript,
		h_outcome_disable_transcript
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_outcome_enable_transcript then
		sound_util.set_music_parameter("Dampen", 1)
	elseif message_id == h_outcome_disable_transcript then
		sound_util.set_music_parameter("Dampen", 0)
	end
end
