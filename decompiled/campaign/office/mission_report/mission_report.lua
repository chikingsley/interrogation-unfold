local missions = require("campaign.missions")
local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local variables = require("campaign.variables")
local FocusGiver = require("crit.focus_giver")
local input_state = require("crit.input_state")
local intl = require("crit.intl")
local sprites = require("campaign.office.sprites")
local office = require("campaign.office")
local h_office_object_select = hash("office_object_select")
local h_office_expo_end = hash("office_expo_end")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_switch_input_method = hash("switch_input_method")
local h_play_sfx = hash("play_sfx")
local h_mission_report = hash("mission_report")
local h_play_animation = hash("play_animation")
local h_scale = hash("scale")
local h_tintw = hash("tint.w")
local h_position = hash("position")
local h_positionx = hash("position.x")
local h_positionz = hash("position.z")
local h_rotation = hash("rotation")
local h_set_parent = hash("set_parent")
local h_sprite = hash("sprite")
local h_outer_glow = hash("outer_glow")
local max_entries = 4
local outer_glow_hover = vmath.vector4(0, 0, 0, 1)
local outer_glow_default = vmath.vector4(0)

local function iterate_previous_missions()
	return coroutine.wrap(function ()
		local i = 0

		for j, mission in ipairs(missions.previous_options) do
			local assigned_character = missions.previous_assigned_character[mission.id]

			if assigned_character and missions.previous_assigned_mission[assigned_character] == mission.id then
				i = i + 1

				coroutine.yield(i, j, mission, assigned_character)
			end
		end
	end)
end

local function glow_on_state_change(self, button, state)
	local outer_glow = outer_glow_default

	if state == Button.STATE_HOVER or state == Button.STATE_PRESSED then
		outer_glow = outer_glow_hover
	elseif state == Button.STATE_DISABLED then
		outer_glow = outer_glow_default
	end

	local sprite_url = button.node

	go.cancel_animations(sprite_url, h_outer_glow)
	go.animate(sprite_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_LINEAR, 0.3)
end

local function swap_cards_on_state_change(self, button, state, old_state, card_index)
	local cards = self.mission_cards
	local cards_in_slots = self.cards_in_slots

	if cards_in_slots[1] ~= cards[card_index] and state == Button.STATE_HOVER and old_state == Button.STATE_DEFAULT then
		local card = cards[card_index]
		local swap_slot_url = msg.url("card_stack_swap")
		local swap_slot_pos = go.get(swap_slot_url, h_position)
		local swap_slot_rot = go.get(swap_slot_url, h_rotation)
		local index_to_swap = nil

		for i in pairs(cards_in_slots) do
			if cards_in_slots[i] == card then
				index_to_swap = i
			end
		end

		if index_to_swap then
			table.remove(cards_in_slots, index_to_swap)
			table.insert(cards_in_slots, 1, card)
		end

		go.animate(card, h_rotation, go.PLAYBACK_ONCE_FORWARD, swap_slot_rot, go.EASING_INOUTEXPO, 0.3, 0.1)
		go.animate(card, h_position, go.PLAYBACK_ONCE_FORWARD, swap_slot_pos, go.EASING_INOUTEXPO, 0.3, 0.1, function ()
			local card_slots = self.mission_card_slots

			for i, url in pairs(cards_in_slots) do
				local current_slot_url = card_slots[i]
				local current_slot_pos = go.get(current_slot_url, h_position)
				local current_slot_rot = go.get(current_slot_url, h_rotation)

				go.cancel_animations(url, h_position)
				go.cancel_animations(url, h_rotation)
				go.set(url, h_positionz, current_slot_pos.z)
				go.animate(url, h_position, go.PLAYBACK_ONCE_FORWARD, current_slot_pos, go.EASING_INOUTEXPO, 0.3)
				go.animate(url, h_rotation, go.PLAYBACK_ONCE_FORWARD, current_slot_rot, go.EASING_INOUTEXPO, 0.3)
			end
		end)
	end
