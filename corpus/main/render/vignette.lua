local dispatcher = require("crit.dispatcher")
local h_vignette_set = hash("vignette_set")
local h_vignette_animation_end = hash("vignette_animation_end")
local h_pause = hash("pause")
local h_resume = hash("resume")
local play_next_animation = nil
local max = math.max

function _env:init()
	self.tag = math.random()

	dispatcher.dispatch(h_vignette_set, {
		brightness = self.brightness,
		contrast = self.contrast,
		tint = self.tint
	})
	play_next_animation(self)

	self.sub_id = dispatcher.subscribe({
		h_vignette_animation_end,
		h_pause,
		h_resume
	})
end

local function random_float(mean, variance)
	return mean - variance + math.random() * 2 * variance
end

function play_next_animation(self)
	local brightness = random_float(self.brightness, self.brightness_variance)
	local contrast = random_float(self.contrast, self.contrast_variance)
	local duration = max(0.01, random_float(self.animation_interval, self.animation_interval_variance))

	dispatcher.dispatch(h_vignette_set, {
		brightness = brightness,
		contrast = contrast,
		duration = duration,
		easing = go.EASING_INOUTQUAD,
		tag = self.tag
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_vignette_animation_end then
		if message.tag == self.tag then
			play_next_animation(self)
		end
	elseif message_id == h_pause then
		if self.disable_on_pause then
			dispatcher.dispatch(h_vignette_set, {
				delay = 0.3,
				duration = 0.5,
				tint = vmath.vector4(0),
				easing = go.EASING_LINEAR
			})
		end
	elseif message_id == h_resume and self.disable_on_pause then
		dispatcher.dispatch(h_vignette_set, {
			duration = 0,
			tint = self.tint,
			easing = go.EASING_LINEAR
		})
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	dispatcher.dispatch(h_vignette_set, {
		tint = vmath.vector4(0, 0, 0, 0)
	})
end
