local scenes = require("main.progression.scenes")

return scenes.skippable(function ()
	scenes.load_scene("jigsaw", {
		jigsaw_id = "elevator"
	})
	scenes.wait_for_end_scene()
end)
