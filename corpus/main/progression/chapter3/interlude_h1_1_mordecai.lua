local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("street")
		fui.load_characters("mordecai")
		fui.wait(2)
		fui.show_character("mordecai", "LEFT", "normal")
		fui.wait(1)
		fui.text("mordecai", "gun", intl("81039c.interlude_h1_1_mordecai.351fb2"))
		fui.text("mordecai", "gun", intl("81039c.interlude_h1_1_mordecai.19799c"))
		fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.5cefaa"))
		fui.text("mordecai", "normal", intl("81039c.interlude_h1_1_mordecai.8671ef"))
		fui.text("mordecai", "explain", intl("81039c.interlude_h1_1_mordecai.e9d54f"))
		fui.text("mordecai", "explain", intl("81039c.interlude_h1_1_mordecai.ac2c2d"))

		if fui.var_get("mordecai_approval") >= 70 then
			fui.text("mordecai", "point", intl("81039c.interlude_h1_1_mordecai.6c8d57"))

			local choice25 = fui.choose({
				intl("81039c.interlude_h1_1_mordecai.b897c0"),
				intl("81039c.interlude_h1_1_mordecai.5df7bc"),
				intl("81039c.interlude_h1_1_mordecai.7cd8a6")
			})

			if choice25 == 1 then
				fui.var_increment("lawful", 1)
				fui.text("mordecai", "point", intl("81039c.interlude_h1_1_mordecai.4e3e0d"))
			elseif choice25 == 2 then
				fui.var_decrement("mordecai_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("mordecai", "thinking", intl("81039c.interlude_h1_1_mordecai.48e90c"))
			elseif choice25 == 3 then
				fui.text("mordecai", "explain", intl("81039c.interlude_h1_1_mordecai.e5802d"))
				fui.text("mordecai", "normal", intl("81039c.interlude_h1_1_mordecai.adca0d"))
			end
		else
			fui.text("mordecai", "gun", intl("81039c.interlude_h1_1_mordecai.ed583f"))

			local choice47 = fui.choose({
				intl("81039c.interlude_h1_1_mordecai.b897c0"),
				intl("81039c.interlude_h1_1_mordecai.5df7bc"),
				intl("81039c.interlude_h1_1_mordecai.7cd8a6")
			})

			if choice47 == 1 then
				fui.var_decrement("mordecai_approval", 10)
				fui.var_increment("lawful", 1)
				fui.text("mordecai", "thinking", intl("81039c.interlude_h1_1_mordecai.c66b79"))
			elseif choice47 == 2 then
				fui.var_increment("justice", 1)
				fui.text("mordecai", "normal", intl("81039c.interlude_h1_1_mordecai.c23da6"))
			elseif choice47 == 3 then
				fui.var_decrement("mordecai_approval", 5)
				fui.var_increment("justice", 1)
				fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.2af90d"))
				fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.28f8dc"))
			end
		end

		if fui.var_get("mordecai_declassified") then
			local choice70 = fui.choose({
				intl("81039c.interlude_h1_1_mordecai.68aae5"),
				intl("81039c.interlude_h1_1_mordecai.a61fad"),
				intl("81039c.interlude_h1_1_mordecai.c9ed37")
			})

			if choice70 == 1 then
				fui.text("mordecai", "normal", intl("81039c.interlude_h1_1_mordecai.c26fad"))
			elseif choice70 == 2 then
				fui.animate("mordecai", "thinking")
				fui.hide_bubbles()
				fui.wait(1)
				fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.165b32"))

				local choice82 = fui.choose({
					intl("81039c.interlude_h1_1_mordecai.407c56"),
					intl("81039c.interlude_h1_1_mordecai.d31c20"),
					intl("81039c.interlude_h1_1_mordecai.573672")
				})

				if choice82 == 1 then
					fui.var_increment("mordecai_approval", 5)
					fui.text("mordecai", "thinking", intl("81039c.interlude_h1_1_mordecai.cc74cc"))
				elseif choice82 == 2 then
					fui.var_increment("freedom", 1)
					fui.var_increment("equity", 1)
					fui.text("mordecai", "thinking", intl("81039c.interlude_h1_1_mordecai.45c7b7"))
					fui.hide_bubbles()
					fui.wait(1)
					fui.text("mordecai", "explain", intl("81039c.interlude_h1_1_mordecai.ed691b"))
				elseif choice82 == 3 then
					fui.animate("mordecai", "explain")
					fui.hide_bubbles()
					fui.wait(1)
					fui.var_decrement("mordecai_approval", 10)
					fui.text("mordecai", "thinking", intl("81039c.interlude_h1_1_mordecai.81dfc9"))
					fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.d83c70"))
					fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.c5e988"))
					fui.text("mordecai", "gun", intl("81039c.interlude_h1_1_mordecai.835750"))
					fui.text("mordecai", "thinking", intl("81039c.interlude_h1_1_mordecai.9d40d0"))
				end

				fui.text("mordecai", nil, intl("81039c.interlude_h1_1_mordecai.4776f8"))
			elseif choice70 == 3 then
				fui.animate("mordecai", "thinking")
				fui.hide_bubbles()
				fui.wait(1)
				fui.var_decrement("mordecai_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.e68d24"))
			end
		else
			local choice129 = fui.choose({
				intl("81039c.interlude_h1_1_mordecai.68aae5"),
				intl("81039c.interlude_h1_1_mordecai.c9ed37")
			})

			if choice129 == 1 then
				fui.text("mordecai", "normal", intl("81039c.interlude_h1_1_mordecai.c26fad"))
			elseif choice129 == 2 then
				fui.animate("mordecai", "thinking")
				fui.hide_bubbles()
				fui.wait(1)
				fui.var_decrement("mordecai_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("mordecai", "hips", intl("81039c.interlude_h1_1_mordecai.e68d24"))
			end
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
