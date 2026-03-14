local dispatcher = require("crit.dispatcher")
local h_settings_show = hash("settings_show")
local h_settings_hide = hash("settings_hide")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_settings_show,
		h_settings_hide
	})
	self.factory = msg.url("#collectionfactory")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_settings_show then
		self.collection = collectionfactory.create(self.factory)
	elseif message_id == h_settings_hide and self.collection then
		go.delete(self.collection, true)

		self.collection = nil
	end
end
