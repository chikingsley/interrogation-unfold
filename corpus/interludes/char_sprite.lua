local slots = require("interludes.slots")
local dispatcher = require("crit.dispatcher")
local h_interludes_show_character = hash("interludes_show_character")
local h_interludes_hide_character_in_slot = hash("interludes_hide_character_in_slot")
local h_interludes_focus_character = hash("interludes_focus_character")
local h_interludes_animate_character = hash("interludes_animate_character")
local h_interludes_set_internal_char_flip = hash("interludes_set_internal_char_flip")
local h_play_animation = hash("play_animation")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_tint = hash("tint")
local h_tintx = hash("tint.x")
local h_tinty = hash("tint.y")
local h_tintz = hash("tint.z")
local h_tintw = hash("tint.w")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h__go = hash("/go")
local h__sprite = hash("/sprite")
local focused_tint = 1
local unfocused_tint = 0.6
local show_character = nil

function _env:init()
	if self.disabled then
		return
	end

	local sprite_targets = {}
	self.sprite_targets = sprite_targets
	local active_sprite = nil

	if self.trimmed_sprite then
		active_sprite = msg.url("sprite#sprite")
		sprite_targets[active_sprite] = msg.url("sprite")
	else
		active_sprite = msg.url("#sprite")
		sprite_targets[active_sprite] = active_sprite
	end

	self.active_sprite = active_sprite
	local clone = collectionfactory.create(self.factory, vmath.vector3(0, 0, -0.025), vmath.quat(), {
		[h__go] = {
			disabled = true
		}
	}, vmath.vector3(1))
	local clone_go = clone[h__go]
	self.clone = clone_go

	msg.post(clone_go, "set_parent", {
		keep_world_transform = 0,
		parent_id = go.get_id()
	})

	local inactive_sprite = nil

	if self.trimmed_sprite then
		local inactive_sprite_target = msg.url(clone[h__sprite])
		inactive_sprite = msg.url(inactive_sprite_target.socket, inactive_sprite_target.path, "sprite")
		sprite_targets[inactive_sprite] = inactive_sprite_target
	else
		local url = msg.url(clone_go)
		inactive_sprite = msg.url(url.socket, url.path, "sprite")
		sprite_targets[inactive_sprite] = inactive_sprite
	end

	self.inactive_sprite = inactive_sprite

	sprite.set_constant(active_sprite, h_tint, vmath.vector4(1, 1, 1, 0))
	sprite.set_constant(inactive_sprite, h_tint, vmath.vector4(1, 1, 1, 0))
	go.set_scale(vmath.vector3(0.0001))

	self.enabled = {
		[active_sprite] = false,
		[inactive_sprite] = false
	}
	self.focused = false
	self.flipped = false
	local slot = slots.slot_of_char[self.name]

	if slot then
		show_character(self)
	end

	self.sub_id = dispatcher.subscribe({
		h_interludes_show_character,
		h_interludes_hide_character_in_slot,
		h_interludes_focus_character,
		h_interludes_animate_character,
		h_interludes_set_internal_char_flip
	})
end

function _env:final()
	if self.disabled then
		return
	end

	dispatcher.unsubscribe(self.sub_id)
end

function show_character(self)
	local active_sprite = self.active_sprite
	local inactive_sprite = self.inactive_sprite

	msg.post(active_sprite, h_enable)

	self.enabled[active_sprite] = true

	go.cancel_animations(active_sprite, h_tintx)
	go.cancel_animations(active_sprite, h_tinty)
	go.cancel_animations(active_sprite, h_tintz)
	go.cancel_animations(active_sprite, h_tintw)
	go.cancel_animations(inactive_sprite, h_tintx)
	go.cancel_animations(inactive_sprite, h_tinty)
	go.cancel_animations(inactive_sprite, h_tintz)
	go.cancel_animations(inactive_sprite, h_tintw)

	self.focused = true

	sprite.set_constant(active_sprite, h_tint, vmath.vector4(1, 1, 1, 0))
	sprite.set_constant(inactive_sprite, h_tint, vmath.vector4(1, 1, 1, 0))

	if self.show_delay then
		timer.cancel(self.show_delay)

		self.show_delay = nil
	end

	self.show_delay = timer.delay(0, false, function ()
		go.animate(active_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.5)
	end)
end

