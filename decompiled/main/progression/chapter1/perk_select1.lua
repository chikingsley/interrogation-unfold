local scenes = require("main.progression.scenes")
local office = require("campaign.office")

return scenes.skippable(function ()
	office.configure({
		objects = {
			"agent_files",
			"pr_report",
			"manual",
			"perks"
		}
	})
	scenes.load_scene("office", {
		select_count = 1,
		new_perks = {
			"speed",
			"profiler",
			"intimidation",
			"pacifist",
			"ideology"
		}
	})
	scenes.wait_for_end_scene()
end)
