local dispatcher = require("crit.dispatcher")
local cutscene_text = require("spine_cutscene.cutscene1.copy")
local Layout = require("crit.layout")
local env = require("lib.environment")
local cursor = require("lib.cursor")
local h_set_parent = hash("set_parent")
local h_spine_event = hash("spine_event")
local h_scene_start = hash("scene_start")
local h_scene_fade_out = hash("scene_fade_out")
local h_scene_end = hash("scene_end")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_cutscene_fade_in = hash("cutscene_fade_in")
local h_cutscene_fade_out = hash("cutscene_fade_out")
local h_explosion = hash("explosion")
local h_stop_splash_particles = hash("stop_splash_particles")
local h_horizontal_pan = hash("horizontal_pan")
local h_show_text = hash("show_text")
local h_camera_flash = hash("camera_flash")
local h_city_ambiance = hash("city_ambiance")
local h_car_engines = hash("car_engines")
local h_crowd = hash("crowd")
local h_crowd_screams = hash("crowd_screams")
local h_play_sfx = hash("play_sfx")
local h_stop_sfx = hash("stop_sfx")
local h_sfx_set_parameters = hash("sfx_set_parameters")
local h_all_sfx = hash("all_sfx")
local h_enable_sfx = hash("enable_sfx")
local h_end_scene = hash("end_scene")
local h_animation = hash("animation")
local h_camera_fine = hash("camera_fine")
local h_droplets = hash("droplets")
local h_text = hash("text")
local h_colorw = hash("color.w")
local h_position_y = hash("position.y")
local h_rotation = hash("rotation")
local show_cue, show_text_box, rotate_rain_particles = nil

function _env:init()
	self.rain = msg.url("rain#rain")
	self.drops = msg.url("rain_splashes#rain_splashes")

	particlefx.play(self.rain)

	local spine_cutscene = msg.url("scene#cutscene")
	local spine_cutscene_bg1 = msg.url("scene#cutscene_bg1")
	local spine_cutscene_bg2 = msg.url("scene#cutscene_bg2")
	local spine_cutscene_overlay = msg.url("scene#cutscene_overlay")
	self.particlefx_smoke = msg.url("scene#explosion_smoke")

	spine.play_anim(spine_cutscene, h_animation, go.PLAYBACK_ONCE_FORWARD)
	spine.play_anim(spine_cutscene_bg1, h_animation, go.PLAYBACK_ONCE_FORWARD)
	spine.play_anim(spine_cutscene_bg2, h_animation, go.PLAYBACK_ONCE_FORWARD)
	spine.play_anim(spine_cutscene_overlay, h_animation, go.PLAYBACK_ONCE_FORWARD)

	local camera_url = msg.url("camera")
	local camera_bone = spine.get_go(spine_cutscene, h_camera_fine)

	msg.post(camera_url, h_set_parent, {
		parent_id = camera_bone
	})

	local splashes_url = msg.url("rain_splashes")
	local splashes_bone = spine.get_go(spine_cutscene, h_droplets)

	msg.post(splashes_url, h_set_parent, {
		parent_id = splashes_bone
	})
	msg.post(".", "acquire_input_focus")

	local text_box_url = msg.url("text_box")
	local text_box_label = msg.url("text_box#label")
	local text_bone = spine.get_go(spine_cutscene, h_text)

	go.set(text_box_label, h_colorw, 0)
	label.set_text(text_box_label, "")
	msg.post(text_box_url, h_set_parent, {
		keep_world_transform = 0,
		parent_id = text_bone
	})

	self.spine_cutscene = spine_cutscene
	self.spine_cutscene_bg1 = spine_cutscene_bg1
	self.spine_cutscene_bg2 = spine_cutscene_bg2
	self.spine_cutscene_overlay = spine_cutscene_overlay
	self.event_cue = msg.url("container#label")
	self.event_cue_container = msg.url("container")

	go.set(self.event_cue, h_colorw, 0)

	if self.hide_mouse_cursor and not env.cutscene_show_cursor then
		cursor.set_visible(false, cursor.PRIORITY_SCENE)
	end
end

