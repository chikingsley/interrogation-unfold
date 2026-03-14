local dispatcher = require("crit.dispatcher")
local h_light_flicker_animate = hash("light_flicker_animate")
local LightFlicker = {
	STATE_RUNNING = 2,
	LIGHT_OFF = 1,
	STATE_FINISHED = 3,
	LIGHT_ON = 2,
	STATE_UNINITIALIZED = 0,
	STATE_READY = 1,
	__index = {},
	animated_sprites = {},
	default_background_tint_dark = vmath.vector4(1, 1, 1, 0.07),
	default_background_tint_light = vmath.vector4(1, 1, 1, 0.1),
	default_object_tint_dark = vmath.vector4(0.05, 0.05, 0.05, 1),
	default_object_tint_light = vmath.vector3(1, 1, 1, 1)
}

function LightFlicker.new(opts)
	opts = opts or {}
	local self = {
		delay = 0,
		elapsed_last_delay = 0,
		total_elapsed = 0,
		collections = opts.collections or {},
		sprites = opts.sprites or {},
		initial_delay = opts.initial_delay or 0,
		duration = opts.duration or 2,
		flicker_duration = opts.flicker_duration or 0.05,
		flicker_interval = opts.flicker_interval or 0.01,
		object_tint = opts.object_tint or {
			LightFlicker.default_object_tint_dark,
			LightFlicker.default_background_tint_light
		},
		background_tint = opts.background_tint or {
			LightFlicker.default_background_tint_dark,
			LightFlicker.default_background_tint_light
		},
		state = LightFlicker.STATE_UNINITIALIZED
	}

	for index, collection in pairs(self.collections) do
		LightFlicker.animated_sprites[collection] = self.sprites[index]
	end

	self.state = LightFlicker.STATE_READY

	setmetatable(self, LightFlicker)

	return self
end

function LightFlicker.__index:start()
	timer.delay(self.initial_delay, false, function ()
		self.state = LightFlicker.STATE_RUNNING
	end)
end

function LightFlicker.__index:update(dt)
	if self.state == LightFlicker.STATE_RUNNING then
		local object_tint_index, background_tint_index = nil

		if self.total_elapsed < self.duration then
			self.elapsed_last_delay = self.elapsed_last_delay + dt
			local random_tint_index = math.random(1, 2)
			object_tint_index = random_tint_index
			background_tint_index = random_tint_index

			if self.delay < self.elapsed_last_delay then
				self.elapsed_last_delay = 0
				self.delay = math.random() * self.flicker_interval + 0.01
			end
		elseif self.state == LightFlicker.STATE_RUNNING then
			object_tint_index = LightFlicker.LIGHT_ON
			background_tint_index = LightFlicker.LIGHT_ON
			self.state = LightFlicker.STATE_FINISHED
		end

		dispatcher.dispatch(h_light_flicker_animate, {
			delay = self.delay,
			duration = self.flicker_duration,
			object_tint = self.object_tint[object_tint_index],
			background_tint = self.background_tint[background_tint_index]
		})

		self.total_elapsed = self.total_elapsed + dt
	end
end

return LightFlicker
