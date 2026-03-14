local env = require("lib.environment")
local save_file = require("lib.save_file")
local globals = save_file.globals

local function needs(id)
	return function ()
		return not not globals[id]
	end
end

local achievements = {
	no_kings = needs("ending_marxist"),
	never_tread_on_me = needs("ending_ancap"),
	evolve_or_die = needs("ending_apocalyptic"),
	cure_for_the_plague = needs("ending_vigilante"),
	and_justice_for_all = needs("ending_good"),
	cuckoos_nest = needs("cuckoos_nest"),
	good_work_officer = needs("won_game"),
	multiverse_completionist = function ()
		return globals.ending_marxist and globals.ending_ancap and globals.ending_apocalyptic and globals.ending_vigilante and globals.ending_good
	end,
	taking_names_and_asking_questions = needs("won_episode0"),
	its_always_the_husband = needs("won_challenge_episode1"),
	the_hornbunny_identity = needs("won_challenge_episode2"),
	lets_go_to_the_mall = needs("won_challenge_episode3"),
	delusions = needs("won_challenge_episode4"),
	the_vet_quandry = needs("won_challenge_episode5"),
	broken_people = needs("won_challenge_episode6"),
	disarming_choices = needs("won_challenge_episode7"),
	elias_keen_investigation = needs("won_challenge_episode8"),
	now_or_never = needs("won_challenge_episode9"),
	decapitating_hydras = needs("won_challenge_episode10"),
	neutralised = needs("lose_assassinated"),
	made_redundant = needs("lose_fired"),
	man_of_steel = needs("approvals_high"),
	dark_knight = needs("approvals_low"),
	informed_citizen = function ()
		return globals.read_newspaper1 and globals.read_newspaper2 and globals.read_newspaper3 and globals.read_newspaper4 and globals.read_newspaper5 and globals.read_newspaper6 and globals.read_newspaper7 and globals.read_newspaper8
	end,
	worst_boss = needs("low_agent_approval"),
	best_boss = needs("high_agent_approval"),
	hate_your_guts = needs("hate_your_guts"),
	stay_and_listen = function ()
		return globals.won_sitdown_fred and globals.won_sitdown_marin and globals.won_sitdown_joseph and globals.won_sitdown_informer1 and globals.won_sitdown_informer2
	end,
	we_told_you_deceived = needs("restart_10_times"),
	maybe_innocent = needs("maybe_innocent")
}
local stats = {}
local achieved = {}
local stat_values = {}
local backends = {}
local cleared_achievements = env.clear_achievements or {}
local force_set_achievements = env.set_achievements or {}

if cleared_achievements == true then
	cleared_achievements = {}

	for id, _ in pairs(achievements) do
		cleared_achievements[id] = true
	end
end

if force_set_achievements == true then
	force_set_achievements = {}

	for id, _ in pairs(achievements) do
		force_set_achievements[id] = true
	end
end

if env.debug or not env.bundled then
	local achievements_log = require("lib.achievements_log")

	table.insert(backends, achievements_log)
end

if env.steam and not env.demo then
	local achievements_steam = require("lib.achievements_steam")

	table.insert(backends, achievements_steam)
end

if env.gog and not env.demo then
	local achievements_gog = require("lib.achievements_gog")

	table.insert(backends, achievements_gog)
end

local function set_achievement(id)
	achieved[id] = true

	for _, backend in ipairs(backends) do
		backend.set_achievement(id)
	end
end

local function clear_achievement(id)
	achieved[id] = false

	for _, backend in ipairs(backends) do
		backend.clear_achievement(id)
	end
end

local function set_stat(id, value)
	stat_values[id] = value

	for _, backend in ipairs(backends) do
		backend.set_stat(id, value)
	end
end

local function store()
	for _, backend in ipairs(backends) do
		backend.store()
	end
end

local function check()
	local needs_store = false

	for id, getter in pairs(stats) do
		local value = getter(id)

		if value ~= stat_values[id] then
			set_stat(id, value)

			needs_store = true
		end
	end

	for id, checker in pairs(achievements) do
		if not achieved[id] and not cleared_achievements[id] and checker(id) then
			set_achievement(id)

			needs_store = true
		end
	end

	if needs_store then
		store()
	end
end

local function clear_achievements(ach_to_clear)
	local needs_store = false

	for id, value in pairs(ach_to_clear) do
		if value then
			clear_achievement(id)

			needs_store = true
		end
	end

	if needs_store then
		store()
	end
end

local function init()
	for _, backend in ipairs(backends) do
		backend.init()
	end

	check()
	clear_achievements(cleared_achievements)

	for k, v in pairs(force_set_achievements) do
		if v then
			set_achievement(k)
		end
	end

	save_file.set_globals_callback(check)
end

return {
	init = init,
	check = check
}
