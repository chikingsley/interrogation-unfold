local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local filters = require("crit.filters")
local Layout = require("crit.layout")
local perks = require("campaign.perks")
local env = require("lib.environment")
local Tooltip = require("lib.tooltip")
local Button = require("crit.button")
local PHASE_RUNNING = state.PHASE_RUNNING
local PHASE_OVER = state.PHASE_OVER
local h_fear_meter = hash("fear_meter")
local h_level_highlight = hash("level_highlight")
local h_window_change_size = hash("window_change_size")
local h_set_subject = hash("set_subject")
local h_start_game = hash("start_game")
local h_init_level = hash("init_level")
local h_kill = hash("kill")
local h_center_alpha_x = hash("center_alpha.x")
local h_center_alpha_y = hash("center_alpha.y")
local h_pulses1 = hash("pulses1")
local h_amplitudes1 = hash("amplitudes1")
local h_pulses_amplitudes2 = hash("pulses_amplitudes2")
local h_tint_w = hash("center_alpha.w")
local h_color_w = hash("color.w")
local h_stats = hash("stats")
local h_switch_input_method = hash("switch_input_method")
local pulse_count = 6
local min_freq = 0.6666666666666666
local max_freq = 3
local min_fear = -3
local max_fear = 8
local min_amplitude = 0.3
local max_amplitude = 0.8
local regular_heartbeat_distance = 0.5
local regular_frequency = min_freq + (max_freq - min_freq) * -min_fear / (max_fear - min_fear)
local scan_speed = regular_heartbeat_distance * regular_frequency
local d_freq = max_freq - min_freq
local d_fear = max_fear - min_fear
local d_amplitude = max_amplitude - min_amplitude
local freq_a = d_freq / d_fear
local freq_b = min_freq - min_fear * freq_a
local amplitude_a = d_amplitude / d_freq
local amplitude_b = min_amplitude - min_freq * amplitude_a
local filter = filters.high_pass(0.08)

function _env:init()
	self.sprite = msg.url("#sprite")
	self.text = msg.url("#text")
	self.filtered_freq = 0
	self.last_freq = nil
	self.enabled = true
	self.last_pulse = 0
	self.pulses = {}
	self.amplitudes = {}
	self.time_to_spawn = 0
	self.shown = false

	for i = 1, pulse_count do
		self.pulses[i] = -0.5
		self.amplitudes[i] = 0.5
	end

	go.set(self.sprite, h_tint_w, 0)
	go.set(self.text, h_color_w, 0)
	label.set_text(self.text, "")

	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(msg.url("."), {
		grav_y = 1,
		grav_x = 1
	})

	self.show_numeric = perks.profiler or env.show_stats
	self.button = Button.new(self.sprite, {
		is_sprite = true,
		padding_left = self.show_numeric and 55 or 0,
		on_state_change = Tooltip.button_on_state_change({
			id = "fear_meter",
			type = h_stats,
			payload = {
				id = "fear_meter"
			}
		}, false)
	})

	self.button:set_enabled(false)

	self.sub_id = dispatcher.subscribe({
		h_start_game,
		h_set_subject,
		h_kill,
		h_window_change_size,
		h_level_highlight,
		h_init_level,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function update_shown(self)
	local subject = store.subjects[state.current_subject]
	local stats_shown = self.enabled and (state.phase == PHASE_RUNNING or state.phase == PHASE_OVER) and subject.health > 0
	local source_alpha = go.get(self.sprite, h_tint_w)
	local target_alpha = stats_shown and 1 or 0
	local duration = math.abs(target_alpha - source_alpha) * 0.3

	self.button:set_enabled(stats_shown)
	go.cancel_animations(self.sprite, h_tint_w)
	go.cancel_animations(self.text, h_color_w)

	if duration ~= 0 then
		local callback = nil

		if target_alpha == 0 then
			function callback()
				self.shown = false
			end
		else
			self.shown = true
		end

		go.animate(self.sprite, h_tint_w, go.PLAYBACK_ONCE_FORWARD, target_alpha, go.EASING_LINEAR, duration, 0, callback)
		go.animate(self.text, h_color_w, go.PLAYBACK_ONCE_FORWARD, target_alpha, go.EASING_LINEAR, duration)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_set_subject then
		self.filtered_freq = 0
		self.last_freq = nil

		update_shown(self)
	elseif message_id == h_kill or message_id == h_start_game then
		update_shown(self)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_init_level then
		self.enabled = not message.hide_meters
	elseif message_id == h_level_highlight then
		if message.object == h_fear_meter then
			self.enabled = true

			update_shown(self)
		end
	elseif message_id == h_switch_input_method then
		self.button:switch_input_method()
	end
end

function _env:on_input(action_id, action)
	if self.button:on_input(action_id, action) then
		return true
	end
end

function _env:update(dt)
	if state.paused then
		return
	end

	local subject = store.subjects[state.current_subject]
	local fear = subject.fear * (subject.fear_meter_scale or 1)
	local raw_freq = fear * freq_a + freq_b
	local has_changed = self.last_freq ~= raw_freq
	local delta_vel = raw_freq - (self.last_freq or raw_freq)
	local filtered_freq = filter(self.filtered_freq, delta_vel, dt)
	self.last_freq = raw_freq
	self.filtered_freq = filtered_freq
	local freq = raw_freq + 2 * filtered_freq

	if freq < min_freq then
		freq = min_freq
	end

	if max_freq < freq then
		freq = max_freq
	end

	local pulses = self.pulses
	local amplitudes = self.amplitudes
	local d_pos = dt * scan_speed

	for i = 1, pulse_count do
		pulses[i] = pulses[i] - d_pos
	end

	local time_to_spawn = self.time_to_spawn - dt

	while time_to_spawn <= 0 do
		local amplitude, pause = nil

		if not self.shown and subject.health <= 0 then
			amplitude = 0
			pause = 1 / max_freq
		else
			local amp_freq = raw_freq + 4 * filtered_freq

			if amp_freq < min_freq then
				amp_freq = min_freq
			end

			if max_freq < amp_freq then
				amp_freq = max_freq
			end

			amplitude = amp_freq * amplitude_a + amplitude_b
			pause = 1 / freq
		end

		local i = self.last_pulse + 1

		if pulse_count < i then
			i = i - pulse_count
		end

		self.last_pulse = i
		pulses[i] = 1.1 + time_to_spawn * scan_speed
		amplitudes[i] = amplitude
		time_to_spawn = time_to_spawn + pause
	end

	self.time_to_spawn = time_to_spawn
	local sprite_url = self.sprite

	sprite.set_constant(sprite_url, h_pulses1, vmath.vector4(pulses[1], pulses[2], pulses[3], pulses[4]))
	sprite.set_constant(sprite_url, h_amplitudes1, vmath.vector4(amplitudes[1], amplitudes[2], amplitudes[3], amplitudes[4]))
	sprite.set_constant(sprite_url, h_pulses_amplitudes2, vmath.vector4(pulses[5], pulses[6], amplitudes[5], amplitudes[6]))

	local pos = go.get_world_position(sprite_url)

	go.set(sprite_url, h_center_alpha_x, pos.x)
	go.set(sprite_url, h_center_alpha_y, pos.y)

	if has_changed and self.show_numeric then
		label.set_text(self.text, tostring(fear))
	end
end
