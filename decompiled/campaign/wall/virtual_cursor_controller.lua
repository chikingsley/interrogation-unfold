local VirtualCursor = require("lib.virtual_cursor")
local dispatcher = require("crit.dispatcher")
local h_switch_input_method = hash("switch_input_method")
local h_virtual_cursor_action = hash("virtual_cursor_action")
local h_virtual_cursor_set = hash("virtual_cursor_set")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_virtual_cursor_edge_push = hash("h_virtual_cursor_edge_push")

function _env:init()
	self.virtual_cursor = VirtualCursor.new({
		on_generated_input = function (action_id, action)
			dispatcher.dispatch(h_virtual_cursor_action, {
				action_id = action_id,
				action = action
			})
		end,
		on_active_change = function (active)
			dispatcher.dispatch(h_virtual_cursor_set, {
				active = active
			})
		end,
		on_edge_push = function (dx, dy)
			dispatcher.dispatch(h_virtual_cursor_edge_push, {
				dx = dx,
				dy = dy
			})
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_switch_input_method,
		h_wall_object_select,
		h_wall_object_deselect
	})

	msg.post(".", "acquire_input_focus")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		self.virtual_cursor:switch_input_method()
	elseif message_id == h_wall_object_select then
		self.virtual_cursor:set_enabled(false)
	elseif message_id == h_wall_object_deselect then
		self.virtual_cursor:set_enabled(true)
	end
end

function _env:on_input(action_id, action)
	if self.virtual_cursor:on_input(action_id, action) then
		return true
	end
end

function _env:update(dt)
	self.virtual_cursor:update(dt)
end
