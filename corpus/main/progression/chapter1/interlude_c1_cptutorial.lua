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
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.b0b54a"))

		if fui.var_get("narrative") then
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.a0585c"))
		else
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.67419d"))
		end

		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.229927"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.abed33"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.62c653"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.04b4bd"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.765a1c"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.c4a2be"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.bfb4d8"))
		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.9fa71c"))

		local choice30 = fui.choose({
			intl("7f031e.interlude_c1_cptutorial.9fa6fe"),
			intl("7f031e.interlude_c1_cptutorial.3d9f4d")
		})

		if choice30 == 1 then
			-- Nothing
		elseif choice30 == 2 then
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.a0cf2d"))
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.418661"))
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.a98798"))
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.c78129"))
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.73070a"))
			fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.0a4ed6"))
		end

		fui.text("dummy", nil, intl("7f031e.interlude_c1_cptutorial.b73b1a"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
