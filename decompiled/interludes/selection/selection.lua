local Button = require("crit.button")
local KeyPrompt = require("lib.key_prompt")
local LongPress = require("lib.long_press")
local FocusGiver = require("crit.focus_giver")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local sound_util = require("sound.util")
local Tooltip = require("lib.tooltip")
local selection_state = require("interludes.selection.state")
local intl = require("crit.intl")
intl = intl.namespace("chapter3")
local h_switch_input_method = hash("switch_input_method")
local h_outer_glow = hash("outer_glow")
local h_scale = hash("scale")
local h_position = hash("position")
local h_rotation = hash("rotation")
local h_tint = hash("tint")
local h_tintw = hash("tint.w")
local h_colorw = hash("color.w")
local h_selection_dismiss = hash("selection_dismiss")
local h_selection_finished = hash("selection_finished")
local h_selection_item = hash("selection_item")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_disable = hash("disable")
local hover_duration = 0.2
local zoom_duration = 0.2
local zero4 = vmath.vector4(0)
local one3 = vmath.vector3(1)
local one4 = vmath.vector4(1)
local deselected_tint = vmath.vector4(0.5, 0.5, 0.5, 1)
local selected_scale = vmath.vector3(1.2, 1.2, 1)
local deal_position_base = vmath.vector3(-1200, -300, 0.7)
local deal_rotation = vmath.quat_rotation_z(20 * math.pi / 180)
local deal_stagger = 0.3
local deal_duration = 0.7
local undeal_duration = 0.5
local forward = go.PLAYBACK_ONCE_FORWARD
local handle_item_state_change, handle_item_action, update_confirm_button = nil

local function first_enabled_index(index, step)
	local next_index = index

	while true do
		if next_index <= 0 or next_index > #selection_state.options then
			return
		end

		if selection_state.required_item_count ~= selection_state.selected_item_count or selection_state.selections[next_index] then
			return next_index
		end

		next_index = next_index + step
	end
end

