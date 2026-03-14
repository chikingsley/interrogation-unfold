local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		if fui.var_get("co_overtime_count") == 2 and not fui.var_get("co_triggered") then
			fui.set("co_triggered")
			fui.set_preset_music("campaign")
			fui.load_interlude("office_floor")
			fui.load_characters("tristan")
			fui.wait(2)
			fui.show_character("tristan", "LEFT", "normal")
			fui.wait(1)
			fui.text("tristan", "explain", intl("efd00d.triggered_community_outreach.28f48a"))
			fui.text("tristan", "thumbs_up", intl("efd00d.triggered_community_outreach.1030f8"))

			local choice16 = fui.choose({
				intl("efd00d.triggered_community_outreach.b0fe2d"),
				intl("efd00d.triggered_community_outreach.0dfae1"),
				intl("efd00d.triggered_community_outreach.9922e1")
			})

			if choice16 == 1 then
				fui.hide_bubbles()
				fui.animate("tristan", "normal")
				fui.var_increment("press", 5)
				fui.wait(2)
			elseif choice16 == 2 then
				fui.hide_bubbles()
				fui.animate("tristan", "arms_crossed")
				fui.var_increment("authorities", 5)
				fui.wait(2)
			elseif choice16 == 3 then
				fui.hide_bubbles()
				fui.animate("tristan", "glasses")
				fui.var_increment("budget", 1000)
				fui.wait(1)
				fui.text("tristan", "explain", intl("efd00d.triggered_community_outreach.112550"))
				fui.wait_for_input()
			end

			fui.hide_all_characters()
			fui.commit_stats("interlude")
		end
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
