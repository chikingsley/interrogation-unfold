local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local state = require("level.state")
local Bubble = require("lib.bubble")
local families = require("main.fonts.families")
local revive_text = require("lib.revive_text")
local font_layers = require("main.fonts.layers")
local h_window_change_size = hash("window_change_size")
local h_set_subject = hash("set_subject")
local h_init_level = hash("init_level")
local h_torture = hash("torture")
local h_torture_animation = hash("torture_animation")
local h_ask_question = hash("ask_question")
local h_position = hash("position")
local h_torture_room_show = hash("torture_room_show")
local h_torture_room_hide = hash("torture_room_hide")
local h_table_set_position = hash("table_set_position")

local function default_compute_initial_metrics(answer_position, answer_size, reaction_position, reaction_size)
	local overlap = answer_position.y + answer_size.y - (reaction_position.y - reaction_size.y * 0.5)
	local indent = answer_position.x - answer_size.x - (reaction_position.x - reaction_size.x * 0.5)

	return overlap, indent
end

local function default_compute_metrics(answer_position, answer_size, reaction_size, overlap, indent)
	local answer_left = answer_position.x - answer_size.x
	local x = answer_left - indent + math.min(0, answer_size.x - reaction_size.x) + reaction_size.x * 0.5
	local y = answer_position.y + answer_size.y - overlap + reaction_size.y * 0.5

	return x, y
end

local function update_texts(self, simultaneous)
	local sid = state.current_subject
	local texts = self.texts[sid]

	self.reaction_bubble:display_bubble(texts and texts.reaction, true, simultaneous and 0.4 or 0.3)
	self.answer_bubble:display_bubble(texts and texts.answer, true, simultaneous and 0.4 or 0.6)
end

local function hide_texts(self, immediate)
	self.reaction_bubble:hide_bubble(immediate and 0 or 0.4)
	self.answer_bubble:hide_bubble(immediate and 0 or 0.4)
end

local function show_texts(self, simultaneous)
	local sid = state.current_subject
	local texts = self.texts[sid]

	if self.reaction_bubble.container_size.x == 0 then
		self.reaction_bubble:display_bubble(texts and texts.reaction, true, simultaneous and 0.4 or 0.3)
	end

	if self.answer_bubble.container_size.x == 0 then
		self.answer_bubble:display_bubble(texts and texts.answer, true, simultaneous and 0.4 or 0.6)
	end
end

local function get_texts(self, subject_id)
	local texts = self.texts[subject_id]

	if not texts then
		texts = {}
		self.texts[subject_id] = texts
	end

	return texts
end

local function empty_string_to_nil(s)
	if s and s ~= "" then
		return s
	end

	return nil
end

