local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("tab", "joseph")
		else
			fui.load_characters("tab")
		end

		fui.wait(2)

		if fui.var_get("has_joseph") then
			fui.show_character("tab", "RIGHT")
			fui.show_character("joseph", "LEFT", "concern")
		else
			fui.show_character("tab", "LEFT")
		end

		fui.wait(1)
		fui.text("tab", "explain", intl("80035d.interlude_e4.71f439"))
		fui.text("tab", "defensive", intl("80035d.interlude_e4.c16107"))
		fui.text("tab", "defensive", intl("80035d.interlude_e4.ba989e"))
		fui.text("tab", "asking", intl("80035d.interlude_e4.6ab041"))
		fui.text("tab", "aback", intl("80035d.interlude_e4.775ef0"))

		if fui.var_get("insanity") >= 5 then
			local choice27 = fui.choose({
				intl("80035d.interlude_e4.b06075")
			})

			if choice27 == 1 then
				fui.var_decrement("tab_approval", 5)
				fui.var_increment("justice", 2)
			end
		end

		fui.text("tab", "aback", intl("80035d.interlude_e4.a7b68f"))
		fui.text("tab", "explain", intl("80035d.interlude_e4.704dd1"))
		fui.text("tab", "defensive", intl("80035d.interlude_e4.d79766"))
		fui.text("tab", "defensive", intl("80035d.interlude_e4.38732c"))

		if fui.var_get("has_joseph") then
			fui.text("joseph", "concern", intl("80035d.interlude_e4.3b7fbc"))
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
