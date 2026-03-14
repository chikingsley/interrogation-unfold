local optionals = {
	["googleanalytics.tracker"] = require("googleanalytics.tracker"),
	["googleanalytics.ga"] = require("googleanalytics.ga"),
	["defnet.http_server"] = require("defnet.http_server"),
	["defnet.tcp_client"] = require("defnet.tcp_client"),
	["socket.mime"] = require("socket.mime")
}

return function (id)
	return optionals[id]
end
