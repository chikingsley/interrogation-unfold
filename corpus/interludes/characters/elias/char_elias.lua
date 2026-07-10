local slots = require("interludes.slots")
local dispatcher = require("crit.dispatcher")
local h_interludes_show_character = hash("interludes_show_character")
local h_interludes_hide_character_in_slot = hash("interludes_hide_character_in_slot")
local h_interludes_animate_character = hash("interludes_animate_character")
local h_play_animation_sfx = hash("play_animation_sfx")
local h_tint = hash("tint")
local h_tintx = hash("tint.x")
local h_tinty = hash("tint.y")
local h_tintz = hash("tint.z")
local h_tintw = hash("tint.w")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_ = hash("")
local h_transition_started = hash("transition_started")
local h_transition_completed = hash("transition_completed")
local h_elias_final_stage = hash("elias_final_stage")
local h_elias_idle4_cut = hash("elias_idle4_cut")
local h_elias_idle4_cut_hand = hash("elias_idle4_cut_hand")
local h_elias_idle4_draw_knife = hash("elias_idle4_draw_knife")
local h_elias_idle4_put_away_knife = hash("elias_idle4_put_away_knife")
local h_knife_hidden = hash("knife_hidden")
local h_knife_shown = hash("knife_shown")
local h_pixel = hash("pixel")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_sprite_animation_done = hash("sprite_animation_done")
local h_sprite_animation = hash("sprite_animation")
local show_character, animate_character, request_idle_animation, cancel_pending_animations, on_animation_done, animate_sprite = nil

function _env:init()
	if self.disabled then
		return
	end

	self.enabled = false
	self.focused = false
	self.transitioning = false

	sprite.set_constant(self.sprite, h_tint, vmath.vector4(1, 1, 1, 0))

	if self.idle_animation == h_ then
		self.idle_animation = nil
	end

	if self.idle_animation_blink == h_ then
		self.idle_animation_blink = self.idle_animation
	end

	if self.transition_animation == h_ then
		self.transition_animation = nil
	end

	if self.initial_animation == h_ then
		self.initial_animation = nil
	end

	if self.alt_idle_animation == h_ then
		self.alt_idle_animation = nil
	end

	if self.alt_idle_animation_blink == h_ then
		self.alt_idle_animation_blink = self.alt_idle_animation
	end

	if self.alt_idle_transition == h_ then
		self.alt_idle_transition = nil
	end

	local this_url = msg.url(".")

	if self.knife_sprite == this_url then
		self.knife_sprite = nil
	end

	if self.aux_sprite == this_url then
		self.aux_sprite = nil
	end

	local slot = slots.slot_of_char[self.name]

	if slot then
		show_character(self, self.initial_animation)
	end

	self.sub_id = dispatcher.subscribe({
		h_interludes_show_character,
		h_interludes_hide_character_in_slot,
		h_interludes_animate_character
	})
end

function _env:final()
	if self.disabled then
		return
	end

	dispatcher.unsubscribe(self.sub_id)
end

function animate_sprite(self, sprite_url, animation, has_callback)
	if self.trimmed_sprite then
		local anim_url = msg.url(sprite_url)
		anim_url.fragment = h_sprite_animation

		msg.post(anim_url, h_sprite_play_animation, {
			id = animation,
			tag = has_callback and 1 or nil
		})
	else
		sprite.play_flipbook(sprite_url, animation, has_callback and on_animation_done or nil)
	end
end

function request_idle_animation(self)
	local go_sprite = self.sprite
	local animation = nil
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
		animation = self.idle_animation_blink
	else
		animation = self.idle_animation
	end

	if animation then
		animate_sprite(self, go_sprite, animation, true)
	end
end

function cancel_pending_animations(self)
	if self.animation_timer then
		timer.cancel(self.animation_timer)
	end
end

