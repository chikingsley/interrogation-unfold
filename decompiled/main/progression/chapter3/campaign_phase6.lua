local budget = require("campaign.budget")
local missions = require("campaign.missions")
local scenes = require("main.progression.scenes")
local office = require("campaign.office")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local cp = require("main.progression.campaign_phase")
local M = {}
local cp_index = 6
M.run = scenes.skippable(function ()
	local mission_list = {}

	cp.add_pursue_informer(mission_list)
	cp.add_recruit_informer(mission_list)
	cp.add_contact_informer(mission_list)
	cp.add_tight_paperwork(mission_list, cp_index)
	cp.add_track_weapon(mission_list)
	cp.add_consult_senior_officer(mission_list)
	cp.add_consult_academic(mission_list)
	cp.add_work_with_da(mission_list)
	cp.add_lobby_for_donations(mission_list)
	cp.add_negotiate_with_da(mission_list)
	cp.add_volunteer(mission_list, cp_index)
	cp.add_go_home_early(mission_list, cp_index)
	cp.add_formulate_budget_request(mission_list, cp_index)
	missions.set_options(mission_list)

	local budget_options = {}

	cp.add_order_hr(budget_options, cp_index)
	cp.add_extend_pr(budget_options, cp_index)
	cp.add_bonuses_for_agents(budget_options, cp_index)
	cp.add_pr_assistance(budget_options, cp_index)
	cp.add_cf_overtime(budget_options, cp_index)
	cp.add_rnr_teambuilding(budget_options, cp_index)
	cp.add_co_overtime(budget_options, cp_index)
	cp.add_informer_stimulants(budget_options, cp_index)
	cp.add_past_service_bonus(budget_options, cp_index)
	cp.add_university_grant(budget_options, cp_index)
	cp.add_procedure_training(budget_options, cp_index)
	cp.add_therapy(budget_options, cp_index)
	budget.set_options(budget_options)
	cp.add_monthly_income()
	office.configure({
		newspaper = "newspaper5",
		wall = 7
	})
	scenes.load_scene("briefing_room")
	scenes.wait_for_end_scene()
	budget.commit()
	cp.apply_budget()
	missions.commit()
	cp.apply_missions()
	cp.apply_fatigue()
	stats.commit("campaign")
end)

function M.expo()
	agents.commit()
	office.configure({
		newspaper = "newspaper6",
		wall = 7,
		has_briefing_room = false
	})
	scenes.load_scene("office")
	scenes.wait_for_end_scene()
	stats.commit()

	variables.classified_unlocked = false
end

return M
