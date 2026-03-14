math.randomseed(os.time())

for i = 1, 8 do
	math.random()
end

local env = require("lib.environment")
local save_file = require("lib.save_file")
local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local server = require("main.hot_reload_server")
local achievements = require("lib.achievements")

local function ensure_cursor(resource_path, file_name)
	local file_path = sys.get_save_file("Interrogation", file_name)
	local f = io.open(file_path, "r")

	if f then
		f:close()

		return file_path
	end

	local data = sys.load_resource(resource_path)

	if not data then
		return nil
	end

	f = io.open(file_path, "wb")

	if not f then
		return nil
	end

	f:write(data)
	f:close()

	return file_path
end

function _env:init()
	local system_name = sys.get_sys_info().system_name

	intl.init({
		language = env.language,
		warn_fallback = not env.bundled or env.debug
	})

	if env.debug or not env.bundled then
		window.set_dim_mode(window.DIMMING_OFF)
	end

	if defos then
		local full_screen_setting = nil

		if env.full_screen == nil then
			full_screen_setting = save_file.config.full_screen
		else
			full_screen_setting = env.full_screen
		end

		defos.set_fullscreen(full_screen_setting)

		if not full_screen_setting and (env.window_width or env.window_height) then
			local aspect = Layout.design_width / Layout.design_height
			local width = env.window_width or env.window_height * aspect
			local height = env.window_height or env.window_width / aspect
			local x, y = nil

			if env.display then
				local display = defos.get_displays()[env.display]

				if display then
					x = display.bounds.x + (display.bounds.width - width) * 0.5
					y = display.bounds.y + (display.bounds.height - height) * 0.5
				end
			end

			defos.set_view_size(x, y, width, height)
		end

		local cursor_data = nil

		if system_name == "Darwin" then
			local image = resource.load("/main/cursors/cursor.tif")

			if image then
				cursor_data = {
					hot_spot_y = 9,
					hot_spot_x = 10,
					image = image
				}
			end
		elseif system_name == "Windows" then
			cursor_data = ensure_cursor("/main/cursors/cursor.cur", "cursor.cur")
		elseif system_name == "Linux" then
			cursor_data = ensure_cursor("/main/cursors/cursor.xcur", "cursor.xcur")
		end

		if cursor_data then
			defos.set_cursor(cursor_data)
		end

		if system_name == "Darwin" then
			local x, y, w, h = defos.get_view_size()

			defos.set_view_size(x, y, w, h - 1)
			timer.delay(0, false, function ()
				defos.set_view_size(x, y, w, h)
			end)
		end
	end

	if html5 then
		html5.run("document.getElementById('canvas').style.backgroundImage = null")
	end

	if discordrich then
		local auto_register = system_name ~= "Linux"

		discordrich.initialize(sys.get_config("discordrich.client_id", ""), nil, auto_register)
		discordrich.update_presence({
			large_image_key = "appiconnotext",
			state = intl("discord.state")
		})
	end

	server.init()
	achievements.init()
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	server.final()

	if discordrich then
		discordrich.clear_presence()
	end
end

function _env:update(dt)
	if defos then
		save_file.config_set("full_screen", defos.is_fullscreen())
	end

	server.update()
end
