local Button = require("crit.button")
local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local intl = require("crit.intl")
local Tooltip = require("lib.tooltip")
local sys_config = require("lib.sys_config")
local h_window_change_size = hash("window_change_size")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_attempt_pause = hash("attempt_pause")
local h_pause = hash("pause")
local h_tint = hash("tint")
local h_scale = hash("scale")
local h_pause_button_acquire_input_focus = hash("pause_button_acquire_input_focus")
local h_switch_input_method = hash("switch_input_method")

local function get_button_bounding_box(button)
	return Tooltip.get_sprite_bounding_box(button.node)
end

local is_mobile = sys_config.is_mobile

function _env:init()
	if not is_mobile then
		go.delete(msg.url(), true)

		return
	end

	local pause_label = msg.url("#label")
	self.button = Button.new(pause_label, {
		is_sprite = true,
		padding_top = 30,
		padding_right = 50,
		faded_nodes = {},
		faded_labels = {
			pause_label
		},
		on_state_change = Tooltip.button_on_state_change({
			id = h_pause,
			type = h_pause,
			get_button_bounding_box = get_button_bounding_box
		}, button_sound.with_sound()),
		action = function ()
			dispatcher.dispatch(h_attempt_pause)
		end
	})

	label.set_text(pause_label, intl("level.pause"))

	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(self.button.node, {
		grav_y = 1,
		grav_x = 1
	})

	self.sub_id = dispatcher.subscribe({
		h_window_change_size,
		h_pause_button_acquire_input_focus,
		h_switch_input_method
	})
	self.this_go = msg.url(".")

	if self.has_background then
		local sprite_url = msg.url("#sprite")

		sprite.set_constant(sprite_url, h_tint, vmath.vector4(0, 0, 0, 1))
		go.set(sprite_url, h_scale, vmath.vector3(1.2))
	end

	if self.should_acquire_focus then
		msg.post(self.this_go, h_pause_button_acquire_input_focus)
	end
end

function _env:final()
	if self.sub_id then
		dispatcher.unsubscribe(self.sub_id)
	end
end

function _env:on_input(action_id, action)
	if self.button:on_input(action_id, action) then
		return true
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_pause_button_acquire_input_focus then
		msg.post(self.this_go, h_acquire_input_focus)
	elseif message_id == h_switch_input_method then
		self.button:switch_input_method()
	end
end
