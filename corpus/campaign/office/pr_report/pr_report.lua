local stats = require("campaign.stats")
local Tooltip = require("lib.tooltip")
local Button = require("crit.button")
local dispatcher = require("crit.dispatcher")
local variables = require("campaign.variables")
local input_state = require("crit.input_state")
local FocusGiver = require("crit.focus_giver")
local commentary = require("main.progression.commentary.index")
local pick = require("crit.pick")
local button_sound = require("sound.button")
local intl = require("crit.intl")
local sprites = require("campaign.office.sprites")
local h_office_object_select = hash("office_object_select")
local h_office_expo_end = hash("office_expo_end")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_play_sfx = hash("play_sfx")
local h_pr_stat_positive = hash("pr_stat_positive")
local h_pr_stat_negative = hash("pr_stat_negative")
local h_pr_stat_difference = hash("pr_stat_difference")
local h_bars_set = hash("bars_set")
local h_bars_expo_reset = hash("bars_expo_reset")
local h_bars_expo_animate = hash("bars_expo_animate")
local h_tintw = hash("tint.w")
local h_pr_report = hash("pr_report")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_sprite = hash("sprite")
local h_up = hash("up")
local h_down = hash("down")
local h_const = hash("const")
local h_play_animation = hash("play_animation")
local h_tick = hash("tick")
local h_tick_red = hash("tick_red")
local h_switch_input_method = hash("switch_input_method")
local h_outer_glow = hash("outer_glow")
local h__breakdown = hash("/breakdown")
local h__gains = hash("/gains")
local h__losses = hash("/losses")
local h__label_breakdown = hash("/label_breakdown")
local h_label_breakdown = hash("label_breakdown")
local h_label_gains = hash("label_gains")
local h_label_losses = hash("label_losses")
local h_positionx = hash("position.x")
local h_set_parent = hash("set_parent")
local h_label = hash("label")
local h_size = hash("size")
local outer_glow_default = vmath.vector4(0, 0, 0, 0)
local outer_glow_hover = vmath.vector4(0, 0, 0, 0.7)
local zero3 = vmath.vector3(0)
local one3 = vmath.vector3(1)
local zero_quat = vmath.quat()
local play_expo_sfx = nil
local checkbox_button_padding = 260
local breakdown_open_x = 580
local breakdown_closed_x = 150
local breakdown_hidden_x = 50
local breakdown_item_spacing = 30
local NAVIGATE_UP = Button.NAVIGATE_UP
local NAVIGATE_DOWN = Button.NAVIGATE_DOWN
local NAVIGATE_LEFT = Button.NAVIGATE_LEFT
local NAVIGATE_RIGHT = Button.NAVIGATE_RIGHT
local stat_ids = {
	"popularity",
	"press",
	"authorities"
}

local function set_checkmark_slot(entry_no, checkmark_slot)
	local checkboxes_sprite = msg.url("checkboxes_" .. entry_no .. "#sprite")
	local checkmark_go = msg.url("checkmark_" .. entry_no)
	local checkmark_sprite = msg.url(checkmark_go.socket, checkmark_go.path, h_sprite)
	local checkbox_size = 48
	local checkmark_pos_x = checkbox_size * (checkmark_slot - 2)
	local checkmark_pos = go.get_position(checkmark_go)
	checkmark_pos.x = checkmark_pos_x

	go.set_position(checkmark_pos, checkmark_go)
	msg.post(checkmark_sprite, h_play_animation, {
		id = checkmark_slot == 0 and h_tick_red or h_tick
	})

	return checkboxes_sprite, checkbox_size
end

local function stat_indicator_on_state_change(button, state)
	local sprite_url = button.node

	if sprite_url then
		local outer_glow = outer_glow_default

		if state == Button.STATE_HOVER or state == Button.STATE_PRESSED then
			outer_glow = outer_glow_hover
		elseif state == Button.STATE_DISABLED then
			outer_glow = outer_glow_default
		end

		go.cancel_animations(sprite_url, h_outer_glow)
		go.animate(sprite_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_LINEAR, 0.3)
	end
end

local function checkbox_button_on_state_change(button, state)
	local outer_glow = outer_glow_default

	if state == Button.STATE_HOVER or state == Button.STATE_PRESSED then
		outer_glow = outer_glow_hover
	elseif state == Button.STATE_DISABLED then
		outer_glow = outer_glow_default
	end

	local perk_icon_url = button.perk_icon
	local checkbox_glow_url = button.checkbox_glow

	go.cancel_animations(perk_icon_url, h_outer_glow)
	go.cancel_animations(checkbox_glow_url, h_outer_glow)
	go.animate(perk_icon_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_LINEAR, 0.3)
	go.animate(checkbox_glow_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_LINEAR, 0.3)
