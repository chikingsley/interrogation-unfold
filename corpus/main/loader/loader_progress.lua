local dispatcher = require("crit.dispatcher")
local loader = require("main.loader.loader_progress")
local h_loader_set_progress = hash("loader_set_progress")
local h_loader_destroy = hash("loader_destroy")

local function set_progress(self)
	if loader.label then
		label.set_text(self.label, loader.label)
	end

	if loader.progress then
		label.set_text(self.progress, loader.progress)
	end
end

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_loader_set_progress,
		h_loader_destroy
	})
	self.label = msg.url("loader_label")
	self.progress = msg.url("loader_progress")

	label.set_text(self.label, "")
	label.set_text(self.progress, "")

	if loader.loaded then
		set_progress(self)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_loader_set_progress then
		set_progress(self)
	elseif message_id == h_loader_destroy then
		go.delete(".", true)
	end
end
