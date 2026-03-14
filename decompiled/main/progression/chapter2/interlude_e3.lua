local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen")
		fui.wait(2)
		fui.show_character("jen", "LEFT", "normal")
		fui.wait(1)
		fui.text("jen", "explain_angry", intl("80035d.interlude_e3.0634c3"))
		fui.text("jen", "explain_angry", intl("80035d.interlude_e3.286241"))
		fui.text("jen", "normal_angry", intl("80035d.interlude_e3.97c2f5"))
		fui.text("jen", "explain_angry", intl("80035d.interlude_e3.0f71b4"))
		fui.text("jen", "explain_angry", intl("80035d.interlude_e3.358465"))
		fui.text("jen", "normal_angry", intl("80035d.interlude_e3.f80e34"))

		local choice20 = fui.choose({
			intl("80035d.interlude_e3.80d76e"),
			intl("80035d.interlude_e3.1bf95e"),
			intl("80035d.interlude_e3.e2dc10")
		})

		if choice20 == 1 then
			fui.hide_bubbles()
			fui.animate("jen", "mega_dissapointed")
			fui.var_decrement("jen_approval", 10)
			fui.var_increment("evolution", 1)
			fui.var_increment("freedom", 1)
			fui.var_increment("equity", 1)
		elseif choice20 == 2 then
			fui.hide_bubbles()
			fui.animate("jen", "normal")
			fui.var_increment("jen_approval", 0)
			fui.var_increment("justice", 1)
		elseif choice20 == 3 then
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.var_increment("jen_approval", 5)
			fui.var_increment("justice", 1)
		end

		fui.text("jen", "pointing", intl("80035d.interlude_e3.8f7723"))
		fui.text("jen", "pointing_smile", intl("80035d.interlude_e3.9b2715"))
		fui.text("jen", "explain", intl("80035d.interlude_e3.72ccaf"))
		fui.text("jen", "explain_angry", intl("80035d.interlude_e3.30bffc"))
		fui.text("jen", "explain", intl("80035d.interlude_e3.08795b"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
