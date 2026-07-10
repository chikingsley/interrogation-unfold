local h_animation = hash("animation")

function _env:init()
	local spine_model = msg.url("running_police#spinemodel")

	spine.play_anim(spine_model, h_animation, go.PLAYBACK_ONCE_FORWARD)
end
