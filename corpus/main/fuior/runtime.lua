local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local variables = require("campaign.variables")
local budget = require("campaign.budget")
local env = require("lib.environment")
local intl = require("crit.intl")
local sound_util = require("sound.util")
local fui = {}

if env.debug or not env.bundled then
	setmetatable(fui, {
		__index = function (table, key)
			error("Command \"" .. key .. "\" does not exist")
		end
	})
end

local function wrap(f, head)
	return function (...)
		head()

		return f(...)
	end
end

function fui.intl(namespace_id, en_strings)
	local namespace = intl.namespace("fuior_" .. (namespace_id or "main"))

	if en_strings then
		namespace.register({
			en = en_strings
		})
	end

	return namespace
end

function fui.load_interlude(background)
	scenes.load_scene("interludes", {
		background = background
	})
end

function fui.load_characters(...)
	interludes.preload_characters({
		...
	})
end

function fui.animate(character, animation, instant, flipped)
	interludes.animate_character(character, character .. "_" .. animation, not not instant, not not flipped)
end

function fui.show_character(character, position, animation, nametag_key)
	local slot = interludes[position]

	if type(slot) ~= "number" then
		error(tostring(position) .. " is not a valid character slot")
	end

	local intl_campaign = intl.namespace("campaign")
	local nametag = intl_campaign.t("interlude.nametag." .. (nametag_key or character))

	interludes.show_character(character, slot, {
		nametag = nametag
	})

	if animation then
		fui.animate(character, animation, true)
	end
end

function fui.text(character, animation, text)
	interludes.show_bubble(character, text)

	if animation then
		interludes.animate_character(character, character .. "_" .. animation)
	end
end

function fui.set_music(event, bank)
	sound_util.set_music(event, bank)
end

function fui.set_preset_music(preset_id)
	sound_util.set_preset_music(preset_id)
end

function fui.stop_music()
	sound_util.set_music(nil, nil)
end

fui.set_music_parameter = sound_util.set_music_parameter

function fui.set(variable)
	fui.var_set(variable, true)
end

function fui.unset(variable)
	fui.var_set(variable, nil)
end

function fui.dump_var(variable)
	pprint(fui.var_get(variable))
end

local function read_only(value, variable)
	error("Fuior variable \"" .. variable .. "\" is read-only and cannot be set")
end

local getters = {
	popularity = function ()
		return stats.popularity
	end,
	press = function ()
		return stats.press
	end,
	authorities = function ()
		return stats.authorities
	end,
	cruelty = function ()
		return stats.cruelty
	end,
	insanity = function ()
		return stats.insanity
	end,
	total_torture_damage = function ()
		return stats.total_torture_damage
	end,
	budget = function ()
		return budget.capacity
	end,
	equity = function ()
		return stats.equity
	end,
	freedom = function ()
		return stats.freedom
	end,
	evolution = function ()
		return stats.evolution
	end,
	lawful = function ()
		return stats.lawful
	end,
	justice = function ()
		return stats.justice
	end,
	jen_approval = function ()
		return agents.jen.approval
	end,
	mordecai_approval = function ()
		return agents.mordecai.approval
	end,
	tab_approval = function ()
		return agents.tab.approval
	end,
	joseph_approval = function ()
		return agents.joseph.approval
	end,
	has_joseph = function ()
		return agents.joseph.present
	end
}
local setters = {
	popularity = stats.set_popularity,
	press = stats.set_press,
	authorities = stats.set_authorities,
	cruelty = stats.set_cruelty,
	insanity = stats.set_insanity,
	total_torture_damage = stats.set_total_torture_damage,
	budget = function (x)
		budget.capacity = x
	end,
	equity = stats.set_equity,
	freedom = stats.set_freedom,
	evolution = stats.set_evolution,
	lawful = stats.set_lawful,
	justice = stats.set_justice,
	jen_approval = function (x)
		agents.set_approval("jen", x)
	end,
	jen_declassified = read_only,
	mordecai_approval = function (x)
		agents.set_approval("mordecai", x)
	end,
	mordecai_declassified = read_only,
	tab_approval = function (x)
		agents.set_approval("tab", x)
	end,
	tab_declassified = read_only,
	joseph_approval = function (x)
		agents.set_approval("joseph", x)
	end,
	joseph_declassified = read_only,
	has_joseph = function (x)
		agents.joseph.present = x
	end
}
local incrementers = {
	popularity = stats.increment_popularity,
	press = stats.increment_press,
	authorities = stats.increment_authorities,
	cruelty = stats.increment_cruelty,
	insanity = stats.increment_insanity,
	total_torture_damage = stats.increment_total_torture_damage,
	budget = budget.increment_capacity,
	equity = stats.increment_equity,
	freedom = stats.increment_freedom,
	evolution = stats.increment_evolution,
	lawful = stats.increment_lawful,
	justice = stats.increment_justice,
	jen_approval = function (x)
		agents.increment_approval("jen", x)
	end,
	mordecai_approval = function (x)
		agents.increment_approval("mordecai", x)
	end,
	tab_approval = function (x)
		agents.increment_approval("tab", x)
	end,
	joseph_approval = function (x)
		agents.increment_approval("joseph", x)
	end
}

function fui.var_set(variable, value)
	local setter = setters[variable]

	if setter then
		setter(value, variable)
	else
		variables[variable] = value
	end
end

function fui.var_get(variable)
	local getter = getters[variable]

	if getter then
		return getter(variable)
	end

	return variables[variable]
end

function fui.var_increment(variable, amount)
	local incrementer = incrementers[variable]

	if incrementer then
		incrementer(amount, variable)
	else
		local value = fui.var_get(variable)

		if type(value) ~= "number" then
			error("Fuior variable \"" .. variable .. "\" is not numeric, so it cannot be incremented")
		end

		fui.var_set(variable, value + amount)
	end
end

function fui.var_decrement(variable, value)
	fui.var_increment(variable, -value)
end

fui.wait = progression.wait
fui.wait_for_input = interludes.wait_for_input
fui.wait_for_click = interludes.wait_for_input
fui.choose = interludes.show_choices
fui.hide_bubbles = interludes.hide_bubbles
fui.hide_all_characters = interludes.hide_all_characters
fui.hide_character = interludes.hide_character
fui.commit_stats = stats.commit

function fui:new()
	self = self or {}

	setmetatable(self, {
		__index = fui
	})

	local needs_wait = false

	local function satisfy_wait()
		needs_wait = false
	end

	self.wait = wrap(fui.wait, satisfy_wait)
	self.wait_for_input = wrap(fui.wait_for_input, satisfy_wait)
	self.wait_for_click = wrap(fui.wait_for_click, satisfy_wait)
	self.choose = wrap(fui.choose, satisfy_wait)
	self.text = wrap(fui.text, function ()
		if needs_wait then
			needs_wait = false

			interludes.wait_for_input()
		end

		needs_wait = true
	end)

	function self.pcall(command, ...)
		local ok, err = xpcall(function (...)
			return self[command](...)
		end, debug.traceback)

		if ok then
			return err
		end

		print("WARNING: " .. err)
	end

	return self
end

return fui
