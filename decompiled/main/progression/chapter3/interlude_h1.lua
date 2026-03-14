local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("chief_office")
		fui.load_characters("dummy")
		fui.show_character("dummy", "CHIEF", false, "chief")
		fui.wait(2)
		fui.text("dummy", nil, intl("81039c.interlude_h1.891f5e"))
		fui.text("dummy", nil, intl("81039c.interlude_h1.6be1f2"))
		fui.text("dummy", nil, intl("81039c.interlude_h1.f0443a"))

		if fui.var_get("insanity") >= 5 then
			local choice13 = fui.choose({
				intl("81039c.interlude_h1.eff99b"),
				intl("81039c.interlude_h1.e81d39")
			})

			if choice13 == 1 then
				fui.var_decrement("authorities", 5)
				fui.var_increment("evolution", 1)
			elseif choice13 == 2 then
				fui.var_decrement("authorities", 5)
				fui.var_increment("freedom", 1)
			end

			fui.text("dummy", nil, intl("81039c.interlude_h1.3fbc0a"))
		end

		fui.text("dummy", nil, intl("81039c.interlude_h1.8617e9"))
		fui.text("dummy", nil, intl("81039c.interlude_h1.153dcc"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
