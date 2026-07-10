local dispatcher = require("crit.dispatcher")
local richtext = require("richtext.richtext")
local Button = require("crit.button")
local Layout = require("crit.layout")
local intl = require("crit.intl")
local button_sound = require("sound.button")
local gesture = require("in.gesture")
local large_ui = require("lib.large_ui")
local rich_fonts = require("main.fonts.families")
local font_layers = require("main.fonts.layers")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_manual_set_position = hash("office_manual_set_position")
local h_office_manual_cancel_touch = hash("office_manual_cancel_touch")
local h_office_manual_reset_scroll = hash("office_manual_reset_scroll")
local h_window_change_size = hash("window_change_size")
local h_gamepad_rshoulder = hash("gamepad_rshoulder")
local h_gamepad_lshoulder = hash("gamepad_lshoulder")
local h_gamepad_lstick_right = hash("gamepad_lstick_right")
local h_gamepad_lpad_right = hash("gamepad_lpad_right")
local h_gamepad_lstick_left = hash("gamepad_lstick_left")
local h_gamepad_lpad_left = hash("gamepad_lpad_left")
local h_key_left = hash("key_left")
local h_key_right = hash("key_right")
local h_play_sfx = hash("play_sfx")
local h_manual = hash("manual")
local h_background = hash("background")
local h_click = hash("click")
local h_switch_input_method = hash("switch_input_method")
local pivot_to_align = {
	[gui.PIVOT_CENTER] = richtext.ALIGN_CENTER,
	[gui.PIVOT_N] = richtext.ALIGN_CENTER,
	[gui.PIVOT_S] = richtext.ALIGN_CENTER,
	[gui.PIVOT_W] = richtext.ALIGN_LEFT,
	[gui.PIVOT_NW] = richtext.ALIGN_LEFT,
	[gui.PIVOT_SW] = richtext.ALIGN_LEFT,
	[gui.PIVOT_E] = richtext.ALIGN_RIGHT,
	[gui.PIVOT_NE] = richtext.ALIGN_RIGHT,
	[gui.PIVOT_SE] = richtext.ALIGN_RIGHT
}
local first_page = 4
local page_count = 8
local pages = {}
local has_text = {}
local toc_spacing = 80
local toc_offset = 100
local buttons_set_enabled, toc_buttons_set_enabled, offset_y_position, create_text, set_text, set_page = nil

function offset_y_position(position, index)
	return vmath.vector3(position.x, position.y - (index - 1) * toc_spacing + toc_offset, position.z)
end

local function follow_background(self, background_position, scale)
	self.container_spec.scale = scale
	self.container_spec.position = self.container_offset * scale.x + background_position + vmath.vector3(Layout.design_width * 0.5, Layout.design_height * 0.5, 0)

	self.layout:place()
end

function _env:init()
	self.container = gui.get_node("contents")
	self.button_container = gui.get_node("button_container")
	self.current_index = 1
	self.page_spread = false
	self.sub_id = dispatcher.subscribe({
		h_office_object_selected,
		h_office_object_deselect,
		h_office_manual_set_position,
		h_office_manual_cancel_touch,
		h_window_change_size,
		h_switch_input_method
	})
	self.hover_paper_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Paper")
	self.layout = Layout.new()

	self.layout:add_node(self.button_container, {
		grav_y = 0.5,
		grav_x = 0.5
	})

	self.container_spec = self.layout:add_node(self.container, {
		grav_y = 0.5,
		grav_x = 0.5
	})
	self.container_offset = self.container_spec.position - vmath.vector3(Layout.design_width * 0.5, Layout.design_height * 0.5, 0) - vmath.vector3(-10, 30, 0)
	self.spread_offset = gui.get_position(gui.get_node("page2")) - gui.get_position(gui.get_node("page1"))
	self.toc_position = gui.get_position(gui.get_node("toc"))

	gui.set_enabled(self.container, false)

	local right_button_node = gui.get_node("right_button")
	local right_arrow_node = gui.get_node("right_arrow")
	self.right_button = Button.new(right_button_node, {
		faded_nodes = {
			right_arrow_node
		},
		shortcut_actions = {
			h_gamepad_rshoulder,
			h_gamepad_lstick_right,
			h_gamepad_lpad_right,
			h_key_right
		},
		on_state_change = button_sound.with_sound({
			release = false,
			press = false
		}),
		action = function ()
			dispatcher.dispatch(h_play_sfx, {
				sfx = "papers",
				parameters = {
					IsPickedUp = 1
				}
			})
			set_page(self, self.current_index + self.page_spread)
		end
	})
	local left_button_node = gui.get_node("left_button")
	local left_arrow_node = gui.get_node("left_arrow")
	self.left_button = Button.new(left_button_node, {
		faded_nodes = {
			left_arrow_node
		},
		shortcut_actions = {
			h_gamepad_lshoulder,
			h_gamepad_lstick_left,
			h_gamepad_lpad_left,
			h_key_left
		},
		on_state_change = button_sound.with_sound({
			release = false,
			press = false
		}),
		action = function ()
			dispatcher.dispatch(h_play_sfx, {
				sfx = "papers",
				parameters = {
					IsPickedUp = 0
				}
			})
			set_page(self, self.current_index - self.page_spread)
		end
	})

	buttons_set_enabled(self, false)

	self.gesture = gesture.create({
		action_id = h_click
	})
	local title_template = gui.get_node("toc_title")
	local page_no_template = gui.get_node("toc_page_no")
	local underline_template = gui.get_node("line")
	local title_template_pos = gui.get_position(title_template)
	local page_no_template_pos = gui.get_position(page_no_template)
	local underline_template_pos = gui.get_position(underline_template)
	self.toc_buttons = {}

	for index = first_page, page_count do
		has_text[index] = true
		local title = intl("manual.page" .. index .. ".title")

		if title ~= "" then
			local title_node = gui.clone(title_template)
			local page_no_node = gui.clone(page_no_template)
			local underline_node = gui.clone(underline_template)

			gui.set_parent(title_node, gui.get_node("toc"))
			gui.set_parent(page_no_node, gui.get_node("toc"))
			gui.set_text(title_node, title)
			gui.set_text(page_no_node, index)
			gui.set_position(title_node, offset_y_position(title_template_pos, index))
			gui.set_position(page_no_node, offset_y_position(page_no_template_pos, index))
			gui.set_position(underline_node, offset_y_position(underline_template_pos, index))

			local button = Button.new(title_node, {
				faded_nodes = {
					title_node,
					page_no_node,
					underline_node
				},
				on_state_change = button_sound.with_sound({
					press = false,
					release = false,
					hover = self.hover_paper_event
				}),
				action = function ()
					dispatcher.dispatch(h_play_sfx, {
						sfx = "papers",
						parameters = {
							IsPickedUp = 0
						}
					})
					set_page(self, index)
				end
			})

			button:set_enabled(false)

			self.toc_buttons[index] = button
		end
	end

	gui.set_enabled(underline_template, false)
