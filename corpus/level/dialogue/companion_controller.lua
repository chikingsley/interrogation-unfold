local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local h_init_level = hash("init_level")
local h_level_event = hash("level_event")
local h_companion_animate = hash("companion_animate")
local h_level_avatar_play_animation = hash("level_avatar_play_animation")

function _env:init()
	self.enabled = false
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_level_event
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		for subject_id, subject in ipairs(store.subjects) do
			if subject.avatar == "helene" then
				local dialogue_companion_factory = msg.url("#factory")

				factory.create(dialogue_companion_factory)

				self.enabled = true

				return
			end
		end
	elseif self.enabled and message_id == h_level_event then
		local event = message

		if event.event_id == h_companion_animate then
			dispatcher.dispatch(h_level_avatar_play_animation, {
				companion = 1,
				animation = hash(event.args[1]),
				subject_id = event.subject_id
			})
		end
	end
end
