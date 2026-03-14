local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen", "tab", "mordecai")
		fui.wait(2)
		fui.show_character("tab", "LEFT", "aback")
		fui.text("tab", nil, intl("7f031e.interlude_c4.1ed828"))
		fui.show_character("jen", "RIGHT", "pointing")
		fui.text("jen", nil, intl("7f031e.interlude_c4.bec8d6"))
		fui.wait_for_input()
		fui.show_character("mordecai", "RIGHT_CENTER")
		fui.text("mordecai", nil, intl("7f031e.interlude_c4.c07c71"))
		fui.text("tab", "asking", intl("7f031e.interlude_c4.e93cf5"))
		fui.animate("jen", "normal")
		fui.text("jen", "pointing_angry", intl("7f031e.interlude_c4.14a5e7"))
		fui.animate("tab", "normal")

		if fui.var_get("interlude_c_pleased_tab") then
			fui.text("tab", "defensive", intl("7f031e.interlude_c4.198ae1"))
			fui.animate("jen", "normal_angry")
		else
			fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c4.ef52a4"))
		end

		fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c4.df53ad"))
		fui.animate("tab", "normal")
		fui.animate("mordecai", "thinking")
		fui.text("tab", "defensive", intl("7f031e.interlude_c4.3a5001"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
