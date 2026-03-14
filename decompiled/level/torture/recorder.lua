local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local store = require("level.store")
local Button = require("crit.button")
local KeyPrompt = require("lib.key_prompt")
local button_sound = require("sound.button")
local sys_config = require("lib.sys_config")
local h_start_game = hash("start_game")
local h_game_over = hash("game_over")
local h_play_animation = hash("play_animation")
local h_recorder_play = hash("recorder_play")
local h_recorder_pause = hash("recorder_pause")
local h_go_on_record = hash("go_on_record")
local h_go_off_record = hash("go_off_record")
local h_level_set_recorder_disabled = hash("level_set_recorder_disabled")
local h_play_sfx = hash("play_sfx")
local h_key_e = hash("key_e")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_gamepad_rpad_left = hash("gamepad_rpad_left")
local h_switch_input_method = hash("switch_input_method")
local h_set_subject = hash("set_subject")
local h_init_level = hash("init_level")
local h_recorder_hover_sound = hash("recorder_hover_sound")
local handle_action, recorder_on_state_change = nil

function recorder_on_state_change(button, button_state, old_state)
	local is_hovering = false

	if button_state == Button.STATE_HOVER then
		is_hovering = true
	end

	dispatcher.dispatch(h_recorder_hover_sound, {
		is_hovering = is_hovering
	})
	Button.darken_on_state_change(button, button_state)
end

function _env:init()
	self.sprite = msg.url("#sprite")
	local prompt_sprite, prompt_action_id = KeyPrompt.select(msg.url("prompt#prompt"), {
		Switch = {
			hash("prompt_x"),
			h_gamepad_rpad_left
		},
		default = {
			hash("prompt_y"),
			h_gamepad_rpad_up
		}
	}, sys_config.system_name)
	self.prompt_action_id = prompt_action_id
	self.key_prompt = KeyPrompt.new(prompt_sprite, {
		is_sprite = true,
		action_id = prompt_action_id,
		halo = msg.url("prompt#prompt_halo")
	})
	self.button = Button.new(self.sprite, {
		is_sprite = true,
		disabled_opacity = 1,
		action = handle_action,
		shortcut_actions = {
			h_key_e,
			prompt_action_id
		},
		on_state_change = button_sound.with_sound({
			press = function ()
				dispatcher.dispatch(h_play_sfx, {
					sfx = "recorder_press"
				})
			end,
			release = function ()
				dispatcher.dispatch(h_play_sfx, {
					sfx = "recorder_release"
				})
			end
		}, function (button, button_state, old_state)
			recorder_on_state_change(button, button_state, old_state)
		end)
	})

	self.button:set_enabled(false)
	self.key_prompt:set_enabled(false)

	self.sub_id = dispatcher.subscribe({
		h_start_game,
		h_game_over,
		h_go_off_record,
		h_go_on_record,
		h_level_set_recorder_disabled,
		h_switch_input_method,
		h_set_subject,
		h_init_level
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function handle_action()
	if state.phase == state.PHASE_RUNNING then
		dispatcher.dispatch(state.on_record and h_go_off_record or h_go_on_record)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		self.button:switch_input_method()
		self.key_prompt:switch_input_method()
	elseif message_id == h_start_game then
		if not state.recorder_disabled then
			self.button:set_enabled(true)
			self.key_prompt:set_enabled(true)
		end

		msg.post(self.sprite, h_play_animation, {
			id = h_recorder_play
		})
	elseif message_id == h_go_on_record then
		self.button.shortcut_actions = {
			[h_key_e] = true,
			[self.prompt_action_id] = true
		}

		msg.post(self.sprite, h_play_animation, {
			id = h_recorder_play
		})
	elseif message_id == h_go_off_record then
		self.button.shortcut_actions = {
			[h_key_e] = true,
			[self.prompt_action_id] = true,
			[h_gamepad_rpad_right] = true
		}

		msg.post(self.sprite, h_play_animation, {
			id = h_recorder_pause
		})
	elseif message_id == h_game_over then
		msg.post(self.sprite, h_play_animation, {
			id = h_recorder_pause
		})
		self.button:set_enabled(false)
		self.key_prompt:set_enabled(false)
	elseif message_id == h_level_set_recorder_disabled then
		self.button:set_enabled(not message.disabled)
		self.key_prompt:set_enabled(not message.disabled)
	elseif message_id == h_set_subject then
		local subject_id = store.subjects[message.subject_id].avatar

		if subject_id == "phone" then
			dispatcher.dispatch(h_level_set_recorder_disabled, {
				disabled = true
			})
		else
			dispatcher.dispatch(h_level_set_recorder_disabled, {
				disabled = false
			})
		end
	elseif message_id == h_init_level and store.level_id == "episode5" then
		dispatcher.dispatch(h_level_set_recorder_disabled, {
			disabled = true
		})
	end
end

function _env:on_input(action_id, action)
	self.key_prompt:on_input(action_id, action)

	return self.button:on_input(action_id, action)
end
