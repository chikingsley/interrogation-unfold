local Layout = require("crit.layout")
local Button = require("crit.button")
local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local level = require("level.interface")
local intl = require("crit.intl")
local Tooltip = require("lib.tooltip")
local PHASE_RUNNING = state.PHASE_RUNNING
local PHASE_OVER = state.PHASE_OVER
local h_window_change_size = hash("window_change_size")
local h_attempt_pause = hash("attempt_pause")
local h_set_subject = hash("set_subject")
local h_init_level = hash("init_level")
local h_start_game = hash("start_game")
local h_ask_question = hash("ask_question")
local h_torture = hash("torture")
local h_game_over = hash("game_over")
local h_level_highlight = hash("level_highlight")
local h_level_highlight_cancel = hash("level_highlight_cancel")
local h_timer = hash("timer")
local h_timer_changed = hash("timer_changed")
local h_red_timer = hash("red_timer")
local h_scale = hash("scale")
local h_color_w = hash("color.w")
local h_label = hash("label")
local h_pause = hash("pause")
local h_positionx = hash("position.x")
local h_play_sfx = hash("play_sfx")
local h_switch_input_method = hash("switch_input_method")
local red = vmath.vector4(1, 0, 0, 1)
local critical_thresholds = {
	60,
	30,
	15,
	10,
	5,
	0
}
local update_timer = nil

local function get_button_bounding_box(button)
	return Tooltip.get_sprite_bounding_box(button.node)
end

function _env:init()
	self.label = msg.url("#label")
	self.pause_label = msg.url("#label_pause")
	self.highlighted = false
	self.critical = false
	self.critical_timer_factory = msg.url("#timer_critical")
	self.add_popup_factory = msg.url("#timer_add_popup")
	self.old_seconds = 0
	self.pause_button = Button.new(self.pause_label, {
		is_sprite = true,
		padding_top = 30,
		padding_right = 50,
		on_state_change = Tooltip.button_on_state_change({
			id = h_pause,
			type = h_pause,
			get_button_bounding_box = get_button_bounding_box
		}, button_sound.with_sound()),
		faded_nodes = {},
		faded_labels = {
			self.label,
			self.pause_label
		},
		action = function ()
			dispatcher.dispatch(h_attempt_pause)
		end
	})
	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(msg.url("."), {
		grav_y = 1,
		grav_x = 1
	})
	go.set("#red_highlight_sprite", "tint", red)
	update_timer(self)

	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_start_game,
		h_game_over,
		h_timer_changed,
		h_set_subject,
		h_ask_question,
		h_torture,
		h_window_change_size,
		h_switch_input_method,
		h_level_highlight,
		h_level_highlight_cancel
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_input(action_id, action)
	if self.pause_button:on_input(action_id, action) then
		return true
	end
end

local function spawn_critical_popup(self, text, threshold)
	local critical_timer_popup = factory.create(self.critical_timer_factory)
	local url = msg.url(critical_timer_popup)
	local label_url = msg.url(url.socket, url.path, h_label)

	label.set_text(label_url, text)
	go.animate(url, h_scale, go.PLAYBACK_ONCE_FORWARD, 3, go.EASING_LINEAR, self.popup_anim_duration)
	go.animate(label_url, h_color_w, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, self.popup_anim_duration, 0, function ()
		go.delete(critical_timer_popup)
	end)

	local timer_sfx = threshold == 0 and "timer_end" or "timer_low"

	dispatcher.dispatch(h_play_sfx, {
		sfx = timer_sfx
	})
end

local function spawn_add_popup(self, amount, decreased)
	local add_popup = factory.create(self.add_popup_factory)
	local url = msg.url(add_popup)
	local label_url = msg.url(url.socket, url.path, h_label)
	local text = (decreased and "-" or "+") .. tostring(amount)

	label.set_text(label_url, text)

	local original_pos_x = go.get(url, h_positionx)

	go.animate(url, h_positionx, go.PLAYBACK_ONCE_FORWARD, original_pos_x - 100, go.EASING_LINEAR, self.popup_anim_duration)
	go.animate(label_url, h_color_w, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, self.popup_anim_duration, 0, function ()
		go.delete(add_popup)
	end)
end

function update_timer(self)
	local timer_text = nil
	local highlighted = self.highlighted

	if (store.time_limit or highlighted) and (state.phase == PHASE_RUNNING or state.phase == PHASE_OVER) then
		local time = highlighted and 59 or store.time_limit - state.time_elapsed
		time = math.ceil(time)
		local seconds = time % 60
		local minutes = math.floor(time / 60)
		local seconds_txt = seconds < 10 and "0" .. seconds or "" .. seconds
		timer_text = minutes .. ":" .. seconds_txt

		for i, threshold in ipairs(critical_thresholds) do
			if self.critical ~= i and math.ceil(time) == threshold then
				self.critical = i

				spawn_critical_popup(self, timer_text, threshold)
			end
		end

		self.old_seconds = seconds
	end

	if timer_text then
		label.set_text(self.label, timer_text)
		label.set_text(self.pause_label, "")
	else
		label.set_text(self.label, "")
		label.set_text(self.pause_label, intl("level.pause"))
	end
end

local function flash_timer(self)
	timer.delay(0.2, false, function ()
		level.highlight_object(h_red_timer)
		timer.delay(2, false, function ()
			level.cancel_highlight()
		end)
	end)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_start_game then
		update_timer(self)

		if store.time_limit then
			flash_timer(self)
		end
	elseif message_id == h_game_over then
		update_timer(self)
	elseif message_id == h_timer_changed then
		self.critical = false

		flash_timer(self)
	elseif message_id == h_window_change_size then
		self.layout:place()
	elseif message_id == h_switch_input_method then
		self.pause_button:switch_input_method()
	elseif message_id == h_level_highlight then
		if message.object == h_timer then
			self.highlighted = true

			update_timer(self)
		end
	elseif message_id == h_level_highlight_cancel then
		self.highlighted = false

		update_timer(self)
	end
end

function _env:update(dt)
	if not state.paused and state.phase == PHASE_RUNNING then
		update_timer(self)
	end
end
