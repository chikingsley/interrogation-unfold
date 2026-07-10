local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local intl = require("crit.intl")
local Layout = require("crit.layout")
local Scroll = require("crit.scroll")
local ScrollBar = require("crit.scrollbar")
local Button = require("crit.button")
local analog_to_digital = require("crit.analog_to_digital")
local dummy_transcript = require("outcome.transcript.dummy_transcript")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")
local h_window_change_size = hash("window_change_size")
local h_dialogue_small = hash("dialogue_small")
local h_colorw = hash("color.w")
local transparent = vmath.vector4(1, 1, 1, 0)
local fade_duration = 0.3
local text_box_margin = 40
local content_padding_bottom = 200
local view_window_lookahead = 50
local view_window_lookbehind = 200
local gamepad_scroll_step = 300
local max_scroll_multiplier = 20
local connector_width = 2
local scroll_detection_threshold = 1
local scroll_jump_detection_threshold = 500
local max_history_events = 10000
local alive_count = 0
local first_alive_box_index = 1
local box_index_lookahead = 15
local em = "M"
local scrollbar_size, scrollbar_axis_size, margin, enable_transcript, disable_transcript, generate_boxes_in_view = nil
local box_type = {
	QUESTION = 1,
	ANSWER = 2,
	GENERIC = 3
}
local richtext_tag_cleaner = {
	{
		"<br ?/?>",
		"\n"
	},
	{
		"(%b<>)",
		""
	},
	{
		"[%s%s]+",
		" "
	},
	{
		"[\n\n]+",
		"\n"
	},
	{
		"^\n*",
		""
	},
	{
		"\n*$",
		""
	}
}

local function easing_out_cubic(t)
	t = t - 1

	return 1 + t * t * t
end

local function gamepad_scroll(self, action, nav_action)
	local scroll = self.scroll
	local current_offset = scroll.offset
	local repeat_count = self.gamepad_action_repeat_count

	if nav_action == Button.NAVIGATE_UP or nav_action == Button.NAVIGATE_DOWN then
		if action.pressed or action.released then
			repeat_count = 0
		elseif action.repeated then
			repeat_count = repeat_count + 1
		end
	end

	local scroll_multiplier = 1 + repeat_count

	if max_scroll_multiplier < scroll_multiplier then
		scroll_multiplier = max_scroll_multiplier or scroll_multiplier
	end

	local new_offset = nil

	if nav_action == Button.NAVIGATE_UP then
		new_offset = current_offset - gamepad_scroll_step * scroll_multiplier
	elseif nav_action == Button.NAVIGATE_DOWN then
		new_offset = current_offset + gamepad_scroll_step * scroll_multiplier
	end

	if new_offset then
		if new_offset < 0 then
			new_offset = 0
		end

		scroll:animate_offset(new_offset, 0.7, easing_out_cubic)
	end

	self.gamepad_action_repeat_count = repeat_count
end

local function increase_content_height(content_height, height)
	return content_height - height - text_box_margin
end

local function get_timestamp_text(time)
	local seconds = math.ceil(time % 60)
	local minutes = math.floor(time / 60)
	local seconds_txt = seconds < 10 and "0" .. seconds or "" .. seconds

	return minutes .. ":" .. seconds_txt
end

local function strip_richtext_tags(text)
	for i = 1, #richtext_tag_cleaner do
		local cleaner = richtext_tag_cleaner[i]
		text = string.gsub(text, cleaner[1], cleaner[2])
	end

	return text
end

