local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local cursor = require("lib.cursor")
local h_virtual_cursor_set = hash("virtual_cursor_set")
local h_virtual_cursor_action = hash("virtual_cursor_action")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_tintw = hash("tint.w")
local h_scale = hash("scale")

function _env:init()
	self.sprite = msg.url("#sprite")
	self.go = msg.url(".")
	self.active = false

	msg.post(self.sprite, h_disable)
	go.set(self.sprite, h_tintw, 0)

	self.sub_id = dispatcher.subscribe({
		h_virtual_cursor_set,
		h_virtual_cursor_action,
		h_pause,
		h_resume
	})
end

local function update_mouse_pos()
	if defos then
		local pos = go.get_position()
		local drop_x, drop_y = Layout.projection_to_window(pos.x, pos.y)
		local _, _, w, h = defos.get_view_size()

		defos.set_cursor_pos_view(drop_x * w / Layout.window_width, (1 - drop_y / Layout.window_height) * h)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)

	if self.active then
		update_mouse_pos()
		cursor.set_visible(true, cursor.PRIORITY_SCENE_HIGH)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_virtual_cursor_action then
		local action = message.action
		local proj_x, proj_y = Layout.window_to_projection(action.screen_x, action.screen_y)

		go.set_position(vmath.vector3(proj_x, proj_y, 0))

		if action.pressed or action.released then
			local scale = message.pressed and 0.8 or 1
			local target = vmath.vector3(scale, scale, 1)

			go.cancel_animations(self.go, h_scale)
			go.animate(self.go, h_scale, go.PLAYBACK_ONCE_FORWARD, target, go.EASING_OUTEXPO, 0.3)
		end
	else
		if message_id == h_virtual_cursor_set then
			local active = message.active
			self.active = active

			if active then
				msg.post(self.sprite, h_enable)
			end

			local target = active and 0.8 or 0

			go.cancel_animations(self.sprite, h_tintw)
			go.animate(self.sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, target, go.EASING_LINEAR, 0.3, 0, function ()
				if not active then
					msg.post(self.sprite, h_disable)
				end
			end)

			if not active then
				update_mouse_pos()
			end

			cursor.set_visible(not active, cursor.PRIORITY_SCENE_HIGH)

			return
		end

		if message_id == h_pause then
			if self.active then
				update_mouse_pos()
			end
		elseif message_id == h_resume and not self.active then
			cursor.set_visible(true, cursor.PRIORITY_SCENE_HIGH)
		end
	end
end
