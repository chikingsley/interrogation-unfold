local dispatcher = require("crit.dispatcher")
local data = require("spine_cutscene.cutscene_final.cutscene_data")
local env = require("lib.environment")
local cursor = require("lib.cursor")
local sys_config = require("lib.sys_config")
local h_spine_cutscene_init_message = hash("spine_cutscene_init_message")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_spine_cutscene_set_options = hash("spine_cutscene_set_options")
local h_spine_cutscene_fade_out_complete = hash("spine_cutscene_fade_out_complete")
local h_colorw = hash("color.w")
local h_position_y = hash("position.y")
local h_tintw = hash("tint.w")
local h_tint = hash("tint")
local h_scene_fade_out = hash("scene_fade_out")
local h_load_next_scene = hash("load_next_scene")
local h_tint_red = hash("tint_red")
local h_show_text = hash("show_text")
local h_scene_end = hash("scene_end")
local h_end_scene = hash("end_scene")
local h_show_newspaper = hash("show_newspaper")
local h_bloom_disable = hash("bloom_disable")
local h_blur_enable = hash("blur_enable")
local overlay_white_transparent = vmath.vector4(1, 1, 1, 0)
local overlay_white = vmath.vector4(1, 1, 1, 0.7)
local overlay_red_transparent = vmath.vector4(1, 0, 0, 0)
local overlay_red = vmath.vector4(1, 0, 0, 0.1)
local overlay_black = vmath.vector4(0, 0, 0, 1)
local overlay_black_transparent = vmath.vector4(0, 0, 0, 0)
local bloom_red = vmath.vector4(4, 0, 0, 1)
local bloom_white = vmath.vector4(4)
local bloom_default = vmath.vector4(1)
local show_cue, show_text_box = nil
local sequential_load = sys_config.is_android or sys_config.low_memory
local preload_a_scene, start_sequence = nil

local function on_scene_load_complete(self)
	self.preloading_scenes_count = self.preloading_scenes_count - 1

	if self.preloading_scenes_count == 0 then
		if not next(self.urls_to_preload) then
			start_sequence(self)
		elseif sequential_load then
			preload_a_scene(self)
		end
	end
end

function preload_a_scene(self)
	local i, def = next(self.urls_to_preload)

	if not def then
		return false
	end

	self.urls_to_preload[i] = nil
	local scene_id = def[1]
	local factory_url = def[2]
	self.loaded_collections[scene_id] = factory_url
	self.preloading_scenes_count = self.preloading_scenes_count + 1

	collectionfactory.load(factory_url, on_scene_load_complete)

	return true
end

local function preload_all_scenes(self)
	local urls_to_preload = self.urls_to_preload

	if not urls_to_preload then
		urls_to_preload = {}
		self.urls_to_preload = urls_to_preload

		for i, scene_id in ipairs(self.scene_sequence) do
			urls_to_preload[i] = {
				scene_id,
				msg.url("scenes#scene" .. scene_id)
			}
		end

		urls_to_preload[#urls_to_preload + 1] = {
			"newspaper",
			msg.url("newspapers#news" .. self.ending)
		}
	end

	if sequential_load then
		if not preload_a_scene(self) then
			start_sequence(self)
		end
	else
		while preload_a_scene(self) do
		end
	end
end

local function unload_previous_scene(self)
	if self.previous_scene_url then
		go.delete(self.previous_scene_url, true)

		self.previous_scene_url = nil
	end
end

local function load_scene(self, scene)
	local factory_url = msg.url("scenes#scene" .. scene)

	if self.previous_scene_url then
		unload_previous_scene(self)
	end

	self.previous_scene_url = self.current_scene_url
	self.current_scene_url = collectionfactory.create(factory_url)

	dispatcher.dispatch(h_spine_cutscene_set_options, {
		enable_seek = self.seek_on_click
	})
end

function start_sequence(self)
	load_scene(self, self.scene_sequence[self.current_scene])
end

local function show_newspaper(ending)
	local factory_url = msg.url("newspapers#news" .. ending)

	collectionfactory.create(factory_url)
end

local function init_final_cutscene(self)
	self.scene_sequence = data.scene_sequences[self.ending]
	self.loaded_collections = {}
	self.preloading_scenes_count = 0

	preload_all_scenes(self)
end

function _env:init()
	self.treshold_model = msg.url("bloom#treshold")
	self.horiz_model = msg.url("bloom#horiz")
	self.vert_model = msg.url("bloom#vert")
	local overlay_add_sprite = msg.url("overlay_add#sprite")

	go.set(overlay_add_sprite, h_tintw, 0)

	self.overlay_add_sprite = overlay_add_sprite
	local overlay_sprite = msg.url("overlay#sprite")

	go.set(overlay_sprite, h_tintw, 0)

	self.overlay_sprite = overlay_sprite
	local text_box_label = msg.url("text_box#label")

	go.set(text_box_label, h_colorw, 0)
	label.set_text(text_box_label, "")

	self.event_cue = msg.url("cue_container#label")
	self.event_cue_container = msg.url("cue_container")

	go.set(self.event_cue, h_colorw, 0)

	if self.hide_mouse_cursor and not env.cutscene_show_cursor then
		cursor.set_visible(false, cursor.PRIORITY_SCENE)
	end

	self.sub_id = dispatcher.subscribe({
		h_spine_cutscene_event,
		h_spine_cutscene_fade_out_complete,
		h_spine_cutscene_init_message
	})

	msg.post(".", "acquire_input_focus")
