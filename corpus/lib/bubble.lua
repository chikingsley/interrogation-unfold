local richtext = require("richtext.richtext")
local revive_text = require("lib.revive_text")
local large_ui = require("lib.large_ui")
local h_colorw = hash("color.w")
local h_size = hash("size")
local h_scale = hash("scale")
local fade_duration = 0.2
local default_delay = 0.3
local v3one = vmath.vector3(1)
local v4one = vmath.vector4(1)
local v3zero = vmath.vector3(0)
local Bubble = {
	KEEP_TEXT = 42,
	__index = {},
	default_resize_animation = function (self, size, duration)
		if duration ~= 0 then
			gui.animate(self.container_node, h_size, size, gui.EASING_OUTQUART, duration)
		else
			gui.set_size(self.container_node, size)
		end
	end,
	default_cancel_resize_animation = function (self)
		gui.cancel_animation(self.container_node, h_size)
	end
}
local pivot_to_point = {
	[gui.PIVOT_CENTER] = vmath.vector3(0.5, 0.5, 0),
	[gui.PIVOT_N] = vmath.vector3(0.5, 1, 0),
	[gui.PIVOT_S] = vmath.vector3(0.5, 0, 0),
	[gui.PIVOT_W] = vmath.vector3(0, 0.5, 0),
	[gui.PIVOT_NW] = vmath.vector3(0, 1, 0),
	[gui.PIVOT_SW] = vmath.vector3(0, 0, 0),
	[gui.PIVOT_E] = vmath.vector3(1, 0.5, 0),
	[gui.PIVOT_NE] = vmath.vector3(1, 1, 0),
	[gui.PIVOT_SE] = vmath.vector3(1, 0, 0)
}
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

local function pivot_as_point(node)
	local pivot = gui.get_pivot(node)

	return pivot_to_point[pivot] or v3zero
end

local function vmul(a, b)
	return vmath.vector3(a.x * b.x, a.y * b.y, a.z * b.z)
end

local max = math.max

local function vmax(a, b)
	return vmath.vector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))
end

function Bubble.new(container_node, text_node, options)
	options = options or {}
	local large_ui_scale = 1

	if options.large_ui_scale then
		large_ui_scale = options.large_ui_scale

		if large_ui_scale == true then
			large_ui_scale = large_ui.default_text_scale
		end
	end

	local original_container_size = gui.get_size(container_node)
	local original_container_scale = gui.get_scale(container_node).x
	local original_text_position = gui.get_position(text_node)
	local rescale_factor = pivot_as_point(text_node) - pivot_as_point(container_node)
	local original_text_size = gui.get_size(text_node)
	local text_scale = gui.get_scale(text_node)
	local tracking = gui.get_tracking(text_node)
	local leading = gui.get_leading(text_node)
	local line_breaks = gui.get_line_break(text_node)
	local width = original_text_size.x
	local font = gui.get_font(text_node)
	local color = gui.get_color(text_node)
	local slice_9 = gui.get_slice9(container_node)
	local min_container_size = options.min_container_size or vmath.vector3(slice_9.x + slice_9.z, slice_9.y + slice_9.w, 0)

	if not options.rich_fonts then
		local rich_fonts = {
			default_font = {
				regular = font
			}
		}
	end

	local default_rich_font = options.default_rich_font

	if not default_rich_font then
		for family_name, family in pairs(rich_fonts) do
			if family.regular == font then
				default_rich_font = family_name

				break
			end
		end
	end

	default_rich_font = default_rich_font or next(rich_fonts) or "default_font"
	local self = {
		container_node = container_node,
		text_node = text_node,
		original_container_size = original_container_size,
		original_container_scale = original_container_scale,
		container_size = original_container_size,
		original_text_position = original_text_position,
		min_container_size = min_container_size,
		rescale_factor = rescale_factor,
		text_scale = text_scale,
		tracking = tracking,
		leading = leading,
		line_breaks = line_breaks,
		width = width,
		font = font,
		color = color,
		default_rich_font = default_rich_font,
		rich_fonts = rich_fonts,
		layers = options.layers,
		revive_words = options.revive_words or function (words)
			return words
		end,
		large_ui_scale = large_ui_scale,
		resize_animation = options.resize_animation or Bubble.default_resize_animation,
		cancel_resize_animation = options.cancel_resize_animation or Bubble.default_cancel_resize_animation,
		margins = original_container_size - vmul(original_text_size, text_scale)
	}

	setmetatable(self, Bubble)

	return self
