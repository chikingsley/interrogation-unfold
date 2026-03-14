local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local stats = require("campaign.stats")
local save_file = require("lib.save_file")
local selection_state = require("interludes.selection.state")
local cutscene_data = require("spine_cutscene.cutscene_final.cutscene_data")
local intl = require("crit.intl")
local sound_util = require("sound.util")
intl = intl.namespace("chapter3")

return scenes.skippable(function ()
	sound_util.set_music("event:/Cutscenes/Cutscene Final/Music", "Cutscene Final.bank")

	local endings = {
		{
			"good",
			stats.lawful
		},
		{
			"vigilante",
			stats.justice
		},
		{
			"marxist",
			stats.equity
		},
		{
			"ancap",
			stats.freedom
		},
		{
			"apocalyptic",
			stats.evolution * 1.35
		}
	}

	table.sort(endings, function (a, b)
		return b[2] < a[2]
	end)

	local available_endings = {
		[endings[1][1]] = true,
		[endings[2][1]] = true,
		[endings[3][1]] = true
	}
	local options = {}

	if available_endings.good then
		table.insert(options, {
			name = "good",
			spine_scene = "arrest",
			id = cutscene_data.endings.GOOD,
			label = intl("final_cutscene.select.label.good"),
			tooltip = intl("final_cutscene.select.tooltip.good")
		})
	end

	if available_endings.vigilante then
		table.insert(options, {
			name = "vigilante",
			spine_scene = "execute",
			id = cutscene_data.endings.VIGILANTE,
			label = intl("final_cutscene.select.label.vigilante"),
			tooltip = intl("final_cutscene.select.tooltip.vigilante")
		})
	end

	if available_endings.marxist then
		table.insert(options, {
			name = "marxist",
			spine_scene = "anaba",
			id = cutscene_data.endings.MARXIST,
			label = intl("final_cutscene.select.label.marxist"),
			tooltip = intl("final_cutscene.select.tooltip.marxist")
		})
	end

	if available_endings.ancap then
		table.insert(options, {
			name = "ancap",
			spine_scene = "reed",
			id = cutscene_data.endings.ANCAP,
			label = intl("final_cutscene.select.label.ancap"),
			tooltip = intl("final_cutscene.select.tooltip.ancap")
		})
	end

	if available_endings.apocalyptic then
		table.insert(options, {
			name = "apocalyptic",
			spine_scene = "james",
			id = cutscene_data.endings.APOCALYPTIC,
			label = intl("final_cutscene.select.label.apocalyptic"),
			tooltip = intl("final_cutscene.select.tooltip.apocalyptic")
		})
	end

	selection_state.set_options(1, options)

	selection_state.confirm_label = intl("final_cutscene.select.confirm")
	selection_state.select_more_label = intl("final_cutscene.select.select_more")
	selection_state.title = intl("final_cutscene.select.title")

	selection_state.reset()
	scenes.load_scene("end_select")

	local selections = progression.wait_for_message("selection_finished").selections

	sound_util.set_music_parameter("Confirm", 1)

	selection_state.confirm_label = nil
	selection_state.select_more_label = nil
	selection_state.title = nil
	local option_name = nil
	local cutscene_id = cutscene_data.endings.GOOD

	for i, value in ipairs(selections) do
		if value then
			cutscene_id = options[i].id
			option_name = options[i].name

			break
		end
	end

	cutscene_data.ending = cutscene_id

	scenes.wait_for_end_scene()
	save_file.set_global("won_game", true)

	if option_name then
		save_file.set_global("ending_" .. option_name, true)
	end

	scenes.load_scene("spine_cutscene", {
		cutscene = "cutscene_final"
	}, {
		no_in_zoom = true
	})

	local is_short = cutscene_id == cutscene_data.endings.GOOD or cutscene_id == cutscene_data.endings.VIGILANTE

	sound_util.set_music_parameter("IsShort", is_short and 1 or 0)
	sound_util.set_music_parameter("Phase", 2)
	scenes.wait_for_end_scene()
	scenes.load_scene("outcome", {
		outcome_id = "lore_cards"
	})
	scenes.wait_for_end_scene()
	sound_util.set_music_parameter("Phase", 3)
end)
