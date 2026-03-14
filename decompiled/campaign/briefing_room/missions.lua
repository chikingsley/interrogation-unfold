local missions = require("campaign.missions")
local agents = require("campaign.agents")
local custom_pick = require("campaign.custom_pick")
local DragAndDrop = require("crit.drag_and_drop")
local Tooltip = require("lib.tooltip")
local Button = require("crit.button")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local variables = require("campaign.variables")
local focus_distance = require("lib.focus_distance")
local table_util = require("crit.table_util")
local input_state = require("crit.input_state")
local office = require("campaign.office")
local h_position = hash("position")
local h_positionx = hash("position.x")
local h_positiony = hash("position.y")
local h_rotation = hash("rotation")
local h_sprite = hash("sprite")
local h_label = hash("label")
local h_label_bg = hash("label_bg")
local h_tint = hash("tint")
local h_tintw = hash("tint.w")
local h_colorw = hash("color.w")
local h_outlinew = hash("outline.w")
local h_scalex = hash("scale.x")
local h_mission = hash("mission")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_scale = hash("scale")
local h_play_sfx = hash("play_sfx")
local h_missions_gain_focus = hash("missions_gain_focus")
local h_budget_gain_focus = hash("budget_gain_focus")
local h_switch_input_method = hash("switch_input_method")
local h_budget_set_focus_enabled = hash("budget_set_focus_enabled")
local h_key_escape = hash("key_escape")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_outer_glow = hash("outer_glow")
local h_shadow = hash("shadow")
local h_save_prompt_enable = hash("save_prompt_enable")
local board_left = -183
local board_right = 855
local board_bottom = -390
local board_top = 420
local board_width = board_right - board_left
local board_height = board_top - board_bottom
local snap_transition_duration = 0.3
local mission_snap_offset = 120
local connector_tint = vmath.vector4(0.6, 0.1, 0, 1)
local connector_label_bg_tint = vmath.vector4(0.9)
local connector_label_show_distance = 220
local connector_default_scale_x = 0.6
local connector_condensed_scale_x = 0.5
local outer_glow_disabled = vmath.vector4(0, 0, 0, 0)
local outer_glow_white = vmath.vector4(1, 1, 1, 1)
local shadow_disabled = vmath.vector4(0)
local shadow_black = vmath.vector4(0, 0, 0, 0.7)
local agent_polaroid_hitbox_padding = {
	top = -14,
	bottom = -17,
	left = -16,
	right = -13
}
local get_transform, snap_to_slots, can_drag, slight_rotation, set_success_rate, custom_dnd_pick, reset_targets_padding, snap_go_to_transform, first_unassigned_index, get_connector_metrics, create_connector, animate_connector, animate_connectors, ensure_agent_connectors, ensure_mission_connectors, update_connectors, hide_agent_connectors, hide_mission_connectors = nil
local mouse_relative_mission_padding = {
	top = 0,
	bottom = 0,
	left = 0,
	right = 0
}

local function hr_perk_active()
	return not not variables.has_hr_report
end

local function all_agents()
	return coroutine.wrap(function ()
		for i, char in ipairs(agents) do
			coroutine.yield(i, char, agents[char].present and not office.unavailable_agents[char])
		end
	end)
end

local function all_present_agents()
	return coroutine.wrap(function ()
		local index = 0

		for i, char in ipairs(agents) do
			if agents[char].present and not office.unavailable_agents[char] then
				index = index + 1

				coroutine.yield(index, char)
			end
		end
	end)
end

