local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("tab")
		fui.wait(2)
		fui.show_character("tab", "LEFT", "normal")
		fui.wait(1)
		fui.text("tab", "normal", intl("80035d.interlude_e2_1_tab.99c894"))
		fui.text("tab", "asking", intl("80035d.interlude_e2_1_tab.24e789"))
		fui.text("tab", "defensive", intl("80035d.interlude_e2_1_tab.99113b"))
		fui.text("tab", "defensive", intl("80035d.interlude_e2_1_tab.75e878"))

		if fui.var_get("tab_approval") >= 70 then
			fui.text("tab", "defensive", intl("80035d.interlude_e2_1_tab.5db0bd"))
			fui.text("tab", "explain", intl("80035d.interlude_e2_1_tab.569b2f"))
			fui.text("tab", "explain", intl("80035d.interlude_e2_1_tab.faad9d"))

			local choice25 = fui.choose({
				intl("80035d.interlude_e2_1_tab.c961d0"),
				intl("80035d.interlude_e2_1_tab.c4a2eb"),
				intl("80035d.interlude_e2_1_tab.fbbdae")
			})

			if choice25 == 1 then
				fui.var_decrement("tab_approval", 10)
				fui.var_decrement("lawful", 1)
				fui.var_increment("freedom", 1)
				fui.text("tab", "aback", intl("80035d.interlude_e2_1_tab.edc173"))
			elseif choice25 == 2 then
				fui.var_increment("tab_approval", 5)
				fui.var_increment("lawful", 1)
				fui.text("tab", "normal", intl("80035d.interlude_e2_1_tab.fcf90a"))
			elseif choice25 == 3 then
				fui.var_decrement("tab_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.3624b9"))
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.0ced1b"))
			end
		else
			fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.faad9d"))

			local choice52 = fui.choose({
				intl("80035d.interlude_e2_1_tab.10e5ee"),
				intl("80035d.interlude_e2_1_tab.c961d0"),
				intl("80035d.interlude_e2_1_tab.fbbdae")
			})

			if choice52 == 1 then
				fui.var_decrement("tab_approval", 5)
				fui.var_increment("justice", 1)
				fui.var_increment("lawful", 1)
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.dc7444"))
				fui.text("tab", "defensive", intl("80035d.interlude_e2_1_tab.0f9cdb"))
			elseif choice52 == 2 then
				fui.var_decrement("tab_approval", 10)
				fui.var_decrement("lawful", 1)
				fui.var_increment("freedom", 1)
				fui.text("tab", "aback", intl("80035d.interlude_e2_1_tab.edc173"))
			elseif choice52 == 3 then
				fui.var_decrement("tab_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.3624b9"))
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.0ced1b"))
			end
		end

		if fui.var_get("tab_declassified") then
			local choice80 = fui.choose({
				intl("80035d.interlude_e2_1_tab.5e0b1f"),
				intl("80035d.interlude_e2_1_tab.2174e8"),
				intl("80035d.interlude_e2_1_tab.b68f8b")
			})

			if choice80 == 1 then
				fui.text("tab", "normal", intl("80035d.interlude_e2_1_tab.b06b76"))
			elseif choice80 == 2 then
				fui.animate("tab", "aback")
				fui.hide_bubbles()
				fui.wait(1)
				fui.text("tab", "defensive", intl("80035d.interlude_e2_1_tab.beaec7"))

				local choice92 = fui.choose({
					intl("80035d.interlude_e2_1_tab.b655cf"),
					intl("80035d.interlude_e2_1_tab.bf0e7d"),
					intl("80035d.interlude_e2_1_tab.909395")
				})

				if choice92 == 1 then
					fui.var_decrement("tab_approval", 10)
					fui.var_increment("justice", 1)
					fui.var_decrement("freedom", 1)
					fui.var_decrement("equity", 1)
					fui.var_decrement("evolution", 1)
					fui.text("tab", "disgust", intl("80035d.interlude_e2_1_tab.b26561"))
				elseif choice92 == 2 then
					fui.var_increment("tab_approval", 5)
					fui.var_increment("lawful", 1)
					fui.var_increment("justice", 1)
					fui.text("tab", "listening", intl("80035d.interlude_e2_1_tab.4bf4c6"))
					fui.text("tab", "listening", intl("80035d.interlude_e2_1_tab.c6c7e1"))
				elseif choice92 == 3 then
					fui.animate("tab", "disgust")
					fui.hide_bubbles()
					fui.wait(1)
					fui.var_decrement("tab_approval", 20)
					fui.text("tab", "aback", intl("80035d.interlude_e2_1_tab.fa43b0"))
					fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.d9dbd7"))
					fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.030a5b"))
					fui.text("tab", "listening", intl("80035d.interlude_e2_1_tab.faee96"))
					fui.text("tab", "disgust", intl("80035d.interlude_e2_1_tab.3ec1dd"))
				end
			elseif choice80 == 3 then
				fui.animate("tab", "disgust")
				fui.hide_bubbles()
				fui.wait(1)
				fui.var_decrement("tab_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.4c7cbb"))
				fui.text("tab", "listening", intl("80035d.interlude_e2_1_tab.e51c0d"))
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.99b461"))
			end
		else
			local choice143 = fui.choose({
				intl("80035d.interlude_e2_1_tab.5e0b1f"),
				intl("80035d.interlude_e2_1_tab.b68f8b")
			})

			if choice143 == 1 then
				fui.text("tab", "normal", intl("80035d.interlude_e2_1_tab.b06b76"))
			elseif choice143 == 2 then
				fui.animate("tab", "disgust")
				fui.hide_bubbles()
				fui.wait(1)
				fui.var_decrement("tab_approval", 10)
				fui.var_increment("justice", 1)
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.4c7cbb"))
				fui.text("tab", "listening", intl("80035d.interlude_e2_1_tab.e51c0d"))
				fui.text("tab", "indignant", intl("80035d.interlude_e2_1_tab.99b461"))
			end
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
