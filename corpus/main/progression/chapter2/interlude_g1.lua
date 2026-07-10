local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("jen", "tab", "mordecai", "chief", "joseph")
		else
			fui.load_characters("jen", "tab", "mordecai", "chief")
		end

		fui.wait(2)
		fui.show_character("jen", "LEFT_CENTER", "normal_angry")
		fui.show_character("tab", "RIGHT_CENTER", "indignant")
		fui.show_character("mordecai", "RIGHT", "hips")
		fui.show_character("chief", "LEFT", "normal")

		if fui.var_get("has_joseph") then
			fui.show_character("joseph", "CENTER_RIGHT", "neutral")
		end

		fui.wait(1)
		fui.text("chief", "worried", intl("80035d.interlude_g1.96aa7f"))

		if fui.var_get("insanity") >= 5 then
			local choice20 = fui.choose({
				intl("80035d.interlude_g1.3aaada"),
				intl("80035d.interlude_g1.f89b63")
			})

			if choice20 == 1 then
				fui.var_decrement("tab_approval", 5)

				if fui.var_get("has_joseph") then
					fui.var_decrement("joseph_approval", 5)
				end

				fui.var_increment("freedom", 1)
				fui.var_increment("evolution", 1)

				if fui.var_get("has_joseph") then
					fui.animate("joseph", "concern")
				end

				fui.animate("tab", "disgust")
			elseif choice20 == 2 then
				fui.var_decrement("jen_approval", 5)
				fui.var_decrement("mordecai_approval", 5)
				fui.var_increment("justice", 1)
				fui.var_increment("lawful", 1)
				fui.animate("jen", "mega_dissapointed")
				fui.animate("mordecai", "thinking")
			end

			fui.text("chief", "cplm", intl("80035d.interlude_g1.951bf8"))
		end

		fui.text("chief", "fuck_it", intl("80035d.interlude_g1.8796a3"))
		fui.text("chief", "get_out", intl("80035d.interlude_g1.64fd6b"))
		fui.wait_for_input()
		fui.hide_character("mordecai")
		fui.wait(0.2)
		fui.hide_character("tab")
		fui.wait(0.2)
		fui.hide_character("jen")
		fui.wait(0.2)

		if fui.var_get("has_joseph") then
			fui.hide_character("joseph")
			fui.wait(0.2)
		end

		fui.wait(0.5)
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
