local variables = require("campaign.variables")
local snapshot = require("campaign.snapshot")
local save_file = require("lib.save_file")
local table_util = require("crit.table_util")
local M = {
	easier = {
		narrative = "vn",
		challenge = "narrative"
	},
	get_difficulty = function (vars)
		vars = vars or variables

		if vars.vn then
			return "vn"
		end

		if vars.narrative then
			return "narrative"
		end

		return "challenge"
	end
}

function M.get_difficulty_in_current_profile()
	local current_profile = save_file.get_current_profile().get()

	return M.get_difficulty(current_profile.history and current_profile.history.latest and current_profile.history.latest.variables or {})
end

function M.set_difficulty(difficulty)
	if difficulty == "challenge" then
		variables.narrative = false
		variables.vn = false
	elseif difficulty == "narrative" then
		variables.narrative = true
		variables.vn = false
	elseif difficulty == "vn" then
		variables.narrative = true
		variables.vn = true
	end
end

function M.set_difficulty_in_current_profile(difficulty, backup_profile)
	local current_profile = save_file.get_current_profile()

	if backup_profile then
		backup_profile.duplicate_from_profile(current_profile)
	end

	local profile_data = table_util.deep_clone(current_profile.get())
	local latest_snap = profile_data.history and profile_data.history.latest

	snapshot.load(latest_snap)
	M.set_difficulty(difficulty)

	local snap = snapshot.snap()

	if latest_snap.route then
		snap.route = table_util.deep_clone(latest_snap.route)
	end

	profile_data.history = profile_data.history or {}
	profile_data.history.latest = snap

	current_profile.save(profile_data)
end

return M
