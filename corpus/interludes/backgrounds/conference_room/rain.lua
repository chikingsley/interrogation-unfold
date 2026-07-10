local h_rotation = hash("rotation")
local rotate_rain_particles = nil

function _env:init()
	self.rain_go = msg.url(".")

	particlefx.play(msg.url("#rain"))
end

function _env:update(dt)
	rotate_rain_particles(self, -5, 10)
end

local function deg_to_rad(deg)
	return math.pi / 180 * deg
end

function rotate_rain_particles(self, offset_deg, randomization_deg)
	local rotation = vmath.quat_rotation_z(deg_to_rad(offset_deg) + deg_to_rad(randomization_deg) * (math.random() - 0.5))

	go.set(self.rain_go, h_rotation, rotation)
end
