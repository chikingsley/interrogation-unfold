local dispatcher = require("crit.dispatcher")
local h_update_insanity_question = hash("update_insanity_question")
local h_brightcon_set = hash("brightcon_set")
local h_brightcon_animation_end = hash("brightcon_animation_end")

function _env:init()
	self.tag = math.random()

	dispatcher.dispatch(h_brightcon_set, {
		duration = 0.5,
		brightness = self.brightness,
		contrast = self.contrast,
		saturation = self.saturation,
		easing = go.EASING_LINEAR
	})

	self.sub_id = dispatcher.subscribe({
		h_update_insanity_question
	})
end

function _env:final()
	dispatcher.dispatch(h_brightcon_set, {
		brightness = 0,
		saturation = 1,
		contrast = 1,
		duration = 0.5,
		easing = go.EASING_LINEAR
	})
	dispatcher.unsubscribe(self.sub_id)
end

local function variance(base, variance_amount)
	return base + (math.random() * 2 - 1) * variance_amount
end

local function pulsate_contrast(self)
	local target = variance(self.target_contrast, self.contrast_variance)
	local duration = variance(self.pulse_duration, self.pulse_variance)

	dispatcher.dispatch(h_brightcon_set, {
		contrast = target,
		duration = duration,
		easing = go.EASING_LINEAR,
		tag = self.tag
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_update_insanity_question then
		local target = message.shown and self.target_contrast or self.contrast

		dispatcher.dispatch(h_brightcon_set, {
			contrast = target,
			duration = self.transition_duration,
			easing = go.EASING_LINEAR,
			tag = message.shown and self.tag or nil
		})
	elseif message_id == h_brightcon_animation_end and message.tag == self.tag then
		pulsate_contrast(self)
	end
end
