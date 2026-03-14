local title = require("title.interface")
local snapshot = require("campaign.snapshot")
local scenes = require("main.progression.scenes")
local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local intl = require("crit.intl")
local variables = require("campaign.variables")
local sound_util = require("sound.util")
intl = intl.namespace("campaign")
local intro_func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("tab")
		fui.wait(2)
		fui.show_character("tab", "LEFT", "normal")
		fui.wait(1)
		fui.text("tab", "defensive", intl("80035d.hannigan2_intro.630f78"))
		fui.text("tab", "normal", intl("80035d.hannigan2_intro.c94fc7"))
		fui.text("tab", "normal", intl("80035d.hannigan2_intro.b32213"))

		local choice13 = fui.choose({
			intl("80035d.hannigan2_intro.ed9a18"),
			intl("80035d.hannigan2_intro.402410")
		})

		if choice13 == 1 then
			fui.var_increment("press", 5)
			fui.var_increment("lawful", 1)
		elseif choice13 == 2 then
			fui.var_increment("tab_approval", 5)
			fui.var_increment("jen_approval", 5)
			fui.var_increment("mordecai_approval", 5)
			fui.var_increment("joseph_approval", 5)
			fui.set("hannigan2")
		end

		fui.hide_bubbles()
		fui.wait(1)
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()
local hannigan_func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("hannigan")

		if fui.var_get("has_joseph") then
			fui.load_characters("jen", "tab", "mordecai", "joseph")
		else
			fui.load_characters("jen", "tab", "mordecai")
		end

		fui.wait(2)
		fui.show_character("jen", "LEFT_CENTER", "normal_smile")
		fui.show_character("tab", "LEFT", "normal")
		fui.show_character("mordecai", "RIGHT", "proud")

		if fui.var_get("has_joseph") then
			fui.show_character("joseph", "RIGHT_CENTER", "neutral")
		end

		fui.wait(1)
		fui.text("mordecai", "thinking", intl("80035d.hannigan2.19e868"))
		fui.text("tab", "listening", intl("80035d.hannigan2.94a600"))
		fui.animate("mordecai", "proud")

		if fui.var_get("has_joseph") then
			fui.text("joseph", "concern", intl("80035d.hannigan2.93d69c"))
			fui.wait_for_input()
			fui.animate("joseph", "neutral")
		else
			fui.text("jen", "explain", intl("80035d.hannigan2.408b57"))
			fui.wait_for_input()
			fui.animate("jen", "normal_smile")
		end

		fui.text("tab", "indignant", intl("80035d.hannigan2.57c661"))
		fui.text("tab", "asking", intl("80035d.hannigan2.9f7740"))
		fui.text("tab", "asking", intl("80035d.hannigan2.0ddbd7"))
		fui.text("mordecai", "proud", intl("80035d.hannigan2.75a884"))
		fui.text("tab", "explain", intl("80035d.hannigan2.73d3ac"))

		if fui.var_get("has_joseph") then
			fui.text("joseph", "smile", intl("80035d.hannigan2.d92fbc"))
		else
			fui.text("jen", "pointing_smile", intl("80035d.hannigan2.885a89"))
		end

		fui.animate("tab", "normal")
		fui.unset("kmk_chief")
		fui.unset("kmk_patricia")
		fui.unset("kmk_tristan")

		local choice52 = fui.choose({
			intl("80035d.hannigan2.78412f"),
			intl("80035d.hannigan2.d8b1c7"),
			intl("80035d.hannigan2.7aaa67")
		})

		if choice52 == 1 then
			fui.var_set("kmk_chief", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "mega_happy")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
			fui.var_increment("jen_approval", 5)
		elseif choice52 == 2 then
			fui.var_set("kmk_patricia", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "point")
			fui.var_increment("mordecai_approval", 5)
		elseif choice52 == 3 then
			fui.var_set("kmk_tristan", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
		end

		if fui.var_get("has_joseph") then
			fui.animate("joseph", "neutral")
		end

		local choice82 = fui.choose({
			not fui.var_get("kmk_chief") and intl("80035d.hannigan2.0cb20c") or nil,
			not fui.var_get("kmk_patricia") and intl("80035d.hannigan2.c7eea9") or nil,
			not fui.var_get("kmk_tristan") and intl("80035d.hannigan2.1f0404") or nil
		})

		if choice82 == 1 then
			fui.var_set("kmk_chief", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
		elseif choice82 == 2 then
			fui.var_set("kmk_patricia", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
			fui.var_increment("jen_approval", 5)
		elseif choice82 == 3 then
			fui.var_set("kmk_tristan", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
			fui.var_increment("tab_approval", 5)
		end

		local choice107 = fui.choose({
			not fui.var_get("kmk_chief") and intl("80035d.hannigan2.6a4cef") or nil,
			not fui.var_get("kmk_patricia") and intl("80035d.hannigan2.4dc675") or nil,
			not fui.var_get("kmk_tristan") and intl("80035d.hannigan2.f88772") or nil
		})

		if choice107 == 1 then
			fui.var_set("kmk_chief", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
			fui.var_decrement("tab_approval", 5)
		elseif choice107 == 2 then
			fui.var_set("kmk_patricia", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "normal")
			fui.var_decrement("mordecai_approval", 5)
		elseif choice107 == 3 then
			fui.var_set("kmk_tristan", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
			fui.var_decrement("jen_approval", 5)
		end

		fui.text("jen", "pointing_smile", intl("80035d.hannigan2.3039dd"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()
local intro = scenes.skippable(function ()
	intro_func(fui.new())
end)
local slide = scenes.skippable(function ()
	if variables.hannigan2 then
		sound_util.set_music()
		title.show_slides({
			intl("hannigan.later_that_night")
		})
	end
end)
local hannigan = scenes.skippable(function ()
	if variables.hannigan2 then
		sound_util.set_preset_music("hannigan", {
			random_start_position = 180
		})
		hannigan_func(fui.new())
	end
end)

return function ()
	return snapshot.segment("hannigan2", {
		{
			"intro",
			intro
		},
		{
			"slide",
			slide,
			no_save = true
		},
		{
			"hannigan",
			hannigan
		}
	})
end
