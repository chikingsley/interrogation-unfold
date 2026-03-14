local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local dispatcher = require("crit.dispatcher")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("mordecai")
		fui.wait(2)
		fui.show_character("mordecai", "RIGHT")
		fui.wait(1)
		fui.pcall("show_picture")
		fui.wait(1)

		local choice11 = fui.choose({
			intl("81039c.jigsaw_conclusion2.732923")
		})

		if choice11 == 1 then
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
				accessory = "document_image"
			})
		end
	}))
end)
