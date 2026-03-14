local perks = require("campaign.perks")
local office = require("campaign.office")
local scenes = require("main.progression.scenes")

return function ()
	perks.reset()
	perks.add_perk("speed")
	perks.add_perk("anatomy")
	perks.add_perk("pacifist")
	office.configure({
		newspaper = "newspaper1"
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
	scenes.run_progression("main")
end
