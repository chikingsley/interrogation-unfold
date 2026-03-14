local episode = require("main.progression.episode")
local store = require("level.store")
local variables = require("campaign.variables")

return episode.create_episode({
	level = "episode1",
	outcome_win = {
		outcome_id = "manic_husband_win",
		text_key = "outcome.episode1.win",
		header_key = "outcome.win",
		intl_namespace = "chapter1"
	},
	import_flags = {
		"vn",
		"narrative"
	},
	post_episode = function ()
		local jerry = store.get_subject("jerry")
		local peterson = store.get_subject("peterson")
		variables.tortured_jerry = not not jerry and jerry.times_tortured > 0
		variables.tortured_peterson = not not peterson and peterson.times_tortured > 0
	end
})
