local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen")
		fui.wait(2)
		fui.show_character("jen", "LEFT", "normal")
		fui.wait(1)
		fui.text("jen", "normal", intl("7f031e.interlude_c2_1_jen.efb8fa"))
		fui.text("jen", "pointing", intl("7f031e.interlude_c2_1_jen.800bd8"))
		fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c2_1_jen.4ebe40"))
		fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c2_1_jen.288f6a"))

		if fui.var_get("jen_approval") >= 70 then
			fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.42f16e"))
			fui.text("jen", "explain_smile", intl("7f031e.interlude_c2_1_jen.2a2e8b"))

			local choice21 = fui.choose({
				intl("7f031e.interlude_c2_1_jen.dc051a"),
				intl("7f031e.interlude_c2_1_jen.cbb60c"),
				intl("7f031e.interlude_c2_1_jen.720377")
			})

			if choice21 == 1 then
				fui.var_decrement("jen_approval", 10)
				fui.var_increment("freedom", 1)
				fui.var_increment("equity", 1)
				fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c2_1_jen.968acf"))
			elseif choice21 == 2 then
				fui.var_decrement("jen_approval", 10)
				fui.var_increment("justice", 1)
				fui.var_increment("evolution", 1)
				fui.text("jen", "explain_angry", intl("7f031e.interlude_c2_1_jen.ced2a6"))
			elseif choice21 == 3 then
				fui.var_increment("jen_approval", 5)
				fui.var_increment("equity", 1)
				fui.var_increment("lawful", 1)
				fui.text("jen", "explain_smile", intl("7f031e.interlude_c2_1_jen.31742f"))
			end
		else
			fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.db7d1a"))
			fui.text("jen", "normal_angry", intl("7f031e.interlude_c2_1_jen.93931c"))
			fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2_1_jen.09897e"))

			local choice51 = fui.choose({
				intl("7f031e.interlude_c2_1_jen.382f30"),
				intl("7f031e.interlude_c2_1_jen.afdf27"),
				intl("7f031e.interlude_c2_1_jen.9222b1")
			})

			if choice51 == 1 then
				fui.animate("jen", "mega_dissapointed")
				fui.hide_bubbles()
				fui.wait(1)
				fui.var_decrement("jen_approval", 5)
				fui.var_increment("justice", 1)
				fui.var_increment("lawful", 1)
				fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2_1_jen.55eed2"))
				fui.text("jen", "explain_angry", intl("7f031e.interlude_c2_1_jen.6fc667"))
			elseif choice51 == 2 then
				fui.var_increment("jen_approval", 5)
				fui.var_increment("lawful", 1)
				fui.var_increment("equity", 1)
				fui.text("jen", "pointing", intl("7f031e.interlude_c2_1_jen.b4f06a"))
				fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.f48fa2"))
				fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.a98492"))
			elseif choice51 == 3 then
				fui.var_decrement("jen_approval", 5)
				fui.var_increment("justice", 2)
				fui.text("jen", "normal_angry", intl("7f031e.interlude_c2_1_jen.8739ca"))
				fui.text("jen", "explain_angry", intl("7f031e.interlude_c2_1_jen.c68478"))
			end
		end

		if fui.var_get("jen_declassified") then
			local choice88 = fui.choose({
				intl("7f031e.interlude_c2_1_jen.c99545"),
				intl("7f031e.interlude_c2_1_jen.c4cc96"),
				intl("7f031e.interlude_c2_1_jen.58e025")
			})

			if choice88 == 1 then
				fui.var_increment("jen_approval", 5)
				fui.text("jen", "normal_smile", intl("7f031e.interlude_c2_1_jen.03859d"))
				fui.text("jen", "pointing", intl("7f031e.interlude_c2_1_jen.53a6d3"))
			elseif choice88 == 2 then
				fui.var_decrement("jen_approval", 5)
				fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c2_1_jen.b61ec9"))
				fui.text("jen", "explain_angry", intl("7f031e.interlude_c2_1_jen.ea45c5"))

				local choice103 = fui.choose({
					intl("7f031e.interlude_c2_1_jen.84f705"),
					intl("7f031e.interlude_c2_1_jen.6ae0ae"),
					intl("7f031e.interlude_c2_1_jen.807300")
				})

				if choice103 == 1 then
					fui.animate("jen", "mega_dissapointed")
					fui.hide_bubbles()
					fui.wait(1)
					fui.var_decrement("jen_approval", 10)
					fui.var_increment("evolution", 1)
					fui.text("jen", "normal_angry", intl("7f031e.interlude_c2_1_jen.77429c"))
					fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2_1_jen.53a6d3"))
				elseif choice103 == 2 then
					fui.var_increment("jen_approval", 5)
					fui.var_increment("freedom", 1)
					fui.var_increment("equity", 1)
					fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.230085"))
					fui.text("jen", "explain_smile", intl("7f031e.interlude_c2_1_jen.5ded38"))
					fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.4802b3"))
					fui.text("jen", "pointing", intl("7f031e.interlude_c2_1_jen.53a6d3"))
				elseif choice103 == 3 then
					fui.var_decrement("jen_approval", 10)
					fui.var_increment("authorities", 5)
					fui.var_increment("lawful", 2)
					fui.var_increment("justice", 2)
					fui.text("jen", "explain_angry", intl("7f031e.interlude_c2_1_jen.230085"))
					fui.text("jen", "explain", intl("7f031e.interlude_c2_1_jen.9ada95"))
					fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2_1_jen.53a6d3"))
				end
			elseif choice88 == 3 then
				fui.var_decrement("jen_approval", 5)
				fui.text("jen", "mega_dissapointed", intl("7f031e.interlude_c2_1_jen.d96ec2"))
				fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2_1_jen.53a6d3"))
			end
		else
			local choice151 = fui.choose({
				intl("7f031e.interlude_c2_1_jen.c99545"),
				intl("7f031e.interlude_c2_1_jen.58e025")
			})

			if choice151 == 1 then
				fui.var_increment("jen_approval", 5)
				fui.text("jen", "normal", intl("7f031e.interlude_c2_1_jen.03859d"))
				fui.text("jen", "pointing", intl("7f031e.interlude_c2_1_jen.53a6d3"))
			elseif choice151 == 2 then
				fui.var_decrement("jen_approval", 5)
				fui.text("jen", "explain_angry", intl("7f031e.interlude_c2_1_jen.d96ec2"))
				fui.text("jen", "pointing_angry", intl("7f031e.interlude_c2_1_jen.53a6d3"))
			end
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
