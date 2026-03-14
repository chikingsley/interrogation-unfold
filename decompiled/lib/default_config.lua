local env = require("lib.environment")

return {
	music_volume = 1,
	gamma = 1,
	master_volume = 1,
	benchmarked = false,
	profile = 1,
	sfx_volume = 1,
	cheats = false,
	cheat_hints = false,
	zoomed_casefile = true,
	commentary = false,
	large_ui_override = false,
	real_time_interrogation = false,
	resolution_scale = 1,
	full_screen = not not env.bundled,
	idle_reset = env.expo and 300 or 0
}
