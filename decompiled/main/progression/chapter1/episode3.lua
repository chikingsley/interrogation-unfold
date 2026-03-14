local episode = require("main.progression.episode")

return episode.create_episode({
	level_options = {
		demo_break = true,
		level = "episode3"
	},
	outcome_lose = {
		outcome_id = "mall_bombing_lose",
		text_key = "outcome.episode3.lose",
		header_key = "outcome.lose",
		intl_namespace = "chapter1"
	},
	import_flags = {
		"vn",
		"narrative",
		"mission_force"
	}
})
