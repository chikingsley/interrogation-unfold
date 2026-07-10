local h_praying_init = hash("praying_init")
local h_praying_loop = hash("praying_loop")

function _env:init()
	local father_adams_spine = msg.url("father_adams#spinemodel")

	spine.play_anim(father_adams_spine, h_praying_init, go.PLAYBACK_ONCE_FORWARD, {}, function ()
		spine.play_anim(father_adams_spine, h_praying_loop, go.PLAYBACK_LOOP_FORWARD)
	end)
end
