local h_highlight = hash("highlight")
local h_tint = hash("tint")
local h_enable = hash("enable")
local h_disable = hash("disable")
local max = math.max
local vector4 = vmath.vector4
local set_constant = particlefx.set_constant
local post = msg.post

local function update_constants(self)
	local fx = self.fx
	local alpha = max(self.alpha1, self.alpha2)

	set_constant(fx, h_highlight, h_tint, vector4(1, 1, 1, alpha))

	local enabled = alpha > 0

	if enabled ~= self.enabled then
		self.enabled = enabled

		post(fx, enabled and h_enable or h_disable)
	end
end

function _env:init()
	self.enabled = true
	self.fx = msg.url("#highlight_fx")

	particlefx.play(self.fx)
	update_constants(self)
end

update = update_constants
