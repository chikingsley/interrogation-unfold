local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen", "tab", "mordecai")
		fui.wait(2)
		fui.show_character("jen", "LEFT")
		fui.show_character("tab", "RIGHT_CENTER")
		fui.show_character("mordecai", "RIGHT")
		fui.wait(1)
		fui.text("jen", "explain_smile", intl("80035d.interlude_e1.bdf0fb"))
		fui.text("mordecai", "explain", intl("80035d.interlude_e1.2747a7"))
		fui.unset("novak_assignee")
		fui.unset("adams_assignee")

		local choice17 = fui.choose({
			intl("80035d.interlude_e1.5e665d"),
			intl("80035d.interlude_e1.6cde4d"),
			intl("80035d.interlude_e1.237a5d")
		})

		if choice17 == 1 then
			fui.var_set("novak_assignee", "tab")
			fui.hide_bubbles()
			fui.animate("jen", "normal")
			fui.animate("tab", "listening")
			fui.animate("mordecai", "normal")
		elseif choice17 == 2 then
			fui.var_set("novak_assignee", "jen")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "listening")
			fui.animate("mordecai", "normal")
		elseif choice17 == 3 then
			fui.var_set("novak_assignee", "mordecai")
			fui.hide_bubbles()
			fui.animate("jen", "normal")
			fui.animate("tab", "listening")
			fui.animate("mordecai", "proud")
		end

		fui.wait(1.5)
		fui.text("tab", "explain", intl("80035d.interlude_e1.b39bcd"))

		local choice43 = fui.choose({
			fui.var_get("novak_assignee") ~= "mordecai" and intl("80035d.interlude_e1.1540b9") or nil,
			fui.var_get("novak_assignee") ~= "jen" and intl("80035d.interlude_e1.5ea4a9") or nil,
			fui.var_get("novak_assignee") ~= "tab" and intl("80035d.interlude_e1.502cb9") or nil,
			intl("80035d.interlude_e1.bdc05e")
		})

		if choice43 == 1 then
			fui.var_set("adams_assignee", "mordecai")
		elseif choice43 == 2 then
			fui.var_set("adams_assignee", "jen")
		elseif choice43 == 3 then
			fui.var_set("adams_assignee", "tab")
		elseif choice43 == 4 then
			-- Nothing
		end

		fui.hide_bubbles()
		fui.animate("jen", "normal")
		fui.animate("tab", "listening")
		fui.animate("mordecai", "normal")
		fui.wait(2)
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