function _env:init()
	selection_state.reset()

	self.bank = sound_util.load_bank("All Campaign.bank")
	self.event_polaroids = fmod and fmod.studio.system:get_event("event:/Campaign/Polaroids")
	self.event_perk_chosen = fmod and fmod.studio.system:get_event("event:/Campaign/Perk Cue")

	if selection_state.title then
		self.title_label = msg.url("title#label")

		label.set_text(self.title_label, selection_state.title)
	end

	local items = {}
	self.items = items

	for index, option in ipairs(selection_state.options) do
		local root_url = msg.url("item" .. index .. "/root")
		local polaroid_sprite_url = msg.url("item" .. index .. "/polaroid#sprite")
		local faded_nodes = {
			polaroid_sprite_url,
			msg.url("item" .. index .. "/suspect#sprite")
		}

		sprite.play_flipbook("item" .. index .. "/suspect#sprite", option.image)
		label.set_text("item" .. index .. "/polaroid#label", option.label)

		local button = Button.new(polaroid_sprite_url, {
			is_sprite = true,
			keyboard_focus = true,
			focus_simulates_hover = true,
			gamepad_focus = true,
			keep_hover = true,
			on_state_change = button_sound.with_sound({
				release = false,
				press = false
			}, Tooltip.button_on_state_change({
				id = "selection_item" .. index,
				type = h_selection_item,
				position = Tooltip.POSITION_BOTTOM,
				payload = {
					index = index
				}
			}, handle_item_state_change)),
			action = function ()
				handle_item_action(self, index)
			end,
			on_pass_focus = function (button, nav_action)
				if not nav_action or nav_action == Button.NAVIGATE_RIGHT then
					local next_index = first_enabled_index(index + 1, 1)

					if next_index then
						return items[next_index].button:focus()
					end
				elseif nav_action == Button.NAVIGATE_LEFT then
					local next_index = first_enabled_index(index - 1, -1)

					if next_index then
						return items[next_index].button:focus()
					end
				elseif nav_action == Button.NAVIGATE_DOWN then
					return self.confirm_button:focus()
				end
			end
		})
		local position_stagger = vmath.vector3(0, 0, 0.02 * (index - 1))
		local position = go.get_position(root_url) + position_stagger
		local rotation = go.get_rotation(root_url)
		local deal_position = deal_position_base + position_stagger

		go.set_position(deal_position, root_url)
		go.set_rotation(deal_rotation, root_url)

		local item = {
			button = button,
			root_url = root_url,
			faded_nodes = faded_nodes,
			position = position,
			rotation = rotation
		}
		items[index] = item
	end

	local item_count = #items
	local button_sprite = msg.url("confirm#sprite")
	local button_label = msg.url("confirm#label")
	local button_glow = msg.url("confirm#glow")
	local prompt_y = msg.url("confirm_prompt#prompt")
	self.confirm_button_label = button_label
	self.confirm_button = Button.new(button_sprite, {
		keyboard_focus = true,
		gamepad_focus = true,
		is_sprite = true,
		faded_labels = {
			button_label
		},
		shortcut_actions = {
			h_gamepad_rpad_up
		},
		focus_node = button_glow,
		on_focus_change = button_sound.with_focus_sound(),
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		action = function ()
			dispatcher.dispatch(h_selection_finished, {
				selections = selection_state.selections
			})
		end,
		on_pass_focus = function (button, nav_action)
			if not nav_action or nav_action == Button.NAVIGATE_UP then
				local next_index = first_enabled_index(1, 1)

				if next_index then
					return items[next_index].button:focus()
				end
			end
		end
	})
	self.confirm_key_prompt = KeyPrompt.new(prompt_y, {
		is_sprite = true,
		fade_duration = 0.2
	})
	self.confirm_long_press = LongPress.new(prompt_y, {
		is_sprite = true,
		gamepad_action_id = h_gamepad_rpad_up,
		button = self.confirm_button
	})

	update_confirm_button(self)

	if not self.confirm_key_prompt.enabled then
		msg.post(prompt_y, h_disable)
	end

	go.cancel_animations(button_sprite, h_tintw)
	go.cancel_animations(button_label, h_colorw)
	go.set(button_sprite, h_tintw, 0)
	go.set(button_label, h_colorw, 0)
	timer.delay(0, false, function ()
		for index = 1, item_count do
			local delay = (index - 1) * deal_stagger
			local item = items[index]
			local root_url = item.root_url
			local position = item.position
			local rotation = item.rotation

			go.animate(root_url, h_position, forward, position, go.EASING_OUTEXPO, deal_duration, delay)
			go.animate(root_url, h_rotation, forward, rotation, go.EASING_OUTEXPO, deal_duration, delay)
			timer.delay(delay, false, function ()
				if self.event_polaroids then
					local instance = self.event_polaroids:create_instance()

					instance:set_parameter_by_name("IsPickedUp", 1, false)
					instance:start()
				end
			end)
		end

		local delay = deal_stagger * item_count

		go.animate(button_sprite, h_tintw, forward, 1, go.EASING_LINEAR, deal_duration, delay)
		go.animate(button_label, h_colorw, forward, 1, go.EASING_LINEAR, deal_duration, delay)
	end)

	self.focus_giver = FocusGiver.new({
		on_pass_focus = function (focus_giver, nav_action)
			if not nav_action or nav_action == Button.NAVIGATE_RIGHT then
				local next_index = first_enabled_index(1, 1)

				if next_index then
					return items[next_index].button:focus()
				end
			elseif nav_action == Button.NAVIGATE_LEFT then
				local next_index = first_enabled_index(item_count, -1)

				if next_index then
					return items[next_index].button:focus()
				end
			end
		end
	})

	self.focus_giver:try_focus_first()
	msg.post(".", "acquire_input_focus")

	self.sub_id = dispatcher.subscribe({
		h_switch_input_method,
		h_selection_dismiss
	})
end

function _env:final()
	sound_util.release_bank(self.bank)
	dispatcher.unsubscribe(self.sub_id)
end

function handle_item_state_change(button, state)
	local sprite_url = button.node
	local hover_or_pressed = state == Button.STATE_HOVER or state == Button.STATE_PRESSED
	local outer_glow = hover_or_pressed and one4 or zero4

	go.cancel_animations(sprite_url, h_outer_glow)
	go.animate(sprite_url, h_outer_glow, forward, outer_glow, go.EASING_INOUTSINE, hover_duration)
end

