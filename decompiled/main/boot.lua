local load_resources = require("main.loader.load_resources")
local dispatcher = require("crit.dispatcher")
local h_loader_destroy = hash("loader_destroy")

local function bootstrap(self)
	dispatcher.dispatch(h_loader_destroy)
	collectionfactory.create("#main", nil, nil, {
		[hash("/controller")] = {
			scenes = self.scenes
		}
	})
end

function _env:init()
	load_resources.bootstrap(self, bootstrap, self.scenes)
end