end

function create_text(text, container)
	local font = gui.get_font(container)

	for family_name, family in pairs(rich_fonts) do
		if family.regular == font then
			font = family_name

			break
		end
	end

	local words = richtext.create(text, font, {
		fonts = rich_fonts,
		layers = {
			fonts = font_layers.layers,
			textures = {
				h_manual = h_background
			}
		},
		width = gui.get_size(container).x,
		parent = container,
		align = pivot_to_align[gui.get_pivot(container)],
		color = gui.get_color(container)
	})
	local outline_color = gui.get_outline(container)

	for i, word in pairs(words) do
		gui.set_outline(word.node, outline_color)
	end
end

function set_text(text, container)
	if pages[container] then
		gui.delete_node(pages[container])

		pages[container] = {}
	end

	local template_node = gui.get_node(container)

	gui.set_text(template_node, "")

	local container_node = gui.clone(template_node)
	pages[container] = container_node

	create_text(text, container_node)
end

function set_page(self, index)
	index = index or self.current_index
	local page_spread = self.page_spread
	local min_page = 1

	if page_spread == 1 then
		min_page = 3
	end

	if index < min_page then
		index = page_count
	elseif page_count < index then
		index = min_page
	end

	index = math.floor((index - 1) / page_spread) * page_spread + 1
	self.current_index = index
	local toc_shown = index == min_page
	local toc_node = gui.get_node("toc")

	gui.set_enabled(toc_node, toc_shown)
	toc_buttons_set_enabled(self, toc_shown)
	gui.set_position(toc_node, page_spread == 1 and self.toc_position - self.spread_offset or self.toc_position)

	for i = 0, 1 do
		if i < page_spread and has_text[index + i] then
			set_text(intl("manual.page" .. index + i .. ".content"), "page" .. i + 1)
			set_text(intl("manual.page" .. index + i .. ".title"), "header" .. i + 1)
		else
			set_text("", "page" .. i + 1)
			set_text("", "header" .. i + 1)
		end

		gui.set_text(gui.get_node("page" .. i + 1 .. "_no"), index + i)
	end

	dispatcher.dispatch(h_office_manual_reset_scroll)
end

function buttons_set_enabled(self, enabled)
	gui.set_enabled(self.left_button.node, enabled)
	gui.set_enabled(self.right_button.node, enabled)
	self.left_button:set_enabled(enabled)
	self.right_button:set_enabled(enabled)
end

function toc_buttons_set_enabled(self, enabled)
	for i, button in pairs(self.toc_buttons) do
		button:set_enabled(enabled)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_selected then
		if message.object_id == h_manual then
			msg.post(".", "acquire_input_focus")
			gui.set_enabled(self.container, true)
			follow_background(self, message.position, message.scale)
			buttons_set_enabled(self, true)

			self.page_spread = large_ui.enabled and 1 or 2

			set_page(self, large_ui.enabled and self.current_index < 3 and 3)

			if large_ui.enabled then
				msg.post("manual_scroll", "acquire_input_focus")
			end
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_manual then
			msg.post(".", "release_input_focus")
			msg.post("manual_scroll", "release_input_focus")
			gui.set_enabled(self.container, false)
			buttons_set_enabled(self, false)
		end
	elseif message_id == h_office_manual_cancel_touch then
		for i, button in pairs(self.toc_buttons) do
			button:cancel_touch()
		end

		self.right_button:cancel_touch()
		self.left_button:cancel_touch()
	elseif message_id == h_office_manual_set_position then
		follow_background(self, message.position, message.scale)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		for i, button in pairs(self.toc_buttons) do
			button:switch_input_method()
		end

		self.left_button:switch_input_method()
		self.right_button:switch_input_method()
	end
end

function _env:on_input(action_id, action)
	local g = self.gesture.on_input(action_id, action)

	if g then
		if g.swipe_left then
			self.right_button.action()
		elseif g.swipe_right then
			self.left_button.action()
		end
	end

	for i, button in pairs(self.toc_buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end

	if self.right_button:on_input(action_id, action) then
		return true
	end

	if self.left_button:on_input(action_id, action) then
		return true
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
