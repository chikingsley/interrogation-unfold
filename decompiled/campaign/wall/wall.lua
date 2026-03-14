local dispatcher = require("crit.dispatcher")
local office = require("campaign.office")
local h_enable_debug_hitboxes = hash("enable_debug_hitboxes")
local total_episode_no = 10

function _env:init()
	for i = total_episode_no, (office.wall or 1) + 1, -1 do
		go.delete("episode" .. i, true)
	end

	if self.enable_debug_hitboxes then
		timer.delay(0.3, false, function ()
			dispatcher.dispatch(h_enable_debug_hitboxes)
		end)
	end
end
