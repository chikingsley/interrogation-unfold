local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local h_init_level = hash("init_level")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_level
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		for subject_id, subject in ipairs(store.subjects) do
			if subject.avatar == "phone" then
				local dialogue_phone_factory = msg.url("#factory")

				factory.create(dialogue_phone_factory)

				return
			end
		end
	end
end
