local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("jen", "tab", "joseph")
		else
			fui.load_characters("jen", "tab")
		end

		fui.wait(2)
		fui.show_character("jen", "LEFT", "normal")

		if fui.var_get("has_joseph") then
			fui.show_character("tab", "RIGHT_CENTER", "normal")
			fui.show_character("joseph", "RIGHT", "neutral")
		else
			fui.show_character("tab", "RIGHT", "normal")
		end

		fui.wait(1)
		fui.text("jen", "normal_smile", intl("80035d.interlude_f1.c6ce12"))

		if fui.var_get("has_joseph") then
			fui.text("joseph", "neutral", intl("80035d.interlude_f1.8446a8"))
		else
			fui.text("jen", "explain_smile", intl("80035d.interlude_f1.8446a8"))
		end

		fui.text("tab", "normal", intl("80035d.interlude_f1.877eef"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
