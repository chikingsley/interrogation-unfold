local h_animation_init = hash("animation_init")
local h_animation_loop = hash("animation_loop")

function _env:init()
	local helicopter_cockpit = msg.url("helicopter_cockpit#spinemodel")
	local helicopter_outside = msg.url("helicopter_outside#spinemodel")

	spine.play_anim(helicopter_cockpit, h_animation_init, go.PLAYBACK_ONCE_FORWARD, {}, function ()
		spine.play_anim(helicopter_cockpit, h_animation_loop, go.PLAYBACK_LOOP_FORWARD)
	end)
	spine.play_anim(helicopter_outside, h_animation_init, go.PLAYBACK_ONCE_FORWARD, {}, function ()
		spine.play_anim(helicopter_outside, h_animation_loop, go.PLAYBACK_LOOP_FORWARD)
	end)
end
