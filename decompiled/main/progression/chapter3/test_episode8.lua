local stats = require("campaign.stats")
local perks = require("campaign.perks")
local variables = require("campaign.variables")
local scenes = require("main.progression.scenes")
local episode8 = require("main.progression.chapter3.episode8")

return function (opts)
	opts = opts or {}
	opts.perks = opts.perks or {}
	opts.variables = opts.variables or {}
	opts.stats = opts.stats or {}

	for perk, value in pairs(opts.perks) do
		if value then
			perks.add_perk(perk, true)
		end
	end

	for stat, value in pairs(opts.stats) do
		if value then
			stats.set(stat, value)
		end
	end

	for k, v in pairs(opts.variables) do
		variables[k] = v
	end

	if opts.insanity then
		stats.set_insanity(opts.insanity)
	end

	episode8.run()
	scenes.run_progression("main")
end
