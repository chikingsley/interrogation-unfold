local scenes = require("main.progression.scenes")

return scenes.skippable(function ()
	scenes.load_scene("difficulty_select")
	scenes.wait_for_end_scene()
end)