end

local function checkbox_buttons_pick(button, action)
	local node = button.node
	local icon = button.perk_icon

	if not node then
		return false
	end

	local x, y = button.action_to_position(action)
	local picked = pick.pick_sprite(node, x, y, button.padding) or pick.pick_sprite(icon, x, y)

	return picked
end

local function breakdown_on_state_change(breakdown, entry_no)
	return function (button, state)
		local x = breakdown_closed_x
		local delay = 0

		if state == Button.STATE_DISABLED then
			x = breakdown_hidden_x
		elseif state == Button.STATE_HOVER or state == Button.STATE_PRESSED then
			local old_state = button.state

			if old_state ~= Button.STATE_HOVER and old_state ~= Button.STATE_PRESSED then
				dispatcher.dispatch(h_play_sfx, {
					sfx = "paper_slide2"
				})
			end

			x = breakdown_open_x
		elseif state == Button.STATE_DEFAULT and button.state == Button.STATE_DISABLED then
			delay = (entry_no - 1) * 0.2
		end

		go.cancel_animations(breakdown, h_positionx)
		go.animate(breakdown, h_positionx, go.PLAYBACK_ONCE_FORWARD, x, go.EASING_INOUTQUAD, 0.3, delay)
	end
end

local function breakdown_pick(breakdown, paper_sprite)
	local url = msg.url(nil, breakdown, h_sprite)
	local size = go.get(url, h_size)
	local padding = {
		top = -60,
		bottom = -60,
		left = -80,
		right = 430
	}

	return function (button, action)
		local local_x, local_y = button.action_to_position(action)
		local y = local_y
		local position = go.get_world_position(url)
		local scale = go.get_world_scale(url)
		y = y - position.y
		y = y / scale.y
		local half_height = size.y * 0.5
		local top = half_height
		local bottom = -half_height

		if y < bottom or top < y then
			return false
		end

		if not pick.pick_sprite(paper_sprite, local_x, local_y, padding) then
			return false
		end

		return true
	end
end

