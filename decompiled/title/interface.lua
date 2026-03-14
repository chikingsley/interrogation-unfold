local scenes = require("main.progression.scenes")
local slides_ = require("title.slides")
local title = {
	show_slides = function (slides, opts, transition_options)
		slides_.set_slides(slides)
		scenes.load_scene("title", opts, transition_options)
		scenes.wait_for_end_scene()
	end
}

return title
