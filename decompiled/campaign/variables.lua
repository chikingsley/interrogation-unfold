local table_util = require("crit.table_util")
local variables = {}

function variables.reset()
	for key, value in pairs(variables) do
		if type(value) ~= "function" then
			variables[key] = nil
		end
	end
end

function variables.save()
	return table_util.deep_clone(variables, table_util.no_functions)
end

function variables.load(snap)
	variables.reset()
	table_util.assign(variables, snap)
end

variables.reset()

return variables
