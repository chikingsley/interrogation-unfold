function _env:init()
	self.sprite1 = msg.url("critique#sprite")
	self.sprite2 = msg.url("mixtvision#sprite")

	go.set(self.sprite1, "tint.w", 0)
	go.set(self.sprite2, "tint.w", 0)

	local scale = go.get_scale()

	go.set_scale(vmath.vector3(0.7, 0.7, 1))
	timer.delay(0, false, function ()
		go.animate(self.sprite1, "tint.w", go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_OUTSINE, 2, 2)
		go.animate(self.sprite2, "tint.w", go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_OUTSINE, 2, 2)
		go.animate(".", "scale", go.PLAYBACK_ONCE_FORWARD, scale, go.EASING_LINEAR, 5.5, 0)
	end)
end
