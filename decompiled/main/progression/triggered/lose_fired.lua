local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local dispatcher = require("crit.dispatcher")
local scenes = require("main.progression.scenes")
local save_file = require("lib.save_file")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.set_preset_music("campaign")
		fui.load_interlude("chief_office")
		fui.load_characters("dummy")
		fui.show_character("dummy", "CHIEF", false, "chief")
		fui.wait(2)
		fui.text("dummy", nil, intl("efd00d.triggered_fired.6c18b8"))
		fui.text("dummy", nil, intl("efd00d.triggered_fired.7583b1"))
		fui.text("dummy", nil, intl("efd00d.triggered_fired.5c87fd"))
		fui.text("dummy", nil, intl("efd00d.triggered_fired.94be6d"))
		fui.text("dummy", nil, intl("efd00d.triggered_fired.d076b9"))
		fui.wait_for_input()
		fui.hide_bubbles()
		fui.pcall("rewind")
	end
end()

return scenes.skippable(function ()
	func(fui.new({
		rewind = function ()
			dispatcher.dispatch("interludes_spawn_accessory", {
				accessory = "rewind"
			})
			save_file.set_global("lose_fired", true)
			coroutine.yield(function ()
				return
			end)
		end
	}))
end)
