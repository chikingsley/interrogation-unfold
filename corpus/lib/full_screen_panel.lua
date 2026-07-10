local Layout = require("crit.layout")
local input_state = require("crit.input_state")
local sys_config = require("lib.sys_config")
local is_mobile = sys_config.is_mobile
local h_click = hash("click")
local h_colorx = hash("color.x")
local h_colory = hash("color.y")
local h_colorz = hash("color.z")
local max = math.max
local min = math.min
local floor = math.floor
local FullScreenPanel = {
	INVALID = -1,
	CLOSED = 0,
	MIDWAY = 2,
	ANIMATING_TO_OPEN = 3,
	ANIMATING_TO_MIDWAY = 1,
	OPEN = 4,
	__index = {}
}

local function nop()
	return
end

local function identity(x)
	return x
end

function FullScreenPanel.new(opts)
	opts = opts or {}
	local self = {}

	setmetatable(self, FullScreenPanel)

	self.node = opts.node
	self.container = opts.container or opts.node
	self.background = opts.background
	self.frames = opts.frames or {}
	self.hitboxes = opts.hitboxes or {}
	self.hover_frame = opts.hover_frame or 0
	self.position = opts.position or vmath.vector3()
	self.scale = opts.scale or 1
	self.fps = opts.fps or 15
	self.on_state_change = opts.on_state_change or nop
	self.on_drawer_set_open = opts.on_drawer_set_open or nop
	self.on_frame_change = opts.on_frame_change or nop
	self.easing = opts.easing or identity
	self.action_map = opts.action_map or {
		[h_click] = true
	}
	self.node_position = self.position
	self.node_scale = 1
	self.hovered = false
	self.opened = false
	self.enabled = true
	self.cursor = 1
	self.current_frame = 0
	self.last_frame = #self.frames
	self.state = FullScreenPanel.INVALID
	self.mouse_position = {
		screen_x = 0,
		offscreen = true,
		screen_y = 0,
		y = 0,
		x = 0
	}
	self.accepted_click = false
	self.accepted_action = h_click
	local frames = self.frames

	for idx, frame in ipairs(frames) do
		frames[idx] = hash(frame)
	end

	local bg = self.background

	if bg then
		local bg_color = gui.get_color(bg)
		self.bg_color = bg_color
		self.bg_opacity = bg_color.w
		bg_color.w = 0

		gui.set_color(bg, bg_color)
		gui.set_size(bg, vmath.vector3(Layout.viewport_width, Layout.viewport_height, 0))
		gui.set_enabled(bg, false)
	end

	gui.play_flipbook(self.node, frames[#frames])

	local panel_size = gui.get_size(self.node)
	panel_size.x = panel_size.x + (opts.margin_horizontal or 0)
	self.panel_size = panel_size

	gui.play_flipbook(self.node, frames[1])

	return self
end

function FullScreenPanel.__index:place()
	local current_frame = self.current_frame
	local hover_frame = self.hover_frame
	local zoom_cursor = max(0, (current_frame - hover_frame) / (self.last_frame - hover_frame))
	local container = self.container
	local viewport_width = Layout.viewport_width
	local viewport_height = Layout.viewport_height
	local screen_center = vmath.vector3(viewport_width * 0.5, viewport_height * 0.5, 0)
	local proj_scale = Layout.projection_to_viewport_scale_x
	local original_scale = self.scale * proj_scale
	local original_position = self.position * proj_scale + screen_center
	local panel_size = self.panel_size
	local target_scale = min(viewport_height / panel_size.y, viewport_width / panel_size.x)
	self.target_scale = target_scale
	local target_position = screen_center
	local t = self.easing(zoom_cursor)
	local final_position = original_position * (1 - t) + target_position * t
	local final_scale = original_scale * (1 - t) + target_scale * t
	self.node_position = final_position
	self.node_scale = final_scale

	gui.set_position(container, final_position)
	gui.set_scale(container, vmath.vector3(final_scale))

	local bg = self.background

	if bg then
		gui.set_size(bg, vmath.vector3(Layout.viewport_width, Layout.viewport_height, 0))
	end
end

local function FullScreenPanel_pick(self, action)
	if action.offscreen then
		return false
	end

	if input_state.input_method ~= input_state.INPUT_METHOD_MOUSE then
		return false
	end

	local current_frame = self.current_frame

	if current_frame == 0 then
		self:update(0)
	end

	local hitbox = self.hitboxes[current_frame]

	if not hitbox then
		return Layout.pick_node(self.node, action)
	end

	local node_position = self.node_position
	local node_inv_scale = 1 / self.node_scale
	local screen_x, screen_y = Layout.action_to_viewport(action)
	local x = (screen_x - node_position.x) * node_inv_scale
	local y = (screen_y - node_position.y) * node_inv_scale

	return hitbox.left <= x and x <= hitbox.right and hitbox.bottom <= y and y <= hitbox.top
end

function FullScreenPanel.__index:update(dt)
	local cursor = self.cursor
	local target = self.opened and self.last_frame or self.hovered and self.enabled and self.hover_frame or 1

	if cursor > target then
		cursor = max(target, cursor - dt * self.fps)
	else
		cursor = min(target, cursor + dt * self.fps)
	end

	self.cursor = cursor
	local state = nil

	if cursor == target then
		state = cursor == 1 and FullScreenPanel.CLOSED or cursor == self.last_frame and FullScreenPanel.OPEN or FullScreenPanel.MIDWAY
	else
		state = cursor < self.hover_frame and FullScreenPanel.ANIMATING_TO_MIDWAY or FullScreenPanel.ANIMATING_TO_OPEN
	end

	local prev_state = self.state

	if state ~= prev_state then
		self.state = state

		self.on_state_change(state, prev_state)
	end

	local node = self.node
	local frame = floor(cursor)
	local prev_frame = self.current_frame

	if frame ~= prev_frame then
		self.current_frame = frame

		gui.play_flipbook(node, self.frames[frame])
		self:place()

		self.hovered = FullScreenPanel_pick(self, self.mouse_position)

		self.on_frame_change(frame)
	end

	local pressed_down = self.accepted_click and (self.hovered or self.accepted_action ~= h_click)
	local hide_pressed_down = self.hover_frame < frame

	if hide_pressed_down and not self.last_pressed_down then
		gui.cancel_animation(node, h_colorx)
		gui.cancel_animation(node, h_colory)
		gui.cancel_animation(node, h_colorz)

		local color = gui.get_color(node)

		gui.set_color(node, vmath.vector4(1, 1, 1, color.w))
	else
		local actual_pressed_down = pressed_down and not hide_pressed_down
		local last_actual_pressed_down = self.last_pressed_down and not self.last_hide_pressed_down

		if actual_pressed_down ~= last_actual_pressed_down then
			gui.cancel_animation(node, h_colorx)
			gui.cancel_animation(node, h_colory)
			gui.cancel_animation(node, h_colorz)

			local target_opacity = actual_pressed_down and 0.6 or 1

			gui.animate(node, h_colorx, target_opacity, gui.EASING_LINEAR, 0.2)
			gui.animate(node, h_colory, target_opacity, gui.EASING_LINEAR, 0.2)
			gui.animate(node, h_colorz, target_opacity, gui.EASING_LINEAR, 0.2)
		end
	end

	self.last_pressed_down = pressed_down
	self.last_hide_pressed_down = hide_pressed_down
	local bg = self.background

	if bg then
		local bg_color = self.bg_color
		local hover_frame = self.hover_frame
		local bg_opacity = self.bg_opacity * min(1, max(0, (cursor - hover_frame) / (self.last_frame - hover_frame)))
		bg_color.w = bg_opacity

		gui.set_color(bg, bg_color)
		gui.set_enabled(bg, bg_opacity > 0)
	end
end

function FullScreenPanel.__index:set_position(pos, scale)
	self.position = pos or self.position
	self.scale = scale or self.scale

	self:place()
end

function FullScreenPanel.__index:set_opened(opened)
	if self.opened == opened then
		return
	end

	self.opened = opened

	if not opened then
		self.hovered = FullScreenPanel_pick(self, self.mouse_position)
	end
end

function FullScreenPanel.__index:set_enabled(enabled)
	if self.enabled == enabled then
		return
	end

	self.enabled = enabled

	if not enabled then
		self.accepted_click = false
	end
end

function FullScreenPanel.__index:on_input(action_id, action)
	local mouse_moved = not action_id and not is_mobile
	local hovered = self.hovered

	if mouse_moved or action_id == h_click and (self.accepted_click or action.pressed) then
		local mouse_position = self.mouse_position
		mouse_position.offscreen = false
		mouse_position.x = action.x
		mouse_position.y = action.y
		mouse_position.screen_x = action.screen_x
		mouse_position.screen_y = action.screen_y
		hovered = FullScreenPanel_pick(self, mouse_position)
		self.hovered = hovered
	end

	if not self.enabled then
		return
	end

	if action_id == h_click and action.pressed and self.opened and not hovered then
		self.on_drawer_set_open(false)

		return true
	end

	if action_id == h_click and is_mobile and action.released then
		self.mouse_position.offscreen = true
		self.hovered = false
	end

	if self.action_map[action_id] then
		if action.pressed then
			self.accepted_click = self.hovered or action_id ~= h_click
			self.accepted_action = action_id
		end

		if action.released and action_id == self.accepted_action and self.accepted_click then
			self.accepted_click = false

			if action_id ~= h_click then
				self.on_drawer_set_open(not self.opened)

				return true
			end

			if hovered and not self.opened then
				self.on_drawer_set_open(true)

				return true
			end
		end
	end

	local state = self.state

	if state == FullScreenPanel.OPEN or state == FullScreenPanel.ANIMATING_TO_OPEN then
		return true
	end

	return self.accepted_click
end

function FullScreenPanel.__index:switch_input_method()
	if input_state.input_method ~= input_state.INPUT_METHOD_MOUSE then
		self.mouse_position.offset = true
		self.hovered = false
	end
end

return FullScreenPanel
