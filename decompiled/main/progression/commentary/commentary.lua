local dispatcher = require("crit.dispatcher")
local richtext = require("richtext.richtext")
local families = require("main.fonts.families")
local Layout = require("crit.layout")
local Button = require("crit.button")
local slides = require("title.slides")
local h_click = hash("click")
local h_colorw = hash("color.w")
local h_scale = hash("scale")
local h_commentary_disable = hash("commentary_disable")
local h_window_change_size = hash("window_change_size")
local go_to_next_slide = nil

function _env:init()
	self.prototypes = {
		{
			gui.get_node("slide1"),
			gui.get_node("slide1_label")
		},
		{
			gui.get_node("slide2"),
			gui.get_node("slide2_label")
		}
	}
	self.background = gui.get_node("background")
	self.slide_no = 0
	self.layout = Layout.new()

	self.layout:add_node(self.background, {
		resize_y = true,
		resize_x = true
	})

	self.label_size = gui.get_size(self.prototypes[1][2])
	self.label_scale = gui.get_scale(self.prototypes[1][2])

	for k, prototype in pairs(self.prototypes) do
		gui.set_color(prototype[1], vmath.vector4(1, 1, 1, 0))
		gui.set_text(prototype[2], "")
	end

	msg.post(".", "acquire_input_focus")
	go_to_next_slide(self)
	gui.set_color(self.background, vmath.vector4(0, 0, 0, 0))
	gui.animate(self.background, h_colorw, 0.8, gui.EASING_LINEAR, 0.5)
	gui.set_render_order(15)

	self.sub_id = dispatcher.subscribe({
		h_window_change_size
	})
end

function _env:on_message(message_id, message)
	if message_id == h_window_change_size then
		self.layout:place()
	end
end

function go_to_next_slide(self, timer_id)
	local duration = 0.5
	local slide_no = self.slide_no + 1
	local next_slide = slides.items[slide_no]
	local current_prototype = self.current_prototype

	if not current_prototype and not next_slide then
		return
	end

	self.slide_no = slide_no

	if current_prototype then
		gui.animate(current_prototype[1], h_scale, vmath.vector3(0.8), gui.EASING_INCUBIC, duration)
		gui.animate(current_prototype[1], h_colorw, 0, gui.EASING_LINEAR, duration)
	end

	if not next_slide then
		gui.animate(self.background, h_colorw, 0, gui.EASING_LINEAR, duration, 0, function ()
			dispatcher.dispatch(h_commentary_disable)
		end)

		return
	end

	local next_prototype = self.prototypes[(slide_no - 1) % 2 + 1]
	self.current_prototype = next_prototype
	local delay = current_prototype and 0.6 * duration or 0

	gui.set_scale(next_prototype[1], vmath.vector3(1.15))
	gui.set_color(next_prototype[1], vmath.vector3(1, 1, 1, 0))

	if next_prototype[3] then
		gui.delete_node(next_prototype[3])
	end

	local new_parent = gui.clone(next_prototype[2])

	gui.set_parent(new_parent, next_prototype[1])

	local _, metrics = richtext.create(next_slide, "title", {
		combine_words = true,
		fonts = families,
		width = self.label_size.x,
		parent = new_parent,
		align = richtext.ALIGN_CENTER
	})

	gui.set_position(new_parent, vmath.vector3(0, metrics.height * 0.5 * self.label_scale.y, 0))

	next_prototype[3] = new_parent

	gui.animate(next_prototype[1], h_scale, vmath.vector3(1), gui.EASING_OUTCUBIC, duration, delay)
	gui.animate(next_prototype[1], h_colorw, 1, gui.EASING_LINEAR, duration, delay)
end

function _env:on_input(action_id, action)
	if self.slide_no >= 1 and (action_id == h_click and action.released or Button.action_id_to_navigation_action(action_id) == Button.NAVIGATE_CONFIRM and action.pressed) then
		go_to_next_slide(self)
	end

	return true
end
