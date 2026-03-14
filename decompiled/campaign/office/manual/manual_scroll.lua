local dispatcher = require("crit.dispatcher")
local Scroll = require("crit.scroll")
local Layout = require("crit.layout")
local Directional = require("lib.directional")
local pick = require("crit.pick")
local large_ui = require("lib.large_ui")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_manual_set_position = hash("office_manual_set_position")
local h_office_manual_cancel_touch = hash("office_manual_cancel_touch")
local h_office_manual_reset_scroll = hash("office_manual_reset_scroll")
local h_manual = hash("manual")
local content_height = 2080

function _env:init()
	local sprite = msg.url("manual_container#sprite")
	local manual_go = msg.url("manual")
	self.manual_go = manual_go
	self.initial_position = go.get_position(manual_go)
	self.initial_scale = go.get_position(manual_go)
	self.scroll = Scroll.new({
		is_go = true,
		pick = function (action)
			return pick.pick_sprite(sprite, Layout.action_to_projection(action))
		end,
		on_capture_touch = function ()
			dispatcher.dispatch(h_office_manual_cancel_touch)
		end
	})
	self.enabled = false

	self.scroll:add_offset_listener(function (scroll)
		if not self.enabled then
			return
		end

		local offset = scroll.offset
		local position = self.initial_position + vmath.vector3(0, offset, 0)

		go.set_position(position, manual_go)
		dispatcher.dispatch(h_office_manual_set_position, {
			position = position,
			scale = self.initial_scale
		})
	end)

	self.directional = Directional.new({
		keyboard = true,
		gamepad = true,
		pan_speed = 1500,
		on_pan = function (dx, dy)
			if self.enabled then
				self.scroll:set_offset(self.scroll.offset - dy)
			end
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_office_object_selected,
		h_office_object_deselect,
		h_office_manual_reset_scroll
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message)
	if message_id == h_office_object_selected then
		if message.object_id == h_manual and large_ui.enabled then
			self.scroll:set_content_height(content_height)
			self.scroll:set_view_height(Layout.projection_height)

			self.initial_position = go.get_position(self.manual_go)
			self.initial_scale = go.get_scale(self.manual_go)
			self.enabled = true

			self.directional.reset()
			self.scroll:set_offset(0)
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_manual then
			self.enabled = false

			self.scroll:set_offset(0)
		end
	elseif message_id == h_office_manual_reset_scroll then
		self.scroll:set_offset(0)
	end
end

function _env:on_input(action_id, action)
	if self.enabled then
		self.directional.on_input(action_id, action)

		if self.scroll:on_input(action_id, action) then
			return true
		end
	end
end

function _env:update(dt)
	if self.enabled then
		self.directional.update(dt)
		self.scroll:update(dt)
	end
end
