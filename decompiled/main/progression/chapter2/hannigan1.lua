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

		fui.load_interlude("street")
		fui.load_characters("jen")
		fui.wait(2)
		fui.show_character("jen", "RIGHT", "normal")
		fui.wait(1)
		fui.text("jen", "explain_smile", intl("80035d.hannigan1_intro.ddb622"))
		fui.text("jen", "explain", intl("80035d.hannigan1_intro.a3bc94"))
		fui.text("jen", "explain", intl("80035d.hannigan1_intro.e63579"))
		fui.text("jen", "explain_smile", intl("80035d.hannigan1_intro.88f4a0"))

		local choice18 = fui.choose({
			fui.var_get("insanity") >= 3 and intl("80035d.hannigan1_intro.192c34") or nil,
			fui.var_get("insanity") < 3 and intl("80035d.hannigan1_intro.4736e8") or nil,
			intl("80035d.hannigan1_intro.2df069")
		})

		if choice18 == 1 then
			fui.text("jen", "normal_angry", intl("80035d.hannigan1_intro.4a45a5"))
			fui.wait_for_input()
		elseif choice18 == 2 then
			fui.var_increment("authorities", 5)
			fui.animate("jen", "normal_smile")
		elseif choice18 == 3 then
			fui.animate("jen", "normal_smile")
			fui.var_increment("tab_approval", 5)
			fui.var_increment("jen_approval", 5)
			fui.var_increment("mordecai_approval", 5)
			fui.set("hannigan1")
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
		fui.load_characters("jen", "tab", "mordecai")
		fui.wait(2)
		fui.show_character("jen", "LEFT_CENTER", "normal_smile")
		fui.show_character("tab", "LEFT", "normal")
		fui.show_character("mordecai", "RIGHT", "proud")
		fui.wait(1)
		fui.text("jen", "explain_angry", intl("80035d.hannigan1.c985f2"))
		fui.text("mordecai", "proud", intl("80035d.hannigan1.b4a2bd"))
		fui.animate("jen", "normal")
		fui.text("tab", "explain", intl("80035d.hannigan1.179110"))
		fui.text("jen", "explain_smile", intl("80035d.hannigan1.1c8937"))
		fui.animate("tab", "normal")
		fui.text("jen", "mega_happy", intl("80035d.hannigan1.ac5e01"))
		fui.text("tab", "laugh", intl("80035d.hannigan1.22e2ea"))
		fui.animate("jen", "normal_smile")
		fui.text("jen", "normal_smile", intl("80035d.hannigan1.5a38ad"))
		fui.animate("tab", "normal")
		fui.text("mordecai", "point", intl("80035d.hannigan1.b7633d"))
		fui.text("jen", "explain_smile", intl("80035d.hannigan1.ae7830"))
		fui.animate("mordecai", "proud")
		fui.text("tab", "asking", intl("80035d.hannigan1.5ec268"))
		fui.text("jen", "pointing_smile", intl("80035d.hannigan1.bc74cd"))
		fui.unset("kmk_lincoln")
		fui.unset("kmk_ghandi")
		fui.unset("kmk_thatcher")

		local choice40 = fui.choose({
			intl("80035d.hannigan1.d9fbcf"),
			intl("80035d.hannigan1.21d066"),
			intl("80035d.hannigan1.71033f")
		})

		if choice40 == 1 then
			fui.var_set("kmk_lincoln", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "mega_happy")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
			fui.var_increment("jen_approval", 5)
		elseif choice40 == 2 then
			fui.var_set("kmk_ghandi", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "point")
			fui.var_increment("mordecai_approval", 5)
		elseif choice40 == 3 then
			fui.var_set("kmk_thatcher", "kiss")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
		end

		local choice68 = fui.choose({
			not fui.var_get("kmk_lincoln") and intl("80035d.hannigan1.bdebc0") or nil,
			not fui.var_get("kmk_ghandi") and intl("80035d.hannigan1.2b38a5") or nil,
			not fui.var_get("kmk_thatcher") and intl("80035d.hannigan1.bb88fc") or nil
		})

		if choice68 == 1 then
			fui.var_set("kmk_lincoln", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
			fui.var_increment("evolution", 1)
		elseif choice68 == 2 then
			fui.var_set("kmk_ghandi", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "proud")
			fui.var_increment("equity", 1)
		elseif choice68 == 3 then
			fui.var_set("kmk_thatcher", "marry")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
			fui.var_increment("tab_approval", 5)
			fui.var_increment("freedom", 1)
		end

		local choice97 = fui.choose({
			not fui.var_get("kmk_lincoln") and intl("80035d.hannigan1.7c196f") or nil,
			not fui.var_get("kmk_ghandi") and intl("80035d.hannigan1.9d839f") or nil,
			not fui.var_get("kmk_thatcher") and intl("80035d.hannigan1.bba090") or nil
		})

		if choice97 == 1 then
			fui.var_set("kmk_lincoln", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
			fui.var_decrement("mordecai_approval", 5)
		elseif choice97 == 2 then
			fui.var_set("kmk_ghandi", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
			fui.var_decrement("jen_approval", 5)
			fui.var_decrement("equity", 1)
		elseif choice97 == 3 then
			fui.var_set("kmk_thatcher", "kill")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "laugh")
			fui.animate("mordecai", "proud")
			fui.var_decrement("mordecai_approval", 5)
			fui.var_decrement("freedom", 1)
		end

		fui.text("mordecai", "point", intl("80035d.hannigan1.16b8bb"))
		fui.wait_for_input()
	end
end()
local intro = scenes.skippable(function ()
	intro_func(fui.new())
end)
local slide = scenes.skippable(function ()
	if variables.hannigan1 then
		sound_util.set_music()
		title.show_slides({
			intl("hannigan.later_that_night")
		})
	end
end)
local hannigan = scenes.skippable(function ()
	if variables.hannigan1 then
		sound_util.set_preset_music("hannigan", {
			random_start_position = 180
		})
		hannigan_func(fui.new())
	end
end)

return function ()
	return snapshot.segment("hannigan1", {
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
