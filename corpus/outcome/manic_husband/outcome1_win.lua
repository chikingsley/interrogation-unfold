local play_animation_sequence = nil
local animation_sequence = coroutine.create(function ()
	local i = 1

	while true do
		if i > 3 then
			i = 1
		end

		local string = "breathe" .. i
		i = i + 1

		coroutine.yield(string)
	end
end)

function _env:init()
	play_animation_sequence()
end

function play_animation_sequence()
	local husband = msg.url("husband#spinemodel")
	local sequence_running, anim = coroutine.resume(animation_sequence)

	if sequence_running then
		spine.play_anim(husband, anim, go.PLAYBACK_ONCE_FORWARD, {}, play_animation_sequence)
	end
end