end

local function play_transition(self, transition)
	if transition == data.transitions.FLASH_WHITE then
		local duration = self.flash_white_duration
		local playback = go.PLAYBACK_ONCE_FORWARD
		local easing = go.EASING_LINEAR

		go.set(self.overlay_add_sprite, h_tint, overlay_white_transparent)
		go.animate(self.overlay_add_sprite, h_tint, playback, overlay_white, easing, duration)
		go.animate(self.vert_model, h_tint, playback, bloom_white, easing, duration, 0, function ()
			go.animate(self.overlay_add_sprite, h_tint, playback, overlay_white_transparent, easing, duration)
			go.animate(self.vert_model, h_tint, playback, bloom_default, easing, duration)
		end)

		return
	end

	if transition == data.transitions.LONG_FADE_OUT then
		local duration = self.long_fade_out_duration

		go.cancel_animations(self.overlay_sprite, h_tint)
		go.set(self.overlay_sprite, h_tint, overlay_black_transparent)
		go.animate(self.overlay_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, overlay_black, go.EASING_LINEAR, duration)
	elseif transition == data.transitions.CUT then
		timer.delay(self.cut_duration, false, function ()
			dispatcher.dispatch(h_bloom_disable)
		end)

		local duration = self.cut_duration
		local playback = go.PLAYBACK_ONCE_FORWARD
		local easing = go.EASING_LINEAR

		go.cancel_animations(self.overlay_sprite, h_tint)
		go.set(self.overlay_sprite, h_tint, overlay_black_transparent)
		go.animate(self.overlay_sprite, h_tint, playback, overlay_black, easing, duration, 0, function ()
			go.animate(self.overlay_sprite, h_tint, playback, overlay_black_transparent, easing, duration, 0.1)
		end)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_cutscene_event then
		local event_id = message.event_id
		local integer = message.integer

		show_cue(self, event_id)

		if event_id == h_scene_fade_out then
			play_transition(self, integer)
		elseif event_id == h_show_text then
			if self.enable_narrative_text then
				show_text_box(integer)
			end
		elseif event_id == h_tint_red then
			go.set(self.overlay_add_sprite, h_tint, overlay_red_transparent)
			go.animate(self.overlay_add_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, overlay_red, go.EASING_LINEAR, 1.5)
			go.animate(self.vert_model, h_tint, go.PLAYBACK_ONCE_FORWARD, bloom_red, go.EASING_LINEAR, 1.5)
		elseif event_id == h_load_next_scene then
			self.current_scene = self.current_scene + 1
			local next_scene = self.scene_sequence[self.current_scene]

			if next_scene then
				load_scene(self, next_scene)

				if self.queue_scene_unload then
					self.queue_scene_unload = false

					unload_previous_scene(self)
				end
			else
				dispatcher.dispatch(h_end_scene)
			end
		elseif event_id == h_scene_end then
			if self.previous_scene_url then
				unload_previous_scene(self)
			else
				self.queue_scene_unload = true
			end
		elseif event_id == h_show_newspaper then
			show_newspaper(self.ending)
			dispatcher.dispatch(h_blur_enable, {
				blur_in_duration = 2
			})
		end
	elseif message_id == h_spine_cutscene_init_message then
		self.current_scene = message.start_at_scene and message.start_at_scene or self.start_at_scene
		local ending = self.alternate_ending ~= 0 and self.alternate_ending or data.ending

		if message.ending then
			ending = message.ending
		end

		self.ending = ending

		init_final_cutscene(self)
	end
end

function show_cue(self, event_id)
	if self.enable_spine_event_cues then
		local text = data.event_cues[event_id]

		if text then
			label.set_text(self.event_cue, text)
			go.set(self.event_cue, h_colorw, 1)
			go.set(self.event_cue_container, h_position_y, 0)
			go.animate(self.event_cue, h_colorw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INEXPO, 1.5)
			go.animate(self.event_cue_container, h_position_y, go.PLAYBACK_ONCE_FORWARD, 100, go.EASING_LINEAR, 1.5)
		end
	end
end

function show_text_box(index, reset)
	local text_box_label = msg.url("text_box#label")

	go.set(text_box_label, h_colorw, 0)
	go.cancel_animations(text_box_label, h_colorw)

	if not reset then
		label.set_text(text_box_label, data.copy[index])
		go.cancel_animations(text_box_label, h_colorw)
		go.animate(text_box_label, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 1.5, 0, function ()
			go.animate(text_box_label, h_colorw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 3, 6)
		end)
	end
end

function _env:final()
	if self.hide_mouse_cursor and not env.cutscene_show_cursor then
		cursor.set_visible(nil, cursor.PRIORITY_SCENE)
	end

	dispatcher.unsubscribe(self.sub_id)

	for _, url in pairs(self.loaded_collections) do
		collectionfactory.unload(url)
	end
end
