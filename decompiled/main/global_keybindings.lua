local dispatcher = require("crit.dispatcher")
local sys_config = require("lib.sys_config")
local cursor = require("lib.cursor")
local analog_to_digital = require("crit.analog_to_digital")
local input_method_switcher = require("main.input_method_switcher")
local env = require("lib.environment")
local save_file = require("lib.save_file")
local Layout = require("crit.layout")
local variables = require("campaign.variables")
local cheatcodes = require("main.cheatcodes")
local debug_input = require("main.debug.debug_input")
local h_text = hash("text")
local h_key_alt = hash("key_alt")
local h_key_ctrl = hash("key_ctrl")
local h_key_shift = hash("key_shift")
local h_key_f4 = hash("key_f4")
local h_key_enter = hash("key_enter")
local h_key_backquote = hash("key_backquote")
local h_key_h = hash("key_h")
local h_key_right = hash("key_right")
local h_key_left = hash("key_left")
local h_key_m = hash("key_m")
local h_key_r = hash("key_r")
local h_key_d = hash("key_d")
local h_debug_info_toggle = hash("debug_info_toggle")
local h_debug_map_toggle = hash("debug_map_toggle")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_pause_menu_init = hash("pause_menu_init")
local h_settings_init = hash("settings_init")
local h_settings_acquire_input_focus = hash("settings_acquire_input_focus")
local h_settings_hide = hash("settings_hide")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_attempt_pause = hash("attempt_pause")
local h_attempt_resume = hash("attempt_resume")
local h_key_p = hash("key_p")
local h_gamepad_start = hash("gamepad_start")
local h_gamepad_back = hash("gamepad_back")
local h_key_backslash = hash("key_backslash")
local h_gamepad_ltrigger = hash("gamepad_ltrigger")
local h_gamepad_rtrigger = hash("gamepad_rtrigger")
local h_gamepad_lshoulder = hash("gamepad_lshoulder")
local h_gamepad_rshoulder = hash("gamepad_rshoulder")
local h_gamepad_rstick_click = hash("gamepad_rstick_click")
local h_gamepad_lstick_click = hash("gamepad_lstick_click")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_gamepad_rpad_left = hash("gamepad_rpad_left")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_click = hash("click")
local current_scene = require("main.scene_loader.current_scene")
local numbers = {}

for i = 0, 9 do
	numbers[hash("key_" .. i)] = i
end

local on_debug_input = nil

