local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local h_outcome_set_options = hash("outcome_set_options")
local h_show_button = hash("show_button")

function _env:init()
	self.spine_scene = msg.url("scene#spinemodel")
	self.sub_id = dispatcher.subscribe({
		h_outcome_set_options
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_outcome_set_options then
		local skin = "lose"
		local nav_button = msg.url("nav_button_lose")

		if message.has_won then
			skin = "win"
			nav_button = msg.url("nav_button_win")
		end

		msg.post(nav_button, h_show_button, {
			delay = 1
		})
		intl.select(function (lang)
			if pcall(function ()
				spine.set_skin(self.spine_scene, skin .. "_" .. lang)
			end) then
				return true
			else
				return nil
			end
		end)
	end
end