function update_confirm_button(self)
	local selected_item_count = selection_state.selected_item_count
	local required_item_count = selection_state.required_item_count
	local is_ready = selected_item_count == required_item_count
	local label_text = is_ready and (selection_state.confirm_label or intl("character_selection.confirm")) or selection_state.select_more_label or intl("character_selection.select_more", {
		count = required_item_count - selected_item_count
	})

	label.set_text(self.confirm_button_label, label_text)
	self.confirm_button:set_enabled(is_ready)
	self.confirm_key_prompt:set_enabled(is_ready)
	self.confirm_long_press:set_enabled(is_ready)
end

function handle_item_action(self, index)
	local selected = not selection_state.selections[index]
	local selected_item_count = selection_state.selected_item_count
	local required_item_count = selection_state.required_item_count

	if selected then
		selected_item_count = selected_item_count + 1
	else
		selected_item_count = selected_item_count - 1
	end

	if required_item_count < selected_item_count then
		return
	end

	selection_state.selected_item_count = selected_item_count
	selection_state.selections[index] = selected

	if selected and self.event_perk_chosen then
		self.event_perk_chosen:create_instance():start()
	end

	local items = self.items
	local item_count = #items
	local root_url = items[index].root_url
	local scale = selected and selected_scale or one3

	go.cancel_animations(root_url, h_scale)
	go.animate(root_url, h_scale, forward, scale, go.EASING_INOUTSINE, zoom_duration)

	local is_ready = selected_item_count == required_item_count

	for item_index = 1, item_count do
		local enabled = not is_ready or selection_state.selections[item_index]
		local tint = enabled and one4 or deselected_tint
		local faded_nodes = items[item_index].faded_nodes

		items[item_index].button:set_enabled(enabled)

		for i, node in ipairs(faded_nodes) do
			go.cancel_animations(node, h_tint)
			go.animate(node, h_tint, forward, tint, go.EASING_INOUTSINE, zoom_duration)
		end
	end

	update_confirm_button(self)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		for i, item in pairs(self.items) do
			item.button:switch_input_method()
		end

		self.confirm_key_prompt:switch_input_method()
		self.confirm_button:switch_input_method()
		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_selection_dismiss then
		self.confirm_button:set_enabled(false)
		self.confirm_key_prompt:set_enabled(false)
		self.confirm_long_press:set_enabled(false)

		local button_sprite = self.confirm_button.node
		local button_label = self.confirm_button.faded_labels[1]

		go.animate(button_sprite, h_tintw, forward, 0, go.EASING_LINEAR, undeal_duration)
		go.animate(button_label, h_colorw, forward, 0, go.EASING_LINEAR, undeal_duration)

		if self.title_label then
			go.animate(self.title_label, h_colorw, forward, 0, go.EASING_LINEAR, undeal_duration)
		end

		local items = self.items
		local item_count = #items

		for index = 1, item_count do
			local root_url = items[index].root_url

			go.cancel_animations(root_url, h_rotation)
			go.cancel_animations(root_url, h_position)

			local position_stagger = vmath.vector3(0, 0, 0.02 * (index - 1))
			local deal_position = deal_position_base + position_stagger
			local delay = (index - 1) * deal_stagger

			go.animate(root_url, h_position, forward, deal_position, go.EASING_INEXPO, undeal_duration, delay)
			go.animate(root_url, h_rotation, forward, deal_rotation, go.EASING_INEXPO, undeal_duration, delay)
			timer.delay(delay + 0.15, false, function ()
				if self.event_polaroids then
					local instance = self.event_polaroids:create_instance()

					instance:set_parameter_by_name("IsPickedUp", 0, false)
					instance:start()
				end
			end)
		end

		timer.delay((item_count - 1) * deal_stagger + undeal_duration, false, function ()
			for index = 1, item_count do
				local root_url = items[index].root_url

				go.delete(root_url, true)
			end

			go.delete(self.confirm_button.node, true)
			go.delete(".", true)
		end)
	end
end

function _env:on_input(action_id, action)
	for i, item in ipairs(self.items) do
		if item.button:on_input(action_id, action) then
			return true
		end
	end

	self.confirm_key_prompt:on_input(action_id, action)

	if self.confirm_long_press:on_input(action_id, action) then
		return true
	end

	if self.confirm_button:on_input(action_id, action) then
		return true
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end
end

function _env:update()
	self.confirm_long_press:update()
end
