local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local h_tintw = hash("tint.w")
local h_spine_event = hash("spine_event")
local h_animation = hash("animation")
local h_scale = hash("scale")
local h_color_addw = hash("color_add.w")
local h_background_fade_in = hash("background_fade_in")
local h_scene_fade_out = hash("scene_fade_out")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_spine_cutscene_set_options = hash("spine_cutscene_set_options")
local h_spine_cutscene_fade_out_complete = hash("spine_cutscene_fade_out_complete")
local background_final_scale = vmath.vector3(0.6, 0.6, 1)

function _env:init()
	local spine_scene = msg.url("scene#pictures")

	spine.play_anim(spine_scene, h_animation, go.PLAYBACK_ONCE_FORWARD)

	self.spine_scene = spine_scene
	self.lf_background_container = msg.url("background1")
	self.lf_background = msg.url("background1#sprite")

	go.set(self.lf_background, h_tintw, 0)

	self.sub_id = dispatcher.subscribe({
		h_spine_cutscene_set_options
	})

	msg.post(".", "acquire_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_cutscene_set_options then
		self.seek_on_click = message.enable_seek
	elseif message_id == h_spine_event then
		dispatcher.dispatch(h_spine_cutscene_event, message)

		local event_id = message.event_id

		if event_id == h_background_fade_in then
			go.animate(self.lf_background, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 3)
			go.animate(self.lf_background_container, h_scale, go.PLAYBACK_ONCE_FORWARD, background_final_scale, go.EASING_LINEAR, 30)
		elseif event_id == h_scene_fade_out then
			local duration = self.fade_out_duration

			go.animate(self.spine_scene, h_color_addw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_INCIRC, duration)
			go.animate(self.lf_background, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INCUBIC, duration)
			go.animate(self.spine_scene, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INCUBIC, duration, 0, function ()
				dispatcher.dispatch(h_spine_cutscene_fade_out_complete, {
					scene = self.scene_no
				})
			end)
		end
	end
end

function _env:on_input(action_id, action)
	if action_id == hash("click") and self.seek_on_click then
		go.set(self.spine_scene, "cursor", action.screen_x / Layout.viewport_width)

		return true
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
