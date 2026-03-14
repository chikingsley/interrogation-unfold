local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local dispatcher = require("crit.dispatcher")
local interludes = require("interludes.interface")

return function ()
	scenes.load_scene("interludes", {
		background = "office_floor"
	})
	interludes.preload_characters({
		"jen"
	})
	interludes.wait_for_input()
	interludes.show_character("jen", interludes.LEFT)
	interludes.show_bubble("jen", "Hi!")
	interludes.wait_for_input()
	interludes.show_bubble("jen", "Who should we bring in? We only have the resources to fetch 2 of them.")
	dispatcher.dispatch("interludes_spawn_accessory", {
		accessory = "selection",
		properties = {
			["/controller"] = {
				required_item_count = 2
			}
		}
	})

	local selections = progression.wait_for_message("selection_finished")

	pprint(selections)
	dispatcher.dispatch("selection_dismiss")
	interludes.show_bubble("jen", "Good! We can begin.")
	interludes.wait_for_input()
	interludes.hide_all_characters()
end
