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

		fui.load_interlude("street")
		fui.load_characters("mordecai")
		fui.wait(2)
		fui.show_character("mordecai", "RIGHT")
		fui.wait(1)
		fui.text("mordecai", "proud", intl("efd00d.triggered_fred_intro.546670"))
		fui.text("mordecai", "hips", intl("efd00d.triggered_fred_intro.8a19d6"))

		local choice12 = fui.choose({
			intl("efd00d.triggered_fred_intro.e8de6e"),
			intl("efd00d.triggered_fred_intro.adbed5"),
			intl("efd00d.triggered_fred_intro.dc7412")
		})

		if choice12 == 1 then
			fui.hide_bubbles()
			fui.animate("mordecai", "proud")
			fui.wait(1)
			fui.var_increment("mordecai_approval", 5)
			fui.var_increment("lawful", 1)
			fui.var_increment("justice", 1)
			fui.text("mordecai", "proud", intl("efd00d.triggered_fred_intro.ef4fa2"))
			fui.text("mordecai", "proud", intl("efd00d.triggered_fred_intro.bc6610"))
		elseif choice12 == 2 then
			fui.hide_bubbles()
			fui.animate("mordecai", "thinking")
			fui.wait(1)
			fui.var_decrement("mordecai_approval", 5)
			fui.var_increment("lawful", 1)
			fui.var_increment("equity", 1)
			fui.text("mordecai", "explain", intl("efd00d.triggered_fred_intro.b76d42"))
			fui.text("mordecai", "thinking", intl("efd00d.triggered_fred_intro.bc6610"))
		elseif choice12 == 3 then
			fui.hide_bubbles()
			fui.animate("mordecai", "thinking")
			fui.wait(1)
			fui.var_increment("cruelty", 1)
			fui.var_increment("insanity", 1)
			fui.var_increment("justice", 1)
			fui.var_increment("authorities", 5)
			fui.text("mordecai", "thinking", intl("efd00d.triggered_fred_intro.d555f9"))
			fui.text("mordecai", "normal", intl("efd00d.triggered_fred_intro.091e63"))
		end

		fui.wait_for_input()
		fui.hide_bubbles()
		fui.wait(1)
		fui.text("mordecai", "hips", intl("efd00d.triggered_fred_intro.73c758"))
		fui.text("mordecai", "point", intl("efd00d.triggered_fred_intro.df4e66"))
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
		report_findings_key = "level.report_findings.consultation",
		music = "event:/Campaign Music/Interview",
		auto_start_game = 1.5,
		play_music_immediately = true,
		background = "prison",
		hide_intro_button = true,
		music_bank = "Campaign 1.bank",
		level = "sitdown_fred",
		flags = episode.import_flags({
			"narrative",
			"fred-cat"
		})
	})
	scenes.wait_for_end_scene()
	save_file.set_global("won_sitdown_fred", true)
	episode.export_flags({
		"mission_prison",
		"mission_prison_recruitment"
	})
end)

return scenes.skippable(function ()
	if env.force_sitdowns or variables.meet_fred and not variables.meet_fred_triggered then
		variables.meet_fred_triggered = true

		intro()
		sitdown()
	end
end)
