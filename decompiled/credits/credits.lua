local Layout = require("crit.layout")
local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local revive_text = require("lib.revive_text")
local families = require("main.fonts.families")
local font_layers = require("main.fonts.layers")
local richtext = require("richtext.richtext")
intl = intl.namespace("credits")
local h_window_change_size = hash("window_change_size")
local h_end_scene = hash("end_scene")
local speed = 130
local layout_lines, sanitize_diacritics = nil

function _env:init()
	local lines = {}
	local i = 0
	local text = sanitize_diacritics(intl("credits.text"))
	local start = 1

	while start do
		local match = text:find("\n", start)
		local line = text:sub(start, match)
		start = match and match + 1
		i = i + 1
		lines[i] = {
			text = line
		}
	end

	self.lines = lines
	self.cursor = 0

	timer.delay(0, false, function ()
		self.cursor = 0
	end)

	self.layout = Layout.new()

	self.layout:add_node(gui.get_node("layout_container"), {
		grav_y = 0,
		grav_x = 0.5
	})

	self.container = gui.get_node("container")

	layout_lines(self)

	self.sub_id = dispatcher.subscribe({
		h_window_change_size
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local replacements = {
	["Ș"] = "S",
	["Â"] = "A",
	["Î"] = "I",
	["ț"] = "t",
	["Ț"] = "T",
	["ă"] = "a",
	["Ă"] = "A",
	["â"] = "a",
	["î"] = "i",
	["ș"] = "s"
}

function sanitize_diacritics(text)
	for from, to in pairs(replacements) do
		text = text:gsub(from, to)
	end

	return text
end

local white = vmath.vector4(1)

local function offset_words(words, offset_x, offset_y)
	for _, word in ipairs(words) do
		local pos = gui.get_position(word.node)
		pos.x = pos.x + offset_x
		pos.y = pos.y + offset_y

		gui.set_position(word.node, pos)
	end
end

local function create_line(self, line, pos_y)
	local text = line.text

	if text == "" then
		text = "<color=#00000000>I</color>"
	end

	local words, metrics = revive_text.richtext_safe_create(text, "dialogue", {
		line_spacing = 1,
		combine_words = true,
		fonts = families,
		parent = self.container,
		align = richtext.ALIGN_CENTER,
		layers = {
			fonts = font_layers.layers
		},
		color = white,
		position = vmath.vector3(0, -pos_y, 0)
	})
	local left_words = richtext.tagged(words, "left")
	local right_words = richtext.tagged(words, "right")

	if next(left_words) and next(right_words) then
		local first_right_node = right_words[1].node
		local last_left_node = left_words[#left_words].node
		local right_offset_x = 10 - gui.get_position(first_right_node).x

		offset_words(right_words, right_offset_x, 0)

		local left_offset_x = -10 - (gui.get_position(last_left_node).x + gui.get_size(last_left_node).x * gui.get_scale(last_left_node).x)

		offset_words(left_words, left_offset_x, 0)
	end

	local offset_y_words = richtext.tagged(words, "offsety")

	for _, word in ipairs(offset_y_words) do
		local pos = gui.get_position(word.node)
		pos.y = pos.y + tonumber(word.tags.offsety)

		gui.set_position(word.node, pos)
	end

	line.words = words
	line.pos_y = pos_y
	line.height = metrics.height
	line.created = true
end

local function delete_line(self, line)
	if line.words then
		for i, word in ipairs(line.words) do
			gui.delete_node(word.node)
		end

		line.words = nil
	end
end

function layout_lines(self)
	local pos_y = 0
	local cursor = self.cursor
	local screen_height = Layout.design_width * Layout.viewport_height / Layout.viewport_width
	local lower_limit = cursor
	local upper_limit = cursor - screen_height * 1.2
	local lines = self.lines

	for i, line in ipairs(lines) do
		if not line.created then
			create_line(self, line, pos_y)
		end

		local pos_y_bottom = line.pos_y + line.height

		if upper_limit > pos_y_bottom then
			delete_line(self, line)
		end

		pos_y = pos_y_bottom

		if lower_limit < line.pos_y then
			break
		end
	end

	if not self.finished then
		local last_line = lines[#lines]

		if last_line.created and not last_line.words then
			self.finished = true

			dispatcher.dispatch(h_end_scene)
		end
	end

	gui.set_position(self.container, vmath.vector3(0, cursor, 0))
end

function _env:update(dt)
	self.cursor = self.cursor + dt * speed

	layout_lines(self)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		self.layout:place()
	end
end
