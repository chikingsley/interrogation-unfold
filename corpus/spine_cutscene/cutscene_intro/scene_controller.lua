local dispatcher = require("crit.dispatcher")
local h_ = hash("")
local h_spine_event = hash("spine_event")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_animation = hash("animation")

function _env:init()
	local scene_go = msg.url("scene")
	local main_spine_component = msg.url(scene_go.socket, scene_go.path, self.spine_component1)
	local spine_component2 = nil

	if self.spine_component2 ~= h_ then
		spine_component2 = msg.url(scene_go.socket, scene_go.path, self.spine_component2)
	end

	spine.play_anim(main_spine_component, h_animation, go.PLAYBACK_ONCE_FORWARD)

	if spine_component2 then
		spine.play_anim(spine_component2, h_animation, go.PLAYBACK_ONCE_FORWARD)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_event then
		dispatcher.dispatch(h_spine_cutscene_event, message)
	end
end
