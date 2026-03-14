local budget = require("campaign.budget")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local stats = require("campaign.stats")
local missions = require("campaign.missions")
local perks = require("campaign.perks")
local office = require("campaign.office")
local table_util = require("crit.table_util")
local env = require("lib.environment")
local progression = require("crit.progression")
local store = require("level.store")
local tracker = require("lib.ga")
local snapshot = {
	reset = function ()
		budget.reset()
		agents.reset()
		variables.reset()
		stats.reset()
		missions.reset()
		perks.reset()
		office.reset()
		store.reset()
	end,
	snap = function ()
		return {
			budget = budget.save(),
			agents = agents.save(),
			variables = variables.save(),
			stats = stats.save(),
			missions = missions.save(),
			perks = perks.save(),
			office = office.save()
		}
	end
}

local function load_module(module, data)
	if data then
		module.load(data)
	else
		module.reset()
	end
end

function snapshot.load(snap)
	if not snap then
		snapshot.reset()

		return
	end

	snap = table_util.deep_clone(snap)

	load_module(budget, snap.budget)
	load_module(agents, snap.agents)
	load_module(variables, snap.variables)
	load_module(stats, snap.stats)
	load_module(missions, snap.missions)
	load_module(perks, snap.perks)
	load_module(office, snap.office)
	store.reset()
end

local function nop()
	return
end

local save_route, save_tracking_path, save_func, save_pre_segment_hook = nil

function snapshot.save_load_progress(snap, save_function, pre_segment_hook, progression_func)
	local route = snap and snap.route

	if route then
		route = table_util.clone(route)
	else
		route = {}
	end

	local cleanup_handler = nil

	if not env.bundled or env.debug then
		_G.save_map = {}
		_G.save_route = route
		cleanup_handler = progression.add_cleanup_handler(function ()
			_G.save_map = nil
			_G.save_route = nil
		end)
	end

	save_route = route
	save_tracking_path = {}
	save_func = save_function
	save_pre_segment_hook = pre_segment_hook or nop

	snapshot.load(snap)
	progression_func()

	save_route = nil
	save_func = nil
	save_pre_segment_hook = nil
	save_tracking_path = nil

	if cleanup_handler then
		progression.remove_cleanup_handler(cleanup_handler)

		_G.save_map = nil
		_G.save_route = nil
	end
end

function snapshot.segment(sequence_id, segments)
	local route = save_route
	local save_map = _G.save_map
	local segment_name = route[sequence_id]

	if save_map then
		save_map[#save_map + 1] = {
			sequence_id,
			segments
		}
	end

	local starting_index = 1

	if segment_name then
		for i, segment in ipairs(segments) do
			if segment[1] == segment_name then
				starting_index = i

				break
			end
		end
	end

	local path_top = #save_tracking_path + 1
	local n = #segments

	for i = starting_index, n do
		local segment = segments[i]
		route[sequence_id] = segment[1]

		if i ~= starting_index and not segment.no_save then
			local snap = snapshot.snap()
			snap.route = table_util.clone(route)

			save_func(snap, segment)
		end

		save_tracking_path[path_top] = segment[1]

		tracker.screenview(table.concat(save_tracking_path, "/"))
		save_pre_segment_hook(segment)
		segment[2]()
	end

	save_tracking_path[path_top] = nil
	route[sequence_id] = nil

	if save_map then
		save_map[#save_map] = nil
	end
end

return snapshot
