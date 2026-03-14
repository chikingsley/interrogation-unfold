local dispatcher = require("crit.dispatcher")
local env = require("lib.environment")
local cursor = require("lib.cursor")
local skip = require("spine_cutscene.skip")
local sys_config = require("lib.sys_config")
local h_spine_cutscene_event = hash("spine_cutscene_event")
local h_scene_loading_complete = hash("scene_loading_complete")
local h_spine_cutscene_fade_out_complete = hash("spine_cutscene_fade_out_complete")
local h_cutscene_start_music = hash("cutscene_start_music")
local h_colorw = hash("color.w")
local h_position_y = hash("position.y")
local h_tint = hash("tint")
local h_spine_cutscene_skip = hash("spine_cutscene_skip")
local h_show_spine_cutscene = hash("show_spine_cutscene")
local h_spine_cutscene_preload_end = hash("spine_cutscene_preload_end")
local h_scene_fade_out = hash("scene_fade_out")
local h_scene_end = hash("scene_end")
local h_end_scene = hash("end_scene")
local h_enable = hash("enable")
local h_disable = hash("disable")
local overlay_black = vmath.vector4(0, 0, 0, 1)
local overlay_black_transparent = vmath.vector4(0, 0, 0, 0)
local show_cue = nil
local scene_count = 7
local sequential_load = sys_config.is_android or sys_config.low_memory

local function load_scene(self, scene_id)
	local factory_url = msg.url("scenes#scene" .. scene_id)
	self.current_scene_url = collectionfactory.create(factory_url)
end

local function unload_previous_scene(self)
	if self.previous_scene_url then
		go.delete(self.previous_scene_url, true)

		self.previous_scene_url = nil
	else
		print("Failed to delete scene.", self.current_scene - 1, " URL not found.")
	end
end

local function preload_all_scenes(self)
	local loaded_factories = self.loaded_factories

	for i = 1, scene_count do
		if not loaded_factories[i] and not self.skipped then
			local factory_url = msg.url("scenes#scene" .. i)
			loaded_factories[i] = factory_url
			self.loading_collections = self.loading_collections + 1

			collectionfactory.load(factory_url, function ()
				self.loading_collections = self.loading_collections - 1

				if self.loading_collections == 0 and self.skip_queued then
					dispatcher.dispatch(h_end_scene)
				else
					dispatcher.dispatch(h_scene_loading_complete)
				end
			end)

			if sequential_load then
				return
			end
		end
	end
end

local function fade_in_scene(self, duration)
	local overlay_sprite = msg.url("overlay#sprite")

	go.set(overlay_sprite, h_tint, overlay_black)
	go.animate(overlay_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, overlay_black_transparent, go.EASING_LINEAR, duration)
end

local function fade_out_scene(self, duration)
	local overlay_sprite = msg.url("overlay#sprite")

	go.set(overlay_sprite, h_tint, overlay_black_transparent)
	go.animate(overlay_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, overlay_black, go.EASING_LINEAR, duration)
end

function _env:init()
	self.current_scene = self.start_at_scene
	self.loaded_factories = {}
	self.preloaded_scenes_count = 0
	self.loading_collections = 0

	preload_all_scenes(self)

	self.scene_urls = msg.url("")
	self.playing = false
	local overlay_sprite = msg.url("overlay#sprite")

	go.set(overlay_sprite, h_tint, overlay_black)

	self.overlay_sprite = overlay_sprite

	msg.post(self.overlay_sprite, h_disable)

	self.event_cue = msg.url("cue_container#label")
	self.event_cue_container = msg.url("cue_container")

	go.set(self.event_cue, h_colorw, 0)

	skip.skip_message = h_spine_cutscene_skip
	self.sub_id = dispatcher.subscribe({
		h_spine_cutscene_event,
		h_spine_cutscene_fade_out_complete,
		h_scene_loading_complete,
		h_spine_cutscene_skip,
		h_show_spine_cutscene
	})
end

local function play_scenes(self)
	if self.preloaded_scenes_count == scene_count then
		fade_in_scene(self, self.scene_fade_duration)
		load_scene(self, self.current_scene)
		dispatcher.dispatch(h_cutscene_start_music)
	else
		preload_all_scenes(self)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_show_spine_cutscene then
		msg.post(self.overlay_sprite, h_enable)

		if defos and self.hide_mouse_cursor and not env.cutscene_show_cursor then
			cursor.set_visible(false, cursor.PRIORITY_SCENE)
		end

		self.playing = true

		play_scenes(self)
	elseif message_id == h_spine_cutscene_event then
		local event_id = message.event_id

		if event_id == h_scene_fade_out then
			fade_out_scene(self, self.scene_fade_duration)
			show_cue(self, "scene1_fade_out")
		elseif event_id == h_scene_end then
			self.current_scene = self.current_scene + 1
			local next_scene = self.current_scene
			self.previous_scene_url = self.current_scene_url

			if next_scene <= scene_count then
				load_scene(self, next_scene)
				fade_in_scene(self, self.scene_fade_duration)
			else
				dispatcher.dispatch(h_end_scene)
			end

			unload_previous_scene(self)
		end
	elseif message_id == h_scene_loading_complete then
		self.preloaded_scenes_count = self.preloaded_scenes_count + 1

		if self.preloaded_scenes_count == scene_count then
			dispatcher.dispatch(h_spine_cutscene_preload_end)

			if self.playing then
				play_scenes(self)
			end
		else
			preload_all_scenes(self)
		end
	elseif message_id == h_spine_cutscene_skip then
		if self.loading_collections == 0 then
			dispatcher.dispatch(h_end_scene)
		else
			self.skip_queued = true
		end
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

function _env:final()
	if defos and self.hide_mouse_cursor and not env.cutscene_show_cursor then
		cursor.set_visible(nil, cursor.PRIORITY_SCENE)
	end

	dispatcher.unsubscribe(self.sub_id)

	for i, url in pairs(self.loaded_factories) do
		collectionfactory.unload(url)
	end

	skip.skip_message = nil
end
