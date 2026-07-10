local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")

		if fui.var_get("has_joseph") then
			fui.load_characters("tab", "jen", "joseph")
		else
			fui.load_characters("tab", "jen")
		end

		fui.wait(2)
		fui.show_character("tab", "RIGHT", "normal")

		if fui.var_get("has_joseph") then
			fui.show_character("joseph", "RIGHT_CENTER", "neutral")
		end

		fui.wait(1)
		fui.text("tab", "asking", intl("81039c.interlude_i3.c42f56"))
		fui.text("tab", "asking", intl("81039c.interlude_i3.9ef858"))
		fui.text("tab", "explain", intl("81039c.interlude_i3.2821d8"))
		fui.text("tab", "explain", intl("81039c.interlude_i3.6cac22"))
		fui.text("tab", "asking", intl("81039c.interlude_i3.b71371"))
		fui.wait_for_input()
		fui.hide_bubbles()
		fui.animate("tab", "normal")
		fui.wait(1)
		fui.show_character("jen", "LEFT", "normal")
		fui.text("jen", "normal_angry", intl("81039c.interlude_i3.bfba56"))
		fui.text("jen", "pointing_angry", intl("81039c.interlude_i3.3dd50c"))
		fui.text("jen", "explain_angry", intl("81039c.interlude_i3.e48ec2"))

		if fui.var_get("has_joseph") then
			fui.text("joseph", "explaining", intl("81039c.interlude_i3.d9067a"))
			fui.wait_for_input()
			fui.animate("joseph", "neutral")
		else
			fui.text("jen", "explain_angry", intl("81039c.interlude_i3.d9067a"))
		end

		fui.text("jen", "explain_angry", intl("81039c.interlude_i3.bb53f6"))

		if fui.var_get("has_joseph") then
			fui.text("joseph", "angry_point", intl("81039c.interlude_i3.7e9bfb"))
		else
			fui.text("jen", "normal_angry", intl("81039c.interlude_i3.bae062"))
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
