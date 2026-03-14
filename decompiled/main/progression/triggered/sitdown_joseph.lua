local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local variables = require("campaign.variables")
local env = require("lib.environment")
local episode = require("main.progression.episode")
local sound_util = require("sound.util")
local save_file = require("lib.save_file")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.set_preset_music("campaign")
		fui.load_interlude("office_floor")
		fui.load_characters("mordecai", "joseph")
		fui.wait(2)
		fui.show_character("mordecai", "LEFT", "normal")
		fui.wait(1)
		fui.text("mordecai", nil, intl("efd00d.triggered_joseph_intro.c142ac"))
		fui.wait_for_input()
		fui.hide_bubbles()
		fui.wait(1)
		fui.show_character("joseph", "RIGHT", "neutral")
		fui.text("mordecai", "gun", intl("efd00d.triggered_joseph_intro.3d2610"))
		fui.text("joseph", "concern", intl("efd00d.triggered_joseph_intro.99c894"))
		fui.text("mordecai", "point", intl("efd00d.triggered_joseph_intro.1a39f7"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()
local intro = scenes.skippable(function ()
	func(fui.new())
end)
local sitdown = scenes.skippable(function ()
	sound_util.set_music(nil)
	scenes.load_scene("level_lite", {
		play_music_immediately = true,
		music_bank = "Campaign 1.bank",
		report_findings_key = "level.report_findings.consultation",
		hide_intro_button = true,
		music = "event:/Campaign Music/Interview",
		auto_start_game = 1.5,
		level = "sitdown_joseph",
		flags = episode.import_flags({
			"narrative"
		})
	})
	scenes.wait_for_end_scene()
	save_file.set_global("won_sitdown_joseph", true)
	episode.export_flags({
		"recruited_joseph",
		"mission_criminals"
	})
end)

return function ()
	if env.force_sitdowns or variables.meet_joseph and not variables.meet_joseph_triggered then
		variables.meet_joseph_triggered = true

		intro()
		sitdown()
	end
end
