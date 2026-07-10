local intl = require("crit.intl")
intl = intl.namespace("chapter3")
local h_background_fade_in = hash("background_fade_in")
local h_scene_fade_out = hash("scene_fade_out")
local h_load_next_scene = hash("load_next_scene")
local h_tint_red = hash("tint_red")
local h_show_text = hash("show_text")
local h_fast_forward = hash("fast_forward")
local h_scene_end = hash("scene_end")
local h_show_newspaper = hash("show_newspaper")
local cutscene_data = {
	ending = 1,
	endings = {
		APOCALYPTIC = 5,
		MARXIST = 3,
		ANCAP = 4,
		GOOD = 1,
		VIGILANTE = 2
	},
	scene_sequences = {
		{
			"1",
			"2a",
			"4a"
		},
		{
			"1",
			"2b",
			"4b"
		},
		{
			"1",
			"2c",
			"3c",
			"4c"
		},
		{
			"1",
			"2c",
			"3d",
			"4d"
		},
		{
			"1",
			"2c",
			"3e",
			"4e"
		}
	},
	transitions = {
		CUT = 3,
		NO_TRANSITION = 0,
		FLASH_WHITE = 1,
		LONG_FADE_OUT = 2
	},
	event_cues = {
		[h_background_fade_in] = "Background Fade In",
		[h_scene_fade_out] = "Scene Fade Out",
		[h_load_next_scene] = "Load Next Scene",
		[h_fast_forward] = "Fast Forward",
		[h_show_text] = "Show Text",
		[h_tint_red] = "Tint Red",
		[h_scene_end] = "Scene End",
		[h_show_newspaper] = "Show Newspaper"
	},
	copy = {
		intl("cutscene.t1"),
		intl("cutscene.t2")
	}
}

return cutscene_data
