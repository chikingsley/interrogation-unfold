local variables = require("campaign.variables")
local episode = require("main.progression.episode")

return episode.create_episode({
	level = "episode6",
	outcome_lose = {
		outcome_id = "factory",
		has_won = false,
		header_key = "outcome.lose",
		text_key = "outcome.episode6.lose",
		intl_namespace = "chapter2"
	},
	outcome_win = {
		outcome_id = "running_police",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode6.win",
		intl_namespace = "chapter2"
	},
	post_episode = function ()
		variables.played_episode_6 = true
	end,
	import_flags = {
		"vn",
		"narrative",
		"mission_cafe",
		"mission_pods",
		"mission_criminals",
		"mission_expansion",
		"professor_collectivist",
		"professor_individualist",
		"professor_realist"
	}
})
