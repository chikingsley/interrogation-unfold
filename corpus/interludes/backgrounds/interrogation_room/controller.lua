local dispatcher = require("crit.dispatcher")
local h_play_animation_sfx = hash("play_animation_sfx")
local h_blur_enable = hash("blur_enable")
local h_blur_disable = hash("blur_disable")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_spine_event = hash("spine_event")
local h_elias_idle4_cut = hash("elias_idle4_cut")
local h_elias_idle3_grab = hash("elias_idle3_grab")
local h_elias_idle3_to_idle4 = hash("elias_idle3_to_idle4")
local h_microphone = hash("microphone")
local h_tintw = hash("tint.w")
local h_tint = hash("tint")
local h_sprite = hash("sprite")
local h_scene_transition_start = hash("scene_transition_start")
local h_interrogation_room_animation_complete = hash("interrogation_room_animation_complete")
local h_play_room_noise_sfx = hash("play_room_noise_sfx")
local h_zoom1 = hash("zoom1")
local h_zoom2 = hash("zoom2")
local h_table_shake = hash("table_shake")
local h_death = hash("death")
local h_lights_on = hash("lights_on")
local h_light_on = hash("light_on")
local h_light_off = hash("light_off")
local h_start_room_sfx = hash("start_room_sfx")
local h_light_on_anim_completed = hash("light_on_anim_completed")
local dark_tint = vmath.vector4(0, 0, 0, 1)
local default_tint = vmath.vector4(1, 1, 1, 1)

function _env:init()
	self.room_spine = msg.url("background#room")
	self.blur_horiz = msg.url("blur#horiz")
	self.blur_vert = msg.url("blur#vert")
	self.microphone_go = msg.url("microphone")
	local mic_sprite = msg.url(self.microphone_go.socket, self.microphone_go.path, h_sprite)
	self.flash = msg.url("flash#sprite")

	go.set(self.flash, h_tintw, 0)
	msg.post(self.flash, h_disable)

	self.sub_id = dispatcher.subscribe({
		h_play_animation_sfx,
		h_scene_transition_start
	})
	self.microphone_bone = spine.get_go(self.room_spine, h_microphone)

	timer.delay(0, false, function ()
		timer.delay(0, false, function ()
			spine.play_anim(self.room_spine, h_lights_on, go.PLAYBACK_ONCE_FORWARD)
		end)
	end)
	go.set_parent(go.get_id("microphone"), self.microphone_bone, false)
	go.set(mic_sprite, h_tint, dark_tint)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function flash(self, in_duration, out_duration, in_delay)
	local flash_url = self.flash

	go.set(flash_url, h_tintw, 0)
	msg.post(flash_url, h_enable)
	go.cancel_animations(flash_url, h_tintw)
	go.animate(flash_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0.3, go.EASING_OUTEXPO, in_duration, in_delay, function ()
		go.animate(flash_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_OUTEXPO, out_duration, 0.1, function ()
			msg.post(flash_url, h_disable)
		end)
	end)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_event then
		local event_id = message.event_id

		if event_id == h_light_off then
			local mic_sprite = msg.url(self.microphone_go.socket, self.microphone_go.path, h_sprite)

			go.cancel_animations(mic_sprite, h_tint)
			go.animate(mic_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, dark_tint, go.EASING_LINEAR, 0.1)
		elseif event_id == h_light_on then
			local mic_sprite = msg.url(self.microphone_go.socket, self.microphone_go.path, h_sprite)

			go.cancel_animations(mic_sprite, h_tint)
			go.animate(mic_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, default_tint, go.EASING_LINEAR, 0.1)
		elseif event_id == h_light_on_anim_completed then
			dispatcher.dispatch(h_interrogation_room_animation_complete)
		elseif event_id == h_start_room_sfx then
			dispatcher.dispatch(h_play_room_noise_sfx, {
				sfx = "room_noise"
			})
		end
	elseif message_id == h_play_animation_sfx then
		local animation_id = message.id

		if animation_id == h_elias_idle4_cut then
			timer.delay(0.3, false, function ()
				flash(self, 0.1, 0.2, 0.3)
				dispatcher.dispatch(h_blur_enable, {
					blur_in_duration = 0.2
				})
				timer.delay(0.4, false, function ()
					dispatcher.dispatch(h_blur_disable, {
						blur_out_duration = 2
					})
				end)
				spine.play_anim(self.room_spine, h_zoom1, go.PLAYBACK_ONCE_FORWARD)
			end)
		elseif animation_id == h_elias_idle3_grab then
			timer.delay(0.3, false, function ()
				flash(self, 0.1, 0.2, 0.3)
				dispatcher.dispatch(h_blur_enable, {
					blur_in_duration = 0.3
				})
				timer.delay(0.4, false, function ()
					dispatcher.dispatch(h_blur_disable, {
						blur_out_duration = 2
					})
				end)
				spine.play_anim(self.room_spine, h_zoom1, go.PLAYBACK_ONCE_FORWARD)
			end)
		elseif animation_id == h_elias_idle3_to_idle4 then
			timer.delay(0.9, false, function ()
				spine.play_anim(self.room_spine, h_table_shake, go.PLAYBACK_ONCE_FORWARD)
			end)
		end
	elseif message_id == h_scene_transition_start then
		spine.play_anim(self.room_spine, h_death, go.PLAYBACK_ONCE_FORWARD)
	end
end
