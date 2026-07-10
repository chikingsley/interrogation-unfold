local budget = require("campaign.budget")
local missions = require("campaign.missions")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local M = {}
local university_grant_boost = 30
local senior_officer_boost = 20
M.mission_positions = {
	tight_paperwork = {
		x = 0.16,
		y = 0.268
	},
	informer = {
		x = 0.083,
		y = 0.947
	},
	track_weapon = {
		x = 0.977,
		y = 0.39
	},
	work_with_da = {
		x = 0.082,
		y = 0.593
	},
	consult_senior_officer = {
		x = 0.643,
		y = 0.985
	},
	consult_academic = {
		x = 0.492,
		y = 0.493
	},
	negotiate_with_da = {
		x = 0.382,
		y = 0.807
	},
	lobby_for_donations = {
		x = 0.828,
		y = 0.649
	},
	monitor_chatroom = {
		x = 0.825,
		y = 0.65
	},
	pursue_advertisers = {
		x = 0.478,
		y = 0.498
	},
	consult_explosive_forensics = {
		x = 0.501,
		y = 0.501
	},
	report_elias = {
		x = 0.37,
		y = 0.807
	},
	denounce_elias = {
		x = 0.831,
		y = 0.65
	},
	organise_press_conference = {
		x = 0.982,
		y = 0.386
	},
	rumour_mongering = {
		x = 0.643,
		y = 0.983
	},
	city_hall_brief = {
		x = 0.509,
		y = 0.488
	},
	brief_interpol = {
		x = 0.085,
		y = 0.589
	},
	formulate_budget_request = {
		x = 0.733,
		y = 0.277
	},
	volunteer = {
		x = 0.47,
		y = 0.147
	},
	go_home_early = {
		x = 0.936,
		y = 0.937
	}
}

function M.add_tight_paperwork(mission_list, cp_index)
	table.insert(mission_list, {
		class_id = "tight_paperwork",
		intl_key = "tight_paperwork",
		intl_namespace = "campaign",
		id = "tight_paperwork" .. cp_index,
		cp_index = cp_index,
		position = M.mission_positions.tight_paperwork,
		modifiers = {
			mordecai = -10,
			joseph = -20,
			jen = -20
		}
	})
end

function M.apply_tight_paperwork(cp_index)
	if missions.completed["tight_paperwork" .. cp_index] then
		stats.increment_authorities(5)

		variables.tight_paperwork = true
	end
end

function M.add_pursue_informer(mission_list)
	if not missions.completed.pursue_informer then
		table.insert(mission_list, {
			intl_key = "pursue_informer",
			id = "pursue_informer",
			intl_namespace = "campaign",
			position = M.mission_positions.informer,
			modifiers = {
				mordecai = -40,
				joseph = -40,
				tab = -50,
				jen = -30
			}
		})
	end
end

function M.apply_pursue_informer()
	if missions.completed.pursue_informer then
		variables.pursue_informer = missions.previous_assigned_character.pursue_informer
	end
end

function M.add_recruit_informer(mission_list)
	if missions.completed.pursue_informer and not missions.completed.recruit_informer then
		table.insert(mission_list, {
			intl_key = "recruit_informer",
			id = "recruit_informer",
			intl_namespace = "campaign",
			position = M.mission_positions.informer,
			modifiers = {
				joseph = -15,
				tab = -30,
				mordecai = -15
			}
		})
	end
end

function M.apply_recruit_informer()
	if missions.completed.recruit_informer then
		variables.recruit_informer = missions.previous_assigned_character.recruit_informer
	end
end

function M.add_contact_informer(mission_list)
	if missions.completed.recruit_informer and not missions.completed.contact_informer then
		table.insert(mission_list, {
			intl_key = "contact_informer",
			id = "contact_informer",
			intl_namespace = "campaign",
			position = M.mission_positions.informer,
			modifiers = {
				joseph = -15,
				tab = -30,
				mordecai = -15
			}
		})
	end
end

function M.apply_contact_informer()
	if missions.completed.contact_informer then
		variables.contact_informer = true
	end
end

