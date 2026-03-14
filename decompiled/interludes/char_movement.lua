local slots = require("interludes.slots")
local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local large_ui = require("lib.large_ui")
local h_interludes_show_character = hash("interludes_show_character")
local h_interludes_hide_character_in_slot = hash("interludes_hide_character_in_slot")
local h_interludes_focus_character = hash("interludes_focus_character")
local h_interludes_set_internal_char_flip = hash("interludes_set_internal_char_flip")
local h_window_change_size = hash("window_change_size")
local h_positionx = hash("position.x")
local h_positiony = hash("position.y")
local h_scale = hash("scale")
local slot_x = {
	-0.32,
	0.32,
	-0.19,
	0.19,
	-0.08,
	0.08,
	-0.25,
	0.5,
	0
}
local large_ui_slot_y = {
	-0.1,
	-0.1,
	-0.1,
	-0.1,
	-0.1,
	-0.1,
	0,
	0,
	0
}
local slot_z = {
	0.6,
	0.6,
	0.5,
	0.5,
	0.4,
	0.4,
	0.6,
	0.5,
	0.5
}
local slot_scale = {
	1,
	1,
	0.92,
	0.92,
	0.85,
	0.85,
	1,
	1,
	1
}
local show_character = nil

function _env:init()
	if self.disabled then
		return
	end

	self.go_url = msg.url(".")
	local slot = slots.slot_of_char[self.name]

	if slot then
		show_character(self, slot, self.animate_on_load)
	end

	self.sub_id = dispatcher.subscribe({
		h_interludes_show_character,
		h_interludes_hide_character_in_slot,
		h_interludes_focus_character,
		h_window_change_size
	})
end

function _env:final()
	if self.disabled then
		return
	end

	dispatcher.unsubscribe(self.sub_id)
end

local function get_character_y(self)
	local slot = slots.slot_of_char[self.name]
	local large_ui_y_offset = 0

	if slot then
		large_ui_y_offset = large_ui.enabled and not slots.large_ui_fixed[slot] and large_ui_slot_y[slot] * Layout.projection_height or 0
	end

	if self.fixed_y then
		return self.fixed_y_value
	end

	return -0.5 * math.min(Layout.projection_height, Layout.projection_width * 0.625) + large_ui_y_offset
end

function show_character(self, slot, animated)
	local x_factor = slot_x[slot]
	local initial_x = x_factor * 1.3 * Layout.projection_width
	local x = x_factor * Layout.projection_width
	local y = get_character_y(self)
	local z = slot_z[slot]
	local focus_scale = (not slots.focused_character or slots.focused_character == self.name) and 1 or self.unfocused_scale_factor
	local scale_factor = slot_scale[slot] * focus_scale * self.scale

	go.set_scale(vmath.vector3(scale_factor, scale_factor, 1))

	local is_flipped = slot_x[slot] < 0

	go.set_rotation(vmath.quat_rotation_y(is_flipped and math.pi or 0))
	dispatcher.dispatch(h_interludes_set_internal_char_flip, {
		character = self.name,
		is_flipped = is_flipped
	})

	local url = self.go_url

	go.cancel_animations(url, h_positionx)

	if self.show_delay then
		timer.cancel(self.show_delay)

		self.show_delay = nil
	end

	if animated then
		go.set_position(vmath.vector3(initial_x, y, z))

		self.show_delay = timer.delay(0, false, function ()
			self.show_delay = nil

			go.animate(url, h_positionx, go.PLAYBACK_ONCE_FORWARD, x, go.EASING_OUTEXPO, 0.5)
		end)
	else
		go.set_position(vmath.vector3(x, y, z))
	end
end

local function hide_character(self, slot)
	local x_factor = slot_x[slot]
	local final_x = x_factor * 1.3 * Layout.projection_width

	if self.show_delay then
		timer.cancel(self.show_delay)

		self.show_delay = nil
	end

	local url = self.go_url

	go.cancel_animations(url, h_positionx)
	go.animate(url, h_positionx, go.PLAYBACK_ONCE_FORWARD, final_x, go.EASING_INCUBIC, 0.5)
end

local function set_focused(self, focused)
	local slot = slots.slot_of_char[self.name]

	if not slot then
		return
	end

	local focus_scale = focused and 1 or self.unfocused_scale_factor
	local scale_factor = slot_scale[slot] * focus_scale * self.scale
	local scale = vmath.vector3(scale_factor, scale_factor, 1)
	local url = self.go_url

	go.cancel_animations(url, h_scale)
	go.animate(url, h_scale, go.PLAYBACK_ONCE_FORWARD, scale, go.EASING_INOUTQUAD, 0.2)
end

function _env:on_message(message_id, message)
	if message_id == h_interludes_show_character then
		if hash(message.character) == self.name then
			local options = message.options or {}
			local animated = options.animate_movement

			if animated == nil then
				animated = true
			end

			show_character(self, message.slot, animated)
		end
	elseif message_id == h_interludes_hide_character_in_slot then
		if hash(message.character) == self.name then
			hide_character(self, message.slot)
		end
	elseif message_id == h_interludes_focus_character then
		local focused_character = message.character
		local focused = not focused_character or focused_character == self.name

		set_focused(self, focused)
	elseif message_id == h_window_change_size then
		go.set(self.go_url, h_positiony, get_character_y(self))
	end
end
