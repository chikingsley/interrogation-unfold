local stats = require("campaign.stats")
local table_util = require("crit.table_util")
local perks = {
	n = 0
}

local function apply_effects(perk)
	if perk == "double" or perk == "messiah" or perk == "unstable" then
		stats.increment_insanity(2)
	end
end

local function undo_effects(perk)
	if perk == "double" or perk == "messiah" or perk == "unstable" then
		stats.increment_insanity(-2)
	end
end

local function set_perk(perk)
	if perks[perk] then
		return false
	end

	perks[perk] = true
	local n = perks.n + 1
	perks[n] = perk
	perks.n = n

	return true
end

function perks.add_perk(perk, no_effects)
	if set_perk(perk) and not no_effects then
		apply_effects(perk)
	end
end

local dependencies = {
	statistics = "profiler",
	framing = "intimidation",
	brutality = "anatomy",
	waterboarding = "intimidation"
}
local conflicts = {
	anatomy = {
		"pacifist"
	},
	waterboarding = {
		"pacifist"
	},
	brutality = {
		"pacifist"
	},
	pacifist = {
		"anatomy",
		"brutality",
		"waterboarding"
	}
}

local function is_selected(perk)
	return not not perks[perk]
end

function perks.meets_dependencies(perk)
	local dependency = dependencies[perk]
	local conflict = conflicts[perk]

	if dependency and not perks[dependency] then
		return false, "dependency", dependency
	end

	if conflict then
		local found_conflict = table_util.find(conflict, is_selected)

		if found_conflict then
			return false, "conflict", found_conflict
		end
	end

	return true
end

function perks.remove_perk(perk)
	if not perks[perk] then
		return
	end

	perks[perk] = nil

	for k, v in ipairs(perks) do
		if v == perk then
			undo_effects(perk)
			table.remove(perks, k)

			perks.n = perks.n - 1

			break
		end
	end
end

function perks.reset()
	for k, perk in ipairs(perks) do
		perks[k] = nil
		perks[perk] = nil
	end

	perks.n = 0
end

function perks.save()
	local snap = {}

	for k, perk in ipairs(perks) do
		snap[k] = perk
	end

	return snap
end

function perks.load(snap)
	perks.reset()

	for k, perk in ipairs(snap) do
		set_perk(perk)
	end
end

return perks
