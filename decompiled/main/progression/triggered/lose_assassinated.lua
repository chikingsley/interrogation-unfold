local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local dispatcher = require("crit.dispatcher")
local progression = require("crit.progression")
local interludes = require("interludes.interface")
local save_file = require("lib.save_file")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.set_preset_music("campaign")
		fui.load_interlude("street")
		fui.load_characters("jen", "mordecai")
		fui.wait(2)
		fui.show_character("jen", "RIGHT", "normal")
		fui.show_character("mordecai", "LEFT", "normal")
		fui.wait(1)
		fui.text("mordecai", "normal", intl("efd00d.triggered_assassinated.8fd561"))
		fui.text("mordecai", "hips", intl("efd00d.triggered_assassinated.80f972"))
		fui.text("jen", "explain", intl("efd00d.triggered_assassinated.cd2190"))
		fui.text("mordecai", "gun", intl("efd00d.triggered_assassinated.de3bd4"))

		local choice18 = fui.choose({
			intl("efd00d.triggered_assassinated.90fdfe"),
			intl("efd00d.triggered_assassinated.1b3db5"),
			intl("efd00d.triggered_assassinated.53707b")
		})

		if choice18 == 1 then
			-- Nothing
		elseif choice18 == 2 then
			-- Nothing
		elseif choice18 == 3 then
			-- Nothing
		end

		fui.text("jen", "normal_smile", intl("efd00d.triggered_assassinated.e15c42"))
		fui.wait_for_input()
		fui.hide_bubbles()
		fui.hide_character("mordecai")
		fui.wait(2)
		fui.text("jen", "mega_dissapointed", intl("efd00d.triggered_assassinated.d1db17"))
		fui.text("jen", "normal_angry", intl("efd00d.triggered_assassinated.efe573"))
		fui.text("jen", "pointing_angry", intl("efd00d.triggered_assassinated.2b07b4"))
		fui.set_preset_music()
		fui.wait_for_input()
		fui.pcall("die")
	end
end()
local h_assassinated_rewind = hash("assassinated_rewind")
local h_interludes_spawn_accessory = hash("interludes_spawn_accessory")

return scenes.skippable(function ()
	func(fui.new({
		die = function ()
			dispatcher.dispatch(h_interludes_spawn_accessory, {
				accessory = "assassinated"
			})
			progression.fork(function ()
				progression.wait(0.2)
				interludes.hide_bubbles()
			end)
			progression.wait_for_message(h_assassinated_rewind)
			dispatcher.dispatch(h_interludes_spawn_accessory, {
				accessory = "rewind"
			})
			save_file.set_global("lose_assassinated", true)
			coroutine.yield(function ()
				return
			end)
		end
	}))
end)
