local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local h_click = hash("click")
local h_gamepad_start = hash("gamepad_start")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_key_escape = hash("key_escape")
local advance = nil

function _env:init()
	msg.post(".", "acquire_input_focus")

	self.sub_id = dispatcher.subscribe({
		self.init_message
	})
	self.advanced = false
	self.inited = false
	self.timer = timer.delay(0, false, function ()
		self.timer = timer.delay(self.splash_duration, false, advance)
	end)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function dispatch_indirectly(self)
	timer.delay(0, false, function ()
		dispatcher.dispatch(self.message)
	end)
end

function advance(self, timer_id)
	if not timer_id and self.timer then
		timer.cancel(self.timer)
	end

	self.timer = nil

	if not self.advanced then
		self.advanced = true

		if self.inited then
			dispatch_indirectly(self)
		end
	end
end

function _env:on_input(action_id, action)
	if action_id == h_click and action.released or (action_id == h_key_escape or action_id == h_gamepad_start or action_id == h_gamepad_rpad_up or Button.action_id_to_navigation_action(action_id) == Button.NAVIGATE_CONFIRM) and action.pressed then
		advance(self)

		return true
	end
end

function _env:on_message(message_id, message)
	if message_id == self.init_message then
		self.inited = true

		if self.advanced then
			dispatch_indirectly(self)
		end
	end
end
