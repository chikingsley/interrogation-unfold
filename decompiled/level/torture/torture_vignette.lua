local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local h_torture_room_hide = hash("torture_room_hide")
local h_torture_room_show = hash("torture_room_show")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_contrast = hash("contrast")
local h_contrast_variance = hash("contrast_variance")
local h_tint = hash("tint")
local h_vignette_set = hash("vignette_set")
local duration = 1

function _env:init()
	local vig = msg.url("#vignette")
	self.vig = vig
	self.tint = go.get(vig, h_tint)
	self.contrast = go.get(vig, h_contrast)
	self.contrast_variance = go.get(vig, h_contrast_variance)
	self.sub_id = dispatcher.subscribe({
		h_torture_room_hide,
		h_torture_room_show,
		h_pause,
		h_resume
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function animate_to(self, tint, contrast, contrast_variance)
	local vig = self.vig

	go.cancel_animations(vig, h_contrast)
	go.cancel_animations(vig, h_contrast_variance)

	local playback = go.PLAYBACK_ONCE_FORWARD

	dispatcher.dispatch(h_vignette_set, {
		tint = tint,
		duration = duration,
		easing = go.EASING_LINEAR
	})
	go.animate(vig, h_contrast, playback, contrast, go.EASING_LINEAR, duration)
	go.animate(vig, h_contrast_variance, playback, contrast_variance, go.EASING_LINEAR, duration)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_torture_room_show then
		animate_to(self, self.torture_tint, self.torture_contrast, self.torture_contrast_variance)
	elseif message_id == h_torture_room_hide then
		animate_to(self, self.tint, self.contrast, self.contrast_variance)
	elseif message_id == h_pause then
		animate_to(self, vmath.vector4(0), self.contrast, self.contrast_variance)
	elseif message_id == h_resume then
		if state.torture_room_shown then
			animate_to(self, self.torture_tint, self.torture_contrast, self.torture_contrast_variance)
		else
			animate_to(self, self.tint, self.contrast, self.contrast_variance)
		end
	end
end
