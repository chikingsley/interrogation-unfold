local stats = require("campaign.stats")
local variables = require("campaign.variables")
local lose_fired = require("main.progression.triggered.lose_fired")
local lose_assassinated = require("main.progression.triggered.lose_assassinated")
local low_authorities_warning = require("main.progression.triggered.low_authorities_warning")
local low_popularity_warning = require("main.progression.triggered.low_popularity_warning")
local title = require("title.interface")
local scenes = require("main.progression.scenes")

local function lose_loop()
	title.show_slides({
		"You lost the game.\n\nClick to return to menu, then use Rewind to undo your wrongs."
	}, {
		auto_next_delay = 10000000
	})
	scenes.run_progression("menu")
	coroutine.yield(function ()
		return
	end)
end

local function triggered_loss()
	if stats.authorities <= 0 and variables.low_authorities_losable then
		lose_fired()
		lose_loop()

		return
	end

	if stats.popularity <= 0 and variables.low_popularity_losable then
		lose_assassinated()
		lose_loop()

		return
	end

	if stats.is_low("authorities") then
		variables.low_authorities_losable = true
	end

	if stats.is_low("popularity") then
		variables.low_popularity_losable = true
	end

	if stats.is_low("authorities") and not variables.low_authorities_warned then
		variables.low_authorities_warned = true

		low_authorities_warning()

		return
	end

	if stats.is_low("popularity") and not variables.low_popularity_warned then
		variables.low_popularity_warned = true

		low_popularity_warning()

		return
	end
end

return triggered_loss
