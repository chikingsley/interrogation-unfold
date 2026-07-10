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
		fui.text("dummy", nil, intl("80035d.interlude_g2.2a3537"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.2888b1"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.7c3669"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.0da2dd"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.40a8af"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.e7d448"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.1bee0b"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.76e77d"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.d4d4ae"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.3d1335"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.d5d612"))

		local choice28 = fui.choose({
			intl("80035d.interlude_g2.e71130"),
			intl("80035d.interlude_g2.23b528"),
			intl("80035d.interlude_g2.a78076")
		})

		if choice28 == 1 then
			fui.var_decrement("authorities", 5)
			fui.var_increment("freedom", 1)
			fui.var_increment("equity", 1)
			fui.text("dummy", nil, intl("80035d.interlude_g2.9cb309"))
			fui.text("dummy", nil, intl("80035d.interlude_g2.d0f15e"))
		elseif choice28 == 2 then
			fui.var_increment("lawful", 1)
			fui.text("dummy", nil, intl("80035d.interlude_g2.8d0960"))
		elseif choice28 == 3 then
			fui.var_increment("authorities", 5)
			fui.var_increment("justice", 1)
			fui.text("dummy", nil, intl("80035d.interlude_g2.b06b76"))
		end

		fui.text("dummy", nil, intl("80035d.interlude_g2.ea96f9"))
		fui.text("dummy", nil, intl("80035d.interlude_g2.9de214"))
		fui.wait_for_input()
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
