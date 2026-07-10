function _env:init()
	local particles_smoke1 = msg.url("#smoke1")

	particlefx.play(particles_smoke1)

	local particles_smoke2 = msg.url("#smoke2")

	particlefx.play(particles_smoke2)
end
