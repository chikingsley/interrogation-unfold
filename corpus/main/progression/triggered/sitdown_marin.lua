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

		if fui.var_get("meet_marin") == "jen" then
			fui.load_characters("jen")
			fui.wait(2)
			fui.show_character("jen", "LEFT", "normal")
			fui.wait(1)
			fui.text("jen", "pointing_smile", intl("efd00d.triggered_professor_intro.450bda"))
			fui.text("jen", "explain_smile", intl("efd00d.triggered_professor_intro.ce7491"))
			fui.text("jen", "normal_smile", intl("efd00d.triggered_professor_intro.05ec93"))
			fui.wait_for_input()
			fui.hide_character("jen")
		elseif fui.var_get("meet_marin") == "joseph" then
			fui.load_characters("joseph")
			fui.wait(2)
			fui.show_character("joseph", "LEFT", "neutral")
			fui.wait(1)
			fui.text("joseph", "dismissive", intl("efd00d.triggered_professor_intro.34db4a"))
			fui.text("joseph", "neutral", intl("efd00d.triggered_professor_intro.51e148"))
			fui.text("joseph", "smile", intl("efd00d.triggered_professor_intro.40617f"))
			fui.wait_for_input()
			fui.hide_character("joseph")
		elseif fui.var_get("meet_marin") == "mordecai" then
			fui.load_characters("mordecai")
			fui.wait(2)
			fui.show_character("mordecai", "LEFT", "normal")
			fui.wait(1)
			fui.text("mordecai", "point", intl("efd00d.triggered_professor_intro.0c392a"))
			fui.text("mordecai", "explain", intl("efd00d.triggered_professor_intro.ba6adb"))
			fui.wait_for_input()
			fui.hide_character("mordecai")
		else
			fui.load_characters("tab")
			fui.wait(2)
			fui.show_character("tab", "LEFT", "normal")
			fui.wait(1)
			fui.text("tab", "asking", intl("efd00d.triggered_professor_intro.8f05f6"))
			fui.text("tab", "explain", intl("efd00d.triggered_professor_intro.bc1f1d"))
			fui.text("tab", "listening", intl("efd00d.triggered_professor_intro.a1ceea"))
			fui.wait_for_input()
			fui.hide_character("tab")
		end
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
		level = "sitdown_marin",
		flags = episode.import_flags({
			"narrative",
			"university_grant",
			"played_episode_6"
		})
	})
	scenes.wait_for_end_scene()
	save_file.set_global("won_sitdown_marin", true)
	episode.export_flags({
		"professor_Torpix",
		"professor_anaba_colonel",
		"professor_anaba_reed",
		"professor_burgundy",
		"professor_collectivist",
		"professor_history",
		"professor_individualist",
		"professor_realist",
		"professor_reed_colonel"
	})
end)

return function ()
	if env.force_sitdowns or variables.meet_marin and not variables.meet_marin_triggered then
		variables.meet_marin_triggered = true

		intro()
		sitdown()
	end
end
