local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("jen", "tab", "mordecai", "joseph")
		else
			fui.load_characters("jen", "tab", "mordecai")
		end

		fui.wait(2)
		fui.show_character("tab", "RIGHT_CENTER", "listening")
		fui.show_character("mordecai", "RIGHT", "normal")

		if fui.var_get("has_joseph") then
			fui.show_character("joseph", "LEFT", "neutral")
			fui.show_character("jen", "LEFT_CENTER", "normal_smile")
		else
			fui.show_character("jen", "LEFT", "normal_smile")
		end

		fui.wait(1)
		fui.text("jen", "explain_smile", intl("81039c.interlude_i1.800b1c"))
		fui.text("tab", "listening", intl("81039c.interlude_i1.6784f5"))
		fui.animate("jen", "normal_smile")

		if fui.var_get("has_joseph") then
			fui.text("joseph", "explaining", intl("81039c.interlude_i1.80fea2"))
			fui.animate("tab", "normal")
		else
			fui.text("tab", "asking", intl("81039c.interlude_i1.25fd2c"))
		end

		fui.text("mordecai", "explain", intl("81039c.interlude_i1.bb3809"))

		if fui.var_get("has_joseph") then
			fui.animate("joseph", "neutral")
		else
			fui.animate("tab", "listening")
		end

		if fui.var_get("has_joseph") then
			fui.text("joseph", "what", intl("81039c.interlude_i1.07eb32"))
			fui.animate("mordecai", "normal")
		else
			fui.text("mordecai", "gun", intl("81039c.interlude_i1.07eb32"))
		end

		fui.text("jen", "pointing", intl("81039c.interlude_i1.f40677"))

		if fui.var_get("has_joseph") then
			fui.animate("joseph", "neutral")
		else
			fui.animate("mordecai", "normal")
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
