local dispatcher = require("crit.dispatcher")
local FocusGiver = require("crit.focus_giver")
local object_focus_map = require("campaign.office.object_focus_map")
local object_focus_context = require("campaign.office.object_focus_context")
local office = require("campaign.office")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_switch_input_method = hash("switch_input_method")
local h_office_object_focus = hash("office_object_focus")
local h_office_focus_giver_init = hash("office_focus_giver_init")

local function focus_object(self, nav_action)
	local next_focused_object = self.focus_map.default[nav_action or "no_action"]

	if next_focused_object then
		dispatcher.dispatch(h_office_object_focus, {
			object_id = next_focused_object
		})

		return true
	end

	return false
end

function _env:init()
	self.focus_map = object_focus_map[office.focus_map]
	self.focus_giver = FocusGiver.new({
		focus_context = object_focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			return focus_object(self, nav_action)
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect,
		h_office_focus_giver_init
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	dispatcher.unsubscribe(self.sub_id2)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		self.something_is_selected = true
	elseif message_id == h_office_object_deselect then
		self.something_is_selected = false

		timer.delay(0, false, function ()
			self.focus_giver:try_focus_first()
		end)
	elseif message_id == h_switch_input_method then
		if not self.something_is_selected then
			self.focus_giver:try_focus_first(message.nav_action)
		end
	elseif message_id == h_office_focus_giver_init then
		self.focus_giver:try_focus_first()

		self.sub_id2 = dispatcher.subscribe({
			h_switch_input_method
		})
	end
end

function _env:on_input(action_id, action)
	if not self.something_is_selected and self.focus_giver:on_input(action_id, action) then
		return true
	end
end
