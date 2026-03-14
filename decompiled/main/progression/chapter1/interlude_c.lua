local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen", "tab")
		fui.wait(2)
		fui.show_character("tab", "RIGHT", "normal")
		fui.show_character("jen", "LEFT", "normal_smile")
		fui.wait(1)
		fui.text("jen", "explain", intl("7f031e.interlude_c.24c1c1"))
		fui.text("jen", "normal", intl("7f031e.interlude_c.90159e"))
		fui.text("tab", "explain", intl("7f031e.interlude_c.5a17cf"))
		fui.text("jen", "pointing", intl("7f031e.interlude_c.31942b"))
		fui.animate("tab", "normal")

		local choice16 = fui.choose({
			intl("7f031e.interlude_c.5394a8"),
			intl("7f031e.interlude_c.63fe9d"),
			intl("7f031e.interlude_c.3b430c")
		})

		if choice16 == 1 then
			fui.set("interlude_c_pleased_jen")
			fui.hide_bubbles()
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "defensive")
			fui.var_increment("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
		elseif choice16 == 2 then
			fui.set("interlude_c_pleased_tab")
			fui.hide_bubbles()
			fui.animate("jen", "normal_angry")
			fui.animate("tab", "listening")
			fui.var_decrement("jen_approval", 5)
			fui.var_increment("tab_approval", 5)
		elseif choice16 == 3 then
			fui.set("interlude_c_hesitated")
			fui.text("tab", "defensive", intl("7f031e.interlude_c.7ee20f"))
			fui.animate("jen", "normal_angry")

			local choice39 = fui.choose({
				intl("7f031e.interlude_c.ee535c"),
				intl("7f031e.interlude_c.8ed40f"),
				intl("7f031e.interlude_c.33c63d")
			})

			if choice39 == 1 then
				fui.set("interlude_c_did_both")
				fui.hide_bubbles()
				fui.animate("jen", "normal_smile")
				fui.animate("tab", "defensive")
				fui.var_decrement("tab_approval", 5)
			elseif choice39 == 2 then
				fui.set("interlude_c_pleased_jen")
				fui.hide_bubbles()
				fui.animate("jen", "normal_smile")
				fui.animate("tab", "disgust")
				fui.var_increment("jen_approval", 5)
				fui.var_decrement("tab_approval", 5)
			elseif choice39 == 3 then
				fui.set("interlude_c_pleased_tab")
				fui.hide_bubbles()
				fui.animate("jen", "normal_angry")
				fui.animate("tab", "listening")
				fui.var_decrement("jen_approval", 5)
				fui.var_increment("tab_approval", 5)
			end
		end

		fui.wait(2)
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
