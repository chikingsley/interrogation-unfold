local Button = require("crit.button")
local Layout = require("crit.layout")
local button_sound = require("sound.button")
local FocusGiver = require("crit.focus_giver")
local KeyPrompt = require("lib.key_prompt")
local input_state = require("crit.input_state")
local caret = require("lib.caret")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_colorw = hash("color.w")
local h_scale = hash("scale")
local h_key_escape = hash("key_escape")
local zoom_scale = vmath.vector3(0.8, 0.8, 1)
local zoom_duration = 0.3
local fade_duration = 1
local fade_alpha = 0.8
local ListModal = {
	__index = {}
}

function ListModal.new(opts)
	local self = {}

	setmetatable(self, ListModal)

	self.focus_context = input_state.new_focus_context()
	self.modal_node = gui.get_node("template/modal")
	self.container_node = gui.get_node("template/container")
	self.layout = Layout.new()

	self.layout:add_node(gui.get_node("template/layout_container"), {
		grav_y = 0.5,
		grav_x = 0.5
	})

	self.fade_node = gui.get_node("template/fade")

	gui.set_color(self.fade_node, vmath.vector4(0, 0, 0, 0))
	gui.set_enabled(self.fade_node, false)
	self.layout:add_node(self.fade_node, {
		resize_y = true,
		resize_x = true
	})
	gui.set_enabled(self.container_node, false)
	gui.set_scale(self.container_node, zoom_scale)
	gui.set_color(self.container_node, vmath.vector4(1, 1, 1, 0))

	self.default_modal_size = gui.get_size(self.modal_node)
	self.buttons = {}
	self.button_node = gui.get_node("template/button")

	gui.set_enabled(self.button_node, false)

	self.focus_caret = gui.get_node("template/focus_caret")

	caret.hide_instantly(self.focus_caret)

	self.cancel_key_prompt = KeyPrompt.new(gui.get_node("template/prompt_b"), {
		action_id = h_gamepad_rpad_right,
		halo = gui.get_node("template/prompt_b_halo")
	})
	self.cancel_button = Button.new(gui.get_node("template/button_cancel"), {
		shortcut_actions = {
			h_gamepad_rpad_right,
			h_key_escape
		},
		faded_nodes = {
			gui.get_node("template/button_cancel_times")
		},
		on_state_change = button_sound.with_sound(),
		action = opts and opts.cancel_action or function ()
			self:hide()
		end
	})
	self.focus_giver = FocusGiver.new({
		focus_context = self.focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			local buttons = self.buttons

			if next(buttons) then
				if not nav_action or nav_action == Button.NAVIGATE_DOWN then
					return buttons[1]:focus()
				elseif nav_action == Button.NAVIGATE_UP then
					return buttons[#buttons]:focus()
				end
			end
		end
	})

	self.cancel_key_prompt:set_enabled(false)
	self.focus_giver:try_focus_first()

	return self
end

local function on_focus_change(self, button, focused, no_anim)
	local focus_caret = self.focus_caret

	if focused then
		self.focused_button = button

		caret.move_to(focus_caret, nil, gui.get_position(button.node).y, no_anim and 0)
	elseif self.focused_button == button then
		self.focused_button = nil

		caret.hide(focus_caret)
	end
end

function ListModal.__index:show(button_specs)
	if not self.shown then
		self.shown = true
		local container_node = self.container_node
		local modal_node = self.modal_node
		local fade_node = self.fade_node
		local button_node = self.button_node

		gui.set_enabled(container_node, true)
		gui.set_enabled(fade_node, true)

		local button_position = gui.get_position(button_node)
		local button_spacing = gui.get_size(button_node).y * gui.get_scale(button_node).y

		for i, button in ipairs(self.buttons) do
			button:cancel_focus()
		end

		local buttons = {}
		self.buttons = buttons

		for i, spec in ipairs(button_specs) do
			local node = gui.clone(button_node)

			gui.set_enabled(node, true)
			gui.set_position(node, button_position - vmath.vector3(0, (i - 1) * button_spacing, 0))
			gui.set_text(node, spec.label)

			if spec.color then
				gui.set_color(node, spec.color)
			end

			buttons[i] = Button.new(node, {
				keyboard_focus = true,
				gamepad_focus = true,
				action = spec.action,
				on_state_change = button_sound.with_sound(),
				focus_context = self.focus_context,
				on_pass_focus = function (button, nav_action)
					if next(buttons) then
						if nav_action == Button.NAVIGATE_UP and i > 1 then
							return buttons[i - 1]:focus()
						elseif nav_action == Button.NAVIGATE_DOWN and i < #buttons then
							return buttons[i + 1]:focus()
						end
					end
				end,
				on_focus_change = button_sound.with_focus_sound(function (button, focused)
					on_focus_change(self, button, focused)
				end)
			})
		end

		local size = vmath.vector3(self.default_modal_size)
		size.y = size.y + (#button_specs - 1) * button_spacing

		gui.set_size(modal_node, size)
		gui.set_position(modal_node, vmath.vector3(0, size.y * 0.5, 0))
		self.cancel_key_prompt:set_enabled(true)
		self.focus_giver:try_focus_first()
		gui.cancel_animation(container_node, h_colorw)
		gui.cancel_animation(container_node, h_scale)
		gui.cancel_animation(fade_node, h_colorw)
		gui.animate(container_node, h_colorw, 1, go.EASING_OUTEXPO, zoom_duration)
		gui.animate(container_node, h_scale, vmath.vector3(1), go.EASING_OUTEXPO, zoom_duration)
		gui.animate(fade_node, h_colorw, fade_alpha, go.EASING_OUTEXPO, fade_duration)
	end
end

function ListModal.__index:hide()
	if not self.shown then
		return
	end

	self.shown = false
	local container_node = self.container_node
	local fade_node = self.fade_node

	gui.cancel_animation(container_node, h_colorw)
	gui.cancel_animation(container_node, h_scale)
	gui.cancel_animation(fade_node, h_colorw)
	gui.animate(container_node, h_colorw, 0, go.EASING_OUTEXPO, zoom_duration)
	gui.animate(fade_node, h_colorw, 0, go.EASING_LINEAR, zoom_duration, 0, function ()
		gui.set_enabled(fade_node, false)
	end)
	gui.animate(container_node, h_scale, zoom_scale, go.EASING_OUTEXPO, zoom_duration, 0, function ()
		gui.set_enabled(container_node, false)
		caret.hide_instantly(self.focus_caret)
	end)
	self.cancel_button:cancel_focus()
	self.cancel_key_prompt:set_enabled(false)
end

function ListModal.__index:window_change_size()
	self.layout:place()
end

function ListModal.__index:switch_input_method(message)
	self.cancel_key_prompt:switch_input_method()
	self.cancel_button:switch_input_method()

	for i, button in ipairs(self.buttons) do
		button:switch_input_method()
	end

	self.focus_giver:try_focus_first(message and message.nav_action)
end

function ListModal.__index:on_input(action_id, action)
	if not self.shown then
		return false
	end

	self.cancel_key_prompt:on_input(action_id, action)

	if self.cancel_button:on_input(action_id, action) then
		return true
	end

	for i, button in ipairs(self.buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end

	return true
end

return ListModal
