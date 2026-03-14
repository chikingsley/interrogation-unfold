local Button = require("crit.button")
local Layout = require("crit.layout")
local button_sound = require("sound.button")
local FocusGiver = require("crit.focus_giver")
local KeyPrompt = require("lib.key_prompt")
local LongPress = require("lib.long_press")
local input_state = require("crit.input_state")
local revive_text = require("lib.revive_text")
local richtext = require("richtext.richtext")
local font_families = require("main.fonts.families")
local font_layers = require("main.fonts.layers")
local h_modal_label = hash("modal_label")
local h_modal_button_cancel = hash("modal_button_cancel")
local h_modal_button_confirm = hash("modal_button_confirm")
local h_modal_button_ok = hash("modal_button_ok")
local h_modal_button_cancel_glow = hash("modal_button_cancel_glow")
local h_modal_button_confirm_glow = hash("modal_button_confirm_glow")
local h_modal_button_ok_glow = hash("modal_button_ok_glow")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_gamepad_rpad_down = hash("gamepad_rpad_down")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_colorw = hash("color.w")
local h_scale = hash("scale")
local h_key_escape = hash("key_escape")
local h_key_space = hash("key_space")
local h_key_enter = hash("key_enter")
local zoom_scale = vmath.vector3(0.8, 0.8, 1)
local zoom_duration = 0.3
local fade_duration = 1
local fade_alpha = 0.8
local ConfirmModal = {
	__index = {}
}

local function try_get_node(id)
	local node = nil

	pcall(function ()
		node = gui.get_node(id)
	end)

	return node
end

