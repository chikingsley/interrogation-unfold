local title = require("title.interface")
local variables = require("campaign.variables")
local copy = require("main.progression.commentary.copy")
local dispatcher = require("crit.dispatcher")
local slides_ = require("title.slides")
local progression = require("crit.progression")
local save_file = require("lib.save_file")
local config = save_file.config
local h_commentary_enable = hash("commentary_enable")
local h_commentary_disable = hash("commentary_disable")

local function new_commentary(t, key)
	local self = {}
	local slides = copy[key]

	if not slides then
		error("No commentary with key \"" .. key .. "\"")
	end

	self.copy = slides
	self.key = key

	function self.slides()
		if config.commentary then
			title.show_slides(slides, {
				font_size = 0.5
			})
		end
	end

	function self.conditioned_slides(predicate)
		return function ()
			if config.commentary and predicate() then
				title.show_slides(slides, {
					font_size = 0.5
				})
			end
		end
	end

	function self.overlay()
		if config.commentary then
			slides_.set_slides(slides)
			dispatcher.dispatch(h_commentary_enable)

			return true
		end

		return false
	end

	function self.overlay_once()
		if config.commentary and not variables["commentary_" .. key] then
			variables["commentary_" .. key] = true

			slides_.set_slides(slides)
			dispatcher.dispatch(h_commentary_enable)

			return true
		end

		return false
	end

	return self
end

local commentary = {
	is_enabled = function ()
		return not not config.commentary
	end,
	wait_for_commentary = function ()
		progression.wait_for_message(h_commentary_disable)
	end
}

setmetatable(commentary, {
	__index = new_commentary
})

return commentary
