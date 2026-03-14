local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local Button = require("crit.button")
local debug_input = require("main.debug.debug_input")
local h_debug_map_toggle = hash("debug_map_toggle")
local h_window_change_size = hash("window_change_size")
local h_click = hash("click")

function _env:init()
	if env.bundled and not env.debug then
		return
	end

	self.enabled = false
	self.nodes = {}
	self.sub_id = dispatcher.subscribe({
		h_debug_map_toggle,
		h_window_change_size
	})
	self.selected_index = 0
	self.container = gui.get_node("container")
	self.proto = gui.get_node("prototype")

	gui.set_enabled(self.proto, false)

	self.layout = Layout.new()

	self.layout:add_node(self.container, {
		grav_y = 1,
		grav_x = 0
	})

	self.text_height = gui.get_text_metrics_from_node(self.proto).height

	gui.set_size(self.proto, vmath.vector3(200, self.text_height, 0))
	gui.set_enabled(self.container, false)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function update_values(self)
	for i, node in ipairs(self.nodes) do
		gui.delete_node(node.node)
	end

	local nodes = {}
	local nodes_count = 0
	self.nodes = nodes
	local text_height = self.text_height

	local function make_line(text, depth)
		local node = gui.clone(self.proto)

		gui.set_enabled(node, true)
		gui.set_parent(node, self.container)
		gui.set_text(node, text)
		gui.set_position(node, vmath.vector3(10 * (depth - 1), -nodes_count * text_height, 0))

		return node
	end

	local map = _G.save_map
	local route = _G.save_route

	if not map or not route then
		local node = make_line("Outside campaign", 1)
		nodes_count = nodes_count + 1
		nodes[nodes_count] = {
			node = node
		}

		return
	end

	local function add_node(segment_name, depth, is_current)
		local node = make_line(segment_name, depth)

		if is_current then
			gui.set_color(node, vmath.vector4(1, 1, 0, 1))
		end

		nodes_count = nodes_count + 1
		nodes[nodes_count] = {
			node = node,
			segment_name = segment_name,
			depth = depth
		}

		if nodes_count == self.selected_index then
			gui.set_color(node, vmath.vector4(1, 0, 0, 1))
		end
	end

	local map_len = #map
	local continue_indices = {}

	for i = 1, map_len do
		local item = map[i]
		local sequence_id = item[1]
		local segments = item[2]
		local current_segment = route[sequence_id]

		for j, segment in ipairs(segments) do
			local segment_name = segment[1]
			local is_current = segment_name == current_segment

			add_node(segment_name, i, is_current)

			if is_current then
				continue_indices[i] = j + 1

				break
			end
		end
	end

	for i = map_len, 1, -1 do
		local item = map[i]
		local segments = item[2]
		local continue_index = continue_indices[i]

		if continue_index then
			local segments_count = #segments

			for j = continue_index, segments_count do
				local segment = segments[j]
				local segment_name = segment[1]

				add_node(segment_name, i, false)
			end
		end
	end
end

function _env:update(dt)
	if not self.enabled then
		return
	end

	update_values(self)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_debug_map_toggle then
		self.enabled = not self.enabled
		self.selected_index = 0

		gui.set_enabled(self.container, self.enabled)
		msg.post(".", self.enabled and "acquire_input_focus" or "release_input_focus")

		if self.enabled then
			update_values(self)
		end
	elseif message_id == h_window_change_size then
		self.layout:place()
	end
end

local function press_node(self, node)
	local new_route = {}
	local map = _G.save_map
	local route = _G.save_route

	if not map and not route then
		return
	end

	local segment_name = node.segment_name
	local depth = node.depth

	if not segment_name or not depth then
		return
	end

	for j = 1, depth - 1 do
		local item = map[j]
		local sequence_id = item[1]
		new_route[sequence_id] = route[sequence_id]
	end

	local last_sequence_id = map[depth][1]
	new_route[last_sequence_id] = segment_name

	dispatcher.dispatch("campaign_rewind", {
		route = new_route
	})
end

function _env:on_input(action_id, action)
	if action_id == h_click and action.pressed then
		local x, y = Layout.action_to_offset_design(action)

		for i, node in ipairs(self.nodes) do
			if gui.pick_node(node.node, x, y) then
				press_node(self, node)

				return true
			end
		end
	end

	if not debug_input.captures_input then
		return
	end

	local nav_action = Button.action_id_to_navigation_action(action_id)

	if nav_action == Button.NAVIGATE_CONFIRM and action.pressed then
		local node = self.nodes[self.selected_index]

		if node then
			press_node(self, node)

			return true
		end
	elseif (nav_action == Button.NAVIGATE_DOWN or nav_action == Button.NAVIGATE_UP) and (action.pressed or action.repeated) then
		local selected_index = self.selected_index + (nav_action == Button.NAVIGATE_DOWN and 1 or -1)

		if selected_index > #self.nodes then
			selected_index = 1
		end

		if selected_index < 1 then
			selected_index = #self.nodes
		end

		self.selected_index = selected_index

		update_values(self)

		return true
	end

	if nav_action then
		return true
	end
end
