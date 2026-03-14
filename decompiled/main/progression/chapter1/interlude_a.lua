local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("chief", "mordecai")
		fui.wait(1.5)
		fui.show_character("chief", "LEFT", "normal")
		fui.wait(1)
		fui.text("chief", nil, intl("7f031e.interlude_a.ca7085"))
		fui.text("chief", nil, intl("7f031e.interlude_a.1eafd5"))
		fui.wait_for_input()
		fui.show_character("mordecai", "RIGHT", "normal")
		fui.text("mordecai", nil, intl("7f031e.interlude_a.1ff192"))
		fui.text("chief", nil, intl("7f031e.interlude_a.7552d9"))
		fui.text("chief", "asking", intl("7f031e.interlude_a.4e5a42"))

		local choice21 = fui.choose({
			intl("7f031e.interlude_a.00fecb"),
			intl("7f031e.interlude_a.1a278d"),
			intl("7f031e.interlude_a.c8dee2")
		})

		if choice21 == 1 then
			-- Nothing
		elseif choice21 == 2 then
			fui.var_increment("lawful", 1)
			fui.var_increment("evolution", 1)
		elseif choice21 == 3 then
			fui.var_increment("freedom", 1)
		end

		fui.text("chief", "normal", intl("7f031e.interlude_a.f0fa23"))
		fui.text("chief", "bossss", intl("7f031e.interlude_a.b9af6b"))
		fui.text("chief", "normal", intl("7f031e.interlude_a.4765e6"))
		fui.text("mordecai", "hips", intl("7f031e.interlude_a.53ae6a"))
		fui.text("mordecai", nil, intl("7f031e.interlude_a.00e629"))
		fui.text("chief", nil, intl("7f031e.interlude_a.74b600"))
		fui.text("chief", "fuck_it", intl("7f031e.interlude_a.079a87"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
