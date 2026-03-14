local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		if fui.var_get("recruited_joseph") and not fui.var_get("recruited_joseph_triggered") then
			fui.set("recruited_joseph_triggered")
			fui.set_preset_music("campaign")
			fui.load_interlude("office_floor")
			fui.load_characters("jen", "tab", "mordecai", "joseph")
			fui.wait(2)
			fui.show_character("jen", "LEFT_CENTER", "normal")
			fui.show_character("tab", "LEFT", "normal")
			fui.show_character("mordecai", "CENTER_LEFT", "normal")
			fui.show_character("joseph", "RIGHT", "neutral")
			fui.wait(1)
			fui.set("has_joseph")
			fui.var_set("joseph_approval", 95)

			local choice18 = fui.choose({
				intl("efd00d.triggered_recruited_joseph.ec5a51"),
				intl("efd00d.triggered_recruited_joseph.30efcf"),
				intl("efd00d.triggered_recruited_joseph.20de82")
			})

			if choice18 == 1 then
				fui.hide_bubbles()
				fui.animate("jen", "normal_angry")
				fui.animate("tab", "indignant")
				fui.animate("mordecai", "normal")
				fui.animate("joseph", "concern")
				fui.var_increment("mordecai_approval", 5)
				fui.var_decrement("joseph_approval", 5)
				fui.var_decrement("jen_approval", 5)
				fui.wait(1)
				fui.text("joseph", "concern", intl("efd00d.triggered_recruited_joseph.7c7944"))
				fui.wait_for_input()
				fui.animate("joseph", "neutral")
			elseif choice18 == 2 then
				fui.hide_bubbles()
				fui.animate("jen", "normal")
				fui.animate("tab", "indignant")
				fui.animate("mordecai", "proud")
				fui.animate("joseph", "neutral")
				fui.var_increment("mordecai_approval", 5)
				fui.var_decrement("tab_approval", 5)
				fui.wait(1)
			elseif choice18 == 3 then
				fui.hide_bubbles()
				fui.animate("jen", "normal")
				fui.animate("tab", "normal")
				fui.animate("mordecai", "hips")
				fui.animate("joseph", "smile")
				fui.var_decrement("mordecai_approval", 5)
				fui.var_increment("joseph_approval", 5)
				fui.wait(1)
			end

			fui.text("jen", "normal_smile", intl("efd00d.triggered_recruited_joseph.d32509"))
			fui.text("mordecai", "proud", intl("efd00d.triggered_recruited_joseph.bcbc6f"))
			fui.text("tab", "normal", intl("efd00d.triggered_recruited_joseph.55e80b"))
			fui.text("joseph", "smile", intl("efd00d.triggered_recruited_joseph.d6e517"))
			fui.wait_for_input()
			fui.hide_all_characters()
		end
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
