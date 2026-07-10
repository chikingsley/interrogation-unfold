local scenes = require("main.progression.scenes")
local perks = require("campaign.perks")
local level_interface = require("level.interface")
local dispatcher = require("crit.dispatcher")

return function ()
	perks.reset()
	scenes.load_scene("level", {
		level = "episode1",
		hidden_subjects = {
			2
		}
	})
	level_interface.add_time_callback(10, function ()
		print("10 second mark")
		dispatcher.dispatch("show_subject", {
			subject_id = 2
		})
	end)

	local outcome = scenes.wait_for_end_scene()

	scenes.load_scene("outcome", {
		outcome_id = "outcome_old",
		outcome = outcome
	})
	scenes.wait_for_end_scene()
	scenes.load_scene("menu")
end
