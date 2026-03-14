local budget = require("campaign.budget")
local missions = require("campaign.missions")
local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local Layout = require("crit.layout")
local button_sound = require("sound.button")
local sound_util = require("sound.util")
local KeyPrompt = require("lib.key_prompt")
local LongPress = require("lib.long_press")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_budget_update = hash("budget_update")
local h_campaign_save = hash("campaign_save")
local h_campaign_back = hash("campaign_back")
local h_save_prompt_enable = hash("save_prompt_enable")
local h_save_prompt_disable = hash("save_prompt_disable")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_gamepad_rpad_left = hash("gamepad_rpad_left")
local h_end_scene = hash("end_scene")
local h_load_scene = hash("load_scene")
local h_zoom = hash("zoom")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	local button_cm_press = fmod and fmod.studio.system:get_event("event:/Campaign/Button CM Press")
	local button_cm_release = fmod and fmod.studio.system:get_event("event:/Campaign/Button CM Release")
	local door_office = fmod and fmod.studio.system:get_event("event:/Campaign/Door Office")
	self.sub_id = dispatcher.subscribe({
		h_campaign_save,
		h_campaign_back,
		h_budget_update,
		h_window_change_size,
		h_save_prompt_enable,
		h_save_prompt_disable,
		h_switch_input_method
	})
	local save_button_label = gui.get_node("button_save_text")
	local prev_button_label = gui.get_node("button_prev_text")

	intl.translate_text_node(save_button_label)
	intl.translate_text_node(prev_button_label)

	local save_button_node = gui.get_node("button_save")
	local save_button_prompt_y = gui.get_node("prompt_y")
	self.save_key_prompt = KeyPrompt.new(save_button_prompt_y, {
		is_long_press = true,
		halo = gui.get_node("prompt_y_halo"),
		action_id = h_gamepad_rpad_up
	})

	self.save_key_prompt:set_enabled(true)

	self.save_button = Button.new(save_button_node, {
		faded_nodes = {
			save_button_node,
			save_button_label
		},
		on_state_change = button_sound.with_sound({
			press = button_cm_press,
			release = button_cm_release
		}, Button.darken_on_state_change),
		action = function ()
			dispatcher.dispatch(h_campaign_save)
		end
	})
	self.save_long_press = LongPress.new(save_button_prompt_y, {
		is_key_prompt = true,
		gamepad_action_id = h_gamepad_rpad_up,
		button = self.save_button
	})
	local prev_button_node = gui.get_node("button_prev")
	local prev_button_prompt_x = gui.get_node("prompt_x")
	self.prev_key_prompt = KeyPrompt.new(prev_button_prompt_x, {
		halo = gui.get_node("prompt_x_halo"),
		action_id = h_gamepad_rpad_left
	})

	self.prev_key_prompt:set_enabled(true)

	self.prev_button = Button.new(prev_button_node, {
		faded_nodes = {
			prev_button_node,
			prev_button_label
		},
		shortcut_actions = {
			h_gamepad_rpad_left
		},
		on_state_change = button_sound.with_sound({
			press = button_cm_press,
			release = door_office
		}, Button.darken_on_state_change),
		action = function ()
			dispatcher.dispatch(h_campaign_back)
		end
	})
	self.save_tooltip_button = Button.new(self.save_button.node, {
		hover_from_external_touch = true,
		faded_nodes = {},
		on_state_change = Tooltip.button_on_state_change({
			id = "save",
			type = h_campaign_save
		}, false)
	})
	self.layout = Layout.new()

	self.layout:add_node(self.save_button.node, {
		grav_y = 0.5,
		grav_x = 0.5
	})
	self.layout:add_node(self.prev_button.node, {
		grav_y = 0.5,
		grav_x = 0.5
	})
	msg.post(".", "acquire_input_focus")
	msg.post(".", h_budget_update)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_campaign_save then
		local budget_set = budget.are_options_set()
		local missions_set = missions.are_assignments_set()
		local unmet_dependencies = false
		local unmet_dependencies_fatal = false

		for _, option in ipairs(budget.options) do
			if budget.is_selected(option.id) and option.depends_on_mission and not missions.assigned_character[option.depends_on_mission] then
				unmet_dependencies = option.depends_on_mission

				if option.hard_dependency then
					unmet_dependencies_fatal = true
				end
			end
		end

		local ends_scene = budget_set and missions_set and not unmet_dependencies

		self.save_long_press:set_auto_reset(not ends_scene)

		if ends_scene then
			dispatcher.dispatch(h_end_scene)
		else
			self.save_tooltip_button:cancel_touch()
			dispatcher.dispatch(h_save_prompt_enable, {
				budget_set = budget_set,
				missions_set = missions_set,
				unmet_dependencies = unmet_dependencies,
				fatal = unmet_dependencies_fatal
			})
		end
	elseif message_id == h_campaign_back then
		dispatcher.dispatch(h_load_scene, {
			scene = "office",
			transition_options = {
				transition = h_zoom
			},
			options = {
				no_expo = true
			}
		})
	elseif message_id == h_budget_update then
		local budget_value = message.budget or budget.capacity - budget.get_total_cost()

		if budget_value < 0 then
			self.save_button:set_enabled(false)
			self.save_long_press:set_enabled(false)
			self.save_key_prompt:set_enabled(false)
		else
			self.save_button:set_enabled(true)
			self.save_long_press:set_enabled(true)
			self.save_key_prompt:set_enabled(true)
		end
	elseif message_id == h_save_prompt_enable then
		self.save_key_prompt:set_enabled(false)
		self.prev_key_prompt:set_enabled(false)
	elseif message_id == h_save_prompt_disable then
		self.save_key_prompt:set_enabled(true)
		self.prev_key_prompt:set_enabled(true)
		self.save_long_press:reset(true)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.save_key_prompt:switch_input_method()
		self.prev_key_prompt:switch_input_method()
	end
end

function _env:on_input(action_id, action)
	self.save_key_prompt:on_input(action_id, action)
	self.prev_key_prompt:on_input(action_id, action)

	if self.save_long_press:on_input(action_id, action) then
		return false
	end

	if self.save_tooltip_button:on_input(action_id, action) then
		return true
	end

	if self.save_button:on_input(action_id, action) then
		return true
	end

	if self.prev_button:on_input(action_id, action) then
		return true
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
	msg.post(".", "release_input_focus")
end
