local all_animations = require("main.animations.animations")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_sprite_animation_done = hash("sprite_animation_done")
local h_sprite_frame_changed = hash("sprite_frame_changed")
local h_ = hash("")
local play_animation = nil

function _env:init()
	self.animations = all_animations[self.texture_id]
	self.current_frame = 1
	self.target_frame = 1
	self.stop_on_target = false
	self.notify_frames = false

	if self.default_animation ~= h_ then
		play_animation(self, {
			id = self.default_animation
		})
	end
end

local zero3 = vmath.vector3(0)
local one3 = vmath.vector3(1)

local function set_frame(self, frame)
	if not frame or frame == self.shown_frame then
		return
	end

	sprite.play_flipbook(self.sprite_url, frame)

	local image = self.animations.images[frame]

	go.set_position(image and image.offset or zero3)
	go.set_scale(image and image.scale or one3)

	if self.notify_frames and self.sender then
		msg.post(self.sender, h_sprite_frame_changed, {
			id = frame
		})
	end
end

local function timer_update(self, handle, dt)
	local animation = self.animation
	local current_frame = self.current_frame
	local target_frame = self.target_frame
	local finished = false

	if current_frame <= target_frame then
		current_frame = current_frame + dt * animation.fps

		if target_frame <= current_frame then
			current_frame = target_frame
			finished = true
		end
	else
		current_frame = current_frame - dt * animation.fps

		if target_frame >= current_frame then
			current_frame = target_frame
			finished = true
		end
	end

	local frame_index = math.floor(current_frame)

	if self.stop_on_target and frame_index == target_frame then
		current_frame = frame_index
		finished = true
	end

	self.current_frame = current_frame

	set_frame(self, animation.frames[frame_index])

	if finished then
		timer.cancel(handle)

		self.timer = nil

		if self.sender then
			msg.post(self.sender, h_sprite_animation_done, {
				id = self.animation_id,
				tag = self.animation_tag
			})
		end
	end
end

function play_animation(self, message, sender)
	local animations = self.animations
	local id = message.id
	local animation = animations.animations[id]
	self.animation = animation
	self.animation_id = id
	self.animation_tag = message.tag
	self.sender = sender

	if self.timer then
		timer.cancel(self.timer)

		self.timer = nil
	end

	if not message.continue or not animation or animation ~= self.animation then
		self.current_frame = 1
	end

	local target = message.target_frame
	target = target or 1 + (message.target or 1) * (animation and #animation.frames or 0)
	self.target_frame = target
	self.stop_on_target = not not message.target_frame
	self.notify_frames = not not message.notify_on_frame_change

	if not animation then
		set_frame(self, id)
	else
		self.timer = timer.delay(0, true, timer_update)

		timer_update(self, self.timer, 0)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_sprite_play_animation then
		play_animation(self, message, sender)
	end
end
