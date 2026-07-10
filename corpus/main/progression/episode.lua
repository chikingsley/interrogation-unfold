local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local snapshot = require("campaign.snapshot")
local sound_util = require("sound.util")
local pause_menu = require("main.pause_menu.pause_menu")
local variables = require("campaign.variables")
local missions = require("campaign.missions")
local store = require("level.store")
local save_file = require("lib.save_file")
local review = require("main.review")
local h_level_restart = hash("level_restart")

local function nop()
	return
end

local function from_variables(flag)
	return not not variables[flag]
end

local function from_missions(flag)
	return not not missions.completed[flag]
end

local function always()
	return true
end

local function to_variables(flag)
	variables[flag] = true
end

local function import_flags(t)
	local flags = {}

	for k, v in pairs(t) do
		if type(k) == "string" then
			local should_add = v

			if v then
				if type(v) == "function" then
					should_add = v(k)
				else
					should_add = from_variables(k)
				end
			end

			if should_add then
				flags[k] = true
			end
		elseif type(k) == "number" then
			if type(v) == "string" then
				if from_variables(v) then
					flags[v] = true
				end
			elseif type(v) == "function" then
				local flag = v()

				if flag then
					flags[flag] = true
				end
			end
		end
	end

	return flags
end

local function export_flags(t)
	local flags = {}

	for k, v in pairs(t) do
		if type(k) == "string" then
			if store.has_flag(k) and v then
				if type(v) == "function" then
					v(k)
				else
					to_variables(k)
				end
			end
		elseif type(k) == "number" and type(v) == "string" and store.has_flag(v) then
			to_variables(v)
		end
	end

	return flags
end

sound_util.set_preset("lose", "event:/Campaign Music/Lose Theme", "All Campaign.bank")

local function create_episode(options)
	options = options or {}
	local level = options.level
	local outcome_win = options.outcome_win
	local outcome_lose = options.outcome_lose or "chief_office"
	local pre_load = options.pre_load or nop
	local post_load = options.post_load or nop
	local post_episode = options.post_episode or nop
	local level_options = options.level_options
	local import_flags_t = options.import_flags
	local export_flags_t = options.export_flags

	if type(level_options) == "table" then
		local opts = level_options

		function level_options()
			return opts
		end
	end

	local episode = {}

	local function hide_restart_level_from_menu()
		pause_menu.has_restart_button = false
	end

	local function retry_loop()
		pre_load()

		local opts = nil

		if level_options then
			opts = level_options()
		else
			opts = {
				level = level
			}
		end

		opts = opts or {}

		if import_flags_t then
			opts.flags = import_flags(import_flags_t)
		end

		sound_util.set_music(nil)

		if options.custom_level then
			options.custom_level()
		else
			local lite = opts and opts.lite

			scenes.load_scene(lite and "level_lite" or "level", opts)
		end

		pause_menu.has_restart_button = true

		progression.add_cleanup_handler(hide_restart_level_from_menu)
		post_load()

		local outcome = scenes.wait_for_end_scene()

		progression.remove_cleanup_handler(hide_restart_level_from_menu)
		hide_restart_level_from_menu()

		if outcome.has_won then
			return opts
		end

		local reason = outcome.reason

		if type(outcome_lose) == "function" then
			outcome_lose = outcome_lose(reason)
		end

		if outcome_lose ~= nil then
			sound_util.set_preset_music("lose", {
				slow_fade_in = true
			})

			local outcome_options = nil

			if reason == "death" then
				outcome_options = {
					outcome_id = "chief_office",
					has_won = false,
					header_key = "outcome.lose",
					text_key = "outcome.death.lose",
					intl_namespace = "main",
					reason = reason
				}

				save_file.set_global("lose_fired", true)
			elseif type(outcome_lose) == "table" then
				outcome_options = outcome_lose
			else
				outcome_options = {
					has_won = false,
					outcome_id = outcome_lose,
					reason = reason
				}
			end

			scenes.load_scene("outcome", outcome_options)
			scenes.wait_for_end_scene()
		end

		return false
	end

	episode.run = scenes.skippable(function ()
		local snap = snapshot.snap()
		local episode_options = false
		local retry_count = 0

		while true do
			local retry_co = progression.fork(function ()
				episode_options = retry_loop()
			end)
			local wait_for_restart_co = progression.fork(function ()
				progression.wait_for_message(h_level_restart)
				progression.cancel(retry_co)
			end)

			progression.join(retry_co)
			progression.cancel(wait_for_restart_co)

			if episode_options then
				break
			end

			snapshot.load(snap)

			retry_count = retry_count + 1

			if retry_count >= 10 then
				save_file.set_global("restart_10_times", true)
			end
		end

		if export_flags_t then
			export_flags(export_flags_t)
		end

		local level_id = episode_options.level

		if level_id then
			save_file.set_global("won_" .. level_id, true)

			if not variables.narrative then
				save_file.set_global("won_challenge_" .. level_id, true)
			end
		end

		post_episode(episode_options)
	end)

	if outcome_win then
		episode.outcome = scenes.skippable(function ()
			local review_thread = nil

			if not options.no_review then
				review_thread = progression.fork(function ()
					progression.wait(10)
					review.try_review()
				end)
			end

			local outcome_options = nil

			if type(outcome_win) == "table" then
				outcome_options = outcome_win
			else
				outcome_options = {
					has_won = true,
					outcome_id = outcome_win
				}
			end

			scenes.load_scene("outcome", outcome_options)
			scenes.wait_for_end_scene()

			if review_thread then
				progression.cancel(review_thread)
			end
		end)
	else
		episode.outcome = nop
	end

	return episode
end

return {
	create_episode = create_episode,
	import_flags = import_flags,
	export_flags = export_flags,
	to_variables = to_variables,
	from_variables = from_variables,
	from_missions = from_missions,
	always = always
}
