local table_util = require("crit.table_util")
local save_file = require("lib.save_file")
local positive_threshold = 80
local negative_threshold = 20
local floor = math.floor
local stats = {
	commits = {}
}

local function commit_snapshot()
	local commit = {}

	for id, amount in pairs(stats) do
		if type(amount) == "number" then
			commit[id] = stats[id]
		end
	end

	return commit
end

function stats.commit(label)
	local commit = commit_snapshot()

	if label then
		commit.label = label
		local commits = stats.commits
		commits[#commits + 1] = commit
	else
		stats.commits = {
			commit
		}
	end
end

function stats.get_commit(index)
	if not index then
		return stats
	end

	local commit = stats.commits[index]

	return commit or stats
end

local default_stats = {
	equity = 0,
	popularity = 50,
	press = 50,
	evolution = 0,
	lawful = 0,
	cruelty = 0,
	insanity = 0,
	freedom = 0,
	justice = 0,
	total_torture_damage = 0,
	authorities = 50,
	max_cruelty = 0
}

function stats.reset()
	stats.commits = {}

	table_util.assign(stats, default_stats)
end

function stats.save()
	return table_util.deep_clone(stats, table_util.no_functions)
end

local function is_high(id)
	return positive_threshold <= stats[id]
end

local function is_low(id)
	return stats[id] <= negative_threshold
end

stats.is_high = is_high
stats.is_low = is_low

local function check_achievements()
	if is_high("popularity") and is_high("press") and is_high("authorities") then
		save_file.set_global("approvals_high", true)
	end

	if is_low("popularity") and is_low("press") and is_low("authorities") then
		save_file.set_global("approvals_low", true)
	end
end

function stats.load(snap)
	stats.reset()
	table_util.assign(stats, snap)

	local previous_stats = stats.previous_stats

	if previous_stats then
		stats.previous_stats = nil
		stats.commits = {
			previous_stats
		}
	end

	stats.commits = stats.commits or {}

	for _, commit in ipairs(stats.commits) do
		for stat, default_value in pairs(default_stats) do
			if commit[stat] == nil then
				commit[stat] = default_value
			end
		end
	end

	check_achievements()
end

local cruelty_tresholds = {
	[3] = {
		press = -5
	},
	[5] = {
		popularity = -5,
		press = -5
	},
	[7] = {
		popularity = -5,
		press = -5
	},
	[9] = {
		popularity = -5,
		press = -5,
		authority = -5
	},
	[11] = {
		popularity = -5,
		press = -10,
		authority = -5
	},
	[13] = {
		popularity = -10,
		press = -10,
		authority = -5
	},
	[15] = {
		popularity = -10,
		press = -10,
		authority = -10
	}
}

local function apply_cruelty_treshold(treshold)
	local commit_before = commit_snapshot()
	local last_commit = stats.commits[#stats.commits] or commit_before

	if treshold.press then
		stats.increment_press(treshold.press)
	end

	if treshold.popularity then
		stats.increment_press(treshold.popularity)
	end

	if treshold.authority then
		stats.increment_press(treshold.authority)
	end

	local commit_after = commit_snapshot()
	local diffed_commit = {
		label = "cruelty"
	}

	for id, amount in pairs(stats) do
		if type(amount) == "number" then
			diffed_commit[id] = last_commit[id] + commit_after[id] - commit_before[id]
		end
	end

	stats.commits[#stats.commits + 1] = diffed_commit
end

function stats.set_popularity(value)
	stats.popularity = value

	check_achievements()
end

function stats.set_press(value)
	stats.press = value

	check_achievements()
end

function stats.set_authorities(value)
	stats.authorities = value

	check_achievements()
end

function stats.set_cruelty(value)
	stats.cruelty = value
	local max_cruelty = stats.max_cruelty

	if max_cruelty < value then
		stats.max_cruelty = value

		for i = max_cruelty + 1, value do
			local treshold = cruelty_tresholds[i]

			if treshold then
				apply_cruelty_treshold(treshold)
			end
		end
	end
end

function stats.set_insanity(value)
	stats.insanity = value

	if value >= 10 then
		save_file.set_global("cuckoos_nest", true)
	end
end

function stats.set_equity(value)
	stats.equity = value
end

function stats.set_freedom(value)
	stats.freedom = value
end

function stats.set_evolution(value)
	stats.evolution = value
end

function stats.set_lawful(value)
	stats.lawful = value
end

function stats.set_justice(value)
	stats.justice = value
end

function stats.set_total_torture_damage(value)
	stats.total_torture_damage = value
end

local function overflow_increment(value, amount)
	if value >= 100 then
		value = 100 + (value - 100) * 2
	elseif value <= 0 then
		value = value * 2
	end

	value = value + amount

	if value >= 100 then
		value = 100 + (value - 100) * 0.5
	elseif value <= 0 then
		value = value * 0.5
	end

	return value
end

function stats.increment_popularity(amount)
	stats.set_popularity(overflow_increment(stats.popularity, amount))
end

function stats.increment_press(amount)
	stats.set_press(overflow_increment(stats.press, amount))

	if amount < 0 and stats.is_low("press") then
		stats.increment_popularity(amount * 0.5)
		stats.increment_authorities(amount * 0.5)
	end
end

function stats.increment_authorities(amount)
	stats.set_authorities(overflow_increment(stats.authorities, amount))
end

function stats.increment_cruelty(amount)
	if amount > 0 and stats.is_high("press") then
		amount = amount * 0.5
	end

	stats.set_cruelty(stats.cruelty + amount)
end

function stats.increment_insanity(amount)
	stats.set_insanity(stats.insanity + amount)
end

function stats.increment_total_torture_damage(amount)
	stats.set_total_torture_damage(stats.total_torture_damage + amount)
end

function stats.increment_equity(amount)
	stats.set_equity(stats.equity + amount)
end

function stats.increment_freedom(amount)
	stats.set_freedom(stats.freedom + amount)
end

function stats.increment_evolution(amount)
	stats.set_evolution(stats.evolution + amount)
end

function stats.increment_lawful(amount)
	stats.set_lawful(stats.lawful + amount)
end

function stats.increment_justice(amount)
	stats.set_justice(stats.justice + amount)
end

function stats.set(id, value)
	stats["set_" .. id](value)
end

function stats.increment(id, amount)
	stats["increment_" .. id](amount)
end

function stats.get_checkbox_slot(value)
	if value <= negative_threshold then
		return 0
	end

	if positive_threshold <= value then
		return 4
	end

	return 1 + floor((value - negative_threshold) / ((positive_threshold - negative_threshold) / 3))
end

stats.reset()

return stats
