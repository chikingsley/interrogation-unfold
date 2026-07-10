local Layout = require("crit.layout")
local store = require("level.store")
local state = require("level.state")
local Button = require("crit.button")
local FocusGiver = require("crit.focus_giver")
local Scroll = require("crit.scroll")
local ScrollBar = require("crit.scrollbar")
local dispatcher = require("crit.dispatcher")
local Bubble = require("lib.bubble")
local richtext = require("richtext.richtext")
local families = require("main.fonts.families")
local button_sound = require("sound.button")
local shaky_text = require("lib.shaky_text")
local revive_text = require("lib.revive_text")
local caret = require("lib.caret")
local font_layers = require("main.fonts.layers")
local twitch = require("main.twitch.twitch")
local vote_option = require("main.twitch.vote_option")
local large_ui = require("lib.large_ui")
local h_table_set_position = hash("table_set_position")
local h_window_change_size = hash("window_change_size")
local h_set_subject = hash("set_subject")
local h_ask_question = hash("ask_question")
local h_start_game = hash("start_game")
local h_torture = hash("torture")
local h_colorw = hash("color.w")
local h_play_sfx = hash("play_sfx")
local h_color = hash("color")
local h_size_y = hash("size.y")
local h_position = hash("position")
local h_question_factory = hash("question_factory")
local h_text_factory = hash("text_factory")
local h_separator_factory = hash("separator_factory")
local h_vote_box_factory = hash("vote/box")
local h_vote_votes_factory = hash("vote/votes")
local h_vote_option_factory = hash("vote/option")
local h_back_factory = hash("back_factory")
local h_level_refresh_questions = hash("level_refresh_questions")
local h_level_disable_controls = hash("level_disable_controls")
local h_level_enable_controls = hash("level_enable_controls")
local h_first_question = hash("first_question")
local h_level_highlight = hash("level_highlight")
local h_level_highlight_cancel = hash("level_highlight_cancel")
local h_update_insanity_question = hash("update_insanity_question")
local h_dialogue = hash("dialogue")
local h_switch_input_method = hash("switch_input_method")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_level_hints_is_visible = hash("level_hints_is_visible")
local h_key_backspace = hash("key_backspace")
local h_init_level_lite = hash("init_level_lite")
local h_init_level = hash("init_level")
local h_twitch_change_voting_enabled = hash("twitch_change_voting_enabled")
local h_level_question_bubble_clearance = hash("level_question_bubble_clearance")
local top_layers = font_layers.prefix_layers("top_")
local design_width = Layout.design_width
local design_height = Layout.design_height
local question_padding_bottom = 200
local update_scrollbar_shown = nil
local v3one = vmath.vector3(1)
local yellow = vmath.vector4(1, 1, 0, 1)
local white = vmath.vector4(1, 1, 1, 1)
local red = vmath.vector4(1, 0.1, 0.1, 1)
local separators = {
	hash("separator1"),
	hash("separator2"),
	hash("separator3")
}

local function on_window_change_size(self)
	local scale = Layout.viewport_width / design_width
	local height = Layout.viewport_height / scale
	local view_height = height
	local padding_bottom = question_padding_bottom

	if self.hints_visible then
		view_height = height - question_padding_bottom
		padding_bottom = 0
	end

	self.scroll:set_view_height(view_height)
	self.scroll:set_padding_bottom(padding_bottom)

	local size_diff = vmath.vector3(0, height - design_height, 0)

	gui.set_size(self.scrollbar_axis, self.scrollbar_axis_size + size_diff)
	self.scrollbar:set_metrics(self.scrollbar.top, vmath.vector3(self.scrollbar_size.x, self.scrollbar_axis_size.y + size_diff.y - 2 * self.margin, 0))
	gui.set_position(self.panel, vmath.vector3(self.panel_offset * scale, Layout.viewport_height, 0))
	gui.set_size(self.panel, vmath.vector3(self.panel_width, height, 0))

	local new_question_bottom_mask_pos = vmath.vector3(self.question_bottom_mask_pos.x, -height, self.question_bottom_mask_pos.z)

	gui.set_position(self.question_bottom_mask, new_question_bottom_mask_pos)
	gui.set_scale(self.panel, vmath.vector3(scale))
	gui.set_render_order(4)
	update_scrollbar_shown(self)
