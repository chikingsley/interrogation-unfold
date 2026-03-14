local intl = require("crit.intl")
local M = {
	hints = {
		1
	},
	hint_is_active = function ()
		return true
	end,
	hint_text = function ()
		return intl.namespace("chapter3").t("episode8.hint")
	end
}

return M
