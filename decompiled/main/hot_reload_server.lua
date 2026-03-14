local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local http_server, mime = nil

if env.debug or not env.bundled then
	local optional_req = require("lib.optional_require")
	http_server = optional_req("defnet.http_server")
	mime = optional_req("socket.mime")
end

local PORT = 3648
local hs = nil
local server = {}

local function load_episode(hot)
	return function (matches)
		local ok, err = pcall(function ()
			local data = json.decode(mime.unb64(matches[1]))
			server.level_data = data
			data.level_id = data.level_id or "unknown"
			local load_options = data.load_options or {}
			data.load_options = nil
			load_options.from_server = true

			if defos and defos.activate then
				defos.activate()
			end

			if hot and server.loaded_level_id == data.level_id then
				dispatcher.dispatch("hot_update_episode")
			else
				dispatcher.dispatch("run_progression", {
					id = "single_level",
					options = load_options
				})
			end
		end)

		if ok then
			return hs.json("{}")
		else
			return hs.json("{ \"error\": \"" .. err .. "\" }")
		end
	end
end

local function load_fuior(matches)
	local ok, err = pcall(function ()
		local data = json.decode(mime.unb64(matches[1]))
		server.fuior_data = {
			data = data.data,
			filename = data.filename
		}

		if defos and defos.activate then
			defos.activate()
		end

		dispatcher.dispatch("run_progression", {
			id = "fuior",
			options = {
				from_server = true
			}
		})
	end)

	if ok then
		return hs.json("{}")
	else
		return hs.json("{ \"error\": \"" .. err .. "\" }")
	end
end

local function toggle_flag(matches)
	dispatcher.dispatch("level_toggle_flag", {
		flag = matches[1]
	})

	return hs.json("{}")
end

function server.init()
	hs = http_server.create(PORT)

	hs.router.get("/load_episode/(.*)$", load_episode(false))
	hs.router.get("/hot_load_episode/(.*)$", load_episode(true))
	hs.router.get("/load_fuior/(.*)$", load_fuior)
	hs.router.get("/toggle_flag/(.*)$", toggle_flag)
	hs.router.unhandled(function (method, uri)
		return hs.json("{ \"error\": \"not_found\" }", http_server.NOT_FOUND)
	end)
	hs.start()
end

function server.final()
	hs.stop()
end

function server.update()
	hs.update()
end

if not http_server or not mime then
	local function nop()
		return
	end

	server.init = nop
	server.final = nop
	server.update = nop
end

return server
