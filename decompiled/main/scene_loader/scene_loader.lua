local dispatcher = require("crit.dispatcher")
local current_scene = require("main.scene_loader.current_scene")
local input_state = require("crit.input_state")
local h_load_scene = hash("load_scene")
local h_post_scene_init = hash("post_scene_init")
local h_proxy_loaded = hash("proxy_loaded")
local h_proxy_unloaded = hash("proxy_unloaded")
local h_scene_transition_start = hash("scene_transition_start")
local h_scene_transition_midpoint = hash("scene_transition_midpoint")
local h_scene_transition_midpoint_continue = hash("scene_transition_midpoint_continue")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_init = hash("init")
local h_final = hash("final")
local h_load = hash("load")
local h_unload = hash("unload")
local h_set_time_step = hash("set_time_step")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_scene_loader_init = hash("scene_loader_init")
local h_scene_set_time_step = hash("scene_set_time_step")
local h_fallback_keybindings_init = hash("fallback_keybindings_init")
local h_set_view = hash("set_view")
local h_preload_scene = hash("preload_scene")
local continue_midpoint = nil

local function get_proxy_url(self, scene)
	local scenes_url = self.scenes

	return msg.url(scenes_url.socket, scenes_url.path, hash(scene))
end

local function load_new_scene(self)
	local scene = current_scene.scene

	if scene then
		current_scene.midpoint_auto_continue = true

		if scene == current_scene.preloaded_scene then
			current_scene.preloaded_scene = nil
			current_scene.preloaded_options = nil

			continue_midpoint(self)

			return
		end

		local proxy = get_proxy_url(self, scene)
		self.pending_proxy = proxy

		msg.post(proxy, h_load)
		msg.post(proxy, h_set_time_step, {
			mode = 0,
			factor = self.time_step
		})
	end
end

local render_url = msg.url("@render:")

local function load_scene(self, scene, options)
	local old_scene = current_scene.scene
	current_scene.scene = scene
	current_scene.options = options

	if old_scene then
		local old_proxy = get_proxy_url(self, old_scene)
		self.pending_proxy = old_proxy

		msg.post(old_proxy, h_disable)
		msg.post(old_proxy, h_final)
		msg.post(old_proxy, h_unload)

		input_state.default_focus_context = input_state.new_focus_context()

		msg.post(render_url, h_set_view, {
			view = vmath.matrix4()
		})
	else
		load_new_scene(self)
	end
end

local function preload_new_scene(self)
	local scene = current_scene.preloaded_scene

	if scene then
		local proxy = get_proxy_url(self, scene)

		msg.post(proxy, h_load)
		msg.post(proxy, h_set_time_step, {
			mode = 0,
			factor = self.time_step
		})
	end
end

local function preload_scene(self, scene, options)
	local old_scene = current_scene.preloaded_scene
	current_scene.preloaded_scene = scene
	current_scene.preloaded_options = options

	if old_scene then
		local old_proxy = get_proxy_url(self, old_scene)

		msg.post(old_proxy, h_disable)
		msg.post(old_proxy, h_final)
		msg.post(old_proxy, h_unload)
	else
		preload_new_scene(self)
	end
end

function _env:init()
	self.wait_frames = 0
	self.time_step = 1
	self.sub_id = dispatcher.subscribe({
		h_load_scene,
		h_preload_scene,
		h_scene_set_time_step,
		h_scene_transition_midpoint,
		h_fallback_keybindings_init
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function continue_midpoint(self)
	if not current_scene.midpoint_auto_continue then
		return
	end

	self.midpoint_timer = nil

	if current_scene.midpoint_wait_frames > 0 then
		current_scene.midpoint_wait_frames = current_scene.midpoint_wait_frames - 1
		self.midpoint_timer = timer.delay(0, false, continue_midpoint)

		return
	end

	dispatcher.dispatch(hash("show_" .. current_scene.scene), current_scene.options)
	dispatcher.dispatch(h_scene_transition_midpoint_continue, self.transition_options)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_load_scene then
		local scene = message.scene
		local options = message.options or {}
		local transition_options = message.transition_options or {}
		self.pending_scene = scene
		self.pending_options = options
		self.transition_options = transition_options

		if self.midpoint_timer then
			timer.cancel(self.midpoint_timer)

			self.midpoint_timer = nil
		end

		dispatcher.dispatch(h_scene_transition_start, transition_options)
	elseif message_id == h_preload_scene then
		local scene = message.scene
		local options = message.options or {}

		preload_scene(self, scene, options)
	elseif message_id == h_scene_transition_midpoint and self.pending_scene then
		current_scene.midpoint_wait_frames = message.wait_frames or 0
		current_scene.transition_options = self.transition_options

		load_scene(self, self.pending_scene, self.pending_options)

		self.pending_scene = nil
		self.pending_options = nil
	elseif message_id == h_proxy_unloaded then
		if sender == self.pending_proxy then
			self.pending_proxy = nil

			timer.delay(0, false, load_new_scene)
		end
	elseif message_id == h_proxy_loaded then
		msg.post(sender, h_init)
		msg.post(sender, h_enable)
		msg.post("#", h_post_scene_init, {
			proxy = sender
		})
	elseif message_id == h_post_scene_init then
		if message.proxy == self.pending_proxy then
			dispatcher.dispatch(hash("init_" .. current_scene.scene), current_scene.options)

			self.pending_proxy = nil

			continue_midpoint(self)
		else
			dispatcher.dispatch(hash("init_" .. current_scene.preloaded_scene), current_scene.preloaded_options)
		end
	elseif message_id == h_scene_set_time_step then
		local factor = message.factor
		self.time_step = factor
		local scene = current_scene.scene

		if scene then
			msg.post(get_proxy_url(self, scene), h_set_time_step, {
				mode = 0,
				factor = factor
			})
		end
	elseif message_id == h_fallback_keybindings_init then
		msg.post(self.scenes, h_acquire_input_focus)
		dispatcher.dispatch(h_scene_loader_init)
	end
end
