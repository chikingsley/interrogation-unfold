local steam = require("main.steam")
local M = {
	init = function ()
		return
	end,
	set_achievement = function (id)
		steam.set_achievement(id)
	end,
	clear_achievement = function (id)
		steam.clear_achievement(id)
	end,
	set_stat = function (id, value)
		return
	end,
	store = function ()
		steam.store()
	end
}

return M
