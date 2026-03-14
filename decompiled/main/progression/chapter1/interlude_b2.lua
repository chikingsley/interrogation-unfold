local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local commentary = require("main.progression.commentary.index")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("chief", "jen", "tab")
		fui.wait(2)
		fui.show_character("chief", "LEFT", "normal")
		fui.wait(1)
		fui.text("chief", nil, intl("7f031e.interlude_b2.58ef91"))
		fui.text("chief", "bossss", intl("7f031e.interlude_b2.eec533"))
		fui.text("chief", "normal", intl("7f031e.interlude_b2.e48e38"))
		fui.show_character("tab", "RIGHT_CENTER", "normal")
		fui.text("tab", "asking", intl("7f031e.interlude_b2.9ceb33"))
		fui.text("chief", "normal", intl("7f031e.interlude_b2.320c7f"))
		fui.animate("tab", "normal")
		fui.show_character("jen", "RIGHT", "normal")
		fui.text("jen", "normal_smile", intl("7f031e.interlude_b2.6906ad"))
		fui.text("chief", nil, intl("7f031e.interlude_b2.2a18b2"))
		fui.animate("jen", "normal")
		fui.text("chief", nil, intl("7f031e.interlude_b2.bcc4ea"))
		fui.wait_for_input()
		fui.hide_character("chief")
		fui.wait(1)
		fui.text("jen", "explain_smile", intl("7f031e.interlude_b2.f40693"))
		fui.text("tab", "defensive", intl("7f031e.interlude_b2.bfd5fe"))

		local choice35 = fui.choose({
			intl("7f031e.interlude_b2.8596ed"),
			intl("7f031e.interlude_b2.14cf3f"),
			intl("7f031e.interlude_b2.10ac7b")
		})

		if choice35 == 1 then
			fui.hide_bubbles()
			fui.var_increment("jen_approval", 10)
			fui.var_decrement("tab_approval", 10)
			fui.animate("jen", "normal_smile")
			fui.animate("tab", "disgust")
		elseif choice35 == 2 then
			fui.hide_bubbles()
			fui.var_decrement("jen_approval", 5)
			fui.var_increment("tab_approval", 5)
			fui.var_increment("lawful", 1)
			fui.animate("jen", "normal_angry")
			fui.animate("tab", "listening")
		elseif choice35 == 3 then
			fui.hide_bubbles()
			fui.var_decrement("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
			fui.var_increment("justice", 1)
			fui.animate("jen", "normal_angry")
			fui.animate("tab", "indignant")
			fui.var_increment("authorities", 5)
		end

		fui.pcall("commentary_agent_choice")
		fui.wait(2)
		fui.hide_all_characters()
		fui.commit_stats("interlude")
	end
end()

return scenes.skippable(function ()
	func(fui.new({
		commentary_agent_choice = function ()
			if commentary.agent_choice.overlay_once() then
				commentary.wait_for_commentary()
			end
		end
	}))
end)
