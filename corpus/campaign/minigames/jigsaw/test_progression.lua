local scenes = require("main.progression.scenes")

return function (args)
	args = args or "test_painting"

	scenes.load_scene("jigsaw", type(args) == "string" and {
		jigsaw_id = args
	} or args)
	scenes.wait_for_end_scene()
	scenes.run_progression("main")
end