end

function _env:init()
	local panel = gui.get_node("panel")
	self.panel = panel
	self.question_boxes = {}
	self.right_aligned = false
	self.questions_container = gui.get_node("questions_container")
	self.question_bubble_mask = gui.get_node("question_bubble_mask")
	self.question_bottom_mask = gui.get_node("question_bottom_mask")
	local text_factory = gui.get_node("text_factory")
	local separator_factory = gui.get_node("separator_factory")
	local question_factory = gui.get_node("question_factory")
	local back_factory = gui.get_node("back_factory")
	self.question_factory = question_factory
	self.panel_width = gui.get_size(panel).x
	self.question_text_pos = gui.get_position(text_factory)
	self.question_text_scale = gui.get_scale(text_factory).y
	self.question_text_size = gui.get_size(text_factory)
	self.question_mask_size = gui.get_size(self.question_bubble_mask)
	self.question_bottom_mask_pos = gui.get_position(self.question_bottom_mask)
	self.question_height = self.question_text_size.y * self.question_text_scale
	self.question_vertical_padding = self.question_height - 84
	local question_pos = gui.get_position(question_factory)
	self.question_padding_top = -question_pos.y - self.question_height * 0.5
	self.question_separator_x = gui.get_position(separator_factory).x
	self.back_offset = gui.get_position(back_factory) - self.question_text_pos + vmath.vector3(self.question_text_size.x * self.question_text_scale * 0.5, 0, 0)
	self.back_x_center_offset = (-self.back_offset.x + gui.get_size(back_factory).x * gui.get_scale(back_factory).x * 0.5) * 0.5

	gui.set_text(text_factory, "")

	self.scroll = Scroll.new({
		padding_bottom = question_padding_bottom,
		pick = function (action)
			return Layout.pick_node(panel, action)
		end,
		on_capture_touch = function ()
			for i, box in ipairs(self.question_boxes) do
				box.button:cancel_touch()
			end
		end
	})

	self.scroll:add_node(gui.get_node("questions_container"), vmath.vector3(0))
	gui.set_enabled(question_factory, false)

	local scrollbar_axis = gui.get_node("scrollbar_axis")
	local scrollbar_node = gui.get_node("scrollbar")
	self.scrollbar_axis = scrollbar_axis
	self.scrollbar_size = gui.get_size(scrollbar_node)
	self.scrollbar_axis_size = gui.get_size(scrollbar_axis)
	self.margin = gui.get_position(scrollbar_axis).y - gui.get_position(scrollbar_node).y
	self.scrollbar = ScrollBar.new(self.scroll, scrollbar_node, {
		knob = true
	})

	gui.set_color(scrollbar_node, vmath.vector4(0, 0, 0, 1))
	gui.set_color(scrollbar_axis, vmath.vector4(1, 1, 1, 0))

	self.previous_questions = {}
	self.previously_asked_text = nil
	local question_node = gui.get_node("question")
	self.question_bubble = Bubble.new(gui.get_node("question_bubble"), question_node, {
		large_ui_scale = true,
		min_container_size = vmath.vector3(280, 125, 0),
		rich_fonts = families,
		layers = {
			fonts = top_layers
		},
		revive_words = revive_text.revive_words
	})
	self.question_padding_top = self.question_padding_top - (self.question_bubble.original_container_size * self.question_bubble.original_container_scale).y
	self.top_padding = 0
	self.panel_offset = 0

	gui.set_scale(self.question_bubble.container_node, vmath.vector3(0))

	self.question_bubble_y = gui.get_position(self.question_bubble.container_node).y
	self.focus_caret = gui.get_node("focus_caret")

	caret.hide_instantly(self.focus_caret)

	self.focus_giver = FocusGiver.new({
		on_pass_focus = function (focus_giver, nav_action)
			local question_boxes = self.question_boxes
			local index = nil

			if nav_action == Button.NAVIGATE_UP then
				index = #question_boxes
			elseif not nav_action or nav_action == Button.NAVIGATE_DOWN then
				index = 1
			else
				return false
			end

			local box = question_boxes[index]

			if not box then
				return false
			end

			return box.button:focus()
		end
	})
	self.hints_visible = false
	self.hover_question_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Question")

	twitch.set_voting_options(nil)

	self.sub_id = dispatcher.subscribe({
		h_set_subject,
		h_ask_question,
		h_start_game,
		h_torture,
		h_table_set_position,
		h_window_change_size,
		h_level_refresh_questions,
		h_level_disable_controls,
		h_level_enable_controls,
		h_level_highlight,
		h_level_highlight_cancel,
		h_level_hints_is_visible,
		h_switch_input_method,
		h_init_level_lite,
		h_init_level,
		h_twitch_change_voting_enabled
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	twitch.set_voting_options(nil)
end

local function easing_out_cubic(t)
	t = t - 1

	return 1 + t * t * t
end

function update_scrollbar_shown(self, scroll_down, content_height)
	content_height = content_height or self.scroll.content_height
	local scroll_shown_old = self.scroll_shown
	local scroll_shown = self.scroll.view_height < content_height

	if scroll_shown ~= scroll_shown_old then
		self.scroll_shown = scroll_shown
		local to = scroll_shown and 1 or 0
		local delay = scroll_down and 0.3 or 0

		gui.animate(self.scrollbar.node, h_color, vmath.vector4(to, to, to, 1), gui.EASING_LINEAR, 0.3, delay)
		gui.animate(self.scrollbar_axis, h_colorw, to, gui.EASING_LINEAR, 0.3, delay)
	end
end

local function remove_question_box(self, question_box, delay)
	question_box.button:cancel_focus()
	gui.animate(question_box.parent_node, h_colorw, 0, gui.EASING_LINEAR, 0.3, delay or 0, function ()
		gui.delete_node(question_box.text_node)
		gui.delete_node(question_box.separator_node)
		gui.delete_node(question_box.parent_node)
	end)
end

local function questions_iterator(questions)
	return coroutine.wrap(function ()
		if not questions then
			return
		end

		local regular_questions = questions.regular
		local regular_n = #regular_questions
		local exit_questions = questions.exit
		local exit_n = #exit_questions
		local back_questions = questions.back
		local back_n = #back_questions

		for i = 1, regular_n do
			local question = regular_questions[i]

			coroutine.yield(i, question, not not question.back_icon)
		end

		for i = 1, exit_n do
			coroutine.yield(i + regular_n, exit_questions[i], false)
		end

		for i = 1, back_n do
			local question = back_questions[i]

			coroutine.yield(i + regular_n + exit_n, back_questions[i], not not question.back_icon)
		end

		local auto_back_question = questions.auto_back_question

		if auto_back_question then
			coroutine.yield(regular_n + exit_n + back_n + 1, auto_back_question, true)
		end
	end)
end

local function on_question_focus_change(self, box, focused, dont_scroll)
	local focus_caret = self.focus_caret
	local index = box.index

	if focused then
		self.focused_button_index = index
		local pos_y = box.position.y
		local caret_pos_y = pos_y

		if box.voting_letter and twitch.is_voting_enabled() then
			caret_pos_y = caret_pos_y - 25
		end

		caret.move_to(focus_caret, nil, caret_pos_y)

		if not dont_scroll then
			local scroll = self.scroll
			local top_padding = self.top_padding
			local height = box.height
			local top_visible = top_padding - (pos_y + height)
			local bottom_visible = -(pos_y - height)
			local new_offset = scroll:nearest_offset_covering_range(top_visible, bottom_visible)

			scroll:animate_offset(new_offset, 0.3, easing_out_cubic)
		end
	elseif self.focused_button_index == index then
		caret.hide(focus_caret)
	end
end

local function populate_questions(self, reset)
	local has_won = state.phase == state.PHASE_OVER and state.has_won

	if not has_won and state.phase ~= state.PHASE_RUNNING then
		return
	end

	if self.scroll_timer then
		timer.cancel(self.scroll_timer)
	end

	local subject_id = state.current_subject
	local question_bubble = self.question_bubble
	local old_questions = self.questions
	local questions = not has_won and store.get_visible_questions(subject_id)
	self.questions = questions
	local asked_text = self.previous_questions[subject_id]

	question_bubble:display_bubble(not reset and asked_text and asked_text == self.previously_asked_text and Bubble.KEEP_TEXT or asked_text, true)

	self.previously_asked_text = asked_text

	dispatcher.dispatch(h_level_question_bubble_clearance, {
		pos_y = self.question_bubble_y - question_bubble.container_size.y - 50
	})

	local question_bubble_size_diff = question_bubble.container_size - question_bubble.original_container_size
	local new_question_mask_size = vmath.vector3(self.question_mask_size.x, self.question_mask_size.y + question_bubble_size_diff.y, self.question_mask_size.z)

	gui.cancel_animation(self.question_bubble_mask, h_size_y)
	gui.animate(self.question_bubble_mask, h_size_y, new_question_mask_size, gui.EASING_OUTEXPO, 0.2, 0.3)

	local twitch_voting_options = {}
	local twitch_voting_letters = {}
	self.twitch_voting_options = twitch_voting_options
	local question_set = {}

	for index, question in questions_iterator(questions) do
		local question_id = question.id
		question_set[question_id] = true
		local letter = twitch.get_voting_letter(index)

		if letter then
			twitch_voting_options[letter] = question_id
			twitch_voting_letters[question_id] = letter
		end
	end

	twitch.set_voting_options(next(twitch_voting_options) and twitch_voting_options or nil)

	local votes = twitch.get_votes()
	local remove_questions = old_questions ~= questions or reset
	local old_question_set = {}

	if remove_questions then
		for index, question_box in ipairs(self.question_boxes) do
			remove_question_box(self, question_box)
		end
	else
		for index, question_box in ipairs(self.question_boxes) do
			local id = question_box.id
			old_question_set[id] = question_box

			if not question_set[id] then
				remove_question_box(self, question_box)
			end
		end
	end

	local question_boxes = {}
	self.question_boxes = question_boxes
	local pos_y = -(question_bubble.container_size * question_bubble.original_container_scale).y - self.question_padding_top
	local animate_padding = self.scroll.offset == 0 or remove_questions
	local top_padding_diff = self.top_padding - pos_y
	local top_padding = pos_y
	self.top_padding = top_padding
	local stagger_index = 0
	local scroll_down = false
	local insanity_question_shown = false

	for index, question, is_back_question in questions_iterator(questions) do
		local box = old_question_set[question.id]
		local height = nil

		if index > 1 then
			local last_box = question_boxes[index - 1]

			if not last_box.new then
				local separator_node = last_box.separator_node

				gui.set_enabled(separator_node, true)
				gui.cancel_animation(separator_node, h_colorw)
				gui.animate(separator_node, h_colorw, 1, gui.EASING_LINEAR, 0.3)
			end
		end

		if question.insanity or question.batshit then
			insanity_question_shown = true
		end

		local parent, text, separator, back_icon, vote_box_node, vote_option_node, vote_votes_node = nil

		if not box then
			stagger_index = stagger_index + 1
			local tree = gui.clone_tree(self.question_factory)
			parent = tree[h_question_factory]
			text = tree[h_text_factory]
			separator = tree[h_separator_factory]
			back_icon = tree[h_back_factory]
			vote_box_node = tree[h_vote_box_factory]
			vote_option_node = tree[h_vote_option_factory]
			vote_votes_node = tree[h_vote_votes_factory]

			large_ui.adjust_text_node(text)
			gui.set_enabled(parent, true)

			local button = Button.new(text, {
				gamepad_focus = true,
				padding_left = 0,
				keyboard_focus = true,
				on_state_change = button_sound.with_sound({
					press = false,
					release = false,
					hover = self.hover_question_event
				}),
				faded_nodes = {
					text,
					back_icon
				},
				action = function ()
					if state.phase ~= state.PHASE_RUNNING or store.subjects[state.current_subject].health <= 0 then
						return
					end

					dispatcher.dispatch(h_play_sfx, {
						sfx = "ask_question"
					})
					dispatcher.dispatch(h_ask_question, {
						question_id = question.id
					})
				end,
				on_pass_focus = function (button, nav_action)
					local index_ = box.index
					local question_boxes_ = self.question_boxes

					if nav_action == Button.NAVIGATE_DOWN and index_ < #question_boxes_ then
						index_ = index_ + 1
					elseif nav_action == Button.NAVIGATE_UP and index_ > 1 then
						index_ = index_ - 1
					else
						return false
					end

					return question_boxes_[index_].button:focus()
				end,
				on_focus_change = button_sound.with_focus_sound({
					focus = self.hover_question_event
				}, function (button, focused)
					on_question_focus_change(self, box, focused)
				end),
				shortcut_actions = is_back_question and {
					h_gamepad_rpad_right,
					h_key_backspace
				} or nil
			})

			gui.play_flipbook(separator, separators[index % 3 + 1])

			local delay = 0.2 + 0.05 * stagger_index

			gui.set_color(parent, vmath.vector4(1, 1, 1, 0))
			gui.animate(parent, h_colorw, 1, gui.EASING_LINEAR, 0.3, delay)

			box = {
				height = 0,
				new = true,
				id = question.id,
				pos_y = pos_y - top_padding,
				parent_node = parent,
				text_node = text,
				separator_node = separator,
				button = button,
				back_icon_node = back_icon,
				vote_box_node = vote_box_node,
				vote_option_node = vote_option_node,
				vote_votes_node = vote_votes_node
			}
		else
			parent = box.parent_node
			text = box.text_node
			separator = box.separator_node
			back_icon = box.back_icon_node
			vote_box_node = box.vote_box_node
			vote_option_node = box.vote_option_node
			vote_votes_node = box.vote_votes_node
			box.new = false
		end

		height = box.height
		local voting_letter = twitch_voting_letters[question.id]
		box.voting_letter = voting_letter

		if voting_letter then
			gui.set_text(vote_option_node, voting_letter)
			vote_option.set_votes(vote_votes_node, votes[voting_letter])
			vote_option.set_enabled(vote_box_node, twitch.is_voting_enabled(), box.new)
		else
			vote_option.set_enabled(vote_box_node, false, box.new)
		end

		local color = question.exit_question and red or question.new_indicated and yellow or white
		local question_text = store.t(store.get_question_text(question, subject_id))

		if box.text ~= question_text then
			box.text = question_text
			local align_node = box.text_align_node

			if align_node then
				gui.delete_node(align_node)
			end

			align_node = gui.clone(text)

			gui.set_color(align_node, white)

			box.text_align_node = align_node

			gui.set_scale(align_node, v3one)

			local ui_scale = large_ui.enabled and large_ui.default_text_scale or 1
			local text_width = self.question_text_size.x / ui_scale
			local words, metrics = revive_text.richtext_safe_create(question_text, "dialogue", {
				combine_words = true,
				fonts = {
					dialogue = {
						regular = h_dialogue
					}
				},
				width = text_width,
				parent = align_node,
				align = richtext.ALIGN_CENTER,
				layers = {
					fonts = font_layers.layers
				},
				color = color
			})
			local characters = {}

			if question.insanity or question.batshit then
				for i, word in ipairs(words) do
					gui.delete_node(word.node)

					local char_table = richtext.characters(word)

					for j, char in ipairs(char_table) do
						table.insert(characters, char)
					end
				end

				words = characters
				local shaky_nodes = {}

				for i, word in pairs(words) do
					shaky_nodes[i] = word.node
				end

				shaky_text.shake_nodes(shaky_nodes, question.batshit)
			end

			box.words = words

			gui.set_parent(align_node, text)
			gui.set_position(align_node, vmath.vector3(0, metrics.height * 0.5, 0))

			height = self.question_height
			local total_scale = self.question_text_scale * ui_scale
			local text_height = metrics.height * total_scale
			local total_height = text_height + self.question_vertical_padding

			if height < total_height then
				height = total_height
			end

			box.height = height

			gui.set_size(text, vmath.vector3(text_width, height / total_scale, 0))
			gui.set_position(separator, vmath.vector3(self.question_separator_x, -height * 0.5, 0))
			gui.set_enabled(back_icon, is_back_question)

			local text_pos = self.question_text_pos

			if is_back_question then
				text_pos = text_pos + vmath.vector3(self.back_x_center_offset, 0, 0)

				gui.set_position(back_icon, self.back_offset + text_pos - vmath.vector3(metrics.width * total_scale * 0.5, 0, 0))
			end

			gui.set_position(text, text_pos)
		else
			for i, word in ipairs(box.words) do
				if not word.tags or not word.tags.color then
					word.color = color

					gui.set_color(word.node, color)
					gui.set_outline(word.node, color)
				end
			end
		end

		local position = vmath.vector3(0, pos_y - height * 0.5, 0)
		box.position = position

		if not box.new then
			if not animate_padding then
				local pos = gui.get_position(parent)
				local old_position = vmath.vector3(pos.x, pos.y - top_padding_diff, pos.z)

				gui.set_position(parent, old_position)
			end

			gui.cancel_animation(parent, h_position)
			gui.animate(parent, h_position, position, gui.EASING_OUTQUART, 0.3)

			if box.button.focused then
				on_question_focus_change(self, box, true, true)
			end
		else
			gui.set_position(parent, position)
		end

		pos_y = pos_y - height
		box.index = index
		question_boxes[index] = box
		scroll_down = scroll_down or question.new and not question.new_unseen
	end

	self.focus_giver.allow_keyboard_empty_focus = #question_boxes ~= 1

	self.focus_giver:try_focus_first()

	if store.insanity_question_shown ~= insanity_question_shown then
		dispatcher.dispatch(h_update_insanity_question, {
			shown = insanity_question_shown
		})
	end

	local last_box = question_boxes[#question_boxes]

	if last_box then
		local separator_node = last_box.separator_node

		if last_box.new then
			gui.set_enabled(separator_node, false)
		elseif gui.is_enabled(separator_node) then
			gui.cancel_animation(separator_node, h_colorw)
			gui.animate(separator_node, h_colorw, 0, gui.EASING_LINEAR, 0.3, 0, function ()
				gui.set_enabled(separator_node, false)
			end)
		end
	end

	local content_height = -pos_y
	local old_offset = self.scroll.offset

	self.scroll:acquire_control()

	if remove_questions then
		timer.delay(0.3, false, function ()
			self.scroll:set_content_height(content_height)
			self.scroll:set_offset(0)
		end)
	else
		self.scroll:set_content_height(content_height)
	end

	if not animate_padding then
		self.scroll:set_offset(old_offset + top_padding_diff)
	end

	if remove_questions then
		timer.delay(0.3, false, function ()
			self.scroll:set_offset(0)
		end)
	end

	if scroll_down then
		if remove_questions then
			self.scroll_timer = timer.delay(0.6, false, function ()
				self.scroll_timer = nil

				self.scroll:animate_offset(content_height, 2, easing_out_cubic)
			end)
		else
			self.scroll:animate_offset(content_height, 2, easing_out_cubic)
		end
	end

	update_scrollbar_shown(self, scroll_down, content_height)
end

function _env:update(dt)
	self.scroll:update(dt)

	if twitch.is_voting_enabled() then
		local votes = twitch.get_votes()

		for i, box in ipairs(self.question_boxes) do
			local voting_letter = box.voting_letter

			if voting_letter then
				vote_option.set_votes(box.vote_votes_node, votes[voting_letter])
			end
		end
	end
end

local function set_position(self)
	self.panel_offset = self.right_aligned and design_width - self.panel_width * state.offset or self.panel_width * (state.offset - 1)
	local scale = Layout.viewport_width / design_width

	gui.set_position(self.panel, vmath.vector3(self.panel_offset * scale, Layout.viewport_height, 0))
end

function _env:on_message(message_id, message, sender)
	if message_id == h_table_set_position then
		set_position(self)
	elseif message_id == h_window_change_size then
		on_window_change_size(self)

		if not message.large_ui_unchanged then
			populate_questions(self, true)
		end
	elseif message_id == h_switch_input_method then
		for i, box in ipairs(self.question_boxes) do
			box.button:switch_input_method()
		end

		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_ask_question then
		local text = store.t(store.get_question_text_by_alt_id(message.question_id, message.alt_text_id))

		if text == "" then
			text = nil
		end

		self.previous_questions[state.current_subject] = text

		populate_questions(self)
	elseif message_id == h_torture then
		self.previous_questions[state.current_subject] = nil

		populate_questions(self)
	elseif message_id == h_set_subject or message_id == h_start_game or message_id == h_level_refresh_questions then
		populate_questions(self)
	elseif message_id == h_level_disable_controls then
		local node = self.questions_container

		gui.cancel_animation(node, h_colorw)
		gui.animate(node, h_colorw, 0.5, gui.EASING_LINEAR, 0.3)
	elseif message_id == h_level_enable_controls then
		local node = self.questions_container

		gui.cancel_animation(node, h_colorw)
		gui.animate(node, h_colorw, 1, gui.EASING_LINEAR, 0.3)
	elseif message_id == h_level_highlight then
		if message.object == h_first_question then
			local question = self.question_boxes[1]

			if not question then
				return
			end

			local node = question.text_align_node
			question.highlighted = true

			gui.cancel_animation(node, h_colorw)
			gui.animate(node, h_colorw, 0.2, gui.EASING_INOUTQUAD, 0.7, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		end
	elseif message_id == h_level_highlight_cancel then
		local question = self.question_boxes[1]

		if not question or not question.highlighted then
			return
		end

		local node = question.text_align_node
		question.highlighted = false

		gui.cancel_animation(node, h_colorw)
		gui.animate(node, h_colorw, 1, gui.EASING_LINEAR, 0.3)
	elseif message_id == h_level_hints_is_visible then
		self.hints_visible = message.visible

		on_window_change_size(self)
	elseif message_id == h_init_level_lite then
		self.right_aligned = true
	elseif message_id == h_init_level then
		set_position(self)
		on_window_change_size(self)
	elseif message_id == h_twitch_change_voting_enabled then
		local enabled = twitch.is_voting_enabled()

		for i, box in ipairs(self.question_boxes) do
			if box.voting_letter then
				vote_option.set_enabled(box.vote_box_node, enabled)
			end
		end
	end
end

function _env:on_input(action_id, action)
	if self.scrollbar:on_input(action_id, action) then
		return true
	end

	if self.scroll:on_input(action_id, action) then
		return true
	end

	for i, box in ipairs(self.question_boxes) do
		if box.button:on_input(action_id, action) then
			return true
		end
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end
end
