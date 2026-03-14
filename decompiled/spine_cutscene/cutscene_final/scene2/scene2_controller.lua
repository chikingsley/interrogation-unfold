local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local h_tint = hash("tint")
local h_spine_event = hash("spine_event")
local h_animation = hash("animation")
local h_playback_rate = hash("playback_rate")
local h_sprite = hash("sprite")
local h_fast_forward = hash("fast_forward")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_spine_cutscene_set_options = hash("spine_cutscene_set_options")
local color_black = vmath.vector4(0, 0, 0, 1)
local color_black_transparent = vmath.vector4(0, 0, 0, 0)

local function scene_fade_in(self)
	local overlay_url = self.overlay
	local sprite_url = msg.url(overlay_url.socket, overlay_url.path, h_sprite)

	msg.post(overlay_url, h_enable)
	go.set(sprite_url, h_tint, color_black)
	go.animate(sprite_url, h_tint, go.PLAYBACK_ONCE_FORWARD, color_black_transparent, go.EASING_LINEAR, self.fade_in_duration, 0, function ()
		msg.post(overlay_url, h_disable)
	end)
end

function _env:init()
	local spine_scene_fg = msg.url("scene#foreground")
	local spine_scene_bg = msg.url("scene#background")
	self.overlay = msg.url("overlay")

	if self.scene_no == 2 then
		scene_fade_in(self)
	else
		local overlay_sprite = msg.url(self.overlay.socket, self.overlay.path, h_sprite)

		go.set(overlay_sprite, h_tint, color_black_transparent)
		msg.post(self.overlay, h_disable)
	end

	spine.play_anim(spine_scene_fg, h_animation, go.PLAYBACK_ONCE_FORWARD)
	spine.play_anim(spine_scene_bg, h_animation, go.PLAYBACK_ONCE_FORWARD)

	self.spine_scene_fg = spine_scene_fg
	self.spine_scene_bg = spine_scene_bg
	self.scene_speed = 1
	self.sub_id = dispatcher.subscribe({
		h_spine_cutscene_set_options
	})

	msg.post(".", "acquire_input_focus")
end

local function fast_forward_scene(self)
	self.fast_forward_timer = timer.delay(0.2, true, function ()
		if self.scene_speed < self.max_fast_forward_speed then
			go.set(self.spine_scene_fg, h_playback_rate, self.scene_speed)
			go.set(self.spine_scene_bg, h_playback_rate, self.scene_speed)

			self.scene_speed = self.scene_speed + self.fast_forward_acceleration
		else
			timer.cancel(self.fast_forward_timer)
		end
	end)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_cutscene_set_options then
		self.seek_on_click = message.enable_seek
	elseif message_id == h_spine_event then
		dispatcher.dispatch(h_spine_cutscene_event, message)

		local event_id = message.event_id

		if event_id == h_fast_forward then
			fast_forward_scene(self)
		end
	end
end

function _env:on_input(action_id, action)
	if action_id == hash("click") and self.seek_on_click then
		go.set(self.spine_scene_fg, "cursor", action.screen_x / Layout.viewport_width)
		go.set(self.spine_scene_bg, "cursor", action.screen_x / Layout.viewport_width)

		return true
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
