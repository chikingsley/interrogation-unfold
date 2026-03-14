local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local Layout = require("crit.layout")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local sound_util = require("sound.util")
local intl = require("crit.intl")
local Tooltip = require("lib.tooltip")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_virtual_cursor_action = hash("virtual_cursor_action")
local h_jigsaw_solved = hash("jigsaw_solved")
local h_end_scene = hash("end_scene")
local h_sprite = hash("sprite")
local h_label = hash("label")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_jigsaw_continue = hash("jigsaw_continue")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	local button_cm_press = fmod and fmod.studio.system:get_event("event:/Campaign/Button CM Press")
	local door_briefing = fmod and fmod.studio.system:get_event("event:/Campaign/Door Briefing")
	local this_go = msg.url(".")
	local this_go_sprite = msg.url(this_go.socket, this_go.path, h_sprite)
	local this_go_label = msg.url(this_go.socket, this_go.path, h_label)

	intl.translate_label(this_go_label, "common.continue")

	self.key_prompt = KeyPrompt.new(msg.url("prompt_y#prompt"), {
		is_sprite = true,
		halo = msg.url("prompt_y#prompt_halo"),
		action_id = h_gamepad_rpad_up
	})
	self.nav_button = Button.new(this_go_sprite, {
		is_sprite = true,
		faded_labels = {
			this_go_label
		},
		shortcut_actions = {
			h_gamepad_rpad_up
		},
		on_state_change = button_sound.with_sound({
			press = button_cm_press,
			release = door_briefing
		}),
		action = function ()
			dispatcher.dispatch(h_end_scene)
		end
	})
	self.tooltip_button = Button.new(this_go_sprite, {
		is_sprite = true,
		hover_from_external_touch = true,
		faded_nodes = {},
		on_state_change = Tooltip.button_on_state_change({
			id = "jigsaw_continue",
			type = h_jigsaw_continue,
			payload = {}
		})
	})

	self.nav_button:set_enabled(false)
	self.key_prompt:set_enabled(false)

	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(this_go, {
		grav_y = 0.5,
		grav_x = 0.5
	})

	self.this_go = msg.url(".")
	self.sub_id = dispatcher.subscribe({
		h_jigsaw_solved,
		h_window_change_size,
		h_switch_input_method,
		h_virtual_cursor_action
	})

	if not self.enabled then
		go.delete(".", true)
	end

	msg.post(".", "acquire_input_focus")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
end

local script_on_input = nil

function _env:on_message(message_id, message, sender)
	if message_id == h_virtual_cursor_action then
		script_on_input(self, message.action_id, message.action)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
		self.nav_button:switch_input_method()
	elseif message_id == h_jigsaw_solved then
		self.tooltip_button:set_enabled(false)
		self.key_prompt:set_enabled(true)
		self.nav_button:set_enabled(true)
	end
end

function script_on_input(self, action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.tooltip_button:on_input(action_id, action) then
		return true
	end

	if self.nav_button:on_input(action_id, action) then
		return true
	end
end

on_input = script_on_input
