local episode = require("main.progression.episode")

return episode.create_episode({
	level = "episode2",
	outcome_lose = {
		outcome_id = "chatroom",
		has_won = false,
		header_key = "outcome.lose",
		text_key = "outcome.episode2.lose",
		intl_namespace = "chapter1"
	},
	outcome_win = {
		outcome_id = "chatroom",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode2.win",
		intl_namespace = "chapter1"
	},
	import_flags = {
		"vn",
		"narrative"
	},
	export_flags = {
		"fred-cat"
	}
})
