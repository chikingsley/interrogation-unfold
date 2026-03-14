local dispatcher = require("crit.dispatcher")
local h_init_outcome = hash("init_outcome")
local h_outcome_set_options = hash("outcome_set_options")
local h_vignette_set = hash("vignette_set")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_outcome
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message)
	if message_id == h_init_outcome then
		local factory_component = msg.url("#" .. message.outcome_id)

		collectionfactory.create(factory_component)

		local transcript = msg.url("#transcript")

		collectionfactory.create(transcript)

		if message.no_vignette then
			dispatcher.dispatch(h_vignette_set, {
				tint = vmath.vector4(0)
			})
		end

		dispatcher.dispatch(h_outcome_set_options, message or {})
	end
end
