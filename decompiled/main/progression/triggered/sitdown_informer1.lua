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

		if fui.var_get("recruit_informer") == "jen" then
			fui.load_characters("jen", "informer")
			fui.wait(2)
			fui.show_character("jen", "LEFT", "normal")
			fui.wait(1)
			fui.text("jen", "pointing_smile", intl("efd00d.triggered_informer_intro.dc2157"))
			fui.wait_for_input()
			fui.hide_bubbles()
			fui.show_character("informer", "RIGHT", "staring")
			fui.wait(1)
			fui.text("informer", "hands_together", intl("efd00d.triggered_informer_intro.dd764d"))
			fui.text("jen", "pointing", intl("efd00d.triggered_informer_intro.e94d51"))
			fui.animate("informer", "look_down")
			fui.text("jen", "explain", intl("efd00d.triggered_informer_intro.bcc4ea"))
			fui.wait_for_input()
			fui.hide_character("jen")
		elseif fui.var_get("recruit_informer") == "joseph" then
			fui.load_characters("joseph", "informer")
			fui.wait(2)
			fui.show_character("joseph", "LEFT", "neutral")
			fui.wait(1)
			fui.text("joseph", "dismissive", intl("efd00d.triggered_informer_intro.2969af"))
			fui.wait_for_input()
			fui.hide_bubbles()
			fui.show_character("informer", "RIGHT", "staring")
			fui.wait(1)
			fui.text("informer", "hands_together", intl("efd00d.triggered_informer_intro.dd764d"))
			fui.text("joseph", "neutral", intl("efd00d.triggered_informer_intro.e94d51"))
			fui.animate("informer", "look_down")
			fui.text("joseph", "dismissive", intl("efd00d.triggered_informer_intro.bcc4ea"))
			fui.wait_for_input()
			fui.hide_character("joseph")
		elseif fui.var_get("recruit_informer") == "mordecai" then
			fui.load_characters("mordecai", "informer")
			fui.wait(2)
			fui.show_character("mordecai", "LEFT", "normal")
			fui.wait(1)
			fui.text("mordecai", "hips", intl("efd00d.triggered_informer_intro.22c9b7"))
			fui.wait_for_input()
			fui.hide_bubbles()
			fui.show_character("informer", "RIGHT", "staring")
			fui.wait(1)
			fui.text("informer", "hands_together", intl("efd00d.triggered_informer_intro.dd764d"))
			fui.text("mordecai", "gun", intl("efd00d.triggered_informer_intro.e94d51"))
			fui.animate("informer", "look_down")
			fui.text("mordecai", "proud", intl("efd00d.triggered_informer_intro.bcc4ea"))
			fui.wait_for_input()
			fui.hide_character("mordecai")
		elseif fui.var_get("recruit_informer") == "tab" then
			fui.load_characters("tab", "informer")
			fui.wait(2)
			fui.show_character("tab", "LEFT", "normal")
			fui.wait(1)
			fui.text("tab", "asking", intl("efd00d.triggered_informer_intro.bf20c2"))
			fui.wait_for_input()
			fui.hide_bubbles()
			fui.show_character("informer", "RIGHT", "staring")
			fui.wait(1)
			fui.text("informer", "hands_together", intl("efd00d.triggered_informer_intro.dd764d"))
			fui.text("tab", "explain", intl("efd00d.triggered_informer_intro.e94d51"))
			fui.animate("informer", "look_down")
			fui.text("tab", "indignant", intl("efd00d.triggered_informer_intro.bcc4ea"))
			fui.wait_for_input()
			fui.hide_character("tab")
		end

		local choice102 = fui.choose({
			intl("efd00d.triggered_informer_intro.712a55"),
			intl("efd00d.triggered_informer_intro.7b0eea"),
			intl("efd00d.triggered_informer_intro.29d88f")
		})

		if choice102 == 1 then
			fui.text("informer", "scared", intl("efd00d.triggered_informer_intro.e2d2bd"))
		elseif choice102 == 2 then
			fui.text("informer", "scared", intl("efd00d.triggered_informer_intro.c6df7b"))
		elseif choice102 == 3 then
			fui.text("informer", "scared", intl("efd00d.triggered_informer_intro.c66b79"))
		end

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
		level = "sitdown_informer1",
		flags = episode.import_flags({
			"narrative"
		})
	})
	scenes.wait_for_end_scene()
	save_file.set_global("won_sitdown_informer1", true)
	episode.export_flags({
		"mission_cafe",
		"mission_pods"
	})
end)

return function ()
	if env.force_sitdowns or variables.recruit_informer and not variables.recruit_informer_triggered then
		variables.recruit_informer_triggered = true

		intro()
		sitdown()
	end
end
