local agents = require("campaign.agents")
local table_util = require("crit.table_util")
local intl = require("crit.intl")
local missions = {}
local max = math.max
local min = math.min
local random = math.random

function missions.reset()
	missions.options = {}
	missions.assigned_mission = {}
	missions.assigned_character = {}
	missions.previous_options = {}
	missions.previous_assigned_mission = {}
	missions.previous_assigned_character = {}
	missions.completed = {}
end

missions.reset()

function missions.save()
	return table_util.deep_clone(missions, table_util.no_functions)
end

function missions.load(snap)
	missions.reset()

	if not snap.previous_assigned_mission then
		snap.previous_assigned_mission = {}

		for j, mission in ipairs(snap.previous_options) do
			local assigned_character = snap.assigned_character[mission.id]

			if assigned_character then
				snap.previous_assigned_mission[assigned_character] = mission.id
			end
		end
	end

	if not snap.previous_assigned_character then
		snap.previous_assigned_character = table_util.deep_clone(snap.assigned_character)
	end

	table_util.assign(missions, snap)
end

function missions.set_options(options)
	missions.options = options
end

function missions.get_option(mission_id)
	for i, option in ipairs(missions.options) do
		if option.id == mission_id then
			return option
		end
	end

	return nil
end

function missions.translate_option_text(option, key, agent)
	local text = option[key]

	if text then
		return text
	end

	local intl_key = option.intl_key
	local intl_namespace = option.intl_namespace

	if intl_key and intl_namespace then
		local final_key = "missions." .. intl_key .. "." .. key

		if agent and option.intl_per_agent and option.intl_per_agent[key] then
			final_key = final_key .. "." .. agent
		end

		return intl.namespace(intl_namespace).t(final_key)
	end
end

function missions.get_assigned_mission_id(char_id)
	return missions.assigned_mission[char_id] or nil
end

function missions.get_previous_option(mission_id)
	for i, option in ipairs(missions.previous_options) do
		if option.id == mission_id then
			return option
		end
	end

	return nil
end

function missions.assign(char_id, mission_id)
	if char_id then
		local old_mission_id = missions.assigned_mission[char_id]
		missions.assigned_mission[char_id] = mission_id

		if old_mission_id then
			missions.assigned_character[old_mission_id] = nil
		end
	end

	if mission_id then
		missions.assigned_character[mission_id] = char_id
	end
end

function missions.are_assignments_set()
	return not not next(missions.assigned_mission)
end

function missions.get_success_rate(mission_option, char_id)
	local rate = 50
	local agent = agents[char_id]

	if agent then
		rate = agent.approval
	end

	local modifiers = mission_option.modifiers

	if modifiers then
		local modifier = modifiers[char_id] or 0
		local global_modifier = modifiers.global or 0
		rate = rate + modifier + global_modifier
	end

	local ineligible = mission_option.ineligible

	if ineligible and ineligible[char_id] then
		return nil
	end

	return max(0, min(100, rate))
end

function missions.commit()
	local bonus = 0

	for i, option in ipairs(table_util.shuffled(missions.options)) do
		local mission_id = option.id
		local character = missions.assigned_character[mission_id]

		if character and missions.assigned_mission[character] == mission_id then
			local rate = missions.get_success_rate(option, character) * 0.01 + max(0, bonus)
			local won_roll = random() < rate

			if won_roll then
				missions.completed[mission_id] = true
			end

			if won_roll then
				bonus = 0
			else
				bonus = bonus + 0.15
			end
		end
	end

	missions.previous_options = missions.options
	missions.previous_assigned_mission = missions.assigned_mission
	missions.previous_assigned_character = missions.assigned_character
	missions.options = {}
	missions.assigned_mission = {}
	missions.assigned_character = {}
end

return missions
