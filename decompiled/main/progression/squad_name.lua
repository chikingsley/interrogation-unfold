local variables = require("campaign.variables")
local intl = require("crit.intl")
intl = intl.namespace("campaign")

local function get_squad_name()
	return intl("press_release.squad_name." .. (variables.squad_name or 1))
end

return get_squad_name
