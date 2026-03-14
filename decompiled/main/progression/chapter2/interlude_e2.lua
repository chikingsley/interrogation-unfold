local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen", "tab", "mordecai")
		fui.wait(2)
		fui.show_character("jen", "LEFT", "normal")
		fui.show_character("mordecai", "LEFT_CENTER", "normal")
		fui.show_character("tab", "RIGHT", "normal")
		fui.wait(1)

		if fui.var_get("adams_assignee") == "jen" then
			fui.text("jen", nil, intl("80035d.interlude_e2.a3ff9d"))
		elseif fui.var_get("adams_assignee") == "mordecai" then
			fui.text("mordecai", nil, intl("80035d.interlude_e2.a3ff9d"))
		elseif fui.var_get("adams_assignee") == "tab" then
			fui.text("tab", nil, intl("80035d.interlude_e2.a3ff9d"))
		end

		if fui.var_get("novak_assignee") == "jen" then
			fui.text("jen", nil, intl("80035d.interlude_e2.a3cebf"))
			fui.text("jen", nil, intl("80035d.interlude_e2.f85a68"))
		elseif fui.var_get("novak_assignee") == "mordecai" then
			fui.text("mordecai", nil, intl("80035d.interlude_e2.a3cebf"))
			fui.text("mordecai", nil, intl("80035d.interlude_e2.f85a68"))
		elseif fui.var_get("novak_assignee") == "tab" then
			fui.text("tab", nil, intl("80035d.interlude_e2.a3cebf"))
			fui.text("tab", nil, intl("80035d.interlude_e2.f85a68"))
		end

		fui.text("tab", "defensive", intl("80035d.interlude_e2.0fbf7c"))
		fui.text("jen", "pointing", intl("80035d.interlude_e2.0d3af2"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