function M.add_formulate_budget_request(mission_list, cp_index)
	table.insert(mission_list, {
		class_id = "formulate_budget_request",
		intl_key = "formulate_budget_request",
		intl_namespace = "campaign",
		id = "formulate_budget_request" .. cp_index,
		cp_index = cp_index,
		position = M.mission_positions.formulate_budget_request,
		modifiers = {
			mordecai = -20,
			joseph = -30,
			tab = -10,
			jen = -30
		}
	})
end

function M.apply_formulate_budget_request(cp_index)
	local mission_id = "formulate_budget_request" .. cp_index

	if missions.completed[mission_id] then
		budget.increment_capacity(500)
	end
end

function M.add_volunteer(mission_list, cp_index)
	table.insert(mission_list, {
		class_id = "volunteer",
		intl_key = "volunteer",
		intl_namespace = "campaign",
		id = "volunteer" .. cp_index,
		cp_index = cp_index,
		position = M.mission_positions.volunteer,
		modifiers = {
			mordecai = -10,
			joseph = -30,
			tab = -10,
			jen = -10
		}
	})
end

function M.apply_volunteer(cp_index)
	local mission_id = "volunteer" .. cp_index

	if missions.completed[mission_id] then
		stats.increment_authorities(5)
	end
end

function M.add_go_home_early(mission_list, cp_index)
	table.insert(mission_list, {
		class_id = "go_home_early",
		intl_key = "go_home_early",
		intl_namespace = "campaign",
		id = "go_home_early" .. cp_index,
		cp_index = cp_index,
		intl_per_agent = {
			success = true
		},
		position = M.mission_positions.go_home_early,
		modifiers = {
			global = 1000
		}
	})
end

function M.apply_go_home_early(cp_index)
	local mission_id = "go_home_early" .. cp_index

	if missions.completed[mission_id] then
		local assignee = missions.previous_assigned_character[mission_id]

		if assignee == "tab" or assignee == "joseph" then
			agents.increment_approval(assignee, 5)
		end
	end
end

function M.add_work_with_da(mission_list)
	if not missions.completed.work_with_da then
		table.insert(mission_list, {
			intl_key = "work_with_da",
			id = "work_with_da",
			intl_namespace = "campaign",
			position = M.mission_positions.work_with_da,
			modifiers = {
				joseph = -10,
				tab = -30,
				mordecai = -15
			}
		})
	end
end

function M.apply_work_with_da()
	if missions.completed.work_with_da then
		budget.increment_capacity(500)
	end
end

function M.add_consult_senior_officer(mission_list)
	if not missions.completed.consult_senior_officer then
		local mission = {
			intl_key = "consult_senior_officer",
			id = "consult_senior_officer",
			intl_namespace = "campaign",
			position = M.mission_positions.consult_senior_officer,
			modifiers = {
				tab = -10
			}
		}

		if variables.joseph_bonus then
			mission.boosted = true
			mission.modifiers.global = senior_officer_boost
		end

		table.insert(mission_list, mission)
	end
end

function M.apply_consult_senior_officer()
	if missions.completed.consult_senior_officer then
		variables.meet_joseph = true
	end
end

function M.add_consult_academic(mission_list)
	if not missions.completed.consult_academic then
		local mission = {
			intl_key = "consult_academic",
			id = "consult_academic",
			intl_namespace = "campaign",
			position = M.mission_positions.consult_academic,
			modifiers = {
				tab = -10,
				joseph = -20
			}
		}

		if variables.university_grant then
			mission.boosted = true
			mission.modifiers.global = university_grant_boost
		end

		table.insert(mission_list, mission)
	end
end

function M.apply_consult_academic()
	if missions.completed.consult_academic then
		variables.meet_marin = missions.previous_assigned_character.consult_academic
	end
end

function M.add_negotiate_with_da(mission_list)
	if not missions.completed.negotiate_with_da then
		table.insert(mission_list, {
			intl_key = "negotiate_with_da",
			id = "negotiate_with_da",
			intl_namespace = "campaign",
			position = M.mission_positions.negotiate_with_da,
			modifiers = {
				mordecai = -10,
				joseph = -10,
				tab = -10,
				jen = -20
			}
		})
	end
end

function M.apply_negotiate_with_da()
	if missions.completed.negotiate_with_da then
		variables.meet_fred = true
	end
end

