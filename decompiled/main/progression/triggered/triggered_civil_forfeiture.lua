local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		if fui.var_get("cf_overtime_count") == 2 and not fui.var_get("cf_triggered") then
			fui.set("cf_triggered")
			fui.set_preset_music("campaign")
			fui.load_interlude("office_floor")
			fui.load_characters("tristan", "chief")
			fui.wait(2)
			fui.show_character("chief", "RIGHT", "normal")
			fui.show_character("tristan", "LEFT", "normal")
			fui.wait(1)
			fui.text("chief", "worried", intl("efd00d.triggered_civil_forfeiture.11834c"))
			fui.text("tristan", "arms_crossed", intl("efd00d.triggered_civil_forfeiture.1b932d"))
			fui.text("tristan", "explain", intl("efd00d.triggered_civil_forfeiture.2e858f"))
			fui.animate("chief", "normal")

			local choice20 = fui.choose({
				intl("efd00d.triggered_civil_forfeiture.8eb5e0"),
				intl("efd00d.triggered_civil_forfeiture.2887b6"),
				intl("efd00d.triggered_civil_forfeiture.f4ae9e")
			})

			if choice20 == 1 then
				fui.hide_bubbles()
				fui.animate("chief", "bossss")
				fui.animate("tristan", "arms_crossed")
				fui.set("cf_press_penalty")
			elseif choice20 == 2 then
				fui.hide_bubbles()
				fui.animate("chief", "bossss")
				fui.animate("tristan", "glasses")
				fui.var_decrement("authorities", 10)
			elseif choice20 == 3 then
				fui.hide_bubbles()
				fui.animate("chief", "smiling")
				fui.animate("tristan", "normal")
				fui.set("cf_popularity_penalty")
			end

			fui.wait(2)
			fui.hide_all_characters()
		end
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
