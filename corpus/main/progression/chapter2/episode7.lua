local episode = require("main.progression.episode")
local store = require("level.store")
local table_util = require("crit.table_util")
local agents = require("campaign.agents")

return episode.create_episode({
	outcome_lose = {
		outcome_id = "factory",
		has_won = false,
		header_key = "outcome.lose",
		text_key = "outcome.episode7.lose",
		intl_namespace = "chapter2"
	},
	outcome_win = {
		outcome_id = "factory",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode7.win",
		intl_namespace = "chapter2"
	},
	import_flags = {
		"vn",
		"narrative",
		"mission_cafe",
		"mission_pods",
		"mission_criminals",
		"mission_expansion",
		"mission_circulara",
		"professor_collectivist",
		"professor_individualist",
		"professor_realist"
	},
	level_options = function ()
		local approval = agents.tab.approval
		local empathy = 0

		if approval <= 30 then
			empathy = -1
		elseif approval >= 100 then
			empathy = 2
		elseif approval >= 70 then
			empathy = 1
		end

		return {
			level = "episode7",
			stat_boosts = {
				tab = {
					empathy = empathy
				}
			}
		}
	end,
	post_episode = function ()
		local subject = store.get_subject("tab")

		if not subject then
			return
		end

		local boost = 0

		local function get_boost(stat, boosts)
			local value = boosts[stat]

			if value then
				return value
			end

			if stat < 0 then
				return boosts[1]
			end

			if stat > #boosts then
				return boosts[#boosts]
			end

			return 0
		end

		local empathy_boosts = {
			-5,
			0,
			0,
			5,
			5,
			10,
			10
		}
		boost = boost + get_boost(subject.empathy, empathy_boosts)
		local fear_boosts = {
			0,
			0,
			-5,
			-10,
			-15,
			-20,
			-25
		}
		boost = boost + get_boost(subject.fear, fear_boosts)

		if subject.torture_damage > 0 then
			boost = boost - 20
		end

		agents.increment_approval("tab", boost)
	end
})
