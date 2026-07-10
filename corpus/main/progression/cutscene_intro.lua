local scenes = require("main.progression.scenes")
local sound_util = require("sound.util")

return scenes.skippable(function ()
	sound_util.set_music(nil)
	scenes.load_scene("spine_cutscene", {
		cutscene = "cutscene_intro"
	}, {
		no_in_zoom = true
	})
	scenes.wait_for_end_scene()
end)
