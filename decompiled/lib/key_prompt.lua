local input_state = require("crit.input_state")
local h_colorw = hash("color.w")
local h_scale = hash("scale")
local h_tintw = hash("tint.w")
local h_enable = hash("enable")
local h_disable = hash("disable")
local KeyPrompt = {
	__index = {}
}

function KeyPrompt.new(node, opts)
	opts = opts or {}
	local self = {
		enabled = true,
		pressed = false,
		node = node,
		halo = opts.halo,
		scale_factor = opts.scale_factor or 1,
		halo_clones = {},
		action_id = opts.action_id,
		input_method = input_state.INPUT_METHOD_GAMEPAD,
		is_sprite = opts.is_sprite or false,
		fade_duration = opts and opts.fade_duration or 0.51,
		is_long_press = opts and opts.is_long_press or false
	}

	if opts.enabled ~= nil then
		self.enabled = opts.enabled
	end

	setmetatable(self, KeyPrompt)

	local starts_shown = self.enabled and input_state.input_method == self.input_method
	self.shown = starts_shown
	local halo = self.halo

	if self.is_sprite then
		if node then
			msg.post(node, starts_shown and h_enable or h_disable)
			go.set(node, h_tintw, starts_shown and 1 or 0)
		end

		if halo then
			msg.post(halo, starts_shown and h_enable or h_disable)
			go.set(halo, h_tintw, 0)
		end
	else
		if halo then
			gui.set_enabled(halo, false)
		end

		if node then
			gui.set_enabled(node, starts_shown)

			local color = gui.get_color(node)
			color.w = starts_shown and 1 or 0

			gui.set_color(node, color)
		end
	end

	return self
end

local function KeyPrompt_update_state(self, anim_duration)
	local shown = self.enabled and input_state.input_method == self.input_method

	if shown == self.shown then
		return
	end

	self.shown = shown
	local node = self.node
	local halo = self.halo
	local duration = anim_duration and anim_duration or self.fade_duration

	if self.is_sprite then
		go.cancel_animations(node, h_tintw)

		if shown then
			msg.post(node, h_enable)
			go.set(node, h_scale, vmath.vector3(1) * self.scale_factor)
			go.animate(node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, duration)

			if halo then
				msg.post(halo, h_enable)
				go.set(halo, h_tintw, 0)
			end
		else
			go.animate(node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, duration, 0, function ()
				go.set(node, h_scale, vmath.vector3(1) * self.scale_factor)
				go.set(node, h_tintw, 0)
				msg.post(node, h_disable)

				if halo then
					go.set(halo, h_tintw, 0)
					msg.post(halo, h_disable)
				end
			end)
		end
	else
		gui.cancel_animation(node, h_colorw)

		if shown then
			gui.set_enabled(node, true)
			gui.set_scale(node, vmath.vector3(1) * self.scale_factor)
			gui.animate(node, h_colorw, 1, go.EASING_LINEAR, duration)
		else
			gui.animate(node, h_colorw, 0, go.EASING_LINEAR, duration, 0, function ()
				for halo_node, _ in pairs(self.halo_clones) do
					gui.delete_node(halo_node)
				end

				self.halo_clones = {}

				gui.set_scale(node, vmath.vector3(1) * self.scale_factor)
				gui.set_enabled(node, false)
			end)
		end
	end
end

function KeyPrompt.__index:set_enabled(enabled, anim_duration)
	self.enabled = enabled

	KeyPrompt_update_state(self, anim_duration)
end

function KeyPrompt.__index:switch_input_method()
	KeyPrompt_update_state(self)
end

function KeyPrompt.__index:trigger_halo()
	local halo = self.halo

	if self.is_sprite then
		if halo then
			local halo_url = msg.url(halo)

			go.cancel_animations(halo_url, h_scale)
			go.cancel_animations(halo_url, h_tintw)
			go.set(halo_url, h_scale, vmath.vector3(1))
			go.set(halo_url, h_tintw, 1)
			go.animate(halo_url, h_scale, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(2), go.EASING_LINEAR, 0.5)
			go.animate(halo_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.4)
		end
	elseif halo then
		local halo_node = gui.clone(halo)

		gui.set_enabled(halo_node, true)

		self.halo_clones[halo_node] = true

		gui.animate(halo_node, h_scale, vmath.vector3(2), gui.EASING_LINEAR, 0.4, 0, function ()
			gui.delete_node(halo_node)

			self.halo_clones[halo_node] = nil
		end)
		gui.animate(halo_node, h_colorw, 0, gui.EASING_LINEAR, 0.4)
	end
end

function KeyPrompt.__index:on_input(action_id, action)
	if self.action_id == action_id and self.shown then
		local node = self.node

		if action.pressed then
			self.pressed = true

			if not self.is_long_press then
				if self.is_sprite then
					go.cancel_animations(node, h_scale)
					go.animate(node, h_scale, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(0.9) * self.scale_factor, go.EASING_LINEAR, 0.2)
				else
					gui.cancel_animation(node, h_scale)
					gui.animate(node, h_scale, vmath.vector3(0.9) * self.scale_factor, gui.EASING_OUTEXPO, 0.2)
				end
			end
		elseif action.released and self.pressed then
			self.pressed = false

			if not self.is_long_press then
				if self.is_sprite then
					go.animate(node, h_scale, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(1) * self.scale_factor, go.EASING_LINEAR, 0.2)
				else
					gui.cancel_animation(node, h_scale)
					gui.animate(node, h_scale, vmath.vector3(1) * self.scale_factor, gui.EASING_INOUTBACK, 0.2)
				end

				self:trigger_halo()
			end
		end
	end
end

function KeyPrompt.select(sprite_url, options, selector)
	local spec = options[selector] or options.default

	if spec then
		sprite.play_flipbook(sprite_url, spec[1])

		return sprite_url, spec[2]
	end

	return sprite_url
end

function KeyPrompt.select_gui(node, options, selector)
	local spec = options[selector] or options.default

	if spec then
		gui.play_flipbook(node, spec[1])

		return node, spec[2]
	end

	return node
end

return KeyPrompt
