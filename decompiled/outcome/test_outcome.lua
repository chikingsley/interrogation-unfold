local scenes = require("main.progression.scenes")

return function (args)
	scenes.load_scene("outcome", type(args) == "string" and {
		outcome_id = args
	} or args)
	scenes.wait_for_end_scene()
	scenes.run_progression("main")
end
