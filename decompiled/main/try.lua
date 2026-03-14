local dispatcher = require("crit.dispatcher")

local function try(f)
	local status, exception = pcall(f)

	if not status then
		_G.interrogation_exception = exception

		dispatcher.dispatch("load_scene", {
			scene = "error"
		})
		error(exception)
	end
end

return try
