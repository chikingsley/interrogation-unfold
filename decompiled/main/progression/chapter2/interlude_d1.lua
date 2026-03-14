local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen", "tab", "mordecai", "tristan", "chief")
		fui.wait(2)
		fui.show_character("jen", "LEFT_CENTER", "mega_dissapointed")
		fui.show_character("tab", "RIGHT_CENTER", "aback")
		fui.show_character("mordecai", "RIGHT", "hips")
		fui.wait(1)
		fui.text("mordecai", "thinking", intl("80035d.interlude_d1.6d6835"))
		fui.text("jen", "explain_angry", intl("80035d.interlude_d1.826000"))

		if fui.var_get("insanity") >= 4 then
			local choice14 = fui.choose({
				intl("80035d.interlude_d1.0196d6"),
				intl("80035d.interlude_d1.5d337a")
			})

			if choice14 == 1 then
				fui.var_decrement("tab_approval", 5)
				fui.var_decrement("jen_approval", 5)
				fui.var_increment("justice", 2)
				fui.animate("jen", "mega_dissapointed")
				fui.animate("tab", "defensive")
			elseif choice14 == 2 then
				fui.var_decrement("jen_approval", 5)
				fui.var_decrement("mordecai_approval", 5)
				fui.var_increment("evolution", 1)
				fui.animate("jen", "mega_dissapointed")
				fui.animate("mordecai", "thinking")
			end

			fui.hide_bubbles()
			fui.wait(2)
		end

		fui.text("mordecai", "thinking", intl("80035d.interlude_d1.127763"))
		fui.text("mordecai", "explain", intl("80035d.interlude_d1.cd3da8"))
		fui.text("tab", "indignant", intl("80035d.interlude_d1.3763e0"))
		fui.text("tab", "indignant", intl("80035d.interlude_d1.58fcab"))
		fui.animate("mordecai", "hips")

		local choice44 = fui.choose({
			intl("80035d.interlude_d1.5e4c3e"),
			intl("80035d.interlude_d1.9cb0ca"),
			intl("80035d.interlude_d1.b01e0e")
		})

		if choice44 == 1 then
			fui.hide_bubbles()
			fui.animate("jen", "normal")
			fui.animate("tab", "disgust")
			fui.animate("mordecai", "normal")
			fui.var_increment("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
			fui.var_decrement("mordecai_approval", 0)
			fui.var_increment("freedom", 1)
		elseif choice44 == 2 then
			fui.hide_bubbles()
			fui.animate("jen", "normal")
			fui.animate("tab", "normal")
			fui.animate("mordecai", "normal")
			fui.var_increment("jen_approval", 0)
			fui.var_decrement("tab_approval", 0)
			fui.var_increment("mordecai_approval", 5)
			fui.var_increment("evolution", 1)
			fui.var_increment("lawful", 1)
		elseif choice44 == 3 then
			fui.hide_bubbles()
			fui.animate("jen", "explain_angry")
			fui.animate("tab", "listening")
			fui.animate("mordecai", "normal")
			fui.var_decrement("jen_approval", 5)
			fui.var_increment("tab_approval", 5)
			fui.var_decrement("mordecai_approval", 0)
			fui.var_increment("justice", 1)
			fui.var_increment("equity", 1)
		end

		fui.wait(2)
		fui.show_character("chief", "LEFT", "worried")
		fui.wait(1)
		fui.text("chief", "thinking", intl("80035d.interlude_d1.b42bc8"))
		fui.text("chief", "thinking", intl("80035d.interlude_d1.458a66"))
		fui.wait_for_input()
		fui.hide_character("jen")
		fui.hide_character("tab")
		fui.hide_character("mordecai")
		fui.wait(1)
		fui.text("chief", "asking", intl("80035d.interlude_d1.f7a73e"))
		fui.wait_for_input()
		fui.hide_bubbles()
		fui.show_character("tristan", "RIGHT", "normal")
		fui.wait(1)
		fui.text("tristan", "normal", intl("80035d.interlude_d1.2e7eb9"))
		fui.text("tristan", "explain", intl("80035d.interlude_d1.261c87"))
		fui.animate("chief", "thinking")
		fui.text("tristan", "arms_crossed", intl("80035d.interlude_d1.55dee6"))
		fui.text("tristan", nil, intl("80035d.interlude_d1.878488"))
		fui.text("tristan", "glasses", intl("80035d.interlude_d1.87d29e"))
		fui.animate("chief", "normal")

		local choice112 = fui.choose({
			intl("80035d.interlude_d1.320fb3"),
			intl("80035d.interlude_d1.890ac9"),
			intl("80035d.interlude_d1.8f7b6f")
		})

		if choice112 == 1 then
			fui.hide_bubbles()
			fui.animate("chief", "thinking")
			fui.var_increment("authorities", 5)
			fui.var_increment("lawful", 1)
		elseif choice112 == 2 then
			fui.hide_bubbles()
			fui.animate("tristan", "arms_crossed")
			fui.animate("chief", "normal")
			fui.var_increment("authorities", 0)
			fui.var_increment("tab_approval", 5)
		elseif choice112 == 3 then
			fui.set("d1_money")
			fui.hide_bubbles()
			fui.animate("tristan", "arms_crossed")
			fui.animate("chief", "fuck_it")
			fui.var_decrement("authorities", 5)
			fui.var_increment("budget", 1000)
		end

		fui.wait(2)

		if fui.var_get("d1_money") then
			fui.text("tristan", "thumbs_up", intl("80035d.interlude_d1.83fee2"))
			fui.animate("chief", "normal")
		end

		fui.text("tristan", "arms_crossed", intl("80035d.interlude_d1.558b29"))
		fui.animate("chief", "normal")

		local choice145 = fui.choose({
			intl("80035d.interlude_d1.188b7f"),
			intl("80035d.interlude_d1.2fd0da"),
			intl("80035d.interlude_d1.85cd09")
		})

		if choice145 == 1 then
			fui.hide_bubbles()
			fui.animate("tristan", "thumbs_up")
			fui.animate("chief", "thinking")
			fui.var_increment("authorities", 5)
			fui.var_decrement("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
			fui.var_increment("lawful", 1)
		elseif choice145 == 2 then
			fui.hide_bubbles()
			fui.animate("tristan", "normal")
			fui.animate("chief", "normal")
			fui.var_increment("authorities", 0)
			fui.var_increment("tab_approval", 5)
			fui.var_increment("evolution", 1)
			fui.var_increment("equity", 1)
			fui.var_increment("freedom", 1)
		elseif choice145 == 3 then
			fui.hide_bubbles()
			fui.animate("tristan", "arms", "crossed.")
			fui.animate("chief", "cplm")
			fui.var_decrement("authorities", 5)
			fui.var_increment("justice", 1)
		end

		fui.wait(2)
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
