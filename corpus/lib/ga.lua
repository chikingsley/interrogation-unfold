local optional_req = require("lib.optional_require")
local ga_tracker = optional_req("googleanalytics.tracker")
local ga = optional_req("googleanalytics.ga")
local env = require("lib.environment")
local tracking_id = nil

if env.ga_tracking or env.debug_tracking then
	local debug = not env.bundled or env.debug
	tracking_id = sys.get_config(debug and "googleanalytics.debug_tracking_id" or "googleanalytics.tracking_id")

	if debug and ga then
		ga.dispatch_period = tonumber(sys.get_config("googleanalytics.debug_dispatch_period", 10))
	end
end

local tracker = nil

if tracking_id and ga_tracker then
	tracker = ga_tracker.create(tracking_id .. "&aip=1")
else
	tracker = {
		disabled = true
	}

	local function nop()
		return
	end

	setmetatable(tracker, {
		__index = function ()
			return nop
		end
	})
end

if env.local_tracking then
	local application_name = sys.get_config("project.title"):gsub(" ", "_")
	local save_file = sys.get_save_file(application_name, "local_tracking.csv")
	local file, err = io.open(save_file, "a")

	if err then
		print("ERROR: Local tracking: " .. err)
	else
		local function log_locally(args)
			local timestamp = socket and socket.gettime() or os.time()

			for i, arg in ipairs(args) do
				if type(arg) ~= "string" then
					arg = tostring(arg)
				end

				if arg:find(",") then
					arg = "\"" .. arg:gsub("\"", "\"\"") .. "\""
				end

				args[i] = arg
			end

			file:write(string.format("%.3f,", timestamp) .. table.concat(args, ",") .. "\n")
			file:flush()
		end

		local old_tracker = tracker
		tracker = {
			local_tracker = true,
			disabled = false
		}

		setmetatable(tracker, {
			__index = function (_, key)
				return function (...)
					log_locally({
						key,
						...
					})
					old_tracker[key](...)
				end
			end
		})
	end
end

return tracker
