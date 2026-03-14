local budget = require("campaign.budget")
local missions = require("campaign.missions")
local scenes = require("main.progression.scenes")
local office = require("campaign.office")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local cp = require("main.progression.campaign_phase")
local M = {}
local cp_index = 7
M.run = scenes.skippable(function ()
	local mission_list = {
		{
			intl_key = "report_elias",
			id = "report_elias",
			intl_namespace = "chapter3",
			position = cp.mission_positions.report_elias,
			modifiers = {
				mordecai = -15,
				joseph = -5,
				jen = -30
			}
		},
		{
			intl_key = "denounce_elias",
			id = "denounce_elias",
			intl_namespace = "chapter3",
			position = cp.mission_positions.denounce_elias,
			modifiers = {
				joseph = -15,
				tab = -30,
				mordecai = -15
			}
		},
		{
			intl_key = "organise_press_conference",
			id = "organise_press_conference",
			intl_namespace = "chapter3",
			position = cp.mission_positions.organise_press_conference,
			modifiers = {
				joseph = -15,
				tab = -15,
				mordecai = -15
			}
		},
		{
			intl_key = "rumour_mongering",
			id = "rumour_mongering",
			intl_namespace = "chapter3",
			position = cp.mission_positions.rumour_mongering,
			modifiers = {
				joseph = -20,
				tab = -30,
				jen = -10
			}
		},
		{
			intl_key = "city_hall_brief",
			id = "city_hall_brief",
			intl_namespace = "chapter3",
			position = cp.mission_positions.city_hall_brief,
			modifiers = {
				mordecai = -10,
				joseph = -5,
				jen = -20
			}
		},
		{
			intl_key = "brief_interpol",
			id = "brief_interpol",
			intl_namespace = "chapter3",
			position = cp.mission_positions.brief_interpol,
			modifiers = {
				mordecai = -10,
				joseph = -5,
				jen = -10
			}
		}
	}

	cp.add_pursue_informer(mission_list)
	cp.add_recruit_informer(mission_list)
	cp.add_contact_informer(mission_list)
	cp.add_tight_paperwork(mission_list, cp_index)
	cp.add_negotiate_with_da(mission_list)
	cp.add_volunteer(mission_list, cp_index)
	cp.add_formulate_budget_request(mission_list, cp_index)
	missions.set_options(mission_list)

	local negotiate_with_da = missions.get_option("negotiate_with_da")

	if negotiate_with_da then
		negotiate_with_da.position = cp.mission_positions.go_home_early
	end

	local budget_options = {}

	cp.add_order_hr(budget_options, cp_index)
	cp.add_extend_pr(budget_options, cp_index)
	cp.add_bonuses_for_agents(budget_options, cp_index)
	cp.add_pr_assistance(budget_options, cp_index)
	cp.add_rnr_teambuilding(budget_options, cp_index)
	cp.add_informer_stimulants(budget_options, cp_index)
	cp.add_procedure_training(budget_options, cp_index)
	cp.add_therapy(budget_options, cp_index)
	table.insert(budget_options, {
		id = "wilson_donation",
		intl_key = "wilson_donation",
		cost = 2500,
		intl_namespace = "chapter3"
	})
	budget.set_options(budget_options)
	cp.add_monthly_income()
	office.configure({
		newspaper = "newspaper6",
		wall = 8
	})
	scenes.load_scene("briefing_room")
	scenes.wait_for_end_scene()
	budget.commit()
	cp.apply_budget()

	if budget.is_selected("wilson_donation") then
		agents.increment_approval("jen", 5)
		agents.increment_approval("tab", 5)
		agents.increment_approval("mordecai", 5)
		agents.increment_approval("joseph", 5)
		stats.increment_press(5)
		stats.increment_authorities(-5)
		stats.increment_popularity(10)
		stats.increment_cruelty(-1)
		stats.increment_insanity(-1)
	end

	missions.commit()
	cp.apply_missions()

	if missions.previous_assigned_character.denounce_elias then
		variables.tried_denounce_elias = true

		stats.increment_authorities(-10)
	end

	if missions.previous_assigned_character.organise_press_conference then
		variables.tried_press_conference = true
	end

	if missions.completed.denounce_elias then
		stats.increment_press(10)
	end

	if missions.completed.report_elias and not missions.previous_assigned_character.denounce_elias then
		stats.increment_authorities(5)
	end

	if missions.completed.organise_press_conference then
		stats.increment_press(10)
		stats.increment_popularity(5)
	end

	if missions.completed.city_hall_brief and not missions.previous_assigned_character.organise_press_conference then
		stats.increment_authorities(5)
	end

	if missions.completed.brief_interpol then
		stats.increment_authorities(5)
	end

	cp.apply_fatigue()
	stats.commit("campaign")
end)

function M.expo()
	agents.commit()
	office.configure({
		newspaper = "newspaper7",
		wall = 8,
		has_briefing_room = false
	})
	scenes.load_scene("office")
	scenes.wait_for_end_scene()
	stats.commit()

	variables.classified_unlocked = false
end

return M
