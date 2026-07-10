local configure_cutscene = require("spine_cutscene.config")

configure_cutscene({
	models = {
		orbit1 = {},
		orbit2 = {
			slot = "my_bone",
			parent = "orbit1"
		}
	}
})

function _env:init()
	local fx = msg.url("rain#rain")
	local drops = msg.url("drops#drops")
	local smoke = msg.url("smonk#smoke")

	particlefx.play(fx)
	particlefx.play(drops)
	particlefx.play(smoke)
end
