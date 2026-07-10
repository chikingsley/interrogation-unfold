local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local h_level_disable_controls = hash("level_disable_controls")
local h_level_enable_controls = hash("level_enable_controls")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_level_advance = hash("level_advance")
local h_click = hash("click")
local h_key_escape = hash("key_escape")

function _env:init()
	self.enabled = false
	self.has_focus = false
	self.wait_for_next_click = false
	self.sub_id = dispatcher.subscribe({
		h_level_disable_controls,
		h_level_enable_controls
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_level_disable_controls then
		self.enabled = true
		self.wait_for_next_click = message.until_next_click

		if not self.has_focus then
			self.has_focus = true

			msg.post(".", h_acquire_input_focus)
		end
	elseif message_id == h_level_enable_controls and self.enabled then
		self.enabled = false

		if self.has_focus then
			self.has_focus = false

			msg.post(".", h_release_input_focus)
		end
	end
end

function _env:on_input(action_id, action)
	if not self.wait_for_next_click then
		return true
	end

	if action_id == h_click then
		if action.pressed then
			if self.enabled then
				self.enabled = false

				dispatcher.dispatch(h_level_advance)
				dispatcher.dispatch(h_level_enable_controls)
			end
		elseif action.released and not self.enabled and self.has_focus then
			self.has_focus = false

			msg.post(".", h_release_input_focus)
		end
	elseif self.enabled and action.pressed and Button.action_id_to_navigation_action(action_id) == Button.NAVIGATE_CONFIRM then
		self.enabled = false

		if self.has_focus then
			self.has_focus = false

			msg.post(".", h_release_input_focus)
		end

		dispatcher.dispatch(h_level_advance)
		dispatcher.dispatch(h_level_enable_controls)

		return true
	end

	if action_id == h_key_escape then
		return false
	end

	return true
end
