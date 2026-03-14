local episode = require("main.progression.episode")
local store = require("level.store")

return episode.create_episode({
	level_options = {
		bring_them_in_key = "level.patch_higgs_through",
		level = "episode5"
	},
	outcome_lose = function ()
		return {
			outcome_id = "tv_news",
			has_won = false,
			header_key = "outcome.lose",
			intl_namespace = "chapter2",
			text_key = store.has_flag("silvia_released") and "outcome.episode5.lose.singular" or "outcome.episode5.lose"
		}
	end,
	outcome_win = {
		outcome_id = "tv_news",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode5.win",
		intl_namespace = "chapter2"
	},
	import_flags = {
		"vn",
		"narrative",
		"mission_force",
		"mission_pods",
		"mission_criminals"
	}
})
