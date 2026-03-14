local dispatcher = require("crit.dispatcher")
local render_helper = require("lib.render_helper")
local save_file = require("lib.save_file")
local config = save_file.config
local h_bcs_params = hash("bcs_params")
local h_bcs_params_x = hash("bcs_params.x")
local h_bcs_params_y = hash("bcs_params.y")
local h_bcs_params_z = hash("bcs_params.z")
local h_brightcon_set = hash("brightcon_set")
local h_brightcon_animation_end = hash("brightcon_animation_end")
local h_brightcon_setting_update = hash("brightcon_setting_update")

local function adjust_bcs_params(bcs_params)
	return vmath.vector4(bcs_params.x, bcs_params.y * config.gamma, bcs_params.z, 0)
end

function _env:init()
	self.model = msg.url("#model")
	self.bcs_params = vmath.vector4(0, 1, 1, 0)

	go.set(self.model, h_bcs_params, adjust_bcs_params(self.bcs_params))

	render_helper.filter1 = true
	self.sub_id = dispatcher.subscribe({
		h_brightcon_setting_update,
		h_brightcon_set
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)

	render_helper.filter1 = false
end

local fire_callback = true

local function animate(self, property, target, model, duration, easing, tag)
	go.cancel_animations(model, property)

	if duration then
		local complete_function = fire_callback and function ()
			dispatcher.dispatch(h_brightcon_animation_end, {
				tag = tag
			})

			self.animating = false
		end or nil
		fire_callback = false

		go.animate(model, property, go.PLAYBACK_ONCE_FORWARD, target, easing, duration, 0, complete_function)

		self.animating = true
	else
		go.set(model, property, target)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_brightcon_setting_update then
		if not self.animating then
			go.set(self.model, h_bcs_params, adjust_bcs_params(self.bcs_params))
		end
	elseif message_id == h_brightcon_set then
		local duration = message.duration
		local easing = message.easing
		local tag = message.tag
		local model = self.model
		fire_callback = true
		local brightness = message.brightness

		if brightness then
			self.bcs_params.x = brightness

			animate(self, h_bcs_params_x, brightness, model, duration, easing, tag)
		end

		local contrast = message.contrast

		if contrast then
			self.bcs_params.y = contrast
			contrast = contrast * config.gamma

			animate(self, h_bcs_params_y, contrast, model, duration, easing, tag)
		end

		local saturation = message.saturation

		if saturation then
			self.bcs_params.z = saturation

			animate(self, h_bcs_params_z, saturation, model, duration, easing, tag)
		end
	end
end
