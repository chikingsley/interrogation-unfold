local Inertia = require("crit.inertia")
local ZoomPan = {}
local abs = math.abs
local zero3 = vmath.vector3(0)

local function in_out_cubic(t)
	t = t * 2

	if t < 1 then
		return 0.5 * t * t * t
	end

	t = t - 2

	return 0.5 * (t * t * t + 2)
end

function ZoomPan.new(options)
	options = options or {}
	local self = {
		viewport = options.viewport or {
			top = 0,
			left = 0,
			bottom = 0,
			right = 0
		},
		content = options.content or {
			top = 0,
			left = 0,
			bottom = 0,
			right = 0
		},
		min_zoom = options.min_zoom or 1,
		max_zoom = options.max_zoom or 1,
		zoom = options.zoom or 1,
		position = options.position or zero3,
		cancel_treshold = options.cancel_treshold or 10,
		on_change = options.on_change or function ()
			return
		end,
		on_cancel_touch = options.on_cancel_touch or function ()
			return
		end,
		is_user_panning = false,
		animating = false,
		enabled = true,
		cancel_touch = false
	}
	local inertia = Inertia.new()
	local total_dragged_x = 0
	local total_dragged_y = 0
	local frame_pan = zero3

	local function adjust_zoom_pan(zoom, position)
		if zoom < self.min_zoom then
			zoom = self.min_zoom
		end

		if self.max_zoom < zoom then
			zoom = self.max_zoom
		end

		local content = self.content
		local left = content.left * zoom + position.x
		local right = content.right * zoom + position.x
		local top = content.top * zoom + position.y
		local bottom = content.bottom * zoom + position.y
		local viewport = self.viewport
		local x = position.x
		local y = position.y

		if right - left < viewport.right - viewport.left then
			x = (viewport.left + viewport.right) * 0.5 - (content.left + content.right) * zoom * 0.5
		elseif viewport.left < left then
			x = viewport.left - content.left * zoom
		elseif right < viewport.right then
			x = viewport.right - content.right * zoom
		end

		if top - bottom < viewport.top - viewport.bottom then
			y = (viewport.bottom + viewport.top) * 0.5 - (content.bottom + content.top) * zoom * 0.5
		elseif viewport.bottom < bottom then
			y = viewport.bottom - content.bottom * zoom
		elseif top < viewport.top then
			y = viewport.top - content.top * zoom
		end

		return zoom, vmath.vector3(x, y, position.z)
	end

	local function set_zoom_pan(zoom, position)
		if not self.enabled then
			return
		end

		local zoom_adjusted, pan_adjusted = adjust_zoom_pan(zoom, position)

		if zoom_adjusted ~= self.zoom or pan_adjusted ~= self.position then
			self.zoom = zoom_adjusted
			self.position = pan_adjusted

			self.on_change(zoom_adjusted, pan_adjusted)
		end
	end

	local anim_zoom_initial, anim_zoom_final, anim_position_initial, anim_position_final, anim_cursor, anim_duration, anim_callback = nil

	local function animate_zoom_pan(zoom, position, duration, callback)
		if not self.enabled then
			return
		end

		anim_zoom_final, anim_position_final = adjust_zoom_pan(zoom, position)
		anim_position_initial = self.position
		anim_zoom_initial = self.zoom
		anim_callback = callback
		anim_cursor = 0
		anim_duration = duration
		self.animating = true
	end

	local function cancel_animation()
		self.animating = false
		anim_callback = nil
	end

	local function pan(dx, dy)
		if not self.enabled then
			return
		end

		cancel_animation()

		local delta = vmath.vector3(dx, dy, 0)
		frame_pan = frame_pan + delta

		set_zoom_pan(self.zoom, self.position + delta)
	end

	local function user_pan(dx, dy)
		if not self.enabled then
			return
		end

		self.is_user_panning = true
		total_dragged_x = total_dragged_x + dx
		total_dragged_y = total_dragged_y + dy
		local total_dragged = abs(total_dragged_x) + abs(total_dragged_y)

		pan(dx, dy)

		if self.cancel_treshold < total_dragged and not self.cancel_touch then
			self.cancel_touch = true

			self.on_cancel_touch()
		end
	end

	local function user_pan_end()
		self.cancel_touch = false
		total_dragged_x = 0
		total_dragged_y = 0
		self.is_user_panning = false
	end

	local function cancel_inertia()
		inertia.reset()

		frame_pan = zero3
	end

	local function update(dt)
		local panned = frame_pan
		frame_pan = zero3

		if not self.enabled then
			return
		end

		if self.animating then
			local callback_triggered = false
			anim_cursor = anim_cursor + dt / anim_duration

			if anim_cursor >= 1 then
				anim_cursor = 1
				self.animating = false
				callback_triggered = true
			end

			local t = in_out_cubic(anim_cursor)
			local zoom = anim_zoom_final * t + anim_zoom_initial * (1 - t)
			local position = vmath.lerp(t, anim_position_initial, anim_position_final)

			set_zoom_pan(zoom, position)

			if callback_triggered and anim_callback then
				anim_callback()

				anim_callback = nil
			end
		end

		local inertia_offset = inertia.update(dt, (self.is_user_panning or panned ~= zero3) and panned)

		if inertia_offset then
			set_zoom_pan(self.zoom, self.position + inertia_offset)
		end
	end

	local function set_enabled(enabled)
		if self.enabled ~= enabled then
			self.enabled = enabled

			if not enabled then
				cancel_animation()
				cancel_inertia()
				user_pan_end()
			end
		end
	end

	local function zoom_around(new_zoom, center)
		local center_local = (center - self.position) / self.zoom

		return center - center_local * new_zoom
	end

	local function force_layout()
		local position = self.position
		self.position = 42

		set_zoom_pan(self.zoom, position)
	end

	self.animate_zoom_pan = animate_zoom_pan
	self.cancel_animation = cancel_animation
	self.set_zoom_pan = set_zoom_pan
	self.user_pan = user_pan
	self.user_pan_end = user_pan_end
	self.update = update
	self.cancel_inertia = cancel_inertia
	self.set_enabled = set_enabled
	self.pan = pan
	self.zoom_around = zoom_around
	self.force_layout = force_layout

	if options.initial_layout then
		force_layout()
	end

	return self
end

return ZoomPan