end

local function Bubble__create_text(self, text, is_rich)
	local scale = large_ui.enabled and self.large_ui_scale or 1

	if not is_rich then
		local metrics = gui.get_text_metrics(self.font, text, self.width / scale, self.line_breaks, self.leading, self.tracking)

		return metrics, text, nil, scale
	end

	local text_node = self.text_node
	local container = gui.clone(text_node)

	gui.set_scale(container, v3one)
	gui.set_color(container, v4one)
	gui.set_text(container, "")
	gui.set_enabled(container, false)

	local pivot = gui.get_pivot(text_node)
	local pivot_point = pivot_to_point[pivot]
	local align = pivot_to_align[pivot]
	local words, metrics = revive_text.richtext_safe_create(text, self.default_rich_font, {
		combine_words = true,
		fonts = self.rich_fonts,
		width = self.width / scale,
		parent = container,
		align = align,
		layers = self.layers
	})

	gui.set_position(container, vmath.vector3(0, (1 - pivot_point.y) * metrics.height, 0))

	return metrics, container, words, scale
end

local function Bubble__apply_text(self, is_rich, created_text, words, scale)
	local rich_node = self.rich_node

	if rich_node then
		gui.delete_node(rich_node)

		self.rich_node = nil
	end

	local text_node = self.text_node

	large_ui.rescale_text_node(text_node, scale, self.text_scale, self.original_text_size)

	if is_rich then
		gui.set_text(text_node, "")
		gui.set_parent(created_text, text_node)
		gui.set_enabled(created_text, true)

		self.rich_node = created_text
		self.words = self.revive_words(words)
	else
		self.words = nil

		gui.set_text(text_node, created_text)
	end
end

local function Bubble__get_resized_metrics(self, metrics, ui_scale)
	local scale = self.text_scale
	local new_text_size = vmath.vector3(metrics.width * scale.x * ui_scale, metrics.height * scale.y * ui_scale, 0)
	local new_container_size = new_text_size + self.margins
	new_container_size = vmax(new_container_size, self.min_container_size)
	local delta_container_size = new_container_size - self.original_container_size
	local new_text_position = self.original_text_position + vmul(delta_container_size, self.rescale_factor)

	return new_container_size, new_text_position
end

local function Bubble__clear_pending_text(self)
	local pending_text = self.pending_text

	if pending_text then
		gui.delete_node(pending_text)

		self.pending_text = nil
	end
end

local function Bubble__cancel_fade(self, text_node)
	text_node = text_node or self.text_node

	gui.cancel_animation(text_node, h_colorw)

	if self.text_animate_delay then
		timer.cancel(self.text_animate_delay)

		self.text_animate_delay = nil
	end
end

function Bubble.__index:set_text(text, is_rich)
	self.text = text
	self.is_rich = is_rich
	local metrics, created_text, words, scale = Bubble__create_text(self, text, is_rich)
	local container_size, text_position = Bubble__get_resized_metrics(self, metrics, scale)
	self.container_size = container_size
	self.text_position = text_position
	self.container_size = container_size

	self:cancel_resize_animation()
	self:resize_animation(container_size, 0)
	Bubble__apply_text(self, is_rich, created_text, words, scale)

	local text_node = self.text_node

	gui.set_position(text_node, text_position)
	Bubble__cancel_fade(self, text_node)
	Bubble__clear_pending_text(self)

	local color = gui.get_color(text_node)
	color.w = 1

	gui.set_color(text_node, color)
end

local function adjust_delay(delay, time_elapsed)
	return max(delay * 0.8, delay - time_elapsed)
end

