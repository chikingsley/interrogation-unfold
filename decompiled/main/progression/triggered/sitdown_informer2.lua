local scenes = require("main.progression.scenes")
local variables = require("campaign.variables")
local episode = require("main.progression.episode")
local env = require("lib.environment")
local sound_util = require("sound.util")
local save_file = require("lib.save_file")

return scenes.skippable(function ()
	if env.force_sitdowns or variables.contact_informer and not variables.contact_informer_triggered then
		variables.contact_informer_triggered = true

		sound_util.set_music(nil)
		scenes.load_scene("level_lite", {
			play_music_immediately = true,
			music_bank = "Campaign 1.bank",
			report_findings_key = "level.report_findings.consultation",
			hide_intro_button = true,
			music = "event:/Campaign Music/Interview",
			auto_start_game = 1.5,
			level = "sitdown_informer2",
			flags = episode.import_flags({
				"narrative"
			})
		})
		scenes.wait_for_end_scene()
		save_file.set_global("won_sitdown_informer2", true)
		episode.export_flags({
			"mission_circulara",
			"mission_expansion"
		})
	end
end)
