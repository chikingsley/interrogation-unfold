local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local Layout = require("crit.layout")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local LongPress = require("lib.long_press")
local sound_util = require("sound.util")
local intl = require("crit.intl")
local env = require("lib.environment")
local office = require("campaign.office")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_load_scene = hash("load_scene")
local h_end_scene = hash("end_scene")
local h_office_navigation_disable = hash("office_navigation_disable")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_sprite = hash("sprite")
local h_label = hash("label")
local h_zoom = hash("zoom")
local h_virtual_cursor_action = hash("virtual_cursor_action")
local h_office = hash("office")
local h_briefing_room = hash("briefing_room")
local h_wall = hash("wall")
local h_continue = hash("continue")
local scenes = {
	[h_office] = "office",
	[h_briefing_room] = "briefing_room",
	[h_wall] = "wall"
}
local intl_labels = {
	[h_office] = "briefing_room.to_office",
	[h_briefing_room] = "office.to_briefing_room",
	[h_wall] = "office.to_wall",
	[h_continue] = "common.continue"
}

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	local button_cm_press = fmod and fmod.studio.system:get_event("event:/Campaign/Button CM Press")
	local door_briefing = fmod and fmod.studio.system:get_event("event:/Campaign/Door Briefing")
	local this_go = msg.url(".")
	local this_go_sprite = msg.url(this_go.socket, this_go.path, h_sprite)
	local this_go_label = msg.url(this_go.socket, this_go.path, h_label)

	intl.translate_label(this_go_label, intl_labels[self.scene])

	local prompt_url = self.prompt_url
	local prompt_component = msg.url(prompt_url.socket, prompt_url.path, "prompt")
	self.key_prompt = KeyPrompt.new(prompt_component, {
		is_sprite = true,
		halo = msg.url(prompt_url.socket, prompt_url.path, "prompt_halo"),
		action_id = self.gamepad_shortcut
	})
	self.nav_button = Button.new(this_go_sprite, {
		is_sprite = true,
		faded_labels = {
			this_go_label
		},
		shortcut_actions = {
			self.gamepad_shortcut
		},
		on_state_change = button_sound.with_sound({
			press = button_cm_press,
			release = door_briefing
		}, Button.darken_on_state_change),
		action = function ()
			local scene = scenes[self.scene]

			if not scene then
				dispatcher.dispatch(h_end_scene)
			else
				dispatcher.dispatch(h_load_scene, {
					scene = scenes[self.scene],
					transition_options = {
						transition = h_zoom
					},
					options = {
						no_expo = true
					}
				})
			end
		end
	})

	if self.requires_long_press then
		self.long_press = LongPress.new(prompt_component, {
			is_sprite = true,
			gamepad_action_id = self.gamepad_shortcut,
			button = self.nav_button
		})
	end

	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(this_go, {
		grav_y = 0,
		grav_x = 0.5
	})

	self.has_focus = true
	self.this_go = msg.url(".")
	self.sub_id = dispatcher.subscribe({
		h_office_navigation_disable,
		h_office_object_select,
		h_office_object_deselect,
		h_window_change_size,
		h_switch_input_method,
		h_virtual_cursor_action
	})

	if self.acquire_input_focus then
		timer.delay(0, false, function ()
			msg.post(".", "acquire_input_focus")
		end)
	end

	if not self.enabled or self.scene == h_wall and not env.show_wall and not office.wall or self.scene == h_briefing_room and not office.has_briefing_room or self.scene == h_continue and office.has_briefing_room then
		go.delete(".", true)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
end

function _env:update(dt)
	if self.long_press then
		self.long_press:update()
	end
end

local function on_input_handler(self, action_id, action)
	if not self.has_focus then
		return
	end

	self.key_prompt:on_input(action_id, action)

	if self.long_press and self.long_press:on_input(action_id, action) then
		return false
	end

	if self.nav_button:on_input(action_id, action) then
		return true
	end
end

on_input = on_input_handler

function _env:on_message(message_id, message, sender)
	if message_id == h_virtual_cursor_action then
		on_input_handler(self, message.action_id, message.action)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_office_navigation_disable then
		go.delete(".", true)
	elseif message_id == h_office_object_select then
		self.key_prompt:set_enabled(false)

		self.has_focus = false
	elseif message_id == h_office_object_deselect then
		self.key_prompt:set_enabled(true)

		self.has_focus = true
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
		self.nav_button:switch_input_method()
	end
end
