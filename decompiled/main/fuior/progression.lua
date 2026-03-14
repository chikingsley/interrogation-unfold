local compiler = require("main.fuior.compiler")
local fui = require("main.fuior.runtime")
local scenes = require("main.progression.scenes")
local title = require("title.interface")
local server = require("main.hot_reload_server")
local variables = require("campaign.variables")
local agents = require("campaign.agents")
local stats = require("campaign.stats")
local perks = require("campaign.perks")

return function (arg)
	if type(arg) == "table" and arg.from_server then
		arg = server.fuior_data
	end

	if type(arg) == "string" then
		arg = {
			filename = arg
		}
	end

	local data = arg.data
	local filename = arg.filename
	local ok, err = xpcall(function ()
		local func = nil

		if data then
			func = compiler.compile_string(data, filename)
		else
			func = compiler.compile(filename)
		end

		perks.reset()
		stats.reset()
		variables.reset()
		agents.reset()
		title.show_slides({
			"Click to start interlude"
		}, {
			auto_next_delay = math.huge
		})

		local runtime = fui.new()

		func(runtime)
	end, debug.traceback)

	if not ok then
		print("ERROR: " .. err)
		title.show_slides({
			"Fuior encountered an error. Check the console for details"
		}, {
			auto_next_delay = math.huge
		})
	end

	scenes.run_progression("main")
end
