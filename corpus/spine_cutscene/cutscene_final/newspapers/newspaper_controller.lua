local h_position = hash("position")
local h_tintw = hash("tint.w")
local h_animation1 = hash("animation1")
local h_animation2 = hash("animation2")
local h_ = hash("")

function _env:init()
	self.newspaper_go = msg.url("newspaper")
	self.newspaper_sprite = msg.url("newspaper#sprite")

	if self.animate_in then
		go.set(self.newspaper_go, h_position, self.initial_position)
		go.set(self.newspaper_sprite, h_tintw, 0)
		go.animate(self.newspaper_go, h_position, go.PLAYBACK_ONCE_FORWARD, self.final_position, go.EASING_OUTEXPO, self.anim_duration, 0.1)
		go.animate(self.newspaper_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, self.anim_duration, 0.1)
	end

	if self.spine_component ~= h_ then
		local spine_url = msg.url(self.newspaper_go.socket, self.newspaper_go.path, self.spine_component)

		spine.play_anim(spine_url, h_animation1, go.PLAYBACK_ONCE_FORWARD, {}, function ()
			spine.play_anim(spine_url, h_animation2, go.PLAYBACK_LOOP_FORWARD)
		end)
	end
end