local function agent_on_state_change(self, button, state)
	local default_scale = 1
	local hovered_scale = 1.05
	local pressed_scale = 1.15
	local scale_factor = default_scale
	local is_dragging = state == Button.STATE_PRESSED or self.dnd:is_dragging() and button.focused
	local is_hovering = button.focused or state == Button.STATE_HOVER

	if is_dragging then
		scale_factor = pressed_scale
	elseif is_hovering then
		scale_factor = hovered_scale
	elseif state == Button.STATE_DISABLED then
		scale_factor = default_scale
	end

	local shows_connectors = is_dragging or is_hovering

	if shows_connectors then
		ensure_agent_connectors(self, button.character)
		animate_connectors(self, true)
		update_connectors(self)
	else
		hide_agent_connectors(self, button.character)
	end

	local go_id = button.go_id

	if is_dragging ~= not not button.is_dragging then
		button.is_dragging = is_dragging
		local pos = go.get_position(go_id)
		local diff = is_dragging and 0.5 or -0.5

		go.set_position(vmath.vector3(pos.x, pos.y, pos.z + diff), go_id)
	end

	scale_factor = scale_factor * button.initial_scale
	local outer_glow = (is_dragging or is_hovering) and outer_glow_white or outer_glow_disabled
	local shadow = (is_dragging or is_hovering) and shadow_disabled or shadow_black
	local sprite_url = button.node

	go.cancel_animations(sprite_url, h_outer_glow)
	go.cancel_animations(sprite_url, h_shadow)
	go.animate(sprite_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_INOUTSINE, 0.2)
	go.animate(sprite_url, h_shadow, go.PLAYBACK_ONCE_FORWARD, shadow, go.EASING_INOUTSINE, 0.2)

	local url = msg.url(go_id)
	local scale = vmath.vector4(1)

	go.cancel_animations(url, h_scale)

	local target_scale = vmath.vector3(scale.x * scale_factor, scale.y * scale_factor, scale.z)

	go.animate(url, h_scale, go.PLAYBACK_ONCE_FORWARD, target_scale, go.EASING_INOUTSINE, 0.2)
end

local function mission_on_state_change(self, button, state)
	local is_dragging = (state == Button.STATE_PRESSED or state == Button.STATE_HOVER) and not self.dnd:is_dragging()
	local shows_connectors = is_dragging

	if shows_connectors then
		ensure_mission_connectors(self, button.mission_id)
		animate_connectors(self, true)
		update_connectors(self)
	else
		hide_mission_connectors(self, button.mission_id)
	end
end

local function source_position_getter(source)
	local position = source.position

	if position then
		return position
	end

	return go.get_position(source.go)
end

local function non_free_source_position_getter(source)
	if source.character and not missions.assigned_mission[source.character] then
		return nil
	end

	return source_position_getter(source)
end

local function on_pass_focus(self, button, nav_action)
	local drag_source = button.drag_source
	local position = source_position_getter(drag_source)

	if self.dnd:is_dragging() then
		if not self.dnd.manually_dragging then
			return false
		end

		local function position_getter(target)
			if not can_drag(drag_source, target) then
				return nil
			end

			return source_position_getter(target)
		end

		local next_target = focus_distance.get_item_in_direction(position, nav_action, self.dnd.drop_targets, position_getter, self.dnd.current_drop_target or self.fallback_drop_target)

		if next_target then
			self.dnd:manual_drag_move(next_target)
		end

		return false
	else
		local position_getter = source_position_getter

		if (nav_action == Button.NAVIGATE_LEFT or nav_action == Button.NAVIGATE_RIGHT) and not missions.assigned_mission[drag_source.character] then
			position_getter = non_free_source_position_getter
		end

		local next_source = focus_distance.get_item_in_direction(position, nav_action, self.focus_sources, position_getter, drag_source)

		if not next_source then
			return false
		end

		if next_source.dummy then
			return false
		end

		if next_source.budget then
			dispatcher.dispatch(h_budget_gain_focus, {
				position = position,
				nav_action = nav_action
			})

			return true
		end

		return next_source.button:focus()
	end
end

local function mission_tooltip_payload(self, mission_id, sprite_url)
	local dragged_source = self.dnd.current_drag_source
	local char_bounding_boxes = nil

	if not dragged_source then
		char_bounding_boxes = {}

		for char, go_id in pairs(self.character_gos) do
			local go_url = msg.url(go_id)
			local char_sprite_url = msg.url(go_url.socket, go_url.path, h_sprite)
			char_bounding_boxes[char] = Tooltip.get_sprite_bounding_box(char_sprite_url)
		end
	end

	sprite_url = sprite_url or msg.url(nil, self.mission_gos[mission_id], h_sprite)

	return {
		mission_id = mission_id,
		dragged_character = dragged_source and dragged_source.character,
		char_bounding_boxes = char_bounding_boxes,
		mission_bounding_box = Tooltip.get_sprite_bounding_box(sprite_url),
		hr_perk_active = hr_perk_active()
	}