function ConfirmModal.new(opts)
	opts = opts or {}
	local self = {}

	setmetatable(self, ConfirmModal)

	local focus_context = input_state.new_focus_context()
	self.modal_node = gui.get_node("modal")
	self.container_node = gui.get_node("modal_container")
	self.layout = Layout.new()

	self.layout:add_node(self.container_node, {
		grav_y = 0.5,
		grav_x = 0.5
	})
	gui.set_enabled(self.modal_node, false)
	gui.set_scale(self.modal_node, zoom_scale)
	gui.set_color(self.modal_node, vmath.vector4(1, 1, 1, 0))

	self.fade_node = gui.get_node("modal_fade")

	gui.set_color(self.fade_node, vmath.vector4(0, 0, 0, 0))
	gui.set_enabled(self.fade_node, false)
	self.layout:add_node(self.fade_node, {
		resize_y = true,
		resize_x = true
	})

	local label_node = gui.get_node(h_modal_label)

	gui.set_text(label_node, "")

	self.label_node = label_node
	self.label_size = gui.get_size(label_node)
	self.ok_only = false
	local modal_button_cancel = try_get_node(h_modal_button_cancel)
	local modal_button_confirm = try_get_node(h_modal_button_confirm)

	if modal_button_cancel and modal_button_confirm then
		self.cancel_button = Button.new(modal_button_cancel, {
			gamepad_focus = true,
			keyboard_focus = true,
			focus_node = gui.get_node(h_modal_button_cancel_glow),
			shortcut_actions = opts.no_shortcuts and {} or {
				h_gamepad_rpad_right,
				h_key_escape
			},
			focus_context = focus_context,
			on_pass_focus = function (button, nav_action)
				if nav_action == Button.NAVIGATE_RIGHT then
					return self.confirm_button:focus()
				end
			end,
			on_focus_change = button_sound.with_focus_sound(),
			faded_nodes = {
				modal_button_cancel,
				gui.get_node("modal_button_cancel_text")
			},
			on_state_change = button_sound.with_sound(opts and (opts.cancel_button_sound or opts.button_sound)),
			action = opts and opts.cancel_action or function ()
				self:hide()
			end
		})
		self.confirm_button = Button.new(modal_button_confirm, {
			keyboard_focus = true,
			gamepad_focus = true,
			focus_node = gui.get_node(h_modal_button_confirm_glow),
			on_state_change = button_sound.with_sound(opts and (opts.confirm_button_sound or opts.button_sound)),
			on_pass_focus = function (button, nav_action)
				if nav_action == Button.NAVIGATE_LEFT then
					return self.cancel_button:focus()
				end
			end,
			on_focus_change = button_sound.with_focus_sound(),
			faded_nodes = {
				modal_button_confirm,
				gui.get_node("modal_button_confirm_text")
			},
			action = opts and opts.confirm_action
		})
		local modal_prompt_b = try_get_node("modal_prompt_b")

		if modal_prompt_b then
			self.cancel_key_prompt = KeyPrompt.new(modal_prompt_b, {
				action_id = h_gamepad_rpad_right,
				halo = gui.get_node("modal_prompt_b_halo")
			})

			self.cancel_key_prompt:set_enabled(false)
		end

		local modal_prompt_y = try_get_node("modal_prompt_y")

		if modal_prompt_y then
			self.confirm_key_prompt = KeyPrompt.new(gui.get_node("modal_prompt_y"), {
				is_long_press = true,
				action_id = h_gamepad_rpad_up,
				halo = gui.get_node("modal_prompt_y_halo")
			})

			self.confirm_key_prompt:set_enabled(false)

			self.confirm_long_press = LongPress.new(gui.get_node("modal_prompt_y"), {
				is_key_prompt = true,
				gamepad_action_id = h_gamepad_rpad_up,
				button = self.confirm_button
			})

			self.confirm_long_press:set_enabled(false)
		end
	end

	local modal_button_ok = try_get_node(h_modal_button_ok)

	if modal_button_ok then
		self.ok_button = Button.new(modal_button_ok, {
			gamepad_focus = true,
			keyboard_focus = true,
			focus_node = gui.get_node(h_modal_button_ok_glow),
			shortcut_actions = {
				h_gamepad_rpad_down,
				h_key_space,
				h_key_enter
			},
			focus_context = focus_context,
			on_pass_focus = function (button, nav_action)
				return false
			end,
			on_focus_change = button_sound.with_focus_sound(),
			faded_nodes = {
				modal_button_ok,
				gui.get_node("modal_button_ok_text")
			},
			on_state_change = button_sound.with_sound(opts and (opts.ok_button_sound or opts.button_sound)),
			action = opts and opts.ok_action or function ()
				self:hide()
			end
		})
		local modal_prompt_a = try_get_node("modal_prompt_a")

		if modal_prompt_a then
			self.ok_key_prompt = KeyPrompt.new(modal_prompt_a, {
				action_id = h_gamepad_rpad_right,
				halo = gui.get_node("modal_prompt_a_halo")
			})
		end
	end

	self.focus_giver = FocusGiver.new({
		focus_context = focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if self.ok_only then
				if self.ok_button then
					return self.ok_button:focus()
				end
			elseif not nav_action or nav_action == Button.NAVIGATE_LEFT then
				if self.cancel_button then
					return self.cancel_button:focus()
				end
			elseif nav_action == Button.NAVIGATE_RIGHT and self.confirm_button then
				return self.confirm_button:focus()
			end
		end
	})

	return self
end