function show_character(self, animation)
	local go_sprite = self.sprite

	msg.post(go_sprite, h_enable)

	self.enabled = true
	self.focused = true

	go.cancel_animations(go_sprite, h_tintx)
	go.cancel_animations(go_sprite, h_tinty)
	go.cancel_animations(go_sprite, h_tintz)
	go.cancel_animations(go_sprite, h_tintw)
	go.cancel_animations(go_sprite, h_tint)

	if self.show_immediately then
		sprite.set_constant(go_sprite, h_tint, vmath.vector4(1, 1, 1, 1))
		go.set(go_sprite, h_tintw, 1)
	else
		sprite.set_constant(go_sprite, h_tint, vmath.vector4(1, 1, 1, 0))
		timer.delay(0, false, function ()
			timer.delay(0, false, function ()
				go.animate(go_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_OUTEXPO, 2)
			end)
		end)
	end

	if animation then
		animate_character(self, animation)
	else
		request_idle_animation(self)
	end
end

local function hide_character(self)
	local go_sprite = self.sprite

	go.cancel_animations(go_sprite, h_tintw)
	go.animate(go_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INEXPO, 0.5, 0, function ()
		msg.post(go_sprite, h_disable)

		self.enabled = false
	end)

	if self.knife_sprite then
		local knife_sprite = self.knife_sprite

		go.cancel_animations(knife_sprite, h_tintw)
		go.animate(knife_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INEXPO, 0.5, 0, function ()
			msg.post(knife_sprite, h_disable)
		end)
	end
end

function on_animation_done(self, message_id, message)
	if self.knife_sprite then
		if message.id == h_elias_idle4_cut then
			animate_sprite(self, self.knife_sprite, h_knife_shown)

			self.pending_knife_shown = false
		elseif message.id == h_elias_idle4_draw_knife then
			animate_sprite(self, self.knife_sprite, h_knife_shown)

			self.pending_knife_shown = false
		end
	end

	if message.id == self.transition_animation then
		self.transitioning = false

		dispatcher.dispatch(h_transition_completed, message)
	else
		request_idle_animation(self)
	end
end

function animate_character(self, animation, fade, flipped)
	local slot = slots.slot_of_char[self.name]

	if not slot then
		return
	end

	local go_sprite = self.sprite

	if animation then
		self.animation_timer = timer.delay(self.animation_delay, false, function ()
			self.animation_timer = nil

			cancel_pending_animations(self)

			if self.transitioning then
				self.transitioning = false

				dispatcher.dispatch(h_transition_completed, {
					initial_animation = animation
				})

				return
			end

			if self.pending_knife_shown and self.knife_sprite then
				animate_sprite(self, self.knife_sprite, h_knife_shown)
			end

			if self.aux_sprite then
				animate_sprite(self, self.aux_sprite, h_pixel)
			end

			animate_sprite(self, go_sprite, animation, true)
			dispatcher.dispatch(h_play_animation_sfx, {
				id = animation
			})

			if animation == self.transition_animation then
				self.transitioning = true

				dispatcher.dispatch(h_transition_started, {
					id = animation
				})
			elseif animation == h_elias_idle4_cut then
				local aux_animation = h_elias_idle4_cut_hand

				if self.aux_sprite then
					animate_sprite(self, self.aux_sprite, aux_animation)
				end

				if self.knife_sprite then
					animate_sprite(self, self.knife_sprite, h_knife_hidden)
				end

				self.pending_knife_shown = true
			elseif animation == h_elias_idle4_draw_knife then
				self.pending_knife_shown = true
			elseif animation == h_elias_idle4_put_away_knife then
				if self.knife_sprite then
					animate_sprite(self, self.knife_sprite, h_knife_hidden)
				end
			elseif animation == self.alt_idle_transition then
				self.idle_animation = self.alt_idle_animation
				self.idle_animation_blink = self.alt_idle_animation_blink

				dispatcher.dispatch(h_elias_final_stage)
			end
		end)
	end
end

function _env:on_message(message_id, message)
	if message_id == h_interludes_show_character then
		if hash(message.character) == self.name then
			show_character(self)
		end
	elseif message_id == h_interludes_hide_character_in_slot then
		if hash(message.character) == self.name then
			hide_character(self)
		end
	elseif message_id == h_interludes_animate_character then
		if hash(message.character) == self.name then
			animate_character(self, message.animation, not message.instant, message.flipped)
		end
	elseif message_id == h_sprite_animation_done and message.tag == 1 then
		on_animation_done(self, message_id, message)
	end
end
