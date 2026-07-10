local demo_cta = require("main.progression.demo_cta")
local iap_utils = require("lib.iap_utils")

local function demo_wall(func)
	return function (...)
		if iap_utils.is_demo() then
			demo_cta({
				continue_after_purchase = true
			})
		end

		return func(...)
	end
end

return demo_wall
