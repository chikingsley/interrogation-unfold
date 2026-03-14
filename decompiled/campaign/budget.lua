local table_util = require("crit.table_util")
local intl = require("crit.intl")
local budget = {
	capacity = 0,
	selected = {},
	options = {}
}

function budget.reset()
	budget.selected = {}
	budget.options = {}
	budget.capacity = 0
end

function budget.save()
	return table_util.deep_clone(budget, table_util.no_functions)
end

function budget.load(snap)
	budget.reset()
	table_util.assign(budget, snap)
end

function budget.translate_option_text(option, key)
	local text = option[key]

	if text then
		return text
	end

	local intl_key = option.intl_key
	local intl_namespace = option.intl_namespace

	if intl_key and intl_namespace then
		return intl.namespace(intl_namespace).t("budget." .. intl_key .. "." .. key)
	end
end

function budget.set_options(options)
	budget.options = options
end

function budget.get_option(option_id)
	for i, option in ipairs(budget.options) do
		if option.id == option_id then
			return option
		end
	end

	return nil
end

function budget.set_selected(option_id, selected)
	budget.selected[option_id] = selected and true or nil
end

function budget.is_selected(option_id)
	return budget.selected[option_id] or false
end

function budget.increment_capacity(amount)
	budget.capacity = budget.capacity + amount
end

function budget.toggle_selected(option_id)
	local new_value = not budget.selected[option_id]

	budget.set_selected(option_id, new_value)

	return new_value
end

function budget.get_total_cost()
	local cost = 0

	for i, option in ipairs(budget.options) do
		if budget.selected[option.id] then
			cost = cost + option.cost
		end
	end

	return cost
end

function budget.are_options_set()
	for i, option in ipairs(budget.options) do
		if budget.selected[option.id] then
			return true
		end
	end

	return false
end

function budget.commit()
	budget.capacity = budget.capacity - budget.get_total_cost()
end

return budget