function M.add_lobby_for_donations(mission_list)
	if not missions.completed.lobby_for_donations then
		table.insert(mission_list, {
			intl_key = "lobby_for_donations",
			id = "lobby_for_donations",
			intl_namespace = "campaign",
			position = M.mission_positions.lobby_for_donations,
			modifiers = {
				joseph = -10,
				tab = -30,
				mordecai = -15
			}
		})
	end
end

function M.apply_lobby_for_donations()
	if missions.completed.lobby_for_donations then
		budget.increment_capacity(1000)
	end
end

function M.add_track_weapon(mission_list)
	if not missions.completed.track_weapon then
		table.insert(mission_list, {
			intl_key = "track_weapon",
			id = "track_weapon",
			intl_namespace = "campaign",
			position = M.mission_positions.track_weapon,
			modifiers = {
				tab = -20,
				jen = -20
			}
		})
	end
end

function M.apply_track_weapon()
	if missions.completed.track_weapon then
		budget.increment_capacity(1000)
	end
end

function M.add_order_hr(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "order_hr",
		intl_key = "order_hr",
		cost = 1000,
		intl_namespace = "campaign",
		id = "order_hr" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_order_hr(cp_index)
	local has_hr_report = budget.is_selected("order_hr" .. cp_index)
	variables.has_hr_report = has_hr_report

	if has_hr_report then
		agents.enable_classified_page()
	end
end

function M.add_extend_pr(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "extend_pr",
		intl_key = "extend_pr",
		cost = 500,
		intl_namespace = "campaign",
		id = "extend_pr" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_extend_pr(cp_index)
	local selected = budget.is_selected("extend_pr" .. cp_index)
	variables.advanced_pr_report = selected
end

function M.add_bonuses_for_agents(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "bonuses_for_agents",
		intl_key = "bonuses_for_agents",
		cost = 1000,
		intl_namespace = "campaign",
		id = "bonuses_for_agents" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_bonuses_for_agents(cp_index)
	if budget.is_selected("bonuses_for_agents" .. cp_index) then
		for id, option in pairs(missions.previous_options) do
			if missions.completed[option.id] then
				local character = missions.previous_assigned_character[option.id]

				if character then
					agents.increment_approval(character, 5)
				end
			end
		end
	end
end

function M.add_pr_assistance(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "pr_assistance",
		intl_key = "pr_assistance",
		cost = 1000,
		intl_namespace = "campaign",
		id = "pr_assistance" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_pr_assistance(cp_index)
	if budget.is_selected("pr_assistance" .. cp_index) then
		stats.increment_press(5)

		variables.pr_bought = true
	end
end

function M.add_cf_overtime(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "cf_overtime",
		intl_key = "cf_overtime",
		cost = 500,
		intl_namespace = "campaign",
		id = "cf_overtime" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_cf_overtime(cp_index)
	if budget.is_selected("cf_overtime" .. cp_index) then
		agents.increment_approval("tab", -5)
		agents.increment_approval("mordecai", -5)
		agents.increment_approval("jen", -5)
		agents.increment_approval("joseph", -5)

		if variables.cf_press_penalty then
			stats.increment_press(-10)
		end

		if variables.cf_popularity_penalty then
			stats.increment_popularity(-10)
		end

		local amount = 1000 + math.random(0, 1) * 500

		budget.increment_capacity(amount)

		variables.cf_overtime_count = (variables.cf_overtime_count or 0) + 1
	end
end

function M.add_rnr_teambuilding(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "rnr_teambuilding",
		intl_key = "rnr_teambuilding",
		cost = 500,
		intl_namespace = "campaign",
		id = "rnr_teambuilding" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_rnr_teambuilding(cp_index)
	if budget.is_selected("rnr_teambuilding" .. cp_index) then
		agents.increment_approval("jen", 10)
		agents.increment_approval("joseph", 5)
		agents.increment_approval("mordecai", 5)
	end
end

function M.add_co_overtime(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "co_overtime",
		intl_key = "co_overtime",
		cost = 500,
		intl_namespace = "campaign",
		id = "co_overtime" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_co_overtime(cp_index)
	if budget.is_selected("co_overtime" .. cp_index) then
		agents.increment_approval("jen", 5)
		stats.increment_popularity(5)

		variables.co_overtime_count = (variables.co_overtime_count or 0) + 1
	end
end

function M.add_informer_stimulants(budget_options, cp_index, max_level)
	local dependency = "pursue_informer"
	local level = 1

	if missions.completed.pursue_informer then
		dependency = "recruit_informer"
		level = 2
	end

	if missions.completed.recruit_informer then
		dependency = "contact_informer"
		level = 3
	end

	if missions.completed.contact_informer then
		return
	end

	if max_level and max_level < level then
		return
	end

	table.insert(budget_options, {
		class_id = "informer_stimulants",
		hard_dependency = true,
		cost = 500,
		intl_namespace = "campaign",
		id = "informer_stimulants" .. cp_index,
		cp_index = cp_index,
		intl_key = "informer_stimulants." .. dependency,
		depends_on_mission = dependency
	})
end

local function apply_booster(option_id, amount)
	local option = budget.get_option(option_id)

	if not option then
		return
	end

	local mission = missions.get_option(option.depends_on_mission)

	if not mission then
		return
	end

	if not mission.boosted then
		mission.boosted = true
		mission.modifiers = mission.modifiers or {}
		mission.modifiers.global = (mission.modifiers.global or 0) + amount
	end
end

function M.apply_informer_stimulants(cp_index)
	local option_id = "informer_stimulants" .. cp_index

	if budget.is_selected(option_id) then
		apply_booster(option_id, 20)
	end
end

function M.add_past_service_bonus(budget_options, cp_index)
	if not variables.joseph_bonus and not missions.completed.consult_senior_officer then
		table.insert(budget_options, {
			class_id = "past_service_bonus",
			intl_key = "past_service_bonus",
			depends_on_mission = "consult_senior_officer",
			cost = 500,
			intl_namespace = "campaign",
			id = "past_service_bonus" .. cp_index,
			cp_index = cp_index
		})
	end
end

function M.apply_past_service_bonus(cp_index)
	local option_id = "past_service_bonus" .. cp_index

	if budget.is_selected(option_id) then
		apply_booster(option_id, senior_officer_boost)

		variables.joseph_bonus = true
	end
end

function M.add_university_grant(budget_options, cp_index)
	if not variables.university_grant and not missions.completed.consult_academic then
		table.insert(budget_options, {
			class_id = "university_grant",
			intl_key = "university_grant",
			depends_on_mission = "consult_academic",
			cost = 500,
			intl_namespace = "campaign",
			id = "university_grant" .. cp_index,
			cp_index = cp_index
		})
	end
end

function M.apply_university_grant(cp_index)
	local option_id = "university_grant" .. cp_index

	if budget.is_selected(option_id) then
		apply_booster(option_id, university_grant_boost)

		variables.university_grant = true
	end
end

function M.add_procedure_training(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "procedure_training",
		intl_key = "procedure_training",
		cost = 1000,
		intl_namespace = "campaign",
		id = "procedure_training" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_procedure_training(cp_index)
	if budget.is_selected("procedure_training" .. cp_index) then
		agents.increment_approval("mordecai", 5)
		agents.increment_approval("joseph", 5)
		agents.increment_approval("tab", 10)
	end
end

function M.add_therapy(budget_options, cp_index)
	table.insert(budget_options, {
		class_id = "therapy",
		intl_key = "therapy",
		cost = 500,
		intl_namespace = "campaign",
		id = "therapy" .. cp_index,
		cp_index = cp_index
	})
end

function M.apply_therapy(cp_index)
	if budget.is_selected("therapy" .. cp_index) and math.random() < 0.3 then
		stats.increment_insanity(-1)
	end
end

function M.apply_missions()
	for _, mission in ipairs(missions.previous_options) do
		local id = mission.class_id or mission.id
		local func = M["apply_" .. id]

		if func then
			func(mission.cp_index, mission)
		end
	end
end

function M.apply_budget()
	variables.has_hr_report = false
	variables.advanced_pr_report = false

	for _, option in ipairs(budget.options) do
		local id = option.class_id or option.id
		local func = M["apply_" .. id]

		if func then
			func(option.cp_index, option)
		end
	end
end

function M.add_monthly_income()
	budget.increment_capacity(variables.narrative and 3000 or 2000)
end

function M.apply_fatigue()
	for _, agent in ipairs(agents) do
		agents.increment_approval(agent, -10)
	end
end

return M
