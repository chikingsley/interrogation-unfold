local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local Bubble = require("lib.bubble")
local FocusGiver = require("crit.focus_giver")
local Button = require("crit.button")
local slots = require("interludes.slots")
local families = require("main.fonts.families")
local button_sound = require("sound.button")
local revive_text = require("lib.revive_text")
local twitch = require("main.twitch.twitch")
local vote_option = require("main.twitch.vote_option")
local large_ui = require("lib.large_ui")
local variables = require("campaign.variables")
local h_interludes_show_character = hash("interludes_show_character")
local h_interludes_focus_character = hash("interludes_focus_character")
local h_interludes_hide_character_in_slot = hash("interludes_hide_character_in_slot")
local h_interludes_hide_all_characters = hash("interludes_hide_all_characters")
local h_interludes_set_nametag = hash("interludes_set_nametag")
local h_interludes_show_bubble = hash("interludes_show_bubble")
local h_interludes_hide_bubbles = hash("interludes_hide_bubbles")
local h_interludes_show_choices = hash("interludes_show_choices")
local h_interludes_choice_picked = hash("interludes_choice_picked")
local h_interludes_advance = hash("interludes_advance")
local h_interludes_wait_for_advance = hash("interludes_wait_for_advance")
local h_window_change_size = hash("window_change_size")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_switch_input_method = hash("switch_input_method")
local h_scene_transition_start = hash("scene_transition_start")
local h_update_insanity_question = hash("update_insanity_question")
local h_pause_button_acquire_input_focus = hash("pause_button_acquire_input_focus")
local h_twitch_change_voting_enabled = hash("twitch_change_voting_enabled")
local h_vote_box = hash("vote/box")
local h_vote_votes = hash("vote/votes")
local h_vote_option = hash("vote/option")
local h_click = hash("click")
local h_colorw = hash("color.w")
local h_position = hash("position")
local h_bubble_background = hash("bubble_background")
local h_bubble_foreground = hash("bubble_foreground")
local h_container = hash("container")
local h_choice = hash("choice")
local h_choice_text = hash("choice_text")
local h_choice_glow = hash("choice_glow")
local slot_count = 9
local INTERVIEW = 7
local choice_padding = 20
local large_ui_extra_size_x = 200
local large_ui_y_offset = -90
local large_ui_adjustment_excluded_slots = {
	[9.0] = true,
	[8.0] = true,
	[7.0] = true
}
local vnbad_color = vmath.vector3(0.3, 0.3, 0.3, 1)
local resize_animation, cancel_resize_animation, show_choices, hide_choices = nil
local is_advance_indicator = revive_text.is_advance_indicator
local bounce_advance_indicator = revive_text.bounce_advance_indicator
local revive_insanity = revive_text.revive_insanity

