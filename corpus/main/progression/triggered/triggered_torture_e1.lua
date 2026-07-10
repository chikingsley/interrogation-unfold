local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		if fui.var_get("total_torture_damage") > (fui.var_get("last_checked_torture_damage") or 0) then
			fui.set_preset_music("campaign")
			fui.var_set("last_checked_torture_damage", fui.var_get("total_torture_damage"))
			fui.load_interlude("chief_office")
			fui.load_characters("dummy")
			fui.show_character("dummy", "CHIEF", false, "chief")
			fui.wait(2)
			fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.3fd8a5"))
			fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.c8a00c"))
			fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.4b4206"))

			local choice17 = fui.choose({
				intl("efd00d.triggered_torture_e1.a271f1"),
				intl("efd00d.triggered_torture_e1.ff3a56"),
				intl("efd00d.triggered_torture_e1.bf4aa2")
			})

			if choice17 == 1 then
				fui.var_decrement("authorities", 5)
				fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.940b4e"))
			elseif choice17 == 2 then
				if fui.var_get("tortured_peterson") then
					fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.bd69be"))
				elseif fui.var_get("tortured_jerry") then
					fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.7ec640"))
				else
					fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.5fe75b"))
				end
			elseif choice17 == 3 then
				fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.9f3801"))
			end

			fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.42ff10"))
			fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.8a35a1"))
			fui.text("dummy", nil, intl("efd00d.triggered_torture_e1.dd837a"))
			fui.wait_for_input()
			fui.hide_all_characters()
			fui.commit_stats("interlude")
		end
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
