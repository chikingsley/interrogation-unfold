local dispatcher = require("crit.dispatcher")
local h_click = hash("click")
local h_animation = hash("animation")
local h_spine_event = hash("spine_event")
local h_set_parent = hash("set_parent")
local h_play_sfx = hash("play_sfx")
local h_play_sound = hash("play_sound")
local h_play_animation = hash("play_animation")
local h_loop_animation = hash("loop_animation")
local h_on_tap_play_animation = hash("on_tap_play_animation")
local h_on_tap_loop_animation = hash("on_tap_loop_animation")
local h_spine_cutscene_event = hash("spine_cutscene_event")

local function configure_cutscene(config)
	function _env:init()
		self.play_animation_targets = {}
		self.loop_animation_targets = {}
		self.on_tap_play_animation_targets = {}
		self.on_tap_loop_animation_targets = {}
		local models = config.models or {}

		for model_id, model_config in pairs(models) do
			local spine_component = msg.url(model_id .. "#spine")
			local default_animation = go.get(spine_component, h_animation)

			spine.play_anim(spine_component, default_animation, go.PLAYBACK_ONCE_FORWARD)

			local parent = model_config.parent
			local slot = model_config.slot

			if parent and slot then
				local parent_component = msg.url(parent .. "#spine")
				local slot_go = spine.get_go(parent_component, slot)

				msg.post(spine_component, h_set_parent, {
					keep_world_transform = 0,
					parent_id = slot_go
				})
			end

			self.play_animation_targets[hash("play_animation_" .. model_id)] = spine_component
			self.loop_animation_targets[hash("loop_animation_" .. model_id)] = spine_component
			self.on_tap_play_animation_targets[hash("on_tap_play_animation_" .. model_id)] = spine_component
			self.on_tap_loop_animation_targets[hash("on_tap_loop_animation_" .. model_id)] = spine_component
		end

		msg.post(".", "acquire_input_focus")
	end

	function _env:on_message(message_id, message, sender)
		if message_id == h_spine_event then
			local event_id = message.event_id

			if event_id == h_play_sfx then
				local url = msg.url()
				url = msg.url(url.socket, url.path, message.string)

				msg.post(url, h_play_sound)
			elseif event_id == h_play_animation then
				spine.play_anim(sender, message.string, go.PLAYBACK_ONCE_FORWARD)
			elseif event_id == h_loop_animation then
				spine.play_anim(sender, message.string, go.PLAYBACK_LOOP_FORWARD)
			elseif event_id == h_on_tap_play_animation then
				self.tap_target = sender
				self.tap_animation = message.string
				self.tap_playback = go.PLAYBACK_ONCE_FORWARD
			elseif event_id == h_on_tap_loop_animation then
				self.tap_target = sender
				self.tap_animation = message.string
				self.tap_playback = go.PLAYBACK_LOOP_FORWARD
			elseif self.play_animation_targets[event_id] then
				local target = self.play_animation_targets[event_id]

				spine.play_anim(target, message.string, go.PLAYBACK_ONCE_FORWARD)
			elseif self.loop_animation_targets[event_id] then
				local target = self.loop_animation_targets[event_id]

				spine.play_anim(target, message.string, go.PLAYBACK_LOOP_FORWARD)
			elseif self.on_tap_play_animation_targets[event_id] then
				self.tap_target = self.on_tap_play_animation_targets[event_id]
				self.tap_animation = message.string
				self.tap_playback = go.PLAYBACK_ONCE_FORWARD
			elseif self.on_tap_loop_animation_targets[event_id] then
				self.tap_target = self.on_tap_loop_animation_targets[event_id]
				self.tap_animation = message.string
				self.tap_playback = go.PLAYBACK_LOOP_FORWARD
			else
				dispatcher.dispatch(h_spine_cutscene_event, message)
			end
		end
	end

	function _env:on_input(action_id, action)
		if action_id == h_click and action.released then
			local target = self.tap_target

			if target then
				self.tap_target = nil

				spine.play_anim(target, self.tap_animation, self.tap_playback)
			end
		end
	end
end

return configure_cutscene