function _env:final()
	if self.hide_mouse_cursor and not env.cutscene_show_cursor then
		cursor.set_visible(nil, cursor.PRIORITY_SCENE)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_event then
		dispatcher.dispatch(h_spine_cutscene_event, message)

		local event_id = message.event_id
		local integer = message.integer
		local float = message.float

		if event_id == h_scene_start then
			show_cue(self, "scene start")
			show_text_box(1, true)
			dispatcher.dispatch(h_enable_sfx, {
				enable_sfx = self.enable_sfx
			})
			dispatcher.dispatch(h_stop_sfx, {
				sfx = h_all_sfx
			})
			dispatcher.dispatch(h_play_sfx, {
				sfx = "light_rain"
			})
			dispatcher.dispatch(h_play_sfx, {
				sfx = "music"
			})
			dispatcher.dispatch(h_cutscene_fade_in, {
				fade_duration = self.fade_in_duration
			})
		elseif event_id == h_show_text then
			show_cue(self, "show text")

			if self.enable_narrative_text then
				show_text_box(integer)
			end
		elseif event_id == h_horizontal_pan then
			show_cue(self, "horizontal pan")
		elseif event_id == h_stop_splash_particles then
			show_cue(self, "stop splash particle fx")
		elseif event_id == h_camera_flash then
			show_cue(self, "camera_flash")

			local track = integer / 3

			dispatcher.dispatch(h_play_sfx, {
				sfx = "camera_shutter",
				parameters = {
					Track = track,
					Pan = float
				}
			})
		elseif event_id == h_city_ambiance then
			show_cue(self, "city sirens")
			dispatcher.dispatch(h_play_sfx, {
				sfx = "city_sirens",
				parameters = {
					IsRunning = integer
				}
			})
		elseif event_id == h_explosion then
			show_cue(self, "explosion")
			dispatcher.dispatch(h_play_sfx, {
				sfx = "explosion",
				parameters = {
					Track = integer
				}
			})

			if integer == 1 then
				particlefx.play(self.particlefx_smoke)
			end
		elseif event_id == h_crowd then
			show_cue(self, "crowd")
			dispatcher.dispatch(h_play_sfx, {
				sfx = "crowd"
			})
		elseif event_id == h_crowd_screams then
			show_cue(self, "crowd_screams")
			dispatcher.dispatch(h_play_sfx, {
				sfx = "crowd_screams",
				parameters = {
					IsRunning = integer
				}
			})
		elseif event_id == h_car_engines then
			show_cue(self, "car engines")

			if integer == 0 then
				dispatcher.dispatch(h_sfx_set_parameters, {
					sfx = "car_engines",
					parameters = {
						IsRunning = integer
					}
				})
			else
				dispatcher.dispatch(h_play_sfx, {
					sfx = "car_engines",
					parameters = {
						IsRunning = integer,
						Track = float
					}
				})
			end
		elseif event_id == h_scene_end then
			show_cue(self, "scene end")
			dispatcher.dispatch(h_end_scene)
		elseif event_id == h_scene_fade_out then
			show_cue(self, "scene fade out")
			dispatcher.dispatch(h_cutscene_fade_out, {
				fade_duration = self.fade_out_duration
			})
			dispatcher.dispatch(h_sfx_set_parameters, {
				sfx = "light_rain",
				parameters = {
					IsRunning = 0
				}
			})
			dispatcher.dispatch(h_sfx_set_parameters, {
				sfx = "city_sirens",
				parameters = {
					IsRunning = 0
				}
			})
			dispatcher.dispatch(h_sfx_set_parameters, {
				sfx = "crowd_screams",
				parameters = {
					IsRunning = 0
				}
			})
		end
	end
end

function show_text_box(index, reset)
	local text_box_label = msg.url("text_box#label")

	go.set(text_box_label, h_colorw, 0)
	go.cancel_animations(text_box_label, h_colorw)

	if not reset then
		label.set_text(text_box_label, cutscene_text[index])
		go.cancel_animations(text_box_label, h_colorw)
		go.animate(text_box_label, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 1.5, 0, function ()
			go.animate(text_box_label, h_colorw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 3, 6)
		end)
	end
end

function show_cue(self, text)
	if self.enable_spine_event_cues then
		label.set_text(self.event_cue, text)
		go.set(self.event_cue, h_colorw, 1)
		go.set(self.event_cue_container, h_position_y, 0)
		go.animate(self.event_cue, h_colorw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INEXPO, 1.5)
		go.animate(self.event_cue_container, h_position_y, go.PLAYBACK_ONCE_FORWARD, 100, go.EASING_LINEAR, 1.5)
	end
end

function _env:update(dt)
	rotate_rain_particles(self.rain_angle, self.rain_randomized_angle_range)
end

function _env:on_input(action_id, action)
	if action_id == hash("click") and self.seek_on_click then
		show_text_box(1, true)

		local cursor_pos = action.screen_x / Layout.viewport_width

		go.set(self.spine_cutscene, "cursor", cursor_pos)
		go.set(self.spine_cutscene_bg1, "cursor", cursor_pos)
		go.set(self.spine_cutscene_bg2, "cursor", cursor_pos)
		go.set(self.spine_cutscene_overlay, "cursor", cursor_pos)

		return true
	end
end

function rotate_rain_particles(offset_deg, randomization_deg)
	local function deg_to_rad(deg)
		return math.pi / 180 * deg
	end

	local rain_go = msg.url("rain")
	local rotation = vmath.quat_rotation_z(deg_to_rad(offset_deg) + deg_to_rad(randomization_deg) * (math.random() - 0.5))

	go.set(rain_go, h_rotation, rotation)
end
