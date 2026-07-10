local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local Layout = require("crit.layout")
local KeyPrompt = require("lib.key_prompt")
local h_set_subject = hash("set_subject")
local h_init_level = hash("init_level")
local h_start_game = hash("start_game")
local h_game_over = hash("game_over")
local h_go_on_record = hash("go_on_record")
local h_go_off_record = hash("go_off_record")
local h_window_change_size = hash("window_change_size")
local h_set_parent = hash("set_parent")
local h_kill = hash("kill")
local h_play_animation = hash("play_animation")
local h_subject_panel = hash("subject_panel")
local h_show_subject = hash("show_subject")
local h_level_highlight = hash("level_highlight")
local h_level_highlight_cancel = hash("level_highlight_cancel")
local h_subject_switcher = hash("subject_switcher")
local h_highlight = hash("highlight")
local h_sprite = hash("sprite")
local h_ex = hash("ex")
local h_tintw = hash("tint.w")
local h_tint = hash("tint")
local h_position_y = hash("position.y")
local h_position_x = hash("position.x")
local h_panel_avatar_dead = hash("panel_avatar_dead")
local h_gamepad_lshoulder = hash("gamepad_lshoulder")
local h_gamepad_rshoulder = hash("gamepad_rshoulder")
local h_switch_input_method = hash("switch_input_method")
local avatar_set_enabled, create_avatar, panel_set_enabled, update_current_subject = nil

function _env:init()
	self.is_enabled = false
	self.avatars = {}
	self.avatar_buttons = {}
	self.highlighted_subjects = {}
	self.prompts_container = msg.url("prompts_container")
	self.prompt_lb = KeyPrompt.new(msg.url("prompt_lb#prompt"), {
		is_sprite = true,
		action_id = h_gamepad_lshoulder,
		halo = msg.url("prompt_lb#prompt_halo")
	})
	self.prompt_rb = KeyPrompt.new(msg.url("prompt_rb#prompt"), {
		is_sprite = true,
		action_id = h_gamepad_rshoulder,
		halo = msg.url("prompt_rb#prompt_halo")
	})

	self.prompt_lb:set_enabled(false)
	self.prompt_rb:set_enabled(false)

	self.container_id = go.get_id("container")
	self.avatar_factory = msg.url("container#factory")
	self.layout = Layout.new({
		is_go = true
	})

	self.layout:add_node(msg.url("."), {
		grav_y = 1,
		grav_x = 1
	})
	self.layout:place()

	self.hover_subject_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Subject")
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_start_game,
		h_game_over,
		h_set_subject,
		h_show_subject,
		h_go_on_record,
		h_go_off_record,
		h_kill,
		h_window_change_size,
		h_level_highlight,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function avatar_set_enabled(self, subject_id, avatar_id, is_enabled, no_delay)
	self.avatar_buttons[subject_id]:set_enabled(is_enabled)

	avatar_id = avatar_id or self.avatars[subject_id]
	local subject = store.subjects[subject_id]
	local room_index = subject.room_index
	local avatar_url = msg.url(avatar_id)
	local avatar_sprite = msg.url(avatar_url.socket, avatar_url.path, h_sprite)
	local avatar_ex = msg.url(avatar_url.socket, avatar_url.path, h_ex)
	local delay = no_delay and 0 or (room_index - 1) * self.animation_stagger_delay

	go.cancel_animations(avatar_sprite, h_tintw)
	go.cancel_animations(avatar_ex, h_tintw)
	go.cancel_animations(avatar_url, h_position_y)
	go.animate(avatar_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, is_enabled and 1 or 0, go.EASING_LINEAR, 0.5, delay)
	go.animate(avatar_ex, h_tintw, go.PLAYBACK_ONCE_FORWARD, is_enabled and 1 or 0, go.EASING_LINEAR, 0.5, delay)
	go.animate(avatar_url, h_position_x, go.PLAYBACK_ONCE_FORWARD, is_enabled and 0 or self.animation_offset, is_enabled and go.EASING_OUTEXPO or go.EASING_INEXPO, 0.5, delay)

	local highlighted_subjects = self.highlighted_subjects

	if highlighted_subjects[subject_id] then
		local avatar_highlight = msg.url(avatar_url.socket, avatar_url.path, h_highlight)

		if self.highlight_delay_timer then
			timer.cancel(self.highlight_delay_timer)

			self.highlight_delay_timer = nil
		end

		if is_enabled then
			self.highlight_delay_timer = timer.delay(0.5 + delay, false, function ()
				self.highlight_delay_timer = nil

				if self.highlighted_subjects[subject_id] then
					msg.post(avatar_highlight, h_level_highlight, {
						object = h_subject_switcher
					})
				end
			end)
		else
			msg.post(avatar_highlight, h_level_highlight_cancel)
		end
	end
end

function panel_set_enabled(self, is_enabled)
	for subject_id, avatar_id in pairs(self.avatars) do
		avatar_set_enabled(self, subject_id, avatar_id, is_enabled)
	end

	self.prompt_lb:set_enabled(is_enabled)
	self.prompt_rb:set_enabled(is_enabled)

	self.is_enabled = is_enabled
