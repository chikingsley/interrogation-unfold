local dispatcher = require("crit.dispatcher")
local h_outcome_set_options = hash("outcome_set_options")
local h_show_button = hash("show_button")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_outcome_set_options
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_outcome_set_options then
		local has_won = message.has_won
		local nav_button = msg.url("nav_button_lose")
		local char_factory = msg.url("elias_hall#lose")

		if has_won then
			nav_button = msg.url("nav_button_win")
			char_factory = msg.url("elias_hall#win")
		end

		msg.post(nav_button, h_show_button, {
			delay = 1
		})
		factory.create(char_factory)
	end
end
