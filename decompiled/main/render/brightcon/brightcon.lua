local dispatcher = require("crit.dispatcher")
local h_brightcon_set = hash("brightcon_set")

function _env:init()
	self.tag = math.random()

	if self.enabled then
		dispatcher.dispatch(h_brightcon_set, {
			duration = 0.5,
			brightness = self.brightness,
			contrast = self.contrast,
			saturation = self.saturation,
			easing = go.EASING_LINEAR,
			tag = self.tag
		})
	end
end

function _env:final()
	if self.enabled then
		dispatcher.dispatch(h_brightcon_set, {
			brightness = 0,
			saturation = 1,
			contrast = 1,
			duration = 0.5,
			easing = go.EASING_LINEAR,
			tag = self.tag
		})
	end
end