local function populate_breakdown(stat_id, item_factory, gains_container, losses_container)
	local changes = {}
	local label_order = {}

	for i = 1, #stats.commits do
		local commit = stats.get_commit(i)
		local next_commit = stats.get_commit(i + 1)
		local change_label = next_commit.label or "misc"
		local diff = next_commit[stat_id] - commit[stat_id]

		if diff ~= 0 then
			if not changes[change_label] then
				label_order[#label_order + 1] = change_label
			end

			changes[change_label] = (changes[change_label] or 0) + diff
		end
	end

	local gain_count = 0
	local loss_count = 0

	for i, change_label in ipairs(label_order) do
		local diff = changes[change_label]

		if diff and diff ~= 0 then
			local item_count = nil

			if diff > 0 then
				item_count = gain_count
				gain_count = gain_count + 1
			else
				item_count = loss_count
				loss_count = loss_count + 1
			end

			local position = vmath.vector3(0, breakdown_item_spacing * -item_count, 0)
			local item = factory.create(item_factory, position, zero_quat, {}, one3)
			local label_url = msg.url(nil, item, h_label)

			label.set_text(label_url, intl("stats.breakdown." .. change_label) or change_label)
			msg.post(item, h_set_parent, {
				keep_world_transform = 0,
				parent_id = diff > 0 and gains_container or losses_container
			})
		end

		changes[label] = nil
	end
end

function _env:init()
	self.entry_buttons_positive = {}
	self.entry_buttons_negative = {}
	self.entry_buttons_stat_diff = {}
	self.breakdowns = {}
	self.selected = false
	local is_advanced = not not variables.advanced_pr_report
	self.is_advanced = is_advanced
	self.trends = {}
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_selected,
		h_office_object_deselect,
		h_switch_input_method
	})
	local focus_context = input_state.new_focus_context()
	local breakdown_factory, breakdown_item_factory = nil

	if is_advanced then
		breakdown_factory = msg.url("#breakdown")
		breakdown_item_factory = msg.url("#breakdown_item")
	end

	local title_sprites = is_advanced and sprites.pr_title_advanced or sprites.pr_title

	sprite.play_flipbook("#title", intl.select(title_sprites))

	local paper_sprite = msg.url("#sprite")

	for entry_no, id in ipairs(stat_ids) do
		local entry_label = msg.url("entry_" .. entry_no .. "#label")
		local label_width = label.get_text_metrics(entry_label).width

		intl.translate_label(entry_label, "stats." .. id .. ".name")
		intl.translate_label("entry_" .. entry_no .. "#brief", "stats." .. id .. ".brief")

		local current_stat = stats[id]
		local previous_stat = stats.get_commit(1)[id]
		local checkmark_slot = stats.get_checkbox_slot(current_stat)
		local previous_checkmark_slot = stats.get_checkbox_slot(previous_stat)
		local bar_go = msg.url("bar_" .. entry_no)

		if is_advanced then
			msg.post(bar_go, h_bars_set, {
				current = math.max(0, math.min(100, current_stat)),
				previous = math.max(0, math.min(100, previous_stat))
			})
		else
			go.delete(bar_go, true)
		end

		local checkboxes_sprite, checkbox_size = set_checkmark_slot(entry_no, checkmark_slot)
		local trend_go = msg.url("trend_" .. entry_no)
		local trend_up = msg.url(trend_go.socket, trend_go.path, h_up)
		local trend_down = msg.url(trend_go.socket, trend_go.path, h_down)
		local trend_const = msg.url(trend_go.socket, trend_go.path, h_const)
		local trend_pos = go.get_position(trend_go)

		timer.delay(0, false, function ()
			trend_pos.x = trend_pos.x - label_width + label.get_text_metrics(entry_label).width

			go.set_position(trend_pos, trend_go)
		end)

		local trend_is_up, trend_is_down, trend_is_const = nil

		if is_advanced then
			trend_is_up = previous_stat < current_stat
			trend_is_down = current_stat < previous_stat
			trend_is_const = current_stat == previous_stat
		else
			trend_is_up = previous_checkmark_slot < checkmark_slot
			trend_is_down = checkmark_slot < previous_checkmark_slot
			trend_is_const = checkmark_slot == previous_checkmark_slot
		end

		msg.post(trend_up, trend_is_up and h_enable or h_disable)
		msg.post(trend_down, trend_is_down and h_enable or h_disable)
		msg.post(trend_const, trend_is_const and h_enable or h_disable)

		if trend_is_up or trend_is_down then
			self.trends[id] = trend_is_up and trend_up or trend_down
		else
			self.trends[id] = trend_const
		end

		local button_padding = -checkbox_size * 4 + 1
		local button_positive = Button.new(checkboxes_sprite, {
			focus_simulates_hover = true,
			gamepad_focus = true,
			is_sprite = true,
			keyboard_focus = true,
			focus_context = focus_context,
			on_pass_focus = function (button, nav_action)
				if nav_action == NAVIGATE_DOWN and entry_no < #stat_ids then
					return self.entry_buttons_positive[stat_ids[entry_no + 1]]:focus()
				elseif nav_action == NAVIGATE_UP and entry_no > 1 then
					return self.entry_buttons_positive[stat_ids[entry_no - 1]]:focus()
				elseif nav_action == NAVIGATE_LEFT or not is_advanced and nav_action == NAVIGATE_RIGHT then
					return self.entry_buttons_negative[id]:focus()
				elseif is_advanced and nav_action == NAVIGATE_RIGHT then
					return self.breakdowns[id]:focus() or self.entry_buttons_negative[id]:focus()
				end
			end,
			on_state_change = Tooltip.button_on_state_change({
				padding = checkbox_button_padding,
				id = "pr_entry_positive" .. id,
				position = Tooltip.POSITION_RIGHT,
				type = h_pr_stat_positive,
				payload = {
					entry_id = id
				}
			}, checkbox_button_on_state_change),
			pick = checkbox_buttons_pick,
			padding_left = button_padding
		})
		button_positive.perk_icon = msg.url("pic_positive" .. entry_no .. "#sprite")
		button_positive.checkbox_glow = msg.url("checkboxes_" .. entry_no .. "#glow_pos")
		self.entry_buttons_positive[id] = button_positive
		local button_negative = Button.new(checkboxes_sprite, {
			focus_simulates_hover = true,
			gamepad_focus = true,
			is_sprite = true,
			keyboard_focus = true,
			focus_context = focus_context,
			on_pass_focus = function (button, nav_action)
				if nav_action == NAVIGATE_DOWN and entry_no < #stat_ids then
					return self.entry_buttons_negative[stat_ids[entry_no + 1]]:focus()
				elseif nav_action == NAVIGATE_UP and entry_no > 1 then
					return self.entry_buttons_negative[stat_ids[entry_no - 1]]:focus()
				elseif nav_action == NAVIGATE_RIGHT or not is_advanced and nav_action == NAVIGATE_LEFT then
					return self.entry_buttons_positive[id]:focus()
				elseif is_advanced and nav_action == NAVIGATE_LEFT then
					return self.breakdowns[id]:focus() or self.entry_buttons_positive[id]:focus()
				end
			end,
			on_state_change = Tooltip.button_on_state_change({
				padding = checkbox_button_padding,
				position = Tooltip.POSITION_LEFT,
				id = "pr_entry_negative" .. id,
				type = h_pr_stat_negative,
				payload = {
					entry_id = id
				}
			}, checkbox_button_on_state_change),
			pick = checkbox_buttons_pick,
			padding_right = button_padding
		})
		button_negative.perk_icon = msg.url("pic_negative" .. entry_no .. "#sprite")
		button_negative.checkbox_glow = msg.url("checkboxes_" .. entry_no .. "#glow_neg")
		self.entry_buttons_negative[id] = button_negative
		self.entry_buttons_stat_diff[id] = Button.new(self.trends[id], {
			is_sprite = true,
			on_state_change = Tooltip.button_on_state_change({
				padding = 30,
				id = "pr_stat_diff_" .. id,
				position = Tooltip.POSITION_RIGHT,
				type = h_pr_stat_difference,
				payload = {
					entry_id = id,
					is_advanced = is_advanced
				}
			}, stat_indicator_on_state_change)
		})

		self.entry_buttons_positive[id]:set_enabled(false)
		self.entry_buttons_negative[id]:set_enabled(false)
		self.entry_buttons_stat_diff[id]:set_enabled(false)

		if is_advanced then
			local breakdown_collection = collectionfactory.create(breakdown_factory, zero3, zero_quat, {}, one3)
			local breakdown = breakdown_collection[h__breakdown]
			local gains = breakdown_collection[h__gains]
			local losses = breakdown_collection[h__losses]

			go.set(breakdown, h_positionx, breakdown_hidden_x)

			local parent = msg.url("entry_" .. entry_no)

			msg.post(breakdown, h_set_parent, {
				keep_world_transform = 0,
				parent_id = parent.path
			})

			local breakdown_label_url = msg.url(nil, breakdown_collection[h__label_breakdown], h_label_breakdown)

			intl.translate_label(breakdown_label_url, "stats.breakdown")
			intl.translate_label(msg.url(nil, breakdown, h_label_gains), "stats.breakdown.gains")
			intl.translate_label(msg.url(nil, breakdown, h_label_losses), "stats.breakdown.losses")
			populate_breakdown(id, breakdown_item_factory, gains, losses)

			local breakdown_button = Button.new(nil, {
				focus_simulates_hover = true,
				gamepad_focus = true,
				is_sprite = true,
				keyboard_focus = true,
				keep_hover = true,
				focus_context = focus_context,
				on_pass_focus = function (button, nav_action)
					if nav_action == NAVIGATE_DOWN and entry_no < #stat_ids then
						return self.breakdowns[stat_ids[entry_no + 1]]:focus()
					elseif nav_action == NAVIGATE_UP and entry_no > 1 then
						return self.breakdowns[stat_ids[entry_no - 1]]:focus()
					elseif nav_action == NAVIGATE_RIGHT then
						return self.entry_buttons_negative[id]:focus()
					elseif nav_action == NAVIGATE_LEFT then
						return self.entry_buttons_positive[id]:focus()
					end
				end,
				on_state_change = button_sound.with_sound({
					hover = false,
					press = false,
					release = false
				}, breakdown_on_state_change(breakdown, entry_no)),
				pick = breakdown_pick(breakdown, paper_sprite),
				action = function ()
					return
				end
			})

			breakdown_button:set_enabled(false)

			self.breakdowns[id] = breakdown_button
		end
	end

	self.focus_giver = FocusGiver.new({
		focus_context = focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if next(self.entry_buttons_positive) and next(self.entry_buttons_negative) then
				if not nav_action or nav_action == NAVIGATE_DOWN or nav_action == NAVIGATE_RIGHT then
					return self.entry_buttons_negative[stat_ids[1]]:focus()
				elseif nav_action == NAVIGATE_LEFT then
					local first_id = stat_ids[1]

					if is_advanced and self.breakdowns[first_id]:focus() then
						return true
					end

					return self.entry_buttons_positive[first_id]:focus()
				elseif nav_action == NAVIGATE_UP then
					return self.entry_buttons_negative[stat_ids[#stat_ids]]:focus()
				end
			end
		end
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if message.object_id == h_pr_report and message.expo then
			self.expo = true

			for entry_no, id in ipairs(stat_ids) do
				local trend_sprite = self.trends[id]

				if trend_sprite then
					go.set(trend_sprite, h_tintw, 0)

					local previous_stat = stats.get_commit(1)[id]
					local previous_checkmark_slot = stats.get_checkbox_slot(previous_stat)

					set_checkmark_slot(entry_no, previous_checkmark_slot)

					if self.is_advanced then
						local bar_go = msg.url("bar_" .. entry_no)

						msg.post(bar_go, h_bars_expo_reset)
					end
				end
			end
		end
	elseif message_id == h_office_object_selected then
		if message.object_id == h_pr_report then
			self.selected = true

			commentary.stats.overlay_once()

			for i, id in ipairs(stat_ids) do
				self.entry_buttons_positive[id]:set_enabled(true)
				self.entry_buttons_negative[id]:set_enabled(true)
				self.entry_buttons_stat_diff[id]:set_enabled(true)

				if self.is_advanced and not message.expo then
					self.breakdowns[id]:set_enabled(true)
				end
			end

			if message.expo then
				local last_stat_no = 0
				local delay = 0

				for entry_no, id in ipairs(stat_ids) do
					local trend_sprite = self.trends[id]

					if trend_sprite then
						last_stat_no = entry_no
						local checkmark_slot = stats.get_checkbox_slot(stats[id])
						local previous_checkmark_slot = stats.get_checkbox_slot(stats.get_commit(1)[id])
						local slot_changed = checkmark_slot ~= previous_checkmark_slot
						local checkmark_sprite = msg.url("checkmark_" .. entry_no .. "#sprite")

						go.animate(checkmark_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, slot_changed and 0 or 1, go.EASING_LINEAR, 0.4, delay, function ()
							set_checkmark_slot(entry_no, checkmark_slot)
							go.animate(trend_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.4)
							go.animate(checkmark_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.4, 0, function ()
								if last_stat_no == entry_no then
									dispatcher.dispatch(h_office_expo_end, {
										object_id = h_pr_report
									})
								end
							end)
							play_expo_sfx(true, slot_changed)
						end)
						timer.delay(delay, false, function ()
							play_expo_sfx(false, slot_changed)
						end)

						if self.is_advanced then
							local bar_go = msg.url("bar_" .. entry_no)

							msg.post(bar_go, h_bars_expo_animate, {
								duration = 0.8,
								delay = delay
							})
						end

						delay = delay + 0.8
					end
				end

				if last_stat_no == 0 then
					dispatcher.dispatch(h_office_expo_end, {
						object_id = h_pr_report
					})
				end

				return
			end

			self.focus_giver:try_focus_first()
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_pr_report then
			if self.expo then
				self.expo = false
			end

			for i, id in ipairs(stat_ids) do
				self.entry_buttons_positive[id]:set_enabled(false)
				self.entry_buttons_negative[id]:set_enabled(false)
				self.entry_buttons_stat_diff[id]:set_enabled(false)

				if self.is_advanced then
					self.breakdowns[id]:set_enabled(false)
				end
			end

			self.selected = false
		end
	elseif message_id == h_switch_input_method then
		for i, button in pairs(self.entry_buttons_negative) do
			button:switch_input_method()
		end

		for i, button in pairs(self.entry_buttons_positive) do
			button:switch_input_method()
		end

		for i, button in pairs(self.breakdowns) do
			button:switch_input_method()
		end

		if not self.expo then
			self.focus_giver:try_focus_first(message.nav_action)
		end
	end
end

function play_expo_sfx(check, slot_changed)
	if slot_changed then
		dispatcher.dispatch(h_play_sfx, {
			sfx = "checkmark",
			parameters = {
				IsEx = 1,
				IsCheck = check and 1 or 0
			}
		})
	end
end

function _env:on_input(action_id, action)
	if not self.expo then
		if self.selected and self.focus_giver:on_input(action_id, action) then
			return true
		end

		for id, button in pairs(self.entry_buttons_positive) do
			if button:on_input(action_id, action) then
				return true
			end
		end

		for id, button in pairs(self.entry_buttons_negative) do
			if button:on_input(action_id, action) then
				return true
			end
		end

		for id, button in pairs(self.entry_buttons_stat_diff) do
			if button:on_input(action_id, action) then
				return true
			end
		end

		for id, button in pairs(self.breakdowns) do
			if button:on_input(action_id, action) then
				return true
			end
		end
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
