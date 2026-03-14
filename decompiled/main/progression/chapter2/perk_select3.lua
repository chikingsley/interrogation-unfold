local scenes = require("main.progression.scenes")
local office = require("campaign.office")

return scenes.skippable(function ()
	office.configure({
		newspaper = "newspaper3"
	})

	local new_perks = {
		"speed",
		"profiler",
		"intimidation",
		"pacifist",
		"anatomy",
		"ideology",
		"framing",
		"unstable",
		"host",
		"nerves",
		"waterboarding",
		"brutality"
	}

	scenes.load_scene("office", {
		select_count = 1,
		new_perks = new_perks
	})
	scenes.wait_for_end_scene()
end)
