local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("honest_abe", "tristan", "chief")
		fui.wait(2)
		fui.show_character("honest_abe", "LEFT", "phone")
		fui.show_character("chief", "RIGHT", "thinking")
		fui.show_character("tristan", "RIGHT_CENTER", "arms_crossed")
		fui.wait(1)
		fui.text("honest_abe", "disgust", intl("81039c.interlude_j.5f01b5"))

		local choice11 = fui.choose({
			intl("81039c.interlude_j.00aa36"),
			intl("81039c.interlude_j.df01d7"),
			intl("81039c.interlude_j.935a23")
		})

		if choice11 == 1 then
			fui.hide_bubbles()
			fui.animate("honest_abe", "wtf")
			fui.var_increment("lawful", 1)
		elseif choice11 == 2 then
			fui.hide_bubbles()
			fui.animate("honest_abe", "wtf")
			fui.var_increment("justice", 1)
		elseif choice11 == 3 then
			fui.hide_bubbles()
			fui.animate("honest_abe", "wtf")
			fui.animate("chief", "bossss")
			fui.animate("tristan", "glasses")
			fui.var_increment("justice", 2)
		end

		fui.wait(1)
		fui.text("tristan", "explain", intl("81039c.interlude_j.8cb639"))
		fui.text("honest_abe", "calm_down", intl("81039c.interlude_j.07e0ce"))
		fui.animate("tristan", "arms_crossed")
		fui.animate("chief", "thinking")
		fui.text("honest_abe", "explain2", intl("81039c.interlude_j.db0a07"))
		fui.text("honest_abe", "explain2", intl("81039c.interlude_j.74a47d"))
		fui.text("honest_abe", "arms_crossed", intl("81039c.interlude_j.22ab97"))
		fui.text("honest_abe", "arms_crossed", intl("81039c.interlude_j.6b4efc"))
		fui.text("honest_abe", "paper", intl("81039c.interlude_j.b198af"))
		fui.text("honest_abe", "paper", intl("81039c.interlude_j.bde845"))
		fui.text("tristan", "glasses", intl("81039c.interlude_j.3030dc"))
		fui.text("chief", "worried", intl("81039c.interlude_j.612ab4"))
		fui.animate("tristan", "arms_crossed")
		fui.text("honest_abe", "hand", intl("81039c.interlude_j.3322d9"))
		fui.text("honest_abe", "hand", intl("81039c.interlude_j.0c12f6"))
		fui.hide_character("honest_abe")

		local choice60 = fui.choose({
			intl("81039c.interlude_j.24376e"),
			intl("81039c.interlude_j.4a9f45"),
			intl("81039c.interlude_j.f9cc84")
		})

		if choice60 == 1 then
			fui.hide_bubbles()
			fui.animate("chief", "fuck_it")
			fui.animate("tristan", "arms_crossed")
			fui.var_increment("lawful", 1)
			fui.wait(2)
		elseif choice60 == 2 then
			fui.hide_bubbles()
			fui.animate("chief", "smiling")
			fui.animate("tristan", "thumbs_up")
			fui.wait(2)
		elseif choice60 == 3 then
			fui.var_increment("justice", 1)
			fui.text("chief", "get_out", intl("81039c.interlude_j.65026d"))
			fui.animate("tristan", "arms_crossed")
		end

		fui.text("chief", "normal", intl("81039c.interlude_j.2e85a6"))
		fui.animate("tristan", "arms_crossed")
		fui.text("tristan", "explain", intl("81039c.interlude_j.1b937f"))
		fui.text("chief", "bossss", intl("81039c.interlude_j.5ef606"))
		fui.animate("tristan", "arms_crossed")
		fui.text("chief", "fuck_it", intl("81039c.interlude_j.35142b"))
		fui.text("chief", "fuck_it", intl("81039c.interlude_j.d5d6f2"))
		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
