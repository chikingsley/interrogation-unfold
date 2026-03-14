function _env:init()
	local dust_particles = msg.url("dust_particles#dust_particles")

	particlefx.play(dust_particles)
end