function ConfirmModal.__index:show(text, ok_only)
	if not self.shown then
		self.shown = true
		ok_only = not not ok_only
		self.ok_only = ok_only
		local modal_node = self.modal_node
		local fade_node = self.fade_node

		gui.set_enabled(modal_node, true)
		gui.set_enabled(fade_node, true)

		if self.ok_key_prompt then
			self.ok_key_prompt:set_enabled(ok_only)
		end

		if self.cancel_key_prompt then
			self.cancel_key_prompt:set_enabled(not ok_only)
		end

		if self.confirm_key_prompt then
			self.confirm_key_prompt:set_enabled(not ok_only)
			self.confirm_long_press:set_enabled(not ok_only)
		end

		if self.ok_button then
			gui.set_enabled(self.ok_button.node, ok_only)
		end

		if self.cancel_button then
			gui.set_enabled(self.cancel_button.node, not ok_only)
		end

		if self.confirm_button then
			gui.set_enabled(self.confirm_button.node, not ok_only)
		end

		gui.cancel_animation(modal_node, h_colorw)
		gui.cancel_animation(modal_node, h_scale)
		gui.cancel_animation(fade_node, h_colorw)
		gui.animate(modal_node, h_colorw, 1, go.EASING_OUTEXPO, zoom_duration)
		gui.animate(modal_node, h_scale, vmath.vector3(1), go.EASING_OUTEXPO, zoom_duration)
		gui.animate(fade_node, h_colorw, fade_alpha, go.EASING_OUTEXPO, fade_duration)
	end

	if self.label_container then
		gui.delete_node(self.label_container)
	end

	local label_node = self.label_node
	local container = gui.clone(label_node)

	gui.set_parent(container, label_node)
	gui.set_scale(container, vmath.vector3(1))

	self.label_container = container
	local _, metrics = revive_text.richtext_safe_create(text, "dialogue", {
		combine_words = true,
		fonts = font_families,
		width = self.label_size.x,
		parent = container,
		align = richtext.ALIGN_CENTER,
		layers = font_layers
	})

	gui.set_position(container, vmath.vector3(0, metrics.height * 0.5, 0))
	self.focus_giver:try_focus_first()
end

function ConfirmModal.__index:hide()
	if not self.shown then
		return
	end

	self.shown = false
	local modal_node = self.modal_node
	local fade_node = self.fade_node

	gui.cancel_animation(modal_node, h_colorw)
	gui.cancel_animation(modal_node, h_scale)
	gui.cancel_animation(fade_node, h_colorw)
	gui.animate(modal_node, h_colorw, 0, go.EASING_OUTEXPO, zoom_duration)
	gui.animate(fade_node, h_colorw, 0, go.EASING_LINEAR, zoom_duration, 0, function ()
		gui.set_enabled(fade_node, false)
	end)
	gui.animate(modal_node, h_scale, zoom_scale, go.EASING_OUTEXPO, zoom_duration, 0, function ()
		gui.set_enabled(modal_node, false)
	end)

	if self.cancel_button then
		self.cancel_button:cancel_focus()
	end

	if self.confirm_button then
		self.confirm_button:cancel_focus()
	end

	if self.ok_button then
		self.ok_button:cancel_focus()
	end

	if self.cancel_key_prompt then
		self.cancel_key_prompt:set_enabled(false)
	end

	if self.confirm_key_prompt then
		self.confirm_key_prompt:set_enabled(false)
	end

	if self.ok_key_prompt then
		self.ok_key_prompt:set_enabled(false)
	end
end

function ConfirmModal.__index:window_change_size()
	self.layout:place()
end

function ConfirmModal.__index:switch_input_method(message)
	if not self.shown then
		return false
	end

	if self.cancel_key_prompt then
		self.cancel_key_prompt:switch_input_method()
	end

	if self.confirm_key_prompt then
		self.confirm_key_prompt:switch_input_method()
	end

	if self.ok_key_prompt then
		self.ok_key_prompt:switch_input_method()
	end

	if self.confirm_button then
		self.confirm_button:switch_input_method()
	end

	if self.cancel_button then
		self.cancel_button:switch_input_method()
	end

	if self.ok_button then
		self.ok_button:switch_input_method()
	end

	self.focus_giver:try_focus_first(message and message.nav_action)
end

function ConfirmModal.__index:on_input(action_id, action)
	if not self.shown then
		return false
	end

	if self.ok_only then
		if self.ok_key_prompt then
			self.ok_key_prompt:on_input(action_id, action)
		end

		if self.ok_button and self.ok_button:on_input(action_id, action) then
			return true
		end
	else
		if self.cancel_key_prompt then
			self.cancel_key_prompt:on_input(action_id, action)
		end

		if self.confirm_key_prompt then
			self.confirm_key_prompt:on_input(action_id, action)
		end

		if self.confirm_long_press and self.confirm_long_press:on_input(action_id, action) then
			return true
		end

		if self.cancel_button and self.cancel_button:on_input(action_id, action) then
			return true
		end

		if self.confirm_button and self.confirm_button:on_input(action_id, action) then
			return true
		end
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end

	return true
end

return ConfirmModal
