local stats = require("campaign.stats")
local variables = require("campaign.variables")
local table_util = require("crit.table_util")
local save_file = require("lib.save_file")
local agents = {
	"jen",
	"mordecai",
	"tab",
	"joseph",
	jen = {
		has_classified = false,
		present = true,
		approval = 90
	},
	mordecai = {
		has_classified = false,
		present = true,
		approval = 90
	},
	tab = {
		has_classified = false,
		present = true,
		approval = 90
	},
	joseph = {
		has_classified = false,
		present = false,
		approval = 90
	}
}
local low_threshold = 25

function agents.save()
	local snap = {}

	for i, char in ipairs(agents) do
		snap[char] = table_util.clone(agents[char])
	end

	return snap
end

local defaults = agents.save()

local function check_achievements()
	local a_min = 100
	local a_max = 0

	for i, char in ipairs(agents) do
		local agent = agents[char]

		if agent.present then
			local approval = agent.approval
			a_min = math.min(a_min, approval)
			a_max = math.max(a_max, approval)
		end
	end

	if a_max <= low_threshold then
		save_file.set_global("low_agent_approval", true)
	end

	if a_min >= 100 then
		save_file.set_global("high_agent_approval", true)
	end
end

function agents.load(snap)
	for i, char in ipairs(agents) do
		agents[char] = snap[char] or table_util.clone(defaults[char])
	end

	check_achievements()
end

function agents.reset()
	agents.load(defaults)
end

function agents.set_approval(agent_id, value)
	local agent = agents[agent_id]

	if not agent.present then
		return
	end

	agent.approval = math.max(0, math.min(100, value))

	check_achievements()
end

function agents.increment_approval(agent_id, value)
	local agent = agents[agent_id]

	if not agent.present then
		return
	end

	agent.approval = math.max(0, math.min(100, agent.approval + value))

	check_achievements()
end

function agents.commit()
	local bonus = nil

	if stats.is_low("authorities") then
		bonus = -20
	elseif stats.is_high("authorities") then
		bonus = 20
	end

	if bonus then
		for i, agent_id in ipairs(agents) do
			agents.increment_approval(agent_id, bonus)
		end
	end
end

function agents.enable_classified_page(agent_id)
	if not agent_id then
		for i, char in ipairs(agents) do
			local agent = agents[char]

			if agent.has_classified == false and agent.present then
				agent_id = char

				break
			end
		end
	end

	if not agent_id then
		return
	end

	local agent = agents[agent_id]

	if not agent then
		return
	end

	agent.has_classified = true
	variables.classified_unlocked = agent_id
end

function agents.cf_overtime()
	for i, char in ipairs(agents) do
		agents.increment_approval(char, -5)
	end
end

function agents.rnr_teambuilding()
	agents.increment_approval("jen", 5)
	agents.increment_approval("mordecai", 10)
end

return agents
