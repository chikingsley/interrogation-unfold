local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local filters = require("crit.filters")
local Layout = require("crit.layout")
local perks = require("campaign.perks")
local env = require("lib.environment")
local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local low_pass_filter = filters.low_pass(1)
local high_pass_filter = filters.high_pass(0.08)
local PHASE_RUNNING = state.PHASE_RUNNING
local PHASE_OVER = state.PHASE_OVER
local h_empathy_meter = hash("empathy_meter")
local h_level_highlight = hash("level_highlight")
local h_window_change_size = hash("window_change_size")
local h_set_subject = hash("set_subject")
local h_start_game = hash("start_game")
local h_init_level = hash("init_level")
local h_kill = hash("kill")
local h_tint_w = hash("tint.w")
local h_color_w = hash("color.w")
local h_stats = hash("stats")
local h_center_width_radius = hash("center_width_radius")
local h_size = hash("size")
local h_switch_input_method = hash("switch_input_method")
local max_empathy = 8
local min_empathy = -4
local max_position = 0.9
local min_position = 0.1
local delta_empathy = max_empathy - min_empathy
local delta_position = max_position - min_position
local position_a = delta_position / delta_empathy
local position_b = min_position - min_empathy * position_a
local pi2 = 2 * math.pi
local sin = math.sin
local cos = math.cos
local abs = math.abs

function _env:init()
	self.text = msg.url("#text")
	self.label = msg.url("#label")
	self.sprite = msg.url("#sprite")
	self.variance_angle = 0
	self.lp_filtered_position = 0
	self.hp_filtered_position = 0
	self.last_position = nil
	self.enabled = true

	go.set(self.label, h_tint_w, 0)
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
	self.button = Button.new(self.label, {
		is_sprite = true,
		padding_left = self.show_numeric and 55 or 0,
		on_state_change = Tooltip.button_on_state_change({
			id = "empathy_meter",
			type = h_stats,
			payload = {
				id = "empathy_meter"
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
	local source_alpha = go.get(self.label, h_tint_w)
	local target_alpha = stats_shown and 1 or 0
	local duration = math.abs(target_alpha - source_alpha) * 0.3

	self.button:set_enabled(stats_shown)
	go.cancel_animations(self.label, h_tint_w)
	go.cancel_animations(self.sprite, h_tint_w)
	go.cancel_animations(self.text, h_color_w)

	if duration ~= 0 then
		go.animate(self.label, h_tint_w, go.PLAYBACK_ONCE_FORWARD, target_alpha, go.EASING_LINEAR, duration)
		go.animate(self.sprite, h_tint_w, go.PLAYBACK_ONCE_FORWARD, target_alpha, go.EASING_LINEAR, duration)
		go.animate(self.text, h_color_w, go.PLAYBACK_ONCE_FORWARD, target_alpha, go.EASING_LINEAR, duration)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_set_subject then
		self.hp_filtered_position = 0
		self.last_position = nil

		update_shown(self)
	elseif message_id == h_kill or message_id == h_start_game then
		update_shown(self)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_init_level then
		self.enabled = not message.hide_meters
	elseif message_id == h_level_highlight then
		if message.object == h_empathy_meter then
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
	local empathy = subject.empathy * (subject.empathy_meter_scale or 1)
	local position = empathy * position_a + position_b
	local has_changed = position ~= self.last_position
	local d_position = abs(position - (self.last_position or position))
	local hp_filtered_position = high_pass_filter(self.hp_filtered_position, d_position, dt)
	self.hp_filtered_position = hp_filtered_position
	self.last_position = position
	position = low_pass_filter(self.lp_filtered_position, position, dt)
	self.lp_filtered_position = position
	local variance_angle = self.variance_angle + dt * 0.25

	if variance_angle > pi2 * 7 * 13 * 23 then
		variance_angle = variance_angle - pi2 * 7 * 13 * 23
	end

	self.variance_angle = variance_angle
	local amplitude_multiplier = hp_filtered_position * 15 + 1
	position = position + (sin(variance_angle * 7) * 0.025 + cos(variance_angle * 13) * 0.05 + sin(variance_angle * 23) * 0.0125) * amplitude_multiplier

	if position < min_position then
		position = min_position
	end

	if max_position < position then
		position = max_position
	end

	local center = go.get_world_position()
	local width = go.get(self.sprite, h_size).x * go.get_world_scale_uniform()

	sprite.set_constant(self.sprite, h_center_width_radius, vmath.vector4(center.x, center.y, width, position))

	if has_changed and self.show_numeric then
		label.set_text(self.text, tostring(empathy))
	end
end
