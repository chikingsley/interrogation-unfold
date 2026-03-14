local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local dispatcher = require("crit.dispatcher")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("jen", "tab", "mordecai")
		fui.wait(2)
		fui.show_character("jen", "LEFT")
		fui.show_character("tab", "RIGHT_CENTER")
		fui.show_character("mordecai", "RIGHT")
		fui.wait(1)
		fui.pcall("show_picture")
		fui.wait(1)

		local choice12 = fui.choose({
			intl("80035d.jigsaw_conclusion.fe0368")
		})

		if choice12 == 1 then
			-- Nothing
		end

		fui.wait(1)
		fui.hide_all_characters()
		fui.wait(1)
	end
end()

return scenes.skippable(function ()
	func(fui.new({
		show_picture = function ()
			dispatcher.dispatch("interludes_spawn_accessory", {
				accessory = "elevator_image"
			})
		end
	}))
end)