local function get_box_metrics(type, factory, label_factory, offset_y, text, timestamp, name, image, name_factory)
	local timestamp_text = get_timestamp_text(timestamp)
	local factory_original_pos = gui.get_position(factory)
	local label_width = gui.get_size(label_factory).x
	local label_scale_y = gui.get_scale(label_factory).y
	local text_offset_x = 0

	if name_factory then
		local name_max_width = gui.get_size(name_factory).x
		local name_width = gui.get_text_metrics(h_dialogue_small, name).width
		text_offset_x = math.max(0, name_width - name_max_width)
	end

	local text_metrics = gui.get_text_metrics(h_dialogue_small, text, label_width - text_offset_x, true)
	local box_new_pos = vmath.vector3(factory_original_pos.x, offset_y, 0)
	local box_size = text_metrics.height * label_scale_y
	local box = {
		type = type,
		factory = factory,
		position = box_new_pos,
		size_y = box_size,
		text = text,
		text_offset_x = text_offset_x,
		time = timestamp_text
	}

	if type == box_type.QUESTION then
		box.name = name
	elseif type == box_type.ANSWER then
		box.name = name
		box.image = image
		local avatar_size_y = gui.get_size(gui.get_node("a_avatar")).y
		box_size = avatar_size_y < box_size and box_size or avatar_size_y
		box.size_y = box_size
	end

	return box
end

local function create_text_box(box, container)
	local node_tree = gui.clone_tree(box.factory)
	local node, label, timestamp = nil

	if box.type == box_type.GENERIC then
		node = node_tree.generic_prototype
		label = node_tree.g_text
		timestamp = node_tree.g_timestamp

		gui.set_text(timestamp, box.time)
	elseif box.type == box_type.QUESTION then
		node = node_tree.question_prototype
		label = node_tree.q_text
		timestamp = node_tree.q_timestamp
		local connector = node_tree.q_connector
		local player = node_tree.q_player

		gui.set_text(timestamp, box.time)
		gui.set_text(player, box.name)

		local line_height = gui.get_text_metrics(h_dialogue_small, em, 1, false).height

		gui.set_size(connector, vmath.vector3(connector_width, box.size_y + text_box_margin + line_height * 0.5, 1))
	elseif box.type == box_type.ANSWER then
		node = node_tree.answer_prototype
		label = node_tree.a_text
		local avatar = node_tree.a_avatar
		local name_label = node_tree.a_name

		gui.play_flipbook(avatar, box.image)
		gui.set_text(name_label, box.name)
	end

	gui.set_parent(node, container)
	gui.set_position(node, box.position)
	gui.set_enabled(node, true)

	if box.text_offset_x ~= 0 then
		local text_pos = gui.get_position(label)
		text_pos.x = text_pos.x + box.text_offset_x

		gui.set_position(label, text_pos)

		local text_size = gui.get_size(label)
		text_size.x = text_size.x - box.text_offset_x

		gui.set_size(label, text_size)
	end

	gui.set_text(label, box.text)

	box.node = node
	box.alive = true

	return box
end

local function delete_text_box(box)
	gui.delete_node(box.node)

	box.node = nil
	box.alive = false

	return box
end

local function write_history_to_file(self)
	local file = io.open("level_transcript", "w+")

	file:write("return {\n")

	for i, entry in ipairs(self.level_history) do
		local text = "\t[" .. i .. "] = {\n"
		text = text .. "\t\ttype = " .. entry.type .. ",\n"
		text = text .. "\t\ttimestamp = " .. entry.timestamp .. ",\n"
		text = text .. "\t\tsubject_id = " .. entry.subject_id .. ",\n"

		if entry.question_id then
			text = text .. "\t\tquestion_id = " .. entry.question_id .. ",\n"
		end

		if entry.question_alt_id then
			text = text .. "\t\tquestion_alt_id = " .. entry.question_alt_id .. ",\n"
		end

		if entry.answer_id then
			text = text .. "\t\tanswer_id = " .. entry.answer_id .. ",\n"
		end

		text = text .. "\n\t},\n"

		file:write(text)
	end

	file:write("}")
end

