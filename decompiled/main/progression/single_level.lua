local episode = require("main.progression.episode")
local scenes = require("main.progression.scenes")
local perks = require("campaign.perks")
local stats = require("campaign.stats")

return function (options)
	if type(options) == "string" then
		options = {
			level = options
		}
	end

	local ep = episode.create_episode({
		level_options = options,
		outcome_lose = {
			outcome_id = "chief_office",
			text = "You failed to achieve your goal in time.",
			header = "Interrogation Failed"
		},
		pre_load = function ()
			perks.reset()
			stats.reset()

			if options.insanity then
				stats.set_insanity(options.insanity)
			end

			if options.cruelty then
				stats.set_cruelty(options.cruelty)
			end

			if options.perks then
				for k, perk in ipairs(options.perks) do
					perks.add_perk(perk)
				end
			end
		end
	})

	ep.run()
	scenes.load_scene("menu")
end
