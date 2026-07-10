local dispatcher = require("crit.dispatcher")
local h_interludes_show_choices = hash("interludes_show_choices")
local h_interludes_choice_picked = hash("interludes_choice_picked")
local h_show = hash("show")
local h_hide = hash("hide")

function _env:init()
	self.spine_scene = msg.url("#spine")

	spine.play_anim(self.spine_scene, h_show, go.PLAYBACK_ONCE_FORWARD)

	self.sub_id = dispatcher.subscribe({
		h_interludes_show_choices,
		h_interludes_choice_picked
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_interludes_choice_picked then
		spine.play_anim(self.spine_scene, h_hide, go.PLAYBACK_ONCE_FORWARD)
	end
end
