local store = require("level.store")
local level_dialogue = require("level.dialogue.dialogue")
local dialogue = level_dialogue.create_dialogue({
	predicate = function (subject_id)
		local subject = store.subjects[subject_id].avatar

		return subject ~= "helene" and subject ~= "phone"
	end
})

function _env:init()
	dialogue.init(self)
	gui.set_render_order(5)
end

function _env:final()
	dialogue.final(self)
end

function _env:on_message(message_id, message, sender)
	dialogue.on_message(self, message_id, message, sender)
end