function _env:init()
	self.alt_down = false
	self.shift_down = false
	self.ctrl_down = false
	self.back_down = false
	self.paused = false
	self.shows_settings = false
	self.idle_timer = 0
	self.sub_id = dispatcher.subscribe({
		h_pause_menu_init,
		h_settings_init,
		h_settings_hide,
		h_settings_acquire_input_focus,
		h_pause,
		h_resume
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local debug = env.debug or not env.bundled

function _env:on_message(message_id, message, sender)
	if message_id == h_pause_menu_init then
		msg.post(".", h_acquire_input_focus)
	elseif message_id == h_settings_init then
		self.shows_settings = true
	elseif message_id == h_settings_acquire_input_focus then
		msg.post(".", h_acquire_input_focus)
	elseif message_id == h_settings_hide then
		self.shows_settings = false
	elseif message_id == h_pause then
		self.paused = true
	elseif message_id == h_resume then
		self.paused = false
	end
end

function _env:on_input(action_id, action)
	analog_to_digital.on_input(action_id, action)
	input_method_switcher(action_id, action)

	self.idle_timer = 0

	if action_id == h_key_alt then
		if action.pressed then
			self.alt_down = true
		end

		if action.released then
			self.alt_down = false
		end
	elseif action_id == h_key_shift then
		if action.pressed then
			self.shift_down = true
		end

		if action.released then
			self.shift_down = false
		end
	elseif action_id == h_key_ctrl then
		if action.pressed then
			self.ctrl_down = true
		end

		if action.released then
			self.ctrl_down = false
		end
	elseif action_id == h_key_enter then
		if action.pressed and self.alt_down and defos then
			defos.toggle_fullscreen()

			return true
		end
	elseif action_id == h_key_f4 then
		if action.pressed and self.alt_down then
			local system_name = sys_config.system_name

			if system_name == "Windows" or system_name == "Linux" then
				msg.post("@system:", "exit", {
					code = 0
				})

				return true
			end
		end
	elseif (action_id == h_key_p or action_id == h_gamepad_start) and not self.back_down then
		if action.pressed and not self.shows_settings and current_scene.scene ~= "menu" then
			dispatcher.dispatch(self.paused and h_attempt_resume or h_attempt_pause)

			return true
		end
	elseif action_id == h_text then
		return cheatcodes.on_text(action.text)
	elseif debug then
		return on_debug_input(self, action_id, action)
	end
end

local hotspot_sequences = {
	{
		1,
		0,
		2,
		pos = 1,
		action = function ()
			dispatcher.dispatch("debug_hub_toggle")
		end
	},
	{
		1,
		0,
		3,
		pos = 1,
		action = function ()
			dispatcher.dispatch("debug_hub_toggle")
		end
	},
	{
		1,
		0,
		0,
		1,
		1,
		1,
		0,
		pos = 1,
		action = function ()
			dispatcher.dispatch("debug_hub_toggle")
		end
	},
	{
		0,
		1,
		0,
		1,
		0,
		pos = 1,
		action = function ()
			dispatcher.dispatch("debug_hub_toggle")
		end
	}
}

for _, seq in ipairs(hotspot_sequences) do
	local fail = {
		0
	}
	local cnd = 1

	for pos = 2, #seq do
		if seq[pos] == seq[cnd] then
			fail[pos] = fail[cnd]
		else
			fail[pos] = cnd
			cnd = fail[cnd]

			while cnd >= 1 and seq[pos] ~= seq[cnd] do
				cnd = fail[cnd]
			end
		end

		cnd = cnd + 1
	end

	seq.fail = fail
end

function on_debug_input(self, action_id, action)
	if action_id == h_click then
		if action.pressed then
			local hotspot = nil
			local low_x = action.screen_x <= 100
			local high_x = action.screen_x >= Layout.window_width - 100
			local low_y = action.screen_y <= 100
			local high_y = action.screen_y >= Layout.window_height - 100

			if low_x and low_y then
				hotspot = 0
			elseif high_x and low_y then
				hotspot = 1
			elseif low_x and high_y then
				hotspot = 2
			elseif high_x and high_y then
				hotspot = 3
			end

			self.hotspot_pressed = false

			if not hotspot then
				return
			end

			local hotspot_pressed = false
			local hotspot_pressed_not_first = false

			for i, seq in ipairs(hotspot_sequences) do
				while seq.pos >= 1 and seq[seq.pos] ~= hotspot do
					seq.pos = seq.fail[seq.pos]
				end

				if seq.pos < 1 then
					seq.pos = 1
				end

				if seq[seq.pos] == hotspot then
					hotspot_pressed = true

					if seq.pos > 1 then
						hotspot_pressed_not_first = true
					end

					if seq.pos == #seq then
						seq.pos = 1

						seq.action()
					else
						seq.pos = seq.pos + 1
					end
				end
			end

			self.hotspot_pressed = hotspot_pressed_not_first

			if not hotspot_pressed then
				return
			end

			if self.hotspot_timer then
				timer.cancel(self.hotspot_timer)

				self.hotspot_timer = nil
			end

			self.hotspot_timer = timer.delay(5, false, function ()
				self.hotspot_timer = nil

				for _, seq in ipairs(hotspot_sequences) do
					seq.pos = 1
				end
			end)

			return hotspot_pressed_not_first
		elseif action.released then
			local hotspot_pressed = self.hotspot_pressed
			self.hotspot_pressed = false

			return hotspot_pressed
		end

		return self.hotspot_pressed
	elseif action_id == h_gamepad_back or action_id == h_key_backslash then
		if action_id == h_gamepad_back then
			if action.pressed then
				self.back_down = true
			end

			if action.released then
				self.back_down = false
			end
		end

		if action.pressed then
			debug_input.captures_input = true
		end

		if action.released then
			local timestamp = socket.gettime()
			local last_back_release = self.last_back_release or 0
			self.last_back_release = timestamp

			if timestamp - last_back_release > 0.5 then
				debug_input.captures_input = false
			end
		end
	elseif action_id == h_key_h then
		if action.pressed and self.alt_down and defos then
			local cursor_visible = not self.cursor_visible
			self.cursor_visible = cursor_visible
			cursor_visible = cursor_visible or nil

			cursor.set_visible(cursor_visible, cursor.PRIORITY_IMPORTANT)

			return true
		end
	elseif action_id == h_key_r then
		if action.pressed and self.alt_down and not self.paused then
			dispatcher.dispatch("campaign_reset")

			return true
		end
	elseif action_id == h_key_right or action_id == h_gamepad_rshoulder then
		if action.pressed and (self.alt_down or self.back_down) and not self.paused then
			dispatcher.dispatch("skip_progression", {
				keep_transition = self.shift_down
			})

			return true
		end
	elseif action_id == h_key_left or action_id == h_gamepad_lshoulder then
		if action.pressed and (self.alt_down or self.back_down) and not self.paused then
			dispatcher.dispatch("campaign_rewind")

			return true
		end
	elseif action_id == h_gamepad_ltrigger then
		if action.pressed and self.back_down then
			dispatcher.dispatch(h_debug_map_toggle)

			return true
		end
	elseif action_id == h_gamepad_rtrigger then
		if action.pressed and self.back_down then
			dispatcher.dispatch(h_debug_info_toggle)

			return true
		end
	elseif action_id == h_gamepad_rstick_click then
		if action.pressed and self.back_down then
			msg.post("@system:", "toggle_profile")

			return true
		end
	elseif action_id == h_gamepad_lstick_click then
		if action.pressed and self.back_down then
			dispatcher.dispatch("debug_misc_key")

			return true
		end
	elseif action_id == h_gamepad_rpad_right then
		if action.pressed and self.back_down then
			dispatcher.dispatch("game_over", {
				reason = "win",
				has_won = true
			})

			return true
		end
	elseif action_id == h_gamepad_rpad_up then
		if action.pressed and self.back_down then
			dispatcher.dispatch("game_over", {
				reason = "death",
				has_won = false
			})

			return true
		end
	elseif action_id == h_gamepad_rpad_left then
		if action.pressed and self.back_down then
			dispatcher.dispatch("game_over", {
				reason = "timeout",
				has_won = false
			})

			return true
		end
	elseif action_id == h_key_left or action_id == h_gamepad_lshoulder then
		if action.pressed and (self.alt_down or self.back_down) and not self.paused then
			dispatcher.dispatch("campaign_rewind")

			return true
		end
	elseif action_id == h_key_backquote then
		if action.pressed then
			if self.alt_down then
				dispatcher.dispatch("debug_misc_key")
			elseif self.shift_down then
				dispatcher.dispatch("campaign_print_history")
			elseif self.ctrl_down then
				msg.post("@system:", "toggle_profile")
			else
				dispatcher.dispatch(h_debug_info_toggle)
			end

			return true
		end
	elseif action_id == h_key_m then
		if action.pressed and self.alt_down then
			if self.shift_down then
				pprint(_G.save_route)
				pprint(variables)
			else
				dispatcher.dispatch(h_debug_map_toggle)
			end

			return true
		end
	elseif action_id == h_key_d or action_id == h_gamepad_start then
		if action.pressed and (self.alt_down or self.back_down) then
			dispatcher.dispatch("debug_hub_toggle")

			return true
		end
	elseif numbers[action_id] and action.pressed and self.alt_down then
		local slot = numbers[action_id]

		if self.shift_down then
			dispatcher.dispatch("campaign_save_to_slot", {
				slot = slot
			})
		else
			dispatcher.dispatch("campaign_rewind", {
				slot = slot
			})
		end
	end
end

function _env:update(dt)
	analog_to_digital.update()

	if debug then
		self.idle_timer = self.idle_timer + dt
		local timeout = save_file.config.idle_reset

		if timeout > 0 and timeout <= self.idle_timer then
			self.idle_timer = 0

			dispatcher.dispatch("campaign_reset")
		end
	end
end
