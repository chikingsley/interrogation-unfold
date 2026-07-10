local Layout = require("crit.layout")
local Button = require("crit.button")
local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local intl = require("crit.intl")
local h_start_game = hash("start_game")
local h_window_change_size = hash("window_change_size")
local h_game_over = hash("game_over")
local h_init_level = hash("init_level")
local h_play_sfx = hash("play_sfx")
local h_end_scene = hash("end_scene")
local h_level_intro_show = hash("level_intro_show")
local h_drawer_casefile_will_autoopen = hash("drawer_casefile_will_autoopen")
local h_drawer_casefile_set_open = hash("drawer_casefile_set_open")
local h_gamepad_rpad_down = hash("gamepad_rpad_down")
local h_key_enter = hash("key_enter")
local h_key_space = hash("key_space")
local h_switch_input_method = hash("switch_input_method")
local h_init_level_lite = hash("init_level_lite")
local h_level_question_bubble_clearance = hash("level_question_bubble_clearance")
local h_color_w = hash("color.w")
local level_start_delay = 2
local level_end_delay = 2

local function button_pressed(button, key_prompt)
	local is_lite = button.is_lite and 1 or 0
	local is_higgs = button.is_higgs and 1 or 0

	if state.phase == state.PHASE_INTRO then
		dispatcher.dispatch(h_play_sfx, {
			sfx = "bring_them_in",
			parameters = {
				IsHiggs = is_higgs
			}
		})
		timer.delay(level_start_delay, false, function ()
			dispatcher.dispatch(h_start_game)
		end)
		key_prompt:set_enabled(false)
		button:set_enabled(false)
	elseif state.phase == state.PHASE_OVER then
		dispatcher.dispatch(h_play_sfx, {
			sfx = "report_findings",
			parameters = {
				LevelLite = is_lite
			}
		})
		timer.delay(level_end_delay, false, function ()
			dispatcher.dispatch(h_end_scene, {
				has_won = true,
				reason = state.game_over_reason
			})
		end)
		key_prompt:set_enabled(false)
		button:set_enabled(false)
	end
end

function _env:init()
	local container = gui.get_node("container")
	self.container = container
	self.key_prompt = KeyPrompt.new(gui.get_node("prompt_a"), {
		halo = gui.get_node("prompt_a_halo"),
		action_id = h_gamepad_rpad_down
	})
	self.button = Button.new(gui.get_node("button"), {
		disabled_opacity = 0,
		keep_hover = true,
		action = function (button)
			button_pressed(button, self.key_prompt)
		end,
		on_state_change = button_sound.with_sound(),
		shortcut_actions = {
			h_gamepad_rpad_down,
			h_key_enter,
			h_key_space
		}
	})

	self.button:set_enabled(false)
	self.key_prompt:set_enabled(false)
	gui.cancel_animation(self.button.node, h_color_w)

	local color = gui.get_color(self.button.node)
	color.w = 0

	gui.set_color(self.button.node, color)

	self.clearance = 0
	self.layout = Layout.new()

	self.layout:add_node(container)

	self.button_label = gui.get_node("button_label")

	gui.set_render_order(6)

	self.sub_id = dispatcher.subscribe({
		h_start_game,
		h_game_over,
		h_window_change_size,
		h_level_intro_show,
		h_init_level,
		h_drawer_casefile_will_autoopen,
		h_drawer_casefile_set_open,
		h_switch_input_method,
		h_init_level_lite,
		h_level_question_bubble_clearance
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function place(self)
	self.layout:place()

	local container = self.container
	local button_node = self.button.node
	local panel_scale = Layout.viewport_width / Layout.design_width
	local button_height = gui.get_size(button_node).y * gui.get_scale(button_node).y * gui.get_scale(container).y
	local max_y = Layout.viewport_height + self.clearance * panel_scale - button_height * 0.5
	local position = gui.get_position(container)

	if max_y < position.y then
		position.y = max_y

		gui.set_position(container, position)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_window_change_size then
		place(self)
	elseif message_id == h_level_question_bubble_clearance then
		self.clearance = message.pos_y

		place(self)
	elseif message_id == h_game_over then
		if message.has_won then
			gui.set_text(self.button_label, intl(self.report_findings_key))
			self.button:set_enabled(true)
			self.key_prompt:set_enabled(true)
		end
	elseif message_id == h_start_game then
		self.key_prompt:set_enabled(false)
	elseif message_id == h_init_level then
		local is_episode5 = message.level == "episode5"
		local bring_them_in_key = message.bring_them_in_key or "level.bring_them_in"
		self.report_findings_key = message.report_findings_key or "level.report_findings"

		gui.set_text(self.button_label, intl(bring_them_in_key))

		if is_episode5 then
			self.button.is_higgs = true

			gui.set_scale(self.button_label, vmath.vector3(0.9))
		end

		if not message.hide_intro_button then
			self.show_button_timer = timer.delay(0.0001, false, function ()
				self.show_button_timer = timer.delay(0.0001, false, function ()
					self.show_button_timer = timer.delay(1, false, function ()
						self.button:set_enabled(true)
						self.key_prompt:set_enabled(true)

						self.show_button_timer = nil
					end)
				end)
			end)
		end
	elseif message_id == h_drawer_casefile_will_autoopen then
		if not self.show_button_timer then
			return
		end

		self.wait_for_casefile_close = true

		timer.cancel(self.show_button_timer)
	elseif message_id == h_drawer_casefile_set_open then
		if self.wait_for_casefile_close and not message.value then
			self.wait_for_casefile_close = false

			self.button:set_enabled(true)
			self.key_prompt:set_enabled(true)
		end
	elseif message_id == h_level_intro_show then
		self.button:set_enabled(true)
		self.key_prompt:set_enabled(true)
	elseif message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
		self.button:switch_input_method()
	elseif message_id == h_init_level_lite then
		self.button.is_lite = true
	end
end

function _env:on_input(action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.button:on_input(action_id, action) then
		return true
	end
end
