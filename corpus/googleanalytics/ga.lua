local tracker = require("googleanalytics.tracker")
local queue = require("googleanalytics.internal.queue")
local M = {
	dispatch_period = tonumber(sys.get_config("googleanalytics.dispatch_period", 1800))
}
local default_tracker = nil

function M.get_default_tracker()
	if not default_tracker then
		local tracking_id = sys.get_config("googleanalytics.tracking_id")

		assert(tracking_id, "You must set tracking_id in section [googleanalytics] in game.project before using this module")

		default_tracker = tracker.create(tracking_id)
	end

	return default_tracker
end

function M.dispatch()
	queue.dispatch()
end

function M.update()
	if M.dispatch_period <= 0 then
		return
	end

	if not queue.last_dispatch_time or socket.gettime() >= queue.last_dispatch_time + M.dispatch_period then
		M.dispatch()
	end
end

return M