function _env:init()
	self.bubbles = {}
	self.choice_buttons = {}
	self.nametag_texts = {}
	self.nametags = {}
	self.nametag_y_offsets = {}
	self.nametag_x_offsets = {}
	self.current_advance_indicator = nil
	self.waiting_for_advance = false
	self.insanity_active = false

	for slot = 1, slot_count do
		local bubble_node = gui.get_node("bubble_" .. slot)
		local text_node = gui.get_node("text_" .. slot)
		local bubble = Bubble.new(bubble_node, text_node, {
			large_ui_scale = true,
			min_container_size = vmath.vector3(238, 148, 0),
			resize_animation = function (bubble, size, duration)
				resize_animation(self, slot, bubble, size, duration)
			end,
			cancel_resize_animation = function (bubble)
				cancel_resize_animation(self, slot, bubble)
			end,
			rich_fonts = families,
			revive_words = function (words)
				local advance_indicator = nil

				for i, word in ipairs(words) do
					if is_advance_indicator(word) then
						advance_indicator = word.node

						if not self.waiting_for_advance then
							local color = gui.get_color(advance_indicator)
							color.w = 0

							gui.set_color(advance_indicator, color)
						end

						bounce_advance_indicator(advance_indicator)
					end
				end

				self.current_advance_indicator = advance_indicator

				return revive_insanity(words)
			end
		})
		self.bubbles[slot] = bubble
		local bubble_position = gui.get_position(bubble_node)
		bubble.original_position = bubble_position
		bubble.large_ui_position = bubble_position

		if not large_ui_adjustment_excluded_slots[slot] then
			bubble.large_ui_position = vmath.vector3(bubble_position.x, bubble_position.y + large_ui_y_offset, bubble_position.z)
		end

		local nametag_node = gui.get_node("nametag_" .. slot)
		local nametag_text_node = gui.get_node("nt_text_" .. slot)
		local nametag_bubble = Bubble.new(nametag_node, nametag_text_node, {
			default_rich_font = "dialogue",
			large_ui_scale = true,
			rich_fonts = families
		})
		self.nametags[slot] = nametag_bubble
		local nametag_position = gui.get_position(nametag_node)
		self.nametag_y_offsets[slot] = nametag_position.y - bubble.original_container_size.y
		self.nametag_x_offsets[slot] = nametag_position.x

		bubble:hide_bubble(0)
	end

	self.choices_node = gui.get_node("choices")
	self.original_choice_position = gui.get_position(self.choices_node)

	gui.set_enabled(self.choices_node, false)

	self.choice_factory = gui.get_node("choice")
	self.original_choice_size = gui.get_size(self.choice_factory)

	gui.set_enabled(self.choice_factory, false)

	self.go_url = msg.url(".")

	msg.post(self.go_url, h_window_change_size)

	self.focus_giver = FocusGiver.new({
		on_pass_focus = function (focus_giver, nav_action)
			if next(self.choice_buttons) then
				if not nav_action or nav_action == Button.NAVIGATE_DOWN then
					return self.choice_buttons[#self.choice_buttons]:focus()
				elseif nav_action == Button.NAVIGATE_UP then
					return self.choice_buttons[1]:focus()
				end
			end
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_interludes_show_character,
		h_interludes_focus_character,
		h_interludes_hide_character_in_slot,
		h_interludes_hide_all_characters,
		h_interludes_show_bubble,
		h_interludes_hide_bubbles,
		h_interludes_wait_for_advance,
		h_interludes_show_choices,
		h_interludes_advance,
		h_interludes_set_nametag,
		h_window_change_size,
		h_switch_input_method,
		h_scene_transition_start,
		h_twitch_change_voting_enabled
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	twitch.set_voting_options(nil)
end

function resize_animation(self, slot, bubble, size, duration)
	Bubble.default_resize_animation(bubble, size, duration)

	local nametag = self.nametags[slot]
	local nametag_node = nametag.container_node
	local nametag_position = gui.get_position(nametag_node)
	local vertical_offset = bubble.container_size.y + self.nametag_y_offsets[slot]
	local x_pos = self.nametag_x_offsets[slot]
	local new_position = vmath.vector3(x_pos, vertical_offset, nametag_position.z)

	if duration ~= 0 then
		gui.animate(nametag_node, h_position, new_position, gui.EASING_OUTEXPO, duration)
	else
		gui.set_position(nametag_node, new_position)
	end
end

function cancel_resize_animation(self, slot, bubble)
	Bubble.default_cancel_resize_animation(bubble)

	local nametag_node = self.nametags[slot].container_node

	gui.cancel_animation(nametag_node, h_position)
end

local function set_insanity_effects_active(self, active)
	if self.insanity_active == active then
		return
	end

	self.insanity_active = active

	dispatcher.dispatch(h_update_insanity_question, {
		shown = active
	})
end

function hide_choices(self, relayout)
	self.choices_shown = false
	local choices_node = self.choices_node

	msg.post(self.go_url, h_release_input_focus)
	twitch.set_voting_options(nil)

	local function on_animation_end()
		gui.set_enabled(choices_node, false)

		for i, button in ipairs(self.choice_buttons) do
			button:cancel_focus()
			gui.delete_node(button.node)
		end

		self.choice_buttons = {}

		if not relayout then
			local pending_choices = self.pending_choices

			if pending_choices then
				self.pending_choices = nil

				show_choices(self, pending_choices)
			end
		end
	end

	gui.cancel_animation(choices_node, h_colorw)

	if relayout then
		gui.set_color(choices_node, vmath.vector4(1, 1, 1, 0))
		on_animation_end()
	else
		gui.animate(choices_node, h_colorw, 0, gui.EASING_LINEAR, 0.3, 0, on_animation_end)
	end

	set_insanity_effects_active(self, false)
end

local function update_votes(self)
	local votes = twitch.get_votes()

	for _, button in ipairs(self.choice_buttons) do
		local voting_letter = button.voting_letter

		if voting_letter then
			vote_option.set_votes(button.vote_votes_node, votes[voting_letter])
		end
	end
end

local function set_voting_timer(self, enabled)
	if enabled and not self.voting_timer then
		self.voting_timer = timer.delay(0, true, update_votes)
	elseif not enabled and self.voting_timer then
		timer.cancel(self.voting_timer)

		self.voting_timer = nil
	end
end

function show_choices(self, choices, relayout)
	local choices_node = self.choices_node

	if gui.is_enabled(choices_node) then
		self.pending_choices = choices

		return
	end

	self.choices_shown = choices

	msg.post(self.go_url, h_acquire_input_focus)
	dispatcher.dispatch(h_pause_button_acquire_input_focus)
	gui.set_enabled(choices_node, true)
	gui.cancel_animation(choices_node, h_colorw)

	if relayout then
		gui.set_color(choices_node, vmath.vector4(1, 1, 1, 1))
	else
		gui.set_color(choices_node, vmath.vector4(1, 1, 1, 0))
		gui.animate(choices_node, h_colorw, 1, gui.EASING_LINEAR, 0.3)
	end

	local has_insane_choice = false
	local voting_options = {}
	local max_choice = 0
	local choice_count = 0

	for i, _ in pairs(choices) do
		if max_choice < i then
			max_choice = i
			choice_count = choice_count + 1
			voting_options[twitch.get_voting_letter(choice_count)] = choice_count
		end
	end

	if not relayout then
		twitch.set_voting_options(voting_options)
	end

	local votes = twitch.get_votes()
	local voting_enabled = twitch.is_voting_enabled()
	local is_interview = false

	for i, slot in pairs(slots.slot_of_char) do
		if slot == INTERVIEW then
			is_interview = true

			break
		end
	end

	local pos_y = 0

	for i = max_choice, 1, -1 do
		local choice = choices[i]

		if choice then
			local nodes = gui.clone_tree(self.choice_factory)
			local choice_node = nodes[h_choice]
			local choice_text_node = nodes[h_choice_text]
			local choice_glow = nodes[h_choice_glow]
			local vote_box_node = nodes[h_vote_box]
			local vote_option_node = nodes[h_vote_option]
			local vote_votes_node = nodes[h_vote_votes]

			gui.set_enabled(choice_node, true)
			gui.set_parent(choice_node, choices_node)
			gui.set_position(choice_node, vmath.vector3(0, pos_y, 0))

			local choice_size = gui.get_size(choice_node)
			local text_size = gui.get_size(choice_text_node)
			local text_scale = gui.get_scale(choice_text_node)

			if is_interview and large_ui.enabled then
				choice_size.x = choice_size.x + large_ui_extra_size_x
				text_size.x = text_size.x + large_ui_extra_size_x * 1 / text_scale.x
				local vote_position = gui.get_position(vote_box_node)
				vote_position.x = vote_position.x - large_ui_extra_size_x

				gui.set_size(choice_text_node, text_size)
				gui.set_size(choice_node, choice_size)
			end

			local original_glow_size = gui.get_size(choice_glow)
			local bubble = Bubble.new(choice_node, choice_text_node, {
				large_ui_scale = true,
				min_container_size = choice_size,
				rich_fonts = families,
				revive_words = function (words)
					words = revive_text.revive_words(words)

					if variables.vn then
						for i, word in ipairs(words) do
							if word.tags and word.tags.vnbad and word.text then
								gui.set_color(word.node, vnbad_color)
								gui.set_outline(word.node, vnbad_color)
							end
						end
					end

					return words
				end
			})

			bubble:set_text(choice, true)

			if not has_insane_choice then
				for _, word in ipairs(bubble.words) do
					if word.tags and (word.tags.insanity or word.tags.batshit) then
						has_insane_choice = true

						break
					end
				end
			end

			local new_choice_size = gui.get_size(choice_node)
			local size_delta = new_choice_size - self.original_choice_size
			local new_glow_size = original_glow_size + size_delta

			gui.set_size(choice_glow, new_glow_size)

			local height = bubble.container_size.y
			pos_y = pos_y + height + choice_padding
			local choice_hover_event = fmod and fmod.studio.system:get_event("event:/Campaign/Interludes Hover")
			local button_index = #self.choice_buttons + 1
			local choice_index = choice_count - button_index + 1
			local voting_letter = twitch.get_voting_letter(choice_index)

			if voting_letter then
				gui.set_text(vote_option_node, voting_letter)
				vote_option.set_votes(vote_votes_node, votes[voting_letter])
				vote_option.set_enabled(vote_box_node, voting_enabled, true)
			else
				vote_option.set_enabled(vote_box_node, false, true)
			end

			self.choice_buttons[button_index] = Button.new(choice_node, {
				keyboard_focus = true,
				gamepad_focus = true,
				on_state_change = button_sound.with_sound({
					press = false,
					release = false,
					hover = choice_hover_event
				}),
				on_pass_focus = function (button, nav_action)
					if nav_action == Button.NAVIGATE_DOWN and button_index > 1 then
						return self.choice_buttons[button_index - 1]:focus()
					elseif nav_action == Button.NAVIGATE_UP and button_index < #self.choice_buttons then
						return self.choice_buttons[button_index + 1]:focus()
					end
				end,
				on_focus_change = button_sound.with_focus_sound({
					focus = choice_hover_event
				}),
				focus_node = choice_glow,
				action = function ()
					hide_choices(self)
					dispatcher.dispatch(h_interludes_choice_picked, {
						choice = i
					})
				end,
				vote_votes_node = vote_votes_node,
				vote_box_node = vote_box_node,
				voting_letter = voting_letter
			})
		end
	end

	set_voting_timer(self, voting_enabled)
	self.focus_giver:try_focus_first()

	local choice_position = self.original_choice_position

	if pos_y < 400 then
		choice_position = choice_position + vmath.vector3(0, 25, 0)
	end

	if is_interview then
		choice_position = self.original_choice_position + vmath.vector3(350, 25, 0)
	end

	gui.set_position(choices_node, choice_position)
	set_insanity_effects_active(self, has_insane_choice)
end

local function append_advance_caret(text)
	if not text then
		return text
	end

	return text .. "<nobr> <img=interludes:advance/></nobr>"
end

local function set_advance_indicator_shown(self, shown)
	local node = self.current_advance_indicator

	if not node then
		return
	end

	local target = shown and 1 or 0

	gui.cancel_animation(node, h_colorw)
	gui.animate(node, h_colorw, target, go.EASING_LINEAR, 0.3)
end

local function update_bubble_position(bubble, slot)
	local position = large_ui.enabled and not slots.large_ui_fixed[slot] and bubble.large_ui_position or bubble.original_position

	gui.set_position(bubble.container_node, position)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_interludes_focus_character then
		local focused_slot = message.slot

		for slot = 1, slot_count do
			local bubble_node = gui.get_node("bubble_" .. slot)

			if not focused_slot or slot == focused_slot then
				gui.set_layer(bubble_node, h_bubble_foreground)
			else
				gui.set_layer(bubble_node, h_bubble_background)
			end
		end
	elseif message_id == h_interludes_show_character then
		local character = hash(message.character)
		local nametag = self.nametag_texts[character]
		local message_nametag = message.options.nametag

		if message_nametag ~= nil then
			nametag = message_nametag
		end

		if nametag == nil then
			nametag = message.character:gsub("^%l", string.upper)
		end

		if not message.options.nametag_unstyled then
			nametag = "<b>" .. nametag .. "</b>"
		end

		self.nametag_texts[character] = nametag
	elseif message_id == h_interludes_set_nametag then
		local nametag = message.nametag

		if not message.unstyled then
			nametag = "<b>" .. nametag .. "</b>"
		end

		self.nametag_texts[hash(message.character)] = nametag
	elseif message_id == h_interludes_hide_character_in_slot then
		self.bubbles[message.slot]:hide_bubble()
	elseif message_id == h_interludes_hide_all_characters then
		for i, bubble in pairs(self.bubbles) do
			bubble:hide_bubble()
		end
	elseif message_id == h_interludes_show_bubble then
		local character = hash(message.character)
		local slot = slots.slot_of_char[character]

		if not slot then
			error("interludes_show_bubble: Character not shown: " .. character)
		end

		local text_bubble = self.bubbles[slot]

		update_bubble_position(text_bubble, slot)

		local nametag_text = self.nametag_texts[character]
		local nametag = self.nametags[slot]

		if nametag_text == "" then
			nametag_text = nil
		end

		local bubble_delay = 0.3

		if text_bubble.container_size.x == 0 then
			if nametag_text then
				nametag:set_text(nametag_text, true)
			else
				nametag:hide_bubble(0)
			end
		elseif nametag_text ~= nametag.text then
			nametag:display_bubble(nametag_text, true, 0.3)

			bubble_delay = 0.6
		end

		nametag.text = nametag_text

		text_bubble:display_bubble(append_advance_caret(message.text), true, bubble_delay)

		for bubble_slot, bubble in ipairs(self.bubbles) do
			if bubble_slot ~= slot then
				bubble:hide_bubble()
			end
		end
	elseif message_id == h_interludes_hide_bubbles then
		for i, bubble in pairs(self.bubbles) do
			bubble:hide_bubble()
		end
	elseif message_id == h_interludes_wait_for_advance then
		msg.post(self.go_url, h_acquire_input_focus)
		dispatcher.dispatch(h_pause_button_acquire_input_focus)

		self.waiting_for_advance = true

		set_advance_indicator_shown(self, true)
	elseif message_id == h_interludes_advance then
		msg.post(self.go_url, h_release_input_focus)

		self.waiting_for_advance = false

		set_advance_indicator_shown(self, false)
	elseif message_id == h_interludes_show_choices then
		show_choices(self, message.choices)
	elseif message_id == h_window_change_size then
		local container_node = gui.get_node(h_container)
		local scale = Layout.viewport_width / Layout.design_width
		local y = math.max(0, (Layout.viewport_height - Layout.viewport_width * 0.625) * 0.5)

		gui.set_scale(container_node, vmath.vector3(scale, scale, 1))
		gui.set_position(container_node, vmath.vector3(0, y, 0))

		if not message.large_ui_unchanged then
			for slot = 1, slot_count do
				local bubble = self.bubbles[slot]

				update_bubble_position(bubble, slot)
				self.nametags[slot]:layout()
				bubble:layout()
			end

			local choices = self.choices_shown

			if choices then
				hide_choices(self, true)
				show_choices(self, choices, true)
			end
		end
	elseif message_id == h_switch_input_method then
		for i, button in ipairs(self.choice_buttons) do
			button:switch_input_method()
		end

		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_scene_transition_start then
		set_insanity_effects_active(self, false)
	elseif message_id == h_twitch_change_voting_enabled then
		local enabled = twitch.is_voting_enabled()

		for _, button in ipairs(self.choice_buttons) do
			local voting_letter = button.voting_letter

			if voting_letter then
				vote_option.set_enabled(button.vote_box_node, enabled)
			end
		end

		set_voting_timer(self, enabled)
	end
end

function _env:on_input(action_id, action)
	if self.choices_shown then
		for i, button in ipairs(self.choice_buttons) do
			if button:on_input(action_id, action) then
				return true
			end
		end
	elseif action_id == h_click and action.released or Button.action_id_to_navigation_action(action_id) == Button.NAVIGATE_CONFIRM and action.pressed then
		dispatcher.dispatch(h_interludes_advance)
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end
end
