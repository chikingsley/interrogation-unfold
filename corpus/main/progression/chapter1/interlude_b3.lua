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
		fui.show_character("jen", "LEFT", "normal")
		fui.wait(1)
		fui.text("jen", "explain", intl("7f031e.interlude_b3.ebc0e3"))
		fui.text("jen", nil, intl("7f031e.interlude_b3.5ef68e"))
		fui.text("tab", "asking", intl("7f031e.interlude_b3.851978"))
		fui.animate("jen", "normal")

		local choice15 = fui.choose({
			intl("7f031e.interlude_b3.67bca9"),
			intl("7f031e.interlude_b3.562b30"),
			intl("7f031e.interlude_b3.7305cb")
		})

		if choice15 == 1 then
			fui.var_increment("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
			fui.var_increment("mordecai_approval", 5)
			fui.animate("jen", "normal_smile")
		elseif choice15 == 2 then
			fui.var_decrement("tab_approval", 5)
			fui.var_increment("justice", 1)
			fui.animate("tab", "disgust")
		elseif choice15 == 3 then
			fui.var_decrement("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
			fui.var_increment("lawful", 1)
			fui.animate("tab", "listening")
			fui.var_increment("authorities", 5)
		end

		fui.hide_bubbles()
		fui.wait(1)
		fui.text("jen", "pointing", intl("7f031e.interlude_b3.755eba"))
		fui.animate("tab", "normal")
		fui.wait_for_input()
		fui.hide_character("jen")
		fui.wait(1)
		fui.text("tab", nil, intl("7f031e.interlude_b3.93a794"))
		fui.text("tab", "aback", intl("7f031e.interlude_b3.5408d4"))
		fui.text("tab", "aback", intl("7f031e.interlude_b3.2d8bb8"))
		fui.wait_for_input()
		fui.hide_bubbles()
		fui.show_character("jen", "LEFT", "normal")
		fui.wait(1)
		fui.text("jen", nil, intl("7f031e.interlude_b3.a84d72"))
		fui.animate("jen", "pointing", false, true)
		fui.text("tab", "normal", intl("7f031e.interlude_b3.37f066"))
		fui.wait_for_input()
		fui.hide_all_characters()
		fui.commit_stats()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
