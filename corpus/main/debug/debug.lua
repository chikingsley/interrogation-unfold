local env = require("lib.environment")

function _env:init()
	if env.bundled and not env.debug then
		go.delete(".", true)

		return
	end
end
