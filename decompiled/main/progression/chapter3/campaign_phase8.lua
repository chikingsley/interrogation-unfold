local scenes = require("main.progression.scenes")
local office = require("campaign.office")
local stats = require("campaign.stats")
local variables = require("campaign.variables")
local M = {
	expo = function ()
		variables.has_hr_report = false
		variables.advanced_pr_report = false

		office.configure({
			newspaper = "newspaper8",
			wall = 9,
			has_briefing_room = false
		})
		scenes.load_scene("office", {
			no_expo = true
		})
		scenes.wait_for_end_scene()
		stats.commit()

		variables.classified_unlocked = false
	end
}

return M