local function create_dialogue(options)
	options = options or {}
	local compute_initial_metrics = options.compute_initial_metrics or default_compute_initial_metrics
	local compute_metrics = options.compute_metrics or default_compute_metrics
	local predicate = options.predicate or function ()
		return true
	end
	local resize_animation, cancel_resize_animation, init_level = nil

	local function init(self)
		local container = gui.get_node("container")
		local reaction_bubble_node = gui.get_node("reaction_bubble")
		local reaction_node = gui.get_node("reaction")
		local answer_bubble_node = gui.get_node("answer_bubble")
		local answer_node = gui.get_node("answer")
		local reaction_bubble = Bubble.new(reaction_bubble_node, reaction_node, {
			large_ui_scale = true,
			resize_animation = function (_self, size, duration)
				resize_animation(self, _self, size, duration)
			end,
			cancel_resize_animation = function (_self)
				cancel_resize_animation(self, _self)
			end,
			rich_fonts = families,
			layers = {
				fonts = font_layers.layers
			},
			revive_words = revive_text.revive_words
		})
		local answer_bubble = Bubble.new(answer_bubble_node, answer_node, {
			large_ui_scale = true,
			min_container_size = vmath.vector3(217, 168, 0),
			resize_animation = function (_self, size, duration)
				resize_animation(self, _self, size, duration)
			end,
			cancel_resize_animation = function (_self)
				cancel_resize_animation(self, _self)
			end,
			rich_fonts = families,
			layers = {
				fonts = font_layers.layers
			},
			revive_words = revive_text.revive_words
		})
		self.reaction_bubble = reaction_bubble
		self.answer_bubble = answer_bubble
		self.layout = Layout.new()
		self.container_spec = self.layout:add_node(container)
		local reaction_position = gui.get_position(reaction_bubble_node)
		local answer_position = gui.get_position(answer_bubble_node)
		reaction_bubble.original_position = reaction_position
		answer_bubble.original_position = answer_position
		local reaction_size = reaction_bubble.container_size * reaction_bubble.original_container_scale
		local answer_size = answer_bubble.container_size * answer_bubble.original_container_scale
		self.overlap, self.indent = compute_initial_metrics(answer_position, answer_size, reaction_position, reaction_size)

		reaction_bubble:hide_bubble(0)
		answer_bubble:hide_bubble(0)

		self.texts = {}
		self.sub_id_dialogue = dispatcher.subscribe({
			h_init_level,
			h_set_subject,
			h_ask_question,
			h_torture,
			h_torture_animation,
			h_torture_room_hide,
			h_torture_room_show,
			h_table_set_position,
			h_window_change_size
		})

		if options.init_now then
			init_level(self)
		end
	end

	local function final(self)
		dispatcher.unsubscribe(self.sub_id_dialogue)
	end

	function resize_animation(self, bubble, size, duration)
		Bubble.default_resize_animation(bubble, size, duration)

		local reaction_bubble = self.reaction_bubble
		local answer_bubble = self.answer_bubble
		local reaction_size = reaction_bubble.container_size * reaction_bubble.original_container_scale
		local answer_size = answer_bubble.container_size * answer_bubble.original_container_scale
		local overlap = self.overlap
		local indent = self.indent
		local x, y = nil

		if answer_size.y == 0 then
			local bottom_padding = gui.get_slice9(answer_bubble.container_node).w * answer_bubble.original_container_scale
			x = 0
			y = answer_bubble.original_position.y + bottom_padding + reaction_size.y * 0.5
		else
			x, y = compute_metrics(answer_bubble.original_position, answer_size, reaction_size, overlap, indent)
		end

		local reaction_position = vmath.vector3(x, y, 0)

		if duration == 0 and bubble == answer_bubble and not self.skip_animation then
			duration = 0.4
		end

		if duration ~= 0 then
			gui.animate(reaction_bubble.container_node, h_position, reaction_position, gui.EASING_OUTEXPO, duration)
		else
			gui.set_position(reaction_bubble.container_node, reaction_position)
		end
	end

	function cancel_resize_animation(self, bubble)
		Bubble.default_cancel_resize_animation(bubble)
		gui.cancel_animation(self.reaction_bubble.container_node, h_position)
	end

	function init_level(self)
		if self.inited then
			return
		end

		self.inited = true

		for subject_id in ipairs(store.subjects) do
			self.texts[subject_id] = {}
		end
	end

	local function on_message(self, message_id, message, sender)
		if message_id == h_table_set_position then
			local table_position = state.table_position
			local relative_y = self.relative_y

			if not relative_y then
				relative_y = self.container_spec.position.y - (state.table_original_position.y + Layout.design_height * 0.5)
				self.relative_y = relative_y
			end

			self.container_spec.position.x = table_position.x + Layout.design_width * 0.5
			self.container_spec.position.y = table_position.y + Layout.design_height * 0.5 + relative_y * state.table_scale

			self.layout:place()
		elseif message_id == h_window_change_size then
			self.layout:place()

			if not message.large_ui_unchanged then
				local texts = get_texts(self, state.current_subject)
				self.skip_animation = true

				if texts.reaction then
					self.reaction_bubble:layout()
				end

				if texts.answer then
					self.answer_bubble:layout()
				end

				self.skip_animation = false
			end
		elseif message_id == h_init_level then
			init_level(self)
		elseif message_id == h_set_subject then
			if predicate(message.subject_id) then
				update_texts(self, true)
			else
				hide_texts(self)
			end
		elseif message_id == h_torture_room_hide then
			if predicate(state.current_subject) then
				show_texts(self)
			else
				hide_texts(self)
			end
		elseif message_id == h_torture_room_show then
			hide_texts(self)
		elseif message_id == h_torture_animation then
			hide_texts(self, true)
		elseif message_id == h_torture then
			local subject_id = state.current_subject

			if predicate(subject_id) then
				local texts = get_texts(self, subject_id)
				texts.reaction = store.get_torture_reaction(subject_id, message.torture_id)
				texts.answer = nil

				update_texts(self)
			end
		elseif message_id == h_ask_question then
			local subject_id = state.current_subject

			if predicate(subject_id) then
				local texts = get_texts(self, subject_id)
				local answer = store.answers[store.subjects[subject_id].last_answer_id]
				texts.reaction = empty_string_to_nil(store.t(answer.reaction))
				texts.answer = empty_string_to_nil(store.t(answer.text))

				update_texts(self)
			end
		else
			return false
		end

		return true
	end

	return {
		init = init,
		final = final,
		on_message = on_message,
		hide_texts = hide_texts,
		show_texts = show_texts,
		update_texts = update_texts
	}
end

return {
	create_dialogue = create_dialogue,
	default_compute_initial_metrics = default_compute_initial_metrics,
	default_compute_metrics = default_compute_metrics
}
