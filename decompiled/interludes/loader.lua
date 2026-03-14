local dispatcher = require("crit.dispatcher")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		self.init_message
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == self.init_message then
		local background = message.background or self.default_background
		local bg_url = msg.url(".")
		bg_url = msg.url(bg_url.socket, bg_url.path, hash(background))

		collectionfactory.create(bg_url)
	end
end
