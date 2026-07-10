local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("jen", "tab", "mordecai", "chief", "joseph")
		else
			fui.load_characters("jen", "tab", "mordecai", "chief")
		end

		fui.wait(2)
		fui.show_character("jen", "LEFT_CENTER")
		fui.show_character("mordecai", "RIGHT")

		if fui.var_get("has_joseph") then
			fui.show_character("joseph", "CENTER_RIGHT")
			fui.show_character("tab", "RIGHT_CENTER")
		else
			fui.show_character("tab", "RIGHT_CENTER")
		end

		fui.show_character("chief", "LEFT")
		fui.wait(1)
		fui.text("jen", "pointing_angry", intl("81039c.interlude_h3.31ae94"))

		local choice21 = fui.choose({
			intl("81039c.interlude_h3.537a99"),
			intl("81039c.interlude_h3.4aaa10"),
			intl("81039c.interlude_h3.409cf1")
		})

		if choice21 == 1 then
			fui.hide_bubbles()
			fui.animate("jen", "normal_angry")
			fui.animate("tab", "indignant")
			fui.animate("mordecai", "normal")
			fui.animate("chief", "normal")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "dismissive")
				fui.var_increment("joseph_approval", 5)
			end

			fui.var_increment("mordecai_approval", 5)
			fui.var_increment("justice", 1)
		elseif choice21 == 2 then
			fui.hide_bubbles()
			fui.animate("jen", "mega_dissapointed")
			fui.animate("tab", "aback")
			fui.animate("mordecai", "hips")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "sad")
			end

			fui.animate("chief", "thinking")
			fui.var_increment("tab_approval", 5)
			fui.var_increment("jen_approval", 5)
			fui.var_increment("lawful", 1)
		elseif choice21 == 3 then
			fui.hide_bubbles()
			fui.animate("jen", "normal_angry")
			fui.animate("tab", "defensive")
			fui.animate("mordecai", "hips")
			fui.animate("chief", "smiling")

			if fui.var_get("has_joseph") then
				fui.animate("joseph", "concern")
			end

			fui.var_increment("authorities", 5)
		end

		fui.text("chief", "fuck_it", intl("81039c.interlude_h3.376878"))
		fui.wait_for_input()
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
