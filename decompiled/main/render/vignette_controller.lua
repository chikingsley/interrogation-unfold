local dispatcher = require("crit.dispatcher")
local h_vig_params_x = hash("vig_params.x")
local h_vig_params_y = hash("vig_params.y")
local h_tint = hash("tint")
local h_vignette_set = hash("vignette_set")
local h_vignette_animation_end = hash("vignette_animation_end")

function _env:init()
	self.model = msg.url("#model")

	go.set(self.model, h_tint, vmath.vector4(0))

	self.sub_id = dispatcher.subscribe({
		h_vignette_set
	})
end

local fire_callback = true

local function animate(property, target, model, duration, delay, easing, tag)
	if target then
		go.cancel_animations(model, property)

		if duration then
			local complete_function = fire_callback and function ()
				dispatcher.dispatch(h_vignette_animation_end, {
					tag = tag
				})
			end or nil
			fire_callback = false

			go.animate(model, property, go.PLAYBACK_ONCE_FORWARD, target, easing, duration, delay or 0, complete_function)
		else
			go.set(model, property, target)
		end
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_vignette_set then
		local duration = message.duration
		local delay = message.delay
		local easing = message.easing
		local tag = message.tag
		local model = self.model
		fire_callback = true

		animate(h_vig_params_x, message.brightness, model, duration, delay, easing, tag)
		animate(h_vig_params_y, message.contrast, model, duration, delay, easing, tag)
		animate(h_tint, message.tint, model, duration, delay, easing, tag)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
