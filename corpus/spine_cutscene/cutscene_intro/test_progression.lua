local scenes = require("main.progression.scenes")

return function ()
	scenes.load_scene("spine_cutscene", {
		cutscene = "cutscene_intro"
	})
	scenes.wait_for_end_scene()
	scenes.load_scene("menu")
end
