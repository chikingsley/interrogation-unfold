local dispatcher = require("crit.dispatcher")
local office_animations = require("campaign.office.office_animations")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_object_deselected = hash("office_object_deselected")
local h_office_blur_disabled = hash("office_blur_disabled")
local h_sprite_play_animation = hash("sprite_play_animation")
local h_sprite_animation_done = hash("sprite_animation_done")
local h_play_sfx = hash("play_sfx")
local h_album = hash("album")
local frame_count = #office_animations.animations[h_album].frames

function _env:init()
	local this_go = msg.url(".")
	self.this_go = this_go
	self.sprite = msg.url("album_container#sprite_animation")
	self.original_z = go.get_position(this_go).z
	self.is_open = false
	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect,
		h_office_object_deselected,
		h_office_blur_disabled
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function set_z(this_go, z)
	local pos = go.get_position(this_go)

	go.set_position(vmath.vector3(pos.x, pos.y, z), this_go)
end

local function fire_sound_effect(is_opening)
	dispatcher.dispatch(h_play_sfx, {
		sfx = "album",
		parameters = {
			IsOpening = is_opening and 1 or 0
		}
	})
end

local function play_animation(self)
	local opening = self.is_open

	msg.post(self.sprite, h_sprite_play_animation, {
		continue = true,
		id = h_album,
		target_frame = opening and frame_count or 1
	})
	fire_sound_effect(opening)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if message.object_id == self.object_id then
			self.is_open = true
			self.queue_z_reset = false

			set_z(self.this_go, self.raised_z)

			if message.new_perks then
				timer.delay(0, false, function ()
					timer.delay(0, false, function ()
						timer.delay(1, false, play_animation)
					end)
				end)
			else
				play_animation(self)
			end
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == self.object_id then
			self.has_sfx_fired = false
			self.is_open = false
			self.queue_z_reset = true

			play_animation(self)
		end
	elseif message_id == h_office_blur_disabled then
		if self.queue_z_reset then
			set_z(self.this_go, self.original_z)

			self.queue_z_reset = false
		end
	elseif message_id == h_sprite_animation_done then
		local sent_message_id = self.is_open and h_office_object_selected or h_office_object_deselected

		dispatcher.dispatch(sent_message_id, {
			object_id = self.object_id
		})
	end
end
