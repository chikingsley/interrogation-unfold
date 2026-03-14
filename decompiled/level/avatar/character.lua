local store = require("level.store")
local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local large_ui = require("lib.large_ui")
local h_place_sprite = hash("place_sprite")
local h_position = hash("position")
local h_tintw = hash("tint.w")
local h_kill = hash("kill")
local h_start_game = hash("start_game")
local h_run_animation = hash("run_animation")
local h_play_animation = hash("play_animation")
local h_animation_done = hash("animation_done")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_alt = hash("alt")
local h_ = hash("")
local h_update_insanity_question = hash("update_insanity_question")
local h_flash_twisted = hash("flash_twisted")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_sprite_animation_done = hash("sprite_animation_done")
local request_idle_animation, set_enabled, schedule_twisted_flash, sprite_set_alpha, sprite_set_enabled = nil

function _env:init()
	if self.fade_animation then
		self.sprite1 = msg.url("sprite1#sprite")
		self.sprite1_go = msg.url("sprite1")
		self.bottom_slot = go.get_position(self.sprite1_go)
		self.sprite2 = msg.url("sprite2#sprite")
		self.sprite2_go = msg.url("sprite2")
		self.top_slot = go.get_position(self.sprite2_go)
		self.pan = 1
	elseif self.trimmed_sprite then
		local sprite_url = self.trimmed_sprite_url
		self.sprite = msg.url(sprite_url.socket, sprite_url.path, "sprite")
		self.sprite_controller = msg.url(sprite_url.socket, sprite_url.path, "sprite_animation")
	else
		self.sprite = msg.url("#sprite")
	end

	self.go = msg.url(".")

	if self.has_shadow then
		self.shadow = msg.url("#shadow")
	end

	self.alpha = 0
	self.killed = false
	self.enabled = true
	self.is_alt = false
	self.effective_is_alt = false
	self.position = go.get_position()
	self.is_twisted = false

	if self.idle_animation == h_ then
		self.idle_animation = nil
	end

	if self.idle_animation_fear == h_ then
		self.idle_animation_fear = self.idle_animation
	end

	if self.idle_animation_empathy == h_ then
		self.idle_animation_empathy = self.idle_animation
	end

	if self.idle_animation_alt == h_ then
		self.idle_animation_alt = self.idle_animation
	end

	if self.idle_animation_blink == h_ then
		self.idle_animation_blink = self.idle_animation
	end

	if self.idle_animation_fear_blink == h_ then
		self.idle_animation_fear_blink = self.idle_animation_fear
	end

	if self.idle_animation_empathy_blink == h_ then
		self.idle_animation_empathy_blink = self.idle_animation_empathy
	end

	if self.idle_animation_alt_blink == h_ then
		self.idle_animation_alt_blink = self.idle_animation_alt
	end

	if self.death_animation == h_ then
		self.death_animation = nil
	end

	if self.idle_animation_dead == h_ then
		self.idle_animation_dead = nil
	end

	if self.has_twisted_frame then
		self.twisted_sprite = msg.url("#twisted")

		msg.post(self.twisted_sprite, h_disable)
	end

	if self.is_fixed then
		self.shown = true

		request_idle_animation(self)
	else
		self.shown = false

		sprite_set_alpha(self, 0)
		set_enabled(self, false)
	end

	self.sub_id = dispatcher.subscribe({
		h_update_insanity_question
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function play_fade_animation(self, animation)
	if self.current_animation == animation then
		return
	end

	self.current_animation = animation
	self.sprite2 = self.sprite1
	self.sprite1 = self.sprite2
	self.sprite2_go = self.sprite1_go
	self.sprite1_go = self.sprite2_go
	self.pan = 1 - self.pan

	msg.post(self.sprite1, h_play_animation, {
		id = animation
	})
end

local function fade_animation_callback(self)
	self.fade_animation_timer = nil

	request_idle_animation(self)
end

local function sprite_play_animation(self, animation)
	animation = hash(animation)

	if self.fade_animation then
		if self.fade_animation_timer then
			timer.cancel(self.fade_animation_timer)
		end

		play_fade_animation(self, animation)

		self.fade_animation_timer = timer.delay(self.fade_animation_hold, false, fade_animation_callback)
	elseif self.trimmed_sprite then
		msg.post(self.sprite_controller, h_sprite_play_animation, {
			id = animation
		})
	else
		msg.post(self.sprite, h_play_animation, {
			id = animation
		})
	end
end

function sprite_set_enabled(self, enabled)
	local message = enabled and h_enable or h_disable

	if self.fade_animation then
		msg.post(self.sprite1, message)
		msg.post(self.sprite2, message)
	else
		msg.post(self.sprite, message)
	end
end

local function fade_animation_update(self, dt)
	local pan = self.pan

	if pan >= 1 then
		return
	end

	pan = pan + dt / self.fade_animation_duration

	if pan >= 1 then
		pan = 1

		go.set_position(self.bottom_slot, self.sprite1_go)
		go.set_position(self.top_slot, self.sprite2_go)
	end

	self.pan = pan
end

function sprite_set_alpha(self, alpha)
	if self.fade_animation then
		self.sprite_alpha = alpha
		local pan = self.pan

		go.set(self.sprite1, h_tintw, alpha * pan)
		go.set(self.sprite2, h_tintw, alpha * (1 - pan))
	else
		go.set(self.sprite, h_tintw, alpha)
	end

	if self.shadow then
		go.set(self.shadow, h_tintw, alpha)
	end
end

function request_idle_animation(self)
	local animation = nil
	local animation_queue = self.animation_queue

	if animation_queue then
		sprite_play_animation(self, animation_queue[1])

		self.animation_queue = animation_queue[2]

		return
	end

	if self.killed then
		animation = self.idle_animation_dead
	end

	if not animation then
		local subject = store.subjects[self.subject_id]
		local is_afraid = subject.fear_idle_treshold <= subject.fear
		local is_empathic = subject.empathy_idle_treshold <= subject.empathy
		local emotion = is_afraid and "fear" or is_empathic and "empathy" or nil

		if self.effective_is_alt then
			emotion = "alt"
		end

		local last_animation = self.blink_last_animation or 1
		local repeat_count = self.blink_repeat_count or 0
		local next_animation = nil

		if repeat_count >= (last_animation == 1 and 1 or 5) then
			next_animation = 3 - last_animation
		else
			next_animation = math.random(2)
		end

		self.blink_last_animation = next_animation

		if next_animation == last_animation then
			self.blink_repeat_count = repeat_count + 1
		else
			self.blink_repeat_count = 1
		end

		local has_blink = next_animation == 1

		if has_blink then
			if emotion then
				animation = self["idle_animation_" .. emotion .. "_blink"]
			else
				animation = self.idle_animation_blink
			end
		elseif emotion then
			animation = self["idle_animation_" .. emotion]
		else
			animation = self.idle_animation
		end
	end

	if animation then
		sprite_play_animation(self, animation)
	end
end

local function twisted_flash_end(self)
	self.is_twisted = false

	msg.post(self.twisted_sprite, h_disable)

	if self.enabled then
		sprite_set_enabled(self, true)
	end

	if not self.twisted_timer then
		schedule_twisted_flash(self)
	end
end

local function twisted_flash(self)
	self.twisted_timer = nil

	if state.current_subject ~= self.subject_id then
		schedule_twisted_flash(self)

		return
	end

	self.is_twisted = true

	msg.post(self.twisted_sprite, h_enable)
	sprite_set_enabled(self, false)
	dispatcher.dispatch(h_flash_twisted)
	timer.delay(0.03, false, twisted_flash_end)
end

function schedule_twisted_flash(self)
	local duration = math.random() * 5
	self.twisted_timer = timer.delay(duration, false, twisted_flash)
end

function set_enabled(self, enabled)
	if self.enabled == enabled then
		return
	end

	self.enabled = enabled

	if self.is_twisted then
		return
	end

	sprite_set_enabled(self, enabled)
end

local function cancel_pending_animations(self)
	self.animation_queue = nil
	self.effective_is_alt = self.is_alt

	if self.animation_timer then
		timer.cancel(self.animation_timer)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_place_sprite then
		local offset = message.offset

		if not offset then
			set_enabled(self, false)

			return
		end

		local dt = message.dt

		if self.killed and not self.shown and dt and self.alpha > 0 then
			self.alpha = math.max(0, self.alpha - dt)
		end

		if self.shown and dt and self.alpha < 1 then
			self.alpha = math.min(self.alpha + dt * 2.5, 1)
		end

		local position_offset = vmath.vector3(offset * 400, 0, 0)
		local alpha = math.pow(self.alpha, 3) * (1 - math.min(math.abs(offset), 1))

		if self.is_fixed then
			position_offset = vmath.vector3()
			alpha = 1
		end

		if self.fade_animation then
			fade_animation_update(self, dt)
		end

		local position = self.position

		if large_ui.enabled then
			position = position + self.large_ui_offset
		end

		local inv_scale = 1 / state.table_scale
		local scaled_pos = vmath.vector3(position.x * inv_scale, position.y * inv_scale, position.z)

		go.set(self.go, h_position, scaled_pos + position_offset)
		sprite_set_alpha(self, alpha)
		set_enabled(self, alpha > 0)
	elseif message_id == h_run_animation then
		if self.is_companion == not not message.companion then
			local mode = message.idle_mode

			if mode then
				local is_alt = mode == h_alt

				if self.is_alt == is_alt then
					return
				end

				self.is_alt = is_alt
				local transition = is_alt and self.normal_to_alt_transition or self.alt_to_normal_transition

				if transition ~= h_ then
					self.animation_timer = timer.delay(self.animation_delay, false, function ()
						self.animation_timer = nil

						cancel_pending_animations(self)
						sprite_play_animation(self, transition)
					end)
				else
					cancel_pending_animations(self)
					request_idle_animation(self)
				end

				return
			end

			local animation = nil

			if self.is_alt then
				animation = message.alt_animation
			else
				animation = message.animation
			end

			if animation then
				local delay = message.instant and 0 or self.animation_delay
				self.animation_timer = timer.delay(delay, false, function ()
					self.animation_timer = nil

					cancel_pending_animations(self)

					if type(animation) == "table" then
						sprite_play_animation(self, animation[1])

						self.animation_queue = animation[2]
					else
						sprite_play_animation(self, animation)

						self.animation_queue = nil
					end
				end)
			end
		end
	elseif message_id == h_animation_done or message_id == h_sprite_animation_done then
		if not self.fade_animation then
			request_idle_animation(self)
		end
	elseif message_id == h_kill then
		self.killed = true

		if self.hide_on_death then
			self.shown = false
		end

		local animation = self.death_animation

		if animation then
			cancel_pending_animations(self)
			sprite_play_animation(self, animation)
		end
	elseif message_id == h_start_game then
		if not self.is_fixed then
			self.shown = true

			set_enabled(self, true)
			request_idle_animation(self)
		end
	elseif message_id == h_update_insanity_question and self.has_twisted_frame then
		if message.shown then
			schedule_twisted_flash(self)
		else
			if self.is_twisted then
				twisted_flash_end(self)
			end

			if self.twisted_timer then
				timer.cancel(self.twisted_timer)

				self.twisted_timer = nil
			end
		end
	end
end
