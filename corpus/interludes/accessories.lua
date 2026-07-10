local dispatcher = require("crit.dispatcher")
local h_interludes_spawn_accessory = hash("interludes_spawn_accessory")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_interludes_spawn_accessory
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_interludes_spawn_accessory then
		local factory_url = msg.url()
		factory_url.fragment = hash(message.accessory)
		local properties = {}

		if message.properties then
			for k, v in pairs(message.properties) do
				properties[hash(k)] = v
			end
		end

		collectionfactory.create(factory_url, nil, nil, properties)
	end
end
