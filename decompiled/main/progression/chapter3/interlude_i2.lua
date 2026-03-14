local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("jen", "tab", "mordecai", "joseph")
		else
			fui.load_characters("jen", "tab", "mordecai")
		end

		fui.wait(2)
		fui.show_character("jen", "LEFT_CENTER", "mega_dissapointed")
		fui.show_character("tab", "LEFT", "defensive")
		fui.show_character("mordecai", "RIGHT", "thinking")

		if fui.var_get("has_joseph") then
			fui.show_character("joseph", "RIGHT_CENTER", "neutral")
		end

		fui.wait(1)
		fui.text("jen", "mega_dissapointed", intl("81039c.interlude_i2.48e679"))
		fui.wait_for_input()

		if fui.var_get("has_joseph") then
			fui.text("joseph", "sad", intl("81039c.interlude_i2.f3023a"))
		else
			fui.text("tab", "defensive", intl("81039c.interlude_i2.c8ebd6"))
		end

		if fui.var_get("insanity") >= 5 then
			local choice28 = fui.choose({
				intl("81039c.interlude_i2.201ac6"),
				intl("81039c.interlude_i2.5d641b")
			})

			if choice28 == 1 then
				fui.var_decrement("jen_approval", 5)
				fui.var_increment("justice", 1)
				fui.animate("jen", "mega_dissapointed")
				fui.wait(2)
			elseif choice28 == 2 then
				if fui.var_get("has_joseph") then
					fui.var_decrement("joseph_approval", 5)
				end

				fui.var_decrement("tab_approval", 5)
				fui.var_decrement("jen_approval", 5)
				fui.var_decrement("mordecai_approval", 5)
				fui.var_increment("justice", 1)
				fui.animate("jen", "mega_dissapointed")
				fui.animate("mordecai", "thinking")
				fui.animate("tab", "disgsut")

				if fui.var_get("has_joseph") then
					fui.animate("joseph", "concern")
				end

				fui.wait(2)
			end
		end

		fui.text("tab", "aback", intl("81039c.interlude_i2.4f6863"))
		fui.text("mordecai", "thinking", intl("81039c.interlude_i2.74f0ea"))

		if fui.var_get("has_joseph") then
			fui.text("joseph", "explaining", intl("81039c.interlude_i2.866dc4"))
			fui.wait_for_input()
			fui.animate("joseph", "sad")
		else
			fui.text("mordecai", "hips", intl("81039c.interlude_i2.b6e231"))
		end

		fui.text("jen", "mega_dissapointed", intl("81039c.interlude_i2.071ecd"))
		fui.wait_for_input()
		fui.hide_character("jen")
		fui.text("mordecai", "point", intl("81039c.interlude_i2.3ce61b"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