end

function update_current_subject(self)
	local subject_id = state.current_subject

	for id, avatar_id in pairs(self.avatars) do
		local avatar_url = msg.url(avatar_id)
		local avatar_sprite = msg.url(avatar_url.socket, avatar_url.path, h_sprite)
		local tintw = self.is_enabled and 1 or 0

		go.cancel_animations(avatar_sprite, h_tint)

		local tint = subject_id == id and vmath.vector4(1, 1, 1, tintw) or vmath.vector4(0.5, 0.5, 0.5, tintw)

		go.animate(avatar_sprite, h_tint, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, 0.3)
	end
end

function create_avatar(self, subject_id)
	local subject = store.subjects[subject_id]
	local subject_name = subject.name
	local subject_avatar = subject.avatar
	local room_index = subject.room_index
	local avatar_id = factory.create(self.avatar_factory)
	local avatar_url = msg.url(avatar_id)

	go.set(avatar_url, h_position_y, (room_index - 1) * -self.avatar_spacing)
	msg.post(avatar_url, h_set_parent, {
		keep_world_transform = 0,
		parent_id = self.container_id
	})

	local avatar_sprite = msg.url(avatar_url.socket, avatar_url.path, h_sprite)

	msg.post(avatar_sprite, h_play_animation, {
		id = hash("panel_avatar_" .. subject_avatar)
	})
	go.set(avatar_sprite, h_tintw, 0)

	local button = Button.new(avatar_sprite, {
		is_sprite = true,
		action = function (button)
			if state.current_subject ~= subject_id then
				dispatcher.dispatch(h_set_subject, {
					subject_id = subject_id
				})
			end
		end,
		on_state_change = button_sound.with_sound({
			press = false,
			release = false,
			hover = self.hover_subject_event
		}, Tooltip.button_on_state_change({
			id = subject_id,
			type = h_subject_panel,
			payload = function ()
				local alive = store.subjects[subject_id].health > 0

				return {
					subject_name = subject_name,
					alive = alive
				}
			end
		}))
	})

	button:set_enabled(false)

	self.avatar_buttons[subject_id] = button
	self.avatars[subject_id] = avatar_id
end

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		self.prompt_lb:switch_input_method()
		self.prompt_rb:switch_input_method()

		for i, button in pairs(self.avatar_buttons) do
			button:switch_input_method()
		end
	elseif message_id == h_init_level then
		local max_subject_id = 0

		for room_index, subject_id in ipairs(store.subject_in_room) do
			create_avatar(self, subject_id)

			max_subject_id = subject_id
		end

		go.set(self.prompts_container, h_position_y, (max_subject_id - 1) * -self.avatar_spacing)
	elseif message_id == h_start_game then
		update_current_subject(self)
		panel_set_enabled(self, true)
	elseif message_id == h_set_subject then
		if state.phase == state.PHASE_RUNNING then
			update_current_subject(self)

			local highlighted_subjects = self.highlighted_subjects

			if highlighted_subjects[state.current_subject] then
				highlighted_subjects[state.current_subject] = nil
				local avatar_url = msg.url(self.avatars[state.current_subject])
				local avatar_highlight = msg.url(avatar_url.socket, avatar_url.path, h_highlight)

				msg.post(avatar_highlight, h_level_highlight_cancel)
			end
		end
	elseif message_id == h_go_off_record then
		panel_set_enabled(self, false)
	elseif message_id == h_go_on_record then
		panel_set_enabled(self, true)
	elseif message_id == h_kill then
		local subject_id = state.current_subject
		local avatar_id = self.avatars[subject_id]
		local avatar_url = msg.url(avatar_id)
		local avatar_ex = msg.url(avatar_url.socket, avatar_url.path, h_ex)

		msg.post(avatar_ex, h_play_animation, {
			id = h_panel_avatar_dead
		})
	elseif message_id == h_show_subject then
		local subject_id = message.subject_id

		create_avatar(self, subject_id)

		if self.is_enabled then
			self.highlighted_subjects[subject_id] = true

			avatar_set_enabled(self, subject_id, nil, true, true)
			update_current_subject(self)
		end

		local current_prompts_pos = go.get(self.prompts_container, h_position_y)

		go.animate(self.prompts_container, h_position_y, go.PLAYBACK_ONCE_FORWARD, current_prompts_pos - self.avatar_spacing, go.EASING_OUTEXPO, 0.2)
	elseif message_id == h_level_highlight then
		if message.object == h_subject_switcher then
			self.highlighted_subjects = {}
		end
	elseif message_id == h_game_over then
		panel_set_enabled(self, false)
	elseif message_id == h_window_change_size then
		self.layout:place()
	end
end

function _env:on_input(action_id, action)
	self.prompt_lb:on_input(action_id, action)
	self.prompt_rb:on_input(action_id, action)

	for i, button in pairs(self.avatar_buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end
end
