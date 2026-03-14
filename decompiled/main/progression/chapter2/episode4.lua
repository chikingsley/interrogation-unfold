local episode = require("main.progression.episode")

return episode.create_episode({
	level = "episode4",
	outcome_win = {
		outcome_id = "father_adams",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode4.win",
		intl_namespace = "chapter2"
	},
	import_flags = {
		"vn",
		"narrative",
		"mission_cafe",
		"mission_force",
		"explosive_details"
	}
})