function _env:init()
	gui.set_render_order(1)

	self.sub_id = dispatcher.subscribe({
		h_outcome_enable_transcript,
		h_outcome_disable_transcript,
		h_window_change_size
	})
	local container = gui.get_node("container")
	local content = gui.get_node("content")

	gui.set_enabled(container, false)
	gui.set_color(container, transparent)

	self.level_history = store.get_history()
	self.layout = Layout.new()

	self.layout:add_node(container, {
		grav_y = 1,
		grav_x = 0.5
	})

	local g_prototype = gui.get_node("generic_prototype")
	local q_prototype = gui.get_node("question_prototype")
	local a_prototype = gui.get_node("answer_prototype")
	local g_label_prototype = gui.get_node("g_text")
	local q_label_prototype = gui.get_node("q_text")
	local q_name_prototype = gui.get_node("q_player")
	local a_label_prototype = gui.get_node("a_text")
	local a_name_prototype = gui.get_node("a_name")

	gui.set_enabled(g_prototype, false)
	gui.set_enabled(q_prototype, false)
	gui.set_enabled(a_prototype, false)

	self.view_window = {
		top = view_window_lookbehind,
		bottom = -(Layout.projection_height + view_window_lookahead)
	}
	self.nodes = {}
	self.visible_nodes = {}
	local question_original_pos = gui.get_position(q_prototype)
	local content_height = question_original_pos.y
	self.last_history_event = nil

	for i, event in ipairs(self.level_history) do
		local subject_id = event.subject_id
		local question_id = event.question_id
		local question_alt_id = event.question_alt_id
		local answer_id = event.answer_id
		local timestamp = event.timestamp

		if max_history_events < i then
			local text = intl("outcome.transcript_event.truncate")
			local box = get_box_metrics(box_type.GENERIC, g_prototype, g_label_prototype, content_height, text, timestamp)
			content_height = increase_content_height(content_height, box.size_y)

			table.insert(self.nodes, box)

			break
		end

		if event.type == store.HISTORY_EVENTS.RECORDER then
			local text = intl("outcome.transcript_event.recorder_stop")
			local box = get_box_metrics(box_type.GENERIC, g_prototype, g_label_prototype, content_height, text, timestamp)
			content_height = increase_content_height(content_height, box.size_y)

			table.insert(self.nodes, box)
		elseif event.type == store.HISTORY_EVENTS.LEVEL_END then
			local text = intl("outcome.transcript_event.interrogation_end")
			local box = get_box_metrics(box_type.GENERIC, g_prototype, g_label_prototype, content_height, text, timestamp)
			content_height = increase_content_height(content_height, box.size_y)

			table.insert(self.nodes, box)
		elseif event.type == store.HISTORY_EVENTS.SWITCH_SUBJECT then
			local subject_name = store.subjects[subject_id].name
			local text = intl("outcome.transcript_event.switch_subject", {
				subject_name = subject_name
			})
			local box = get_box_metrics(box_type.GENERIC, g_prototype, g_label_prototype, content_height, text, timestamp)
			content_height = increase_content_height(content_height, box.size_y)

			table.insert(self.nodes, box)
		elseif event.type == store.HISTORY_EVENTS.KILL then
			local subject_name = store.subjects[subject_id].name
			local text = intl("outcome.transcript_event.kill", {
				subject_name = subject_name
			})
			local box = get_box_metrics(box_type.GENERIC, g_prototype, g_label_prototype, content_height, text, timestamp)
			content_height = increase_content_height(content_height, box.size_y)

			table.insert(self.nodes, box)
		elseif event.type == store.HISTORY_EVENTS.QUESTION then
			local question_box = nil
			local q_text = strip_richtext_tags(store.t(store.get_question_text_by_alt_id(question_id, question_alt_id)))
			local player_name = intl("outcome.transcript.player_name")
			question_box = get_box_metrics(box_type.QUESTION, q_prototype, q_label_prototype, content_height, q_text, timestamp, player_name, nil, q_name_prototype)
			content_height = increase_content_height(content_height, question_box.size_y)

			table.insert(self.nodes, question_box)

			local answer_box = nil
			local a_text = strip_richtext_tags(store.t(store.answers[answer_id].text))
			local subject_name = string.match(store.subjects[subject_id].name, "%w+") .. ":"
			local image = "panel_avatar_" .. store.subjects[subject_id].avatar
			answer_box = get_box_metrics(box_type.ANSWER, a_prototype, a_label_prototype, content_height, a_text, timestamp, subject_name, image, a_name_prototype)
			content_height = increase_content_height(content_height, answer_box.size_y)

			table.insert(self.nodes, answer_box)
		end
	end

	self.content_height = content_height
	self.scroll = Scroll.new({
		content_height = -self.content_height,
		view_height = Layout.projection_height,
		padding_bottom = content_padding_bottom
	})

	self.scroll:add_node(content)

	local scrollbar_axis = gui.get_node("scrollbar_axis")
	local scrollbar_node = gui.get_node("scrollbar")

	if -self.content_height < Layout.projection_height then
		gui.set_enabled(scrollbar_axis, false)
		gui.set_enabled(scrollbar_node, false)
	end

	self.scrollbar = ScrollBar.new(self.scroll, scrollbar_node, {
		knob = true
	})
	scrollbar_size = gui.get_size(scrollbar_node)
	scrollbar_axis_size = gui.get_size(scrollbar_axis)
	margin = gui.get_position(scrollbar_axis).y - gui.get_position(scrollbar_node).y
	local scrollbar_bottom = vmath.vector3(scrollbar_size.x, scrollbar_axis_size.y - 2 * margin, 0)

	self.scrollbar:set_metrics(self.scrollbar.top, scrollbar_bottom)

	self.container = container
	self.content_container = content
	self.gamepad_action_repeat_count = 0
	self.old_scroll_offset = 0
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function enable_transcript(self)
	self.transcript_enabled = true
	local container = self.container

	gui.set_enabled(container, true)
	gui.animate(container, h_colorw, 1, gui.EASING_LINEAR, fade_duration)
	generate_boxes_in_view(self, true)
	msg.post(".", "acquire_input_focus")
