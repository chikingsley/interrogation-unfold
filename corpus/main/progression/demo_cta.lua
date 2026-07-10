local scenes = require("main.progression.scenes")
local sound_util = require("sound.util")
local progression = require("crit.progression")

local function demo_cta(options)
	sound_util.set_music(nil)
	scenes.load_scene("demo_cta", nil, {
		transition = "fade"
	})
	progression.wait_for_message("iap_bought_full_game")

	if options and options.continue_after_purchase then
		return
	end

	scenes.run_progression("campaign")
end

return demo_cta
