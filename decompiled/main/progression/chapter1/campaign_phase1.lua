local budget = require("campaign.budget")
local missions = require("campaign.missions")
local scenes = require("main.progression.scenes")
local office = require("campaign.office")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local cp = require("main.progression.campaign_phase")
local M = {}
local cp_index = 1
M.run = scenes.skippable(function ()
	local mission_list = {
		{
			intl_key = "monitor_chatroom",
			id = "monitor_chatroom",
			intl_namespace = "chapter1",
			position = cp.mission_positions.monitor_chatroom,
			modifiers = {
				tab = -10,
				mordecai = -20
			}
		},
		{
			intl_key = "pursue_advertisers",
			id = "pursue_advertisers",
			intl_namespace = "chapter1",
			position = cp.mission_positions.pursue_advertisers,
			modifiers = {
				mordecai = -15,
				tab = -15,
				jen = -30
			}
		}
	}

	cp.add_pursue_informer(mission_list)
	cp.add_tight_paperwork(mission_list, cp_index)
	cp.add_track_weapon(mission_list)
	cp.add_work_with_da(mission_list)
	cp.add_volunteer(mission_list, cp_index)
	cp.add_go_home_early(mission_list, cp_index)
	cp.add_formulate_budget_request(mission_list, cp_index)
	missions.set_options(mission_list)

	local budget_options = {}

	cp.add_order_hr(budget_options, cp_index)
	cp.add_extend_pr(budget_options, cp_index)
	cp.add_pr_assistance(budget_options, cp_index)
	cp.add_cf_overtime(budget_options, cp_index)
	cp.add_rnr_teambuilding(budget_options, cp_index)
	cp.add_co_overtime(budget_options, cp_index)
	cp.add_informer_stimulants(budget_options, cp_index, 1)
	cp.add_procedure_training(budget_options, cp_index)
	cp.add_therapy(budget_options, cp_index)
	budget.set_options(budget_options)
	cp.add_monthly_income()
	office.configure({
		wall = 2,
		newspaper = "newspaper1",
		focus_map = "episode1",
		objects = {
			"agent_files",
			"pr_report",
			"newspaper",
			"manual",
			"perks"
		}
	})

	variables.has_hr_report = true

	scenes.load_scene("briefing_room")
	scenes.wait_for_end_scene()
	budget.commit()
	cp.apply_budget()
	missions.commit()
	cp.apply_missions()
	cp.apply_fatigue()

	if missions.completed.monitor_chatroom then
		variables.mission_force = true
	end

	stats.commit("campaign")
end)

function M.expo()
	agents.commit()
	office.configure({
		newspaper = "newspaper1",
		wall = 2,
		has_briefing_room = false
	})
	scenes.load_scene("office")
	scenes.wait_for_end_scene()
	stats.commit()

	variables.classified_unlocked = false
end

return M