end

local function force_mission_tooltip(self, mission_id)
	local current_tooltip_mission_id = self.current_tooltip_mission_id

	if current_tooltip_mission_id then
		dispatcher.dispatch(h_tooltip_hide, {
			id = "mission_" .. current_tooltip_mission_id,
			type = h_mission
		})
	end

	self.current_tooltip_mission_id = mission_id

	if mission_id then
		dispatcher.dispatch(h_tooltip_show, {
			id = "mission_" .. mission_id,
			type = h_mission,
			payload = mission_tooltip_payload(self, mission_id)
		})
	end
end

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_missions_gain_focus,
		h_switch_input_method,
		h_save_prompt_enable
	})
	local character_connectors = {}
	local mission_connectors = {}
	self.connector_factory = msg.url("#connector_factory")
	self.character_connectors = character_connectors
	self.mission_connectors = mission_connectors
	self.active_connectors = {}
	local free_area_slots = {}
	local character_gos = {}
	self.free_area_slots = free_area_slots
	self.character_gos = character_gos
	self.agent_buttons = {}
	self.hover_polaroid_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Polaroid")
	self.hover_paper_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Paper")

	for i, character, is_present in all_agents() do
		local id = go.get_id(character)
		free_area_slots[i] = get_transform(id)

		if is_present then
			character_gos[character] = id
			character_connectors[character] = create_connector(self)
			local url = msg.url(id)
			local sprite_url = msg.url(url.socket, url.path, h_sprite)

			go.set(sprite_url, h_shadow, shadow_black)
			go.set(sprite_url, h_outer_glow, outer_glow_disabled)

			self.agent_buttons[character] = Button.new(sprite_url, {
				focus_simulates_hover = true,
				gamepad_focus = true,
				is_sprite = true,
				keyboard_focus = true,
				go_id = id,
				character = character,
				initial_scale = go.get_scale(url).x,
				padding = agent_polaroid_hitbox_padding,
				on_pass_focus = function (button, nav_action)
					return on_pass_focus(self, button, nav_action)
				end,
				on_state_change = button_sound.with_sound({
					press = false,
					release = false,
					hover = self.hover_polaroid_event
				}, function (button, state)
					agent_on_state_change(self, button, state)
				end),
				action = function (button, click)
					if click then
						return
					end

					local dnd = self.dnd

					if dnd:is_dragging() then
						if dnd.current_drop_target then
							dnd:manual_drag_commit()
						else
							dnd:drag_cancel()
						end
					else
						dnd:manual_drag_start(button.drag_source)

						local current_mission = missions.assigned_mission[button.drag_source.character]

						if current_mission then
							local current_target = table_util.find(dnd.drop_targets, function (target)
								return target.mission and target.mission.id == current_mission
							end)

							dnd:manual_drag_move(current_target)
						end
					end
				end
			})
		else
			go.delete(id, true)
		end
	end

	local mission_factory = msg.url("#mission_factory")
	local mission_slots = {}
	local mission_gos = {}
	local mission_buttons = {}
	self.mission_slots = mission_slots
	self.mission_gos = mission_gos
	self.mission_buttons = mission_buttons

	for i, character in all_agents() do
		local mission_id = missions.assigned_mission[character]

		if mission_id and (missions.assigned_character[mission_id] ~= character or not missions.get_option(mission_id)) then
			missions.assign(character, nil)
		end
	end

	for i, mission in ipairs(missions.options) do
		local character = missions.assigned_character[mission.id]

		if character and (not character_gos[character] or missions.assigned_mission[character] ~= mission.id) then
			missions.assign(nil, mission.id)
		end
	end

	for i, mission in ipairs(missions.options) do
		local transform = {
			position = vmath.vector3(board_left + mission.position.x * board_width, board_bottom + mission.position.y * board_height - mission_snap_offset, 0),
			rotation = slight_rotation()
		}
		mission_slots[mission.id] = transform
		local mission_go = factory.create(mission_factory, transform.position + vmath.vector3(0, mission_snap_offset, -0.2), slight_rotation())
		mission_gos[mission.id] = mission_go
		mission_connectors[mission.id] = create_connector(self)
		local mission_url = msg.url(mission_go)
		local label_url = msg.url(mission_url.socket, mission_url.path, h_label)

		label.set_text(label_url, missions.translate_option_text(mission, "title"))

		local sprite_url = msg.url(mission_url.socket, mission_url.path, h_sprite)
		mission_buttons[mission.id] = Button.new(sprite_url, {
			is_sprite = true,
			hover_from_external_touch = true,
			mission_id = mission.id,
			on_state_change = button_sound.with_sound({
				press = false,
				release = false,
				hover = self.hover_paper_event
			}, Tooltip.button_on_state_change({
				id = "mission_" .. mission.id,
				type = h_mission,
				payload = function ()
					return mission_tooltip_payload(self, mission.id, sprite_url)
				end
			}, function (button, state)
				mission_on_state_change(self, button, state)
			end))
		})
	end

	for id, button in pairs(mission_buttons) do
		button.padding = mouse_relative_mission_padding
	end

	self.free_area_char_to_index = {}
	self.free_area_index_to_char = {}

	snap_to_slots(self, true)

	local sources = {}

	for i, character in all_present_agents() do
		local go = msg.url(character_gos[character])
		local sprite = msg.url(go.socket, go.path, h_sprite)
		local button = self.agent_buttons[character]
		local source = {
			character = character,
			go = go,
			sprite = sprite,
			pick = custom_dnd_pick,
			button = button
		}
		button.drag_source = source
		sources[i] = source
	end

	local focus_sources = table_util.clone(sources)

	table.insert(focus_sources, {
		budget = true,
		position = vmath.vector3(-500, 0, 0)
	})
	table.insert(focus_sources, {
		dummy = true,
		position = vmath.vector3(1000, 0, 0)
	})

	self.focus_sources = focus_sources
	local targets = {}

	for i, mission in ipairs(missions.options) do
		local go = msg.url(mission_gos[mission.id])
		local sprite = msg.url(go.socket, go.path, h_sprite)
		targets[i] = {
			mission = mission,
			go = go,
			sprite = sprite,
			padding = mouse_relative_mission_padding
		}
	end

	self.fallback_drop_target = {
		unassign = true,
		position = vmath.vector3(-480, 0, 0),
		pick = function ()
			return true
		end
	}
	targets[#targets + 1] = self.fallback_drop_target
	self.dragged_character = nil
	self.dnd = DragAndDrop.new({
		drag_sources = sources,
		drop_targets = targets,
		can_drag = can_drag,
		on_drag_start = function (drag_source)
			agent_on_state_change(self, drag_source.button, drag_source.button.state)

			if not self.dnd.manually_dragging then
				dispatcher.dispatch(h_budget_set_focus_enabled, {
					enabled = false
				})
			end

			dispatcher.dispatch(h_play_sfx, {
				sfx = "polaroids",
				parameters = {
					IsPickedUp = 1
				}
			})
		end,
		on_drag_move = function (drag_source, dx, dy)
			local go_id = drag_source.go or drag_source.sprite

			if go_id then
				go.set_position(go.get_position(go_id) + vmath.vector3(dx, dy, 0), go_id)
				update_connectors(self)
			end
		end,
		on_manual_drag_move = function (drag_source, drop_target)
			local mission = drop_target.mission

			if mission then
				snap_go_to_transform(self, drag_source.go, self.mission_slots[mission.id])
				force_mission_tooltip(self, mission.id)
			else
				local free_area_index = self.free_area_char_to_index[drag_source.character] or first_unassigned_index(self)

				snap_go_to_transform(self, drag_source.go, self.free_area_slots[free_area_index])
				force_mission_tooltip(self, nil)
			end

			self.keep_updating_connectors = true

			update_connectors(self)
		end,
		on_drag_commit = function (drag_source, drop_target)
			agent_on_state_change(self, drag_source.button, drag_source.button.state)

			local character = drag_source.character
			local mission = drop_target.mission
			local mission_id = mission and mission.id

			missions.assign(character, mission_id)
			snap_to_slots(self)
			reset_targets_padding()
			force_mission_tooltip(self, nil)
			animate_connectors(self, false, true)
			dispatcher.dispatch(h_play_sfx, {
				sfx = "polaroids",
				parameters = {
					IsPickedUp = 0
				}
			})
			dispatcher.dispatch(h_budget_set_focus_enabled, {
				enabled = true
			})
		end,
		on_drag_cancel = function (drag_source)
			agent_on_state_change(self, drag_source.button, drag_source.button.state)
			snap_to_slots(self)
			reset_targets_padding()
			force_mission_tooltip(self, nil)
			animate_connectors(self, false, true)
			dispatcher.dispatch(h_budget_set_focus_enabled, {
				enabled = true
			})
		end
	})

	msg.post(".", "acquire_input_focus")
end

local slight_rotation_spread = 10 * math.pi / 180

function slight_rotation()
	return vmath.quat_rotation_z((math.random() - 0.5) * slight_rotation_spread)
end

function can_drag(drag_source, drop_target)
	local mission = drop_target.mission

	if not mission then
		return true
	end

	local assigned_character = missions.assigned_character[mission.id]

	if assigned_character and assigned_character ~= drag_source.character then
		return false
	end

	local ineligible = mission.ineligible

	return not ineligible or not ineligible[drag_source.character]
end

function get_transform(id)
	return {
		position = go.get_position(id),
		rotation = go.get_rotation(id)
	}
end

function snap_go_to_transform(self, go_id, transform, instant)
	go.cancel_animations(go_id, h_positionx)
	go.cancel_animations(go_id, h_positiony)
	go.cancel_animations(go_id, h_rotation)

	local position = transform.position

	if instant then
		go.set(go_id, h_positionx, position.x)
		go.set(go_id, h_positiony, position.y)
		go.set_rotation(transform.rotation, go_id)
	else
		go.animate(go_id, h_positionx, go.PLAYBACK_ONCE_FORWARD, position.x, go.EASING_OUTEXPO, snap_transition_duration)
		go.animate(go_id, h_positiony, go.PLAYBACK_ONCE_FORWARD, position.y, go.EASING_OUTEXPO, snap_transition_duration)
		go.animate(go_id, h_rotation, go.PLAYBACK_ONCE_FORWARD, transform.rotation, go.EASING_OUTEXPO, snap_transition_duration)
	end
end

function first_unassigned_index(self)
	local free_area_index_to_char = self.free_area_index_to_char
	local index = 1

	while free_area_index_to_char[index] do
		index = index + 1
	end

	return index
end

function snap_to_slots(self, instant)
	local free_area_char_to_index = self.free_area_char_to_index
	local free_area_index_to_char = self.free_area_index_to_char

	for i, character in all_present_agents() do
		local mission_id = missions.assigned_mission[character]

		if mission_id and missions.assigned_character[mission_id] ~= character then
			mission_id = nil
		end

		local free_area_index = free_area_char_to_index[character]
		local character_go = self.character_gos[character]

		if mission_id then
			if free_area_index then
				free_area_char_to_index[character] = nil
				free_area_index_to_char[free_area_index] = nil
			end

			snap_go_to_transform(self, character_go, self.mission_slots[mission_id], instant)
		else
			if not free_area_index then
				free_area_index = first_unassigned_index(self)
				free_area_char_to_index[character] = free_area_index
				free_area_index_to_char[free_area_index] = character
			end

			snap_go_to_transform(self, character_go, self.free_area_slots[free_area_index], instant)
		end
	end
end

function _env:on_input(action_id, action)
	if self.dnd:on_input(action_id, action) then
		return true
	end

	for i, button in pairs(self.mission_buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end

	for i, button in pairs(self.agent_buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end

	if action.pressed and (action_id == h_key_escape or action_id == h_gamepad_rpad_right) and self.dnd.manually_dragging and self.dnd:is_dragging() then
		self.dnd:drag_cancel()

		return true
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		for i, button in pairs(self.agent_buttons) do
			button:switch_input_method()
		end

		if self.dnd.manually_dragging and message.input_method == input_state.INPUT_METHOD_MOUSE then
			self.dnd:drag_cancel()
		end
	elseif message_id == h_missions_gain_focus then
		local source = focus_distance.get_item_in_direction(message.position, message.nav_action, self.dnd.drag_sources, source_position_getter)

		if source then
			source.button:focus()
		end
	elseif message_id == h_save_prompt_enable then
		for i, button in pairs(self.agent_buttons) do
			button:cancel_focus()
		end

		if self.dnd.manually_dragging then
			self.dnd:drag_cancel()
		end
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function reset_targets_padding(self, targets, padding)
	for i, value in pairs(mouse_relative_mission_padding) do
		mouse_relative_mission_padding[i] = 0
	end
end

function custom_dnd_pick(source, action)
	local picked, padding = nil
	local sprite = source.sprite

	if sprite then
		local x, y = DragAndDrop.default_sprite_action_to_position(action)
		picked, padding = custom_pick.pick_sprite(sprite, x, y, source.padding)

		if picked then
			for i, value in pairs(padding) do
				mouse_relative_mission_padding[i] = value
			end
		end
	end

	return picked
end

function create_connector(self)
	local go_id = factory.create(self.connector_factory)
	local connector_sprite = msg.url(nil, go_id, h_sprite)
	local connector_label_bg = msg.url(nil, go_id, h_label_bg)

	sprite.set_constant(connector_sprite, h_tint, connector_tint)
	sprite.set_constant(connector_label_bg, h_tint, connector_label_bg_tint)
	animate_connector(go_id, false, true)

	return go_id
end

local connector_mode_mission = 0
local connector_mode_agent = 1

function ensure_mission_connectors(self, mission_id)
	if self.connector_mode == connector_mode_mission and self.connector_key == mission_id then
		return
	end

	self.connector_mode = connector_mode_mission
	self.connector_key = mission_id

	animate_connectors(self, false, true)

	local active_connectors = {}
	self.active_connectors = active_connectors
	local mission = missions.get_option(mission_id)
	local mission_go = self.mission_gos[mission_id]

	for character, character_go in pairs(self.character_gos) do
		local success_rate = missions.get_success_rate(mission, character)

		if success_rate then
			active_connectors[#active_connectors + 1] = {
				go_id = self.character_connectors[character],
				character_go = character_go,
				mission_go = mission_go,
				success_rate = success_rate
			}
		end
	end
end

local function cancel_scheduled_connector_update(self)
	self.keep_updating_connectors = false

	if self.scheduled_connector_update then
		timer.cancel(self.scheduled_connector_update)

		self.scheduled_connector_update = nil
	end
end

local function hide_connectors(self)
	animate_connectors(self, false)
	cancel_scheduled_connector_update(self)
end

function hide_mission_connectors(self, mission_id)
	if self.connector_mode == connector_mode_mission and self.connector_key == mission_id then
		hide_connectors(self)
	end
end

function ensure_agent_connectors(self, character)
	if self.connector_mode == connector_mode_agent and self.connector_key == character then
		return
	end

	self.connector_mode = connector_mode_agent
	self.connector_key = character

	animate_connectors(self, false, true)

	local active_connectors = {}
	self.active_connectors = active_connectors
	local character_go = self.character_gos[character]

	for i, mission in ipairs(missions.options) do
		local success_rate = missions.get_success_rate(mission, character)

		if success_rate then
			active_connectors[#active_connectors + 1] = {
				go_id = self.mission_connectors[mission.id],
				character_go = character_go,
				mission_go = self.mission_gos[mission.id],
				success_rate = success_rate
			}
		end
	end
end

function hide_agent_connectors(self, character)
	if self.connector_mode == connector_mode_agent and self.connector_key == character then
		hide_connectors(self)
	end
end

function animate_connectors(self, enabled, instant)
	for _, connector in ipairs(self.active_connectors) do
		animate_connector(connector.go_id, enabled, instant)
	end
end

function update_connectors(self)
	for _, connector in ipairs(self.active_connectors) do
		local go_id = connector.go_id
		local connector_url = msg.url(go_id)
		local connector_sprite = msg.url(nil, go_id, h_sprite)
		local connector_label = msg.url(nil, go_id, h_label)
		local connector_label_bg = msg.url(nil, go_id, h_label_bg)
		local success_rate = connector.success_rate

		set_success_rate(connector_label, success_rate)

		local character_pos = go.get(connector.character_go, h_position)
		local mission_pos = go.get(connector.mission_go, h_position)
		local connector_length, connector_pos, connector_rotation = get_connector_metrics(mission_pos, character_pos)

		go.set(connector_url, h_position, connector_pos)
		go.set(connector_sprite, h_scalex, connector_length)
		go.set(connector_url, h_rotation, connector_rotation)

		if hr_perk_active() then
			local label_active = connector_label_show_distance <= connector_length
			local message_id = label_active and h_enable or h_disable

			msg.post(connector_label, message_id)
			msg.post(connector_label_bg, message_id)
		end
	end

	if self.keep_updating_connectors then
		self.scheduled_connector_update = timer.delay(0, false, update_connectors)
	end
end

function animate_connector(go_id, enabled, instant)
	local connector_sprite = msg.url(nil, go_id, h_sprite)
	local connector_label = msg.url(nil, go_id, h_label)
	local connector_label_bg = msg.url(nil, go_id, h_label_bg)

	go.cancel_animations(connector_sprite, h_tintw)
	go.cancel_animations(connector_label, h_colorw)
	go.cancel_animations(connector_label, h_outlinew)
	go.cancel_animations(connector_label_bg, h_tintw)

	local has_label = hr_perk_active()

	if enabled then
		msg.post(connector_sprite, h_enable)

		if has_label then
			msg.post(connector_label, h_enable)
			msg.post(connector_label_bg, h_enable)
		end
	end

	local target_alpha_sprite = 0
	local target_alpha_label = 0
	local target_alpha_label_bg = 0

	if enabled then
		target_alpha_sprite = connector_tint.w
		target_alpha_label = 1
		target_alpha_label_bg = connector_label_bg_tint.w
	end

	if instant then
		go.set(connector_sprite, h_tintw, target_alpha_sprite)
		go.set(connector_label, h_colorw, target_alpha_label)
		go.set(connector_label, h_outlinew, target_alpha_label)
		go.set(connector_label_bg, h_tintw, target_alpha_label_bg)

		if not enabled then
			msg.post(connector_sprite, h_disable)
			msg.post(connector_label, h_disable)
			msg.post(connector_label_bg, h_disable)
		end
	else
		local playback = go.PLAYBACK_ONCE_FORWARD
		local easing = go.EASING_OUTCIRC
		local duration = enabled and 0.2 or 0.6

		go.animate(connector_sprite, h_tintw, playback, target_alpha_sprite, easing, duration, 0, function ()
			if not enabled then
				msg.post(connector_sprite, h_disable)
				msg.post(connector_label, h_disable)
				msg.post(connector_label_bg, h_disable)
			end
		end)
		go.animate(connector_label, h_colorw, playback, target_alpha_label, easing, duration)
		go.animate(connector_label, h_outlinew, playback, target_alpha_label, easing, duration)
		go.animate(connector_label_bg, h_tintw, playback, target_alpha_label_bg, easing, duration)
	end
end

function get_connector_metrics(object1_pos, object2_pos)
	local dist_x = object1_pos.x - object2_pos.x
	local dist_y = object1_pos.y - object2_pos.y
	local pos = vmath.vector3()
	pos.x = object1_pos.x - 0.5 * dist_x
	pos.y = object1_pos.y - 0.5 * dist_y
	pos.z = -0.2
	local len = math.sqrt(math.pow(math.abs(dist_x), 2) + math.pow(math.abs(dist_y), 2))
	local rot_z = math.asin(dist_y / len)

	if dist_x < 0 then
		rot_z = 2 * math.pi - rot_z or rot_z
	end

	local rot = vmath.quat_rotation_z(rot_z)

	return len, pos, rot
end

function set_success_rate(connector_label, success_rate)
	go.set(connector_label, h_scalex, success_rate == 100 and connector_condensed_scale_x or connector_default_scale_x)
	label.set_text(connector_label, success_rate and success_rate .. "%" or "N/A")
end