local function Bubble__animate_text(self, delay, is_rich, created_text, words, scale)
	delay = delay or default_delay
	local container_size = self.container_size
	local text_position = self.text_position

	self:cancel_resize_animation()
	self:resize_animation(container_size, delay)
	Bubble__apply_text(self, is_rich, created_text, words, scale)

	self.pending_text = nil
	local text_node = self.text_node

	gui.set_position(text_node, text_position)

	self.text_animate_delay = timer.delay(0, false, function (_self, handle, time_elapsed)
		self.text_animate_delay = nil

		if text_node == self.text_node then
			gui.animate(text_node, h_colorw, 1, gui.EASING_LINEAR, fade_duration, adjust_delay(delay, time_elapsed))
		end
	end)
end

function Bubble.__index:animate_text(text, is_rich, delay)
	self.text = text
	self.is_rich = is_rich
	local text_node = self.text_node
	local text_opacity = gui.get_color(text_node).w

	Bubble__cancel_fade(self, text_node)
	Bubble__clear_pending_text(self)

	local metrics, created_text, words, scale = Bubble__create_text(self, text, is_rich)
	local container_size, text_position = Bubble__get_resized_metrics(self, metrics, scale)
	self.container_size = container_size
	self.text_position = text_position

	if text_opacity == 0 then
		Bubble__animate_text(self, delay, is_rich, created_text, words, scale)
	else
		if is_rich then
			self.pending_text = created_text
		end

		gui.animate(text_node, h_colorw, 0, gui.EASING_LINEAR, text_opacity * fade_duration, 0, function ()
			Bubble__animate_text(self, delay, is_rich, created_text, words, scale)
		end)
	end
end

function Bubble.__index:display_bubble(text, is_rich, delay, callback)
	local container_node = self.container_node
	local original_scale = self.original_container_scale
	delay = delay or default_delay
	local scale = gui.get_scale(container_node).x / original_scale

	gui.cancel_animation(container_node, h_scale)

	if self.animate_scale_timer then
		timer.cancel(self.animate_scale_timer)

		self.animate_scale_timer = nil
	end

	if not text then
		local old_container_size = self.container_size
		self.container_size = vmath.vector3(0)
		local duration = scale * delay
		local target_scale = vmath.vector3(0, 0, 1)

		if duration == 0 then
			gui.set_scale(container_node, target_scale)
			gui.set_enabled(container_node, false)

			self.animating_container_size = nil

			if callback then
				callback()
			end
		else
			self.animating_container_size = self.animating_container_size or old_container_size

			gui.animate(container_node, h_scale, target_scale, gui.EASING_INEXPO, duration, 0, function ()
				self.animating_container_size = nil

				gui.set_enabled(container_node, false)
				gui.set_scale(container_node, target_scale)

				if callback then
					callback()
				end
			end)
		end

		return
	end

	self.animating_container_size = nil

	gui.set_enabled(container_node, true)

	local text_created = false

	if text ~= Bubble.KEEP_TEXT then
		if scale < 0.01 then
			text_created = true

			self:set_text(text, is_rich)
		else
			self:animate_text(text, is_rich, delay)
		end
	end

	local duration = (1 - scale) * delay
	local target_scale = vmath.vector3(original_scale, original_scale, 1)

	if duration == 0 then
		gui.set_scale(container_node, target_scale)

		if callback then
			callback()
		end
	else
		local function animate_scale(self_, handle, time_elapsed)
			self.animate_scale_timer = nil
			local adjusted_delay = adjust_delay(duration, time_elapsed)

			gui.animate(container_node, h_scale, target_scale, gui.EASING_OUTEXPO, adjusted_delay, 0, callback)
		end

		if not text_created then
			animate_scale(self, nil, 0)
		else
			self.animate_scale_timer = timer.delay(0, false, animate_scale)
		end
	end
end

function Bubble.__index:layout()
	if self.text then
		self:set_text(self.text, self.is_rich)
	end
end

function Bubble.__index:hide_bubble(delay, callback)
	self:display_bubble(nil, false, delay, callback)
end

return Bubble
