local uuid_generator = require("googleanalytics.internal.uuid")
local queue = require("googleanalytics.internal.queue")
local file = require("googleanalytics.internal.file")
local M = {}
local UUID_FILENAME = "__ga_uuid"

local function url_encode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w %-%_%.%~])", function (c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = string.gsub(str, " ", "+")
	end

	return str
end

local function url_decode(str)
	str = string.gsub(str, "+", " ")
	str = string.gsub(str, "%%(%x%x)", function (h)
		return string.char(tonumber(h, 16))
	end)
	str = string.gsub(str, "\r\n", "\n")

	return str
end

local function get_uuid()
	local uuid, err = file.load(UUID_FILENAME)

	if not uuid then
		uuid_generator.seed()

		uuid = uuid_generator()

		file.save(UUID_FILENAME, uuid)
	end

	return uuid
end

local function get_application_name()
	return sys.get_config("project.title"):gsub(" ", "_")
end

local function get_application_id()
	local APPLICATION_IDS = {
		Android = sys.get_config("android.package"),
		["iPhone OS"] = sys.get_config("ios.bundle_identifier"),
		Darwin = sys.get_config("osx.bundle_identifier")
	}
	local system_name = sys.get_sys_info().system_name

	return APPLICATION_IDS[system_name] or get_application_name() .. system_name
end

function M.create(tracking_id)
	local tracker = {
		base_params = "v=1&ds=app" .. "&cid=" .. get_uuid() .. "&tid=" .. tracking_id .. "&vp=" .. sys.get_config("display.width") .. "x" .. sys.get_config("display.height") .. "&ul=" .. sys.get_sys_info().device_language .. "&an=" .. url_encode(get_application_name()) .. "&aid=" .. url_encode(get_application_id()) .. "&av=" .. (sys.get_config("project.version") or "1.0")
	}
	local event_params = tracker.base_params .. "&t=event"
	local timing_params = tracker.base_params .. "&t=timing"
	local screenview_params = tracker.base_params .. "&t=screenview"
	local exception_params = tracker.base_params .. "&t=exception"

	function tracker.enable_crash_reporting(enabled, on_soft_crash, on_hard_crash)
		if enabled then
			sys.set_error_handler(function (source, message, traceback)
				tracker.exception(message, false)

				if on_soft_crash then
					on_soft_crash(source, message, traceback)
				end
			end)

			local handle = crash.load_previous()

			if handle then
				tracker.exception(crash.get_extra_data(handle), true)

				if on_hard_crash then
					on_hard_crash(handle)
				end

				crash.release(handle)
			end
		else
			sys.set_error_handler(function ()
				return
			end)
		end
	end

	function tracker.raw(params)
		assert(params and type(params) == "string", "You must provide some params (of type string)")
		queue.add(params)
	end

	function tracker.exception(description, is_fatal)
		assert(not description or type(description) == "string", "Description must be nil or of type string")
		assert(is_fatal == nil or type(is_fatal) == "boolean", "Is_fatal must be nil or of type boolean")
		queue.add(exception_params .. (is_fatal ~= nil and "&exf=" .. (is_fatal and "1" or "0") or "") .. (description and "&exd=" .. url_encode(description) or ""))
	end

	function tracker.event(category, action, label, value)
		assert(category and type(category) == "string" and #category > 0, "You must provide a category (of type string, must not be empty)")
		assert(action and type(action) == "string" and #action > 0, "You must provide an action (of type string, must not be empty)")
		assert(not label or type(label) == "string", "Label must be nil or of type string")
		assert(not value or type(value) == "number" and value >= 0, "Value must be nil or a positive number")
		queue.add(event_params .. "&ec=" .. url_encode(category) .. "&ea=" .. url_encode(action) .. (label and "&el=" .. url_encode(label) or "") .. (value and "&ev=" .. tostring(value) or ""))
	end

	function tracker.screenview(screen_name)
		assert(screen_name and type(screen_name) == "string", "You must specify a screen name (of type string)")
		queue.add(screenview_params .. "&cd=" .. url_encode(screen_name))
	end

	function tracker.timing(category, variable, time, label)
		assert(category and type(category) == "string", "You must provide a category (of type string)")
		assert(variable and type(variable) == "string", "You must provide a variable (of type string)")
		assert(time and type(time) == "number" and time >= 0, "You must provide a time (as a positive number)")
		assert(not label or type(label) == "string", "Label must be nil or a string")
		queue.add(timing_params .. "&utc=" .. url_encode(category) .. "&utv=" .. url_encode(variable) .. "&utt=" .. tostring(time) .. (label and "&utl=" .. url_encode(label) or ""))
	end

	return tracker
end

return M
