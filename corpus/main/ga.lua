local optional_req = require("lib.optional_require")
local ga = optional_req("googleanalytics.ga")
local tracker = require("lib.ga")

function _env:init()
	tracker.enable_crash_reporting(true)
	tracker.event("app", "boot")
end

if ga then
	function _env:update(dt)
		ga.update()
	end
end
