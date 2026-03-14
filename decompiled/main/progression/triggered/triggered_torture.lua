local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local warning1 = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.set_preset_music("campaign")
		fui.load_interlude("office_floor")
		fui.load_characters("jen")
		fui.wait(2)
		fui.show_character("jen", "LEFT", "normal")
		fui.wait(1)
		fui.text("jen", nil, intl("efd00d.triggered_torture1.2f2dd8"))
		fui.text("jen", "normal_angry", intl("efd00d.triggered_torture1.7fc393"))
		fui.text("jen", "explain", intl("efd00d.triggered_torture1.b506ae"))
		fui.text("jen", nil, intl("efd00d.triggered_torture1.75c1fc"))

		local choice19 = fui.choose({
			intl("efd00d.triggered_torture1.d91eec"),
			intl("efd00d.triggered_torture1.f0427e"),
			intl("efd00d.triggered_torture1.9b0e62")
		})

		if choice19 == 1 then
			fui.text("jen", "mega_dissapointed", intl("efd00d.triggered_torture1.940181"))
			fui.var_decrement("jen_approval", 5)
		elseif choice19 == 2 then
			fui.text("jen", "explain_angry", intl("efd00d.triggered_torture1.d770c2"))
			fui.var_increment("popularity", 5)
		elseif choice19 == 3 then
			fui.text("jen", "explain_smile", intl("efd00d.triggered_torture1.e33f68"))
			fui.var_increment("jen_approval", 5)
		end

		fui.wait_for_input()
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()
local warning2 = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.set_preset_music("campaign")
		fui.load_interlude("office_floor")
		fui.load_characters("tab")
		fui.wait(2)
		fui.show_character("tab", "RIGHT", "normal")
		fui.wait(1)
		fui.text("tab", nil, intl("efd00d.triggered_torture2.04c50e"))
		fui.text("tab", "indignant", intl("efd00d.triggered_torture2.b0a8b6"))
		fui.text("tab", "indignant", intl("efd00d.triggered_torture2.6fc214"))
		fui.text("tab", "defensive", intl("efd00d.triggered_torture2.6c2b36"))
		fui.text("tab", "defensive", intl("efd00d.triggered_torture2.26138b"))

		local choice21 = fui.choose({
			intl("efd00d.triggered_torture2.cd7b45"),
			intl("efd00d.triggered_torture2.b4204f"),
			intl("efd00d.triggered_torture2.da34fa")
		})

		if choice21 == 1 then
			fui.text("tab", "aback", intl("efd00d.triggered_torture2.132544"))
			fui.var_decrement("tab_approval", 10)
		elseif choice21 == 2 then
			fui.text("tab", "indignant", intl("efd00d.triggered_torture2.490429"))
			fui.var_decrement("tab_approval", 5)
		elseif choice21 == 3 then
			fui.text("tab", "normal", intl("efd00d.triggered_torture2.858f8c"))
			fui.var_increment("tab_approval", 5)
			fui.set("promised_no_torture")
		end

		fui.wait_for_input()
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()

return scenes.skippable(function ()
	if stats.total_torture_damage > (variables.last_checked_torture_damage or 0) then
		variables.last_checked_torture_damage = stats.total_torture_damage

		if not variables.torture_warned1 then
			variables.torture_warned1 = true

			warning1(fui.new())
		elseif not variables.torture_warned2 then
			variables.torture_warned2 = true

			warning2(fui.new())
		elseif not variables.torture_warned3 then
			variables.torture_warned3 = true

			if variables.promised_no_torture then
				agents.increment_approval("tab", -20)
			end
		end
	end
end)
