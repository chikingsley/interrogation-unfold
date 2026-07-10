local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local dispatcher = require("crit.dispatcher")
local interludes = require("interludes.interface")
local episode = require("main.progression.episode")
local selection_state = require("interludes.selection.state")
local intl = require("crit.intl")
local store = require("level.store")
local variables = require("campaign.variables")
intl = intl.namespace("chapter3")

return episode.create_episode({
	level = "episode9",
	outcome_lose = {
		outcome_id = "honest_abe",
		has_won = false,
		header_key = "outcome.lose",
		text_key = "outcome.episode9.lose",
		intl_namespace = "chapter3"
	},
	outcome_win = {
		outcome_id = "helicopter",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode9.win",
		intl_namespace = "chapter3"
	},
	import_flags = {
		"vn",
		"narrative",
		"mission_criminals",
		"mission_circulara",
		"mission_expansion",
		"mission_prison_recruitment",
		"mission_prison",
		"professor_Torpix",
		"professor_burgundy"
	},
	level_options = function ()
		scenes.load_scene("interludes", {
			background = "office_floor"
		})
		interludes.preload_characters({
			"tab"
		})
		progression.wait(1.5)
		interludes.show_character("tab", interludes.LEFT, {
			large_ui_fixed = true
		})
		progression.wait(1)
		interludes.show_bubble("tab", intl("character_selection.prompt"))
		progression.wait(1)
		selection_state.set_options(2, {
			{
				image = "valerie",
				label = intl("episode9.select.name.valerie"),
				tooltip = intl("episode9.select.tooltip.valerie")
			},
			{
				image = "anaba",
				label = intl("episode9.select.name.anaba"),
				tooltip = intl("episode9.select.tooltip.anaba")
			},
			{
				image = "dennis",
				label = intl("episode9.select.name.dennis"),
				tooltip = intl("episode9.select.tooltip.dennis")
			},
			{
				image = "reed",
				label = intl("episode9.select.name.reed"),
				tooltip = intl("episode9.select.tooltip.reed")
			}
		})
		dispatcher.dispatch("interludes_spawn_accessory", {
			accessory = "selection_episode9"
		})

		local selections = progression.wait_for_message("selection_finished").selections

		dispatcher.dispatch("selection_dismiss")
		interludes.show_bubble("tab", intl("character_selection.prompt_confirm"))
		interludes.wait_for_input()
		interludes.hide_all_characters()

		local disabled_subjects = {}

		for i, enabled in ipairs(selections) do
			if not enabled then
				disabled_subjects[#disabled_subjects + 1] = selection_state.options[i].image
			end
		end

		return {
			music_bank = "Level episode1.bank",
			music = "event:/Level Music/episode1",
			level = "episode9",
			disabled_subjects = disabled_subjects
		}
	end,
	post_episode = function ()
		local anaba = store.get_subject("anaba")
		local reed = store.get_subject("reed")
		variables.ep9_anaba_fear = anaba and anaba.shown and anaba.fear or 0
		variables.ep9_anaba_empathy = anaba and anaba.shown and anaba.empathy or 0
		variables.ep9_reed_fear = reed and reed.shown and reed.fear or 0
		variables.ep9_reed_empathy = reed and reed.shown and reed.empathy or 0
	end
})
