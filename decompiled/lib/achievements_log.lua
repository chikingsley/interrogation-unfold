local M = {
	init = function ()
		print("Achievements initialised")
	end,
	set_achievement = function (id)
		print("Achievement set: " .. id)
	end,
	clear_achievement = function (id)
		print("Achievement cleared: " .. id)
	end,
	set_stat = function (id, value)
		print("Stat set: " .. id .. " = " .. value)
	end,
	store = function ()
		return
	end
}

return M
