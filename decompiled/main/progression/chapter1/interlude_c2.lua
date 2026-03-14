local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		if fui.var_get("interlude_c_pleased_jen") or fui.var_get("interlude_c_did_both") then
			fui.load_interlude("office_floor")
			fui.load_characters("jen", "tab")
			fui.wait(2)
			fui.show_character("jen", "LEFT", "normal_smile")
			fui.show_character("tab", "RIGHT", "normal")
			fui.wait(1)
			fui.text("jen", nil, intl("7f031e.interlude_c2.3a492c"))

			if fui.var_get("interlude_c_did_both") then
				fui.text("tab", "defensive", intl("7f031e.interlude_c2.7c83fb"))
			end

			fui.text("jen", "normal", intl("7f031e.interlude_c2.ffaf3f"))
			fui.animate("tab", "normal")
			fui.text("jen", nil, intl("7f031e.interlude_c2.9e8e68"))
			fui.text("jen", "normal_angry", intl("7f031e.interlude_c2.4ae9e3"))
			fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2.7be262"))
			fui.text("tab", "defensive", intl("7f031e.interlude_c2.7566ad"))
			fui.wait_for_input()
			fui.hide_all_characters()
		end
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