end

local function numeric_mission_id(mission_id)
	local hex = hash_to_hex(hash(mission_id))
	hex = string.sub(hex, math.max(0, #hex - 6))

	return tonumber(hex, 16) % 887 + 100
end

function _env:init()
	local entry_buttons = {}
	self.entry_buttons = entry_buttons
	local outcome_urls = {}
	self.outcome_urls = outcome_urls
	local mission_cards = {}
	self.mission_cards = mission_cards
	local mission_card_slots = {}
	self.mission_card_slots = mission_card_slots
	local cards_in_slots = {}
	self.cards_in_slots = cards_in_slots
	local agents_full_names = {
		mordecai = "Mordecai Fischer",
		joseph = "Joseph Ward",
		tab = "Tab Thompson",
		jen = "Jennifer Reyes"
	}
	local focus_context = input_state.new_focus_context()
	local card_stack_url = go.get_id("card_stack")
	local card_stack_id = go.get_id("card_stack")

	sprite.play_flipbook("#title", intl.select(sprites.mission_title))

	local last_entry = 0

	for i, mission_index, mission, assigned_character in iterate_previous_missions() do
		last_entry = i
		local label_url = msg.url("entry" .. i .. "#name")

		label.set_text(label_url, missions.translate_option_text(mission, "title", assigned_character))

		local id_url = msg.url("entry" .. i .. "#id")

		label.set_text(id_url, intl("mission_report.id") .. " #" .. numeric_mission_id(mission.id))

		local agent_name_url = msg.url("agent_name" .. i .. "#label")
		local assigned_to_url = msg.url("entry" .. i .. "#assigned_to")
		local assigned_to_width = label.get_text_metrics(assigned_to_url).width
		local assigned_to_scale = go.get(assigned_to_url, h_scale)
		local agent_name_pos = go.get_position(agent_name_url.path)

		intl.translate_label(assigned_to_url, "mission_report.assigned_to")
		label.set_text(agent_name_url, agents_full_names[assigned_character])
		timer.delay(0, false, function ()
			local width = label.get_text_metrics(assigned_to_url).width
			agent_name_pos.x = agent_name_pos.x + (width - assigned_to_width) * assigned_to_scale.x

			go.set_position(agent_name_pos, agent_name_url.path)
		end)

		local description_url = msg.url("entry" .. i .. "#description")
		local description_text = nil

		if missions.completed[mission.id] then
			description_text = missions.translate_option_text(mission, "success", assigned_character)
		else
			description_text = missions.translate_option_text(mission, "fail", assigned_character)
		end

		description_text = description_text or missions.translate_option_text(mission, "description", assigned_character)

		if description_text then
			label.set_text(description_url, description_text)
		end

		intl.translate_label("entry" .. i .. "#status", "mission_report.status")

		local status_animation = missions.completed[mission.id] and sprites.success or sprites.fail
		local outcome_url = msg.url("outcome" .. i .. "#sprite")

		msg.post(outcome_url, h_play_animation, {
			id = intl.select(status_animation)
		})

		outcome_urls[i] = outcome_url

		if office.mission_cards then
			self.has_cards = true
			local card_stack_slot_id = go.get_id("card_stack" .. i)
			local card_stack_slot_pos = go.get(msg.url(card_stack_slot_id), h_position)
			local card_stack_slot_rot = go.get(msg.url(card_stack_slot_id), h_rotation)
			local mission_card_factory = msg.url("mission_cards#mission_cards" .. variables.mission_cards)
			local card_id = factory.create(mission_card_factory, card_stack_slot_pos, card_stack_slot_rot)
			local card_url = msg.url(card_id)
			local card_sprite = msg.url(card_url.socket, card_url.path, h_sprite)

			msg.post(card_url, h_set_parent, {
				keep_world_transform = 0,
				parent_id = card_stack_id
			})

			local card_animation = "mission_card_" .. string.gsub(mission.id, "%d", "")

			sprite.play_flipbook(card_sprite, card_animation)
			go.set(card_url, h_scale, vmath.vector3(1))
			go.set(card_sprite, h_tintw, 0)

			mission_cards[i] = card_url
			mission_card_slots[i] = msg.url(card_stack_slot_id)
			cards_in_slots[i] = card_url
			local close_button_url = msg.url("close_button")
			local zoom_on_select_url = msg.url("report#zoom_on_select")
			local close_button_position = go.get(close_button_url, h_position)

			go.set(close_button_url, h_positionx, close_button_position.x - 100)
			go.set(zoom_on_select_url, "zoomed_position.x", -300)
		end

		local button_sprite = msg.url("table" .. i .. "#sprite")
		local entry_button = Button.new(button_sprite, {
			gamepad_focus = true,
			focus_simulates_hover = true,
			padding_left = -25,
			padding_top = -37,
			padding_bottom = -37,
			is_sprite = true,
			keyboard_focus = true,
			padding_right = -25,
			focus_context = focus_context,
			on_pass_focus = function (button, nav_action)
				if not nav_action or nav_action == Button.NAVIGATE_DOWN and i < #entry_buttons then
					return entry_buttons[i + 1]:focus()
				elseif nav_action == Button.NAVIGATE_UP and i > 1 then
					return entry_buttons[i - 1]:focus()
				end
			end,
			on_state_change = function (button, state, old_state)
				swap_cards_on_state_change(self, button, state, old_state, i)
				glow_on_state_change(self, button, state)
			end
		})

		entry_button:set_enabled(false)

		entry_buttons[i] = entry_button
	end

	local cards_slot_closed_url = msg.url("cards_slot_closed")
	local cards_slot_closed_pos = go.get(cards_slot_closed_url, h_position)
	local cards_slot_closed_rot = go.get(cards_slot_closed_url, h_rotation)
	local cards_slot_closed_scale = go.get(cards_slot_closed_url, h_scale)

	go.set(card_stack_url, h_position, cards_slot_closed_pos)
	go.set(card_stack_url, h_rotation, cards_slot_closed_rot)
	go.set(card_stack_url, h_scale, cards_slot_closed_scale)

	for i = last_entry + 1, max_entries do
		go.delete("entry" .. i, true)
	end

	self.focus_giver = FocusGiver.new({
		focus_context = focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if not nav_action or nav_action == Button.NAVIGATE_DOWN then
				return entry_buttons[1]:focus()
			elseif nav_action == Button.NAVIGATE_UP then
				return entry_buttons[#entry_buttons]:focus()
			end
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_selected,
		h_office_object_deselect,
		h_switch_input_method
	})
end

local function animate_card_stack(self, is_selected)
	local card_stack_url = msg.url("card_stack")
	local cards_slot_open = msg.url("cards_slot_open")
	local cards_slot_open_pos = go.get(cards_slot_open, h_position)
	local cards_slot_open_rot = go.get(cards_slot_open, h_rotation)
	local cards_slot_open_scale = go.get(cards_slot_open, h_scale)
	local cards_slot_closed = msg.url("cards_slot_closed")
	local cards_slot_closed_pos = go.get(cards_slot_closed, h_position)
	local cards_slot_closed_rot = go.get(cards_slot_closed, h_rotation)
	local cards_slot_closed_scale = go.get(cards_slot_closed, h_scale)

	go.cancel_animations(card_stack_url, h_position)
	go.cancel_animations(card_stack_url, h_rotation)
	go.cancel_animations(card_stack_url, h_scale)

	if is_selected then
		for i, url in pairs(self.mission_cards) do
			local sprite_url = msg.url(url.socket, url.path, h_sprite)

			go.cancel_animations(sprite_url, h_tintw)
			go.animate(sprite_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.3)
		end

		go.animate(card_stack_url, h_position, go.PLAYBACK_ONCE_FORWARD, cards_slot_open_pos, go.EASING_OUTEXPO, 0.7, 0.3)
		go.animate(card_stack_url, h_rotation, go.PLAYBACK_ONCE_FORWARD, cards_slot_open_rot, go.EASING_OUTEXPO, 0.7, 0.3)
		go.animate(card_stack_url, h_scale, go.PLAYBACK_ONCE_FORWARD, cards_slot_open_scale, go.EASING_OUTEXPO, 0.7, 0.3)
	else
		for i, url in pairs(self.mission_cards) do
			local sprite_url = msg.url(url.socket, url.path, h_sprite)

			go.cancel_animations(sprite_url, h_tintw)
			go.animate(sprite_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.5, 0.3)
		end

		go.animate(card_stack_url, h_position, go.PLAYBACK_ONCE_FORWARD, cards_slot_closed_pos, go.EASING_INOUTEXPO, 0.4)
		go.animate(card_stack_url, h_rotation, go.PLAYBACK_ONCE_FORWARD, cards_slot_closed_rot, go.EASING_INOUTEXPO, 0.4)
		go.animate(card_stack_url, h_scale, go.PLAYBACK_ONCE_FORWARD, cards_slot_closed_scale, go.EASING_INOUTEXPO, 0.4)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if message.object_id == h_mission_report then
			if message.expo then
				self.expo = true

				for i, outcome_url in ipairs(self.outcome_urls) do
					go.set_scale(vmath.vector3(1.5), outcome_url)
					go.set(outcome_url, h_tintw, 0)
				end
			else
				animate_card_stack(self, true)
			end
		end
	elseif message_id == h_office_object_selected then
		if message.object_id == h_mission_report then
			self.selected = true

			for i, button in ipairs(self.entry_buttons) do
				button:set_enabled(true)
			end

			if message.expo then
				local function end_expo()
					dispatcher.dispatch(h_office_expo_end, {
						object_id = h_mission_report
					})
				end

				local outcome_count = #self.outcome_urls

				for i, outcome_url in ipairs(self.outcome_urls) do
					local go_url = msg.url(outcome_url.socket, outcome_url.path, nil)

					go.animate(go_url, h_scale, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(1), go.EASING_INEXPO, 0.5, 0.5 * (i - 1))
					go.animate(outcome_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_INEXPO, 0.5, 0.5 * (i - 1), i == outcome_count and end_expo or nil)
					timer.delay(0.4 + 0.5 * (i - 1), false, function ()
						dispatcher.dispatch(h_play_sfx, {
							sfx = "stamp"
						})
					end)
				end

				if outcome_count == 0 then
					end_expo()
				end
			elseif self.has_cards then
				self.focus_giver:try_focus_first()
			end
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_mission_report then
			if self.expo then
				self.expo = false
			end

			for i, button in ipairs(self.entry_buttons) do
				if button.focused then
					button:cancel_focus()
				end

				button:set_enabled(false)
			end

			animate_card_stack(self, false)

			self.selected = false
		end
	elseif message_id == h_switch_input_method then
		for i, button in pairs(self.entry_buttons) do
			button:switch_input_method()
		end

		if not self.expo and self.has_cards then
			self.focus_giver:try_focus_first(message.nav_action)
		end
	end
end

function _env:on_input(action_id, action)
	if not self.expo and self.has_cards then
		if self.selected and self.focus_giver:on_input(action_id, action) then
			return true
		end

		for i, button in ipairs(self.entry_buttons) do
			if button:on_input(action_id, action) then
				return true
			end
		end
	end
end

function _env:final()
	for i, button in pairs(self.entry_buttons) do
		if button.focused then
			button:cancel_focus()
		end
	end

	dispatcher.unsubscribe(self.sub_id)
end