end

function disable_transcript(self)
	self.transcript_enabled = false
	local container = self.container

	gui.animate(container, h_colorw, 0, gui.EASING_LINEAR, fade_duration, 0, function ()
		gui.set_enabled(container, false)
	end)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_outcome_enable_transcript then
		enable_transcript(self)
	elseif message_id == h_outcome_disable_transcript then
		disable_transcript(self)
	elseif message_id == h_window_change_size then
		self.layout:place()
	end
end

function generate_boxes_in_view(self, is_jump)
	local view_window = self.view_window
	local content_container = self.content_container
	local start_index = 1
	local box_count = #self.nodes
	local end_index = box_count

	if not is_jump then
		start_index = first_alive_box_index - box_index_lookahead

		if start_index < 1 then
			start_index = 1
		end

		end_index = first_alive_box_index + alive_count + box_index_lookahead

		if box_count < end_index then
			end_index = box_count or end_index
		end
	end

	local last_box_alive = false
	local iter = 0

	for i = start_index, end_index do
		local box = self.nodes[i]
		local box_pos_y = box.position.y
		iter = iter + 1

		if not box.alive and box_pos_y < view_window.top and view_window.bottom < box_pos_y then
			if not last_box_alive then
				first_alive_box_index = i
				last_box_alive = true
			end

			self.nodes[i] = create_text_box(box, content_container)
			alive_count = alive_count + 1
		elseif box.alive and (view_window.top < box_pos_y or box_pos_y < view_window.bottom) then
			self.nodes[i] = delete_text_box(box)
			alive_count = alive_count - 1
		end
	end
end

function _env:update(dt)
	self.scroll:update(dt)

	local scroll_offset = self.scroll.offset
	local scroll_dt = math.abs(scroll_offset - self.old_scroll_offset)
	local has_scrolled = scroll_detection_threshold < scroll_dt
	self.old_scroll_offset = scroll_offset

	if has_scrolled then
		local is_jump = scroll_jump_detection_threshold < scroll_dt
		self.view_window.top = -(scroll_offset - view_window_lookbehind)
		self.view_window.bottom = -(scroll_offset + Layout.projection_height + view_window_lookahead)

		generate_boxes_in_view(self, is_jump)
	end
end

on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
	if action.pressed or action.repeated then
		local nav_action = Button.action_id_to_navigation_action(action_id)

		gamepad_scroll(self, action, nav_action)
	end

	if self.scrollbar:on_input(action_id, action) then
		return true
	end

	if self.scroll:on_input(action_id, action) then
		return true
	end
end)