local function hide_character(self)
	local active_sprite = self.active_sprite
	local inactive_sprite = self.inactive_sprite

	if self.show_delay then
		timer.cancel(self.show_delay)

		self.show_delay = nil
	end

	go.cancel_animations(active_sprite, h_tintw)
	go.cancel_animations(inactive_sprite, h_tintw)
	go.animate(inactive_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.5, 0, function ()
		msg.post(inactive_sprite, h_disable)

		self.enabled[inactive_sprite] = false
	end)
	go.animate(active_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.5, 0, function ()
		msg.post(active_sprite, h_disable)

		self.enabled[active_sprite] = false
	end)
end

local function animate_character(self, animation, fade, flipped)
	local slot = slots.slot_of_char[self.name]

	if not slot then
		return
	end

	if self.current_animation == animation then
		return
	end

	self.current_animation = animation
	local active_sprite, inactive_sprite = nil

	if fade then
		active_sprite = self.inactive_sprite
		inactive_sprite = self.active_sprite
		self.inactive_sprite = inactive_sprite
		self.active_sprite = active_sprite
		local clone = self.clone

		go.set_position(-go.get_position(clone), clone)
	else
		inactive_sprite = self.inactive_sprite
		active_sprite = self.active_sprite
	end

	if not self.enabled[active_sprite] then
		msg.post(active_sprite, h_enable)

		self.enabled[active_sprite] = true
		local tint = self.focused and focused_tint or unfocused_tint

		go.cancel_animations(active_sprite, h_tintx)
		go.cancel_animations(active_sprite, h_tinty)
		go.cancel_animations(active_sprite, h_tintz)
		go.set(active_sprite, h_tintx, tint)
		go.set(active_sprite, h_tinty, tint)
		go.set(active_sprite, h_tintz, tint)
	end

	local msg_play_animation = self.trimmed_sprite and h_sprite_play_animation or h_play_animation

	msg.post(self.sprite_targets[active_sprite], msg_play_animation, {
		id = animation
	})

	if fade then
		go.cancel_animations(active_sprite, h_tintw)
		go.cancel_animations(inactive_sprite, h_tintw)
		go.animate(active_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.5)
		go.animate(inactive_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.5, 0.1, function ()
			msg.post(inactive_sprite, h_disable)

			self.enabled[inactive_sprite] = false
		end)
	end
end

local function set_focused(self, focused)
	local slot = slots.slot_of_char[self.name]

	if not slot then
		return
	end

	if self.focused == focused then
		return
	end

	self.focused = focused
	local active_sprite = self.active_sprite
	local inactive_sprite = self.inactive_sprite

	go.cancel_animations(active_sprite, h_tintx)
	go.cancel_animations(active_sprite, h_tinty)
	go.cancel_animations(active_sprite, h_tintz)
	go.cancel_animations(inactive_sprite, h_tintx)
	go.cancel_animations(inactive_sprite, h_tinty)
	go.cancel_animations(inactive_sprite, h_tintz)

	local value = focused and focused_tint or unfocused_tint

	go.animate(active_sprite, h_tintx, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTQUAD, 0.2)
	go.animate(active_sprite, h_tinty, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTQUAD, 0.2)
	go.animate(active_sprite, h_tintz, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTQUAD, 0.2)
	go.animate(inactive_sprite, h_tintx, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTQUAD, 0.2)
	go.animate(inactive_sprite, h_tinty, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTQUAD, 0.2)
	go.animate(inactive_sprite, h_tintz, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_INOUTQUAD, 0.2)
end

function _env:on_message(message_id, message)
	if message_id == h_interludes_show_character then
		if hash(message.character) == self.name then
			show_character(self)
		end
	elseif message_id == h_interludes_set_internal_char_flip then
		if hash(message.character) == self.name then
			if self.flipped ~= message.is_flipped then
				self.flipped = message.is_flipped
				local clone = self.clone

				go.set_position(-go.get_position(clone), clone)
			end

			show_character(self)
		end
	elseif message_id == h_interludes_hide_character_in_slot then
		if hash(message.character) == self.name then
			hide_character(self)
		end
	elseif message_id == h_interludes_animate_character then
		if hash(message.character) == self.name then
			animate_character(self, hash(message.animation), not message.instant, message.flipped)
		end
	elseif message_id == h_interludes_focus_character then
		local focused_character = message.character
		local focused = not focused_character or focused_character == self.name

		set_focused(self, focused)
	end
end
