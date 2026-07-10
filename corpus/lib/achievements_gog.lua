local gog = require("main.gog")
local M = {
	init = function ()
		return
	end,
	set_achievement = function (id)
		gog.set_achievement(id)
	end,
	clear_achievement = function (id)
		gog.clear_achievement(id)
	end,
	set_stat = function (id, value)
		return
	end,
	store = function ()
		gog.store()
	end
}

return M
