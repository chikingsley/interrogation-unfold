local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local h_kill = hash("kill")
local h_set_subject = hash("set_subject")
local h_tintw = hash("tint.w")
local slow_death_duration = 1
local fast_death_duration = 0.3

function _env:init()
	self.go = msg.url(".")
	self.blood = msg.url("#blood")
	self.is_killed = false

	go.set(self.blood, h_tintw, 0)

	self.sub_id = dispatcher.subscribe({
		h_set_subject,
		h_kill
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_kill then
		if not self.is_killed then
			go.cancel_animations(self.blood, h_tintw)
			go.animate(self.blood, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_OUTCUBIC, slow_death_duration)

			self.is_killed = true
		end
	elseif message_id == h_set_subject then
		local is_dead = store.subjects[message.subject_id].health <= 0

		if is_dead == self.is_killed then
			return
		end

		self.is_killed = is_dead

		go.cancel_animations(self.blood, h_tintw)
		go.animate(self.blood, h_tintw, go.PLAYBACK_ONCE_FORWARD, is_dead and 1 or 0, go.EASING_LINEAR, fast_death_duration)
	end
end
