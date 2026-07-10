local steam = require("main.steam")

function init()
	steam.init()
end

function final()
	steam.final()
end

function _env:update(dt)
	steam.update()
end
