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
		fui.load_characters("mordecai")
		fui.wait(2)
		fui.show_character("mordecai", "RIGHT", "normal")
		fui.wait(1)
		fui.text("mordecai", "gun", intl("81039c.hannigan3_intro.120eb8"))

		local choice9 = fui.choose({
			intl("81039c.hannigan3_intro.2d7ed4"),
			intl("81039c.hannigan3_intro.cafc00")
		})

		if choice9 == 1 then
			fui.var_increment("press", 5)
			fui.var_increment("equity", 1)
		elseif choice9 == 2 then
			fui.var_increment("tab_approval", 5)
			fui.var_increment("jen_approval", 5)
			fui.var_increment("mordecai_approval", 5)
			fui.var_increment("joseph_approval", 5)
			fui.var_increment("freedom", 1)
			fui.set("hannigan3")
		end

		fui.hide_bubbles()
		fui.animate("mordecai", "normal")
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
			fui.show_character("joseph", "RIGHT_CENTER", "smile")
		end

		fui.wait(1)

		if fui.var_get("has_joseph") then
			fui.text("joseph", "smile", intl("81039c.hannigan3.32cd22"))
			fui.text("joseph", "smile", intl("81039c.hannigan3.badbad"))
			fui.text("joseph", "concern", intl("81039c.hannigan3.6475d0"))
			fui.text("jen", "explain_smile", intl("81039c.hannigan3.a97cea"))
			fui.text("joseph", "smile", intl("81039c.hannigan3.539ab4"))
		else
			fui.text("mordecai", "thinking", intl("81039c.hannigan3.792760"))
			fui.text("mordecai", "hips", intl("81039c.hannigan3.655347"))
			fui.text("tab", "indignant", intl("81039c.hannigan3.882800"))
			fui.text("jen", "pointing_smile", intl("81039c.hannigan3.b46b7d"))
			fui.text("tab", "normal", intl("81039c.hannigan3.bbe5a4"))
		end

		fui.unset("kmk_jen")
		fui.unset("kmk_tab")
		fui.unset("kmk_mordecai")

		local choice42 = fui.choose({
			intl("81039c.hannigan3.49562e"),
			intl("81039c.hannigan3.f67cf7"),
			intl("81039c.hannigan3.608d98")
		})

		if choice42 == 1 then
			fui.var_set("kmk_jen", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "mega_happy")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_increment("jen_approval", 5)
		elseif choice42 == 2 then
			fui.var_set("kmk_tab", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_increment("tab_approval", 5)
		elseif choice42 == 3 then
			fui.var_set("kmk_mordecai", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "indignant")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_increment("mordecai_approval", 5)
		end

		local choice78 = fui.choose({
			not fui.var_get("kmk_jen") and intl("81039c.hannigan3.9c5514") or nil,
			not fui.var_get("kmk_tab") and intl("81039c.hannigan3.f57b29") or nil,
			not fui.var_get("kmk_mordecai") and intl("81039c.hannigan3.e4fbce") or nil
		})

		if choice78 == 1 then
			fui.var_set("kmk_jen", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "pointing_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_increment("jen_approval", 5)
		elseif choice78 == 2 then
			fui.var_set("kmk_tab", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_increment("tab_approval", 5)
		elseif choice78 == 3 then
			fui.var_set("kmk_mordecai", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_increment("mordecai_approval", 5)
		end

		local choice114 = fui.choose({
			not fui.var_get("kmk_jen") and intl("81039c.hannigan3.c808f7") or nil,
			not fui.var_get("kmk_tab") and intl("81039c.hannigan3.324575") or nil,
			not fui.var_get("kmk_mordecai") and intl("81039c.hannigan3.0832f5") or nil
		})

		if choice114 == 1 then
			fui.var_set("kmk_jen", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_decrement("jen_approval", 5)
		elseif choice114 == 2 then
			fui.var_set("kmk_tab", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "defensive")
			fui.animate("mordecai", "normal")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_decrement("tab_approval", 5)
		elseif choice114 == 3 then
			fui.var_set("kmk_mordecai", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "thinking")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "smile")
			end

			fui.var_decrement("mordecai_approval", 5)
		end

		if fui.var_get("has_joseph") then
			fui.text("tab", "laugh", intl("81039c.hannigan3.be5bd9"))
		else
			fui.text("tab", "laugh", intl("81039c.hannigan3.3d922c"))
		end

		fui.text("jen", "explain_smile", intl("81039c.hannigan3.991553"))
		fui.animate("tab", "normal")
		fui.wait_for_input()
	end
end()
local intro = scenes.skippable(function ()
	intro_func(fui.new())
end)
local slide = scenes.skippable(function ()
	if variables.hannigan3 then
		sound_util.set_music()
		title.show_slides({
			intl("hannigan.later_that_night")
		})
	end
end)
local hannigan = scenes.skippable(function ()
	if variables.hannigan3 then
		sound_util.set_music("event:/Campaign Music/Hannigans", "Campaign 1.bank", {
			random_start_position = 180
		})
		hannigan_func(fui.new())
	end
end)

return function ()
	return snapshot.segment("hannigan3", {
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
