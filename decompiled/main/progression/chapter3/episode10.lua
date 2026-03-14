local episode = require("main.progression.episode")
local missions = require("campaign.missions")
local variables = require("campaign.variables")
local store = require("level.store")

return episode.create_episode({
	level = "episode10",
	import_flags = {
		"vn",
		"narrative",
		"mission_cafe",
		"mission_pods",
		"professor_anaba_reed",
		"professor_anaba_colonel",
		"professor_reed_colonel",
		"professor_history",
		"mission_circulara",
		"mission_expansion",
		"mission_prison"
	},
	outcome_lose = {
		outcome_id = "honest_abe",
		has_won = false,
		header_key = "outcome.lose",
		text_key = "outcome.episode10.lose",
		intl_namespace = "chapter3"
	},
	level_options = function ()
		local function dampen(x)
			if not x then
				return 0
			end

			if x >= 0 then
				return math.floor(x / 3)
			end

			return math.ceil(x / 3)
		end

		return {
			level = "episode10",
			stat_boosts = {
				anaba = {
					fear = dampen(variables.ep9_anaba_fear),
					empathy = dampen(variables.ep9_anaba_empathy)
				},
				reed = {
					fear = dampen(variables.ep9_reed_fear),
					empathy = dampen(variables.ep9_reed_empathy)
				}
			}
		}
	end,
	post_load = function ()
		if missions.completed.rumour_mongering and not missions.previous_assigned_character.organise_press_conference and not variables.tried_press_conference then
			for subject_id, subject in ipairs(store.subjects) do
				subject.fear = subject.fear + 1
			end
		end
	end
})
