local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local store = require("level.store")
local state = require("level.state")
local perks = require("campaign.perks")
local button_sound = require("sound.button")
local FocusGiver = require("crit.focus_giver")
local focus_context = require("level.torture.torture_focus_context")
local sys_config = require("lib.sys_config")
local input_state = require("crit.input_state")
local h_tint = hash("tint")
local h_color_add = hash("color_add")
local h_alpha1 = hash("alpha1")
local h_alpha2 = hash("alpha2")
local h_torture_animation = hash("torture_animation")
local h_kill = hash("kill")
local h_torture_room_hide = hash("torture_room_hide")
local h_torture_room_show = hash("torture_room_show")
local h_torture = hash("torture")
local h_highlight = hash("highlight")
local h_init_level = hash("init_level")
local h_level_set_tortures_enabled = hash("level_set_tortures_enabled")
local h_level_skip_next_torture_enable = hash("level_skip_next_torture_enable")
local h_switch_input_method = hash("switch_input_method")
local h_cabinet_open = hash("cabinet_open")
local h_cabinet_close = hash("cabinet_close")
local h_set_subject = hash("set_subject")
local h_go_off_record = hash("go_off_record")
local h_go_on_record = hash("go_on_record")
local h_ask_question = hash("ask_question")
local h_crack_destroyed = hash("crack_destroyed")
local h_key_escape = hash("key_escape")
local h_cut = hash("cut")
local h_whisky = hash("whisky")
local STATE_DISABLED = Button.STATE_DISABLED
local STATE_HOVER = Button.STATE_HOVER
local STATE_PRESSED = Button.STATE_PRESSED
local STATE_DEFAULT = Button.STATE_DEFAULT
local DRAWER_KNIFE = 1
local DRAWER_WHISKY = 2
local disable_duration = 0.7
local hover_duration = 0.3
local disabled_tint = vmath.vector4(0.1, 0.1, 0.1, 1)
local idle_tint = vmath.vector4(1, 1, 1, 1)
local hover_tint = vmath.vector4(1, 1, 1, 1)
local pressed_tint = vmath.vector4(1, 1, 1, 1)
local disabled_ca = vmath.vector4(1, 0, 0, 0)
local idle_ca = vmath.vector4(1, 0, 0, 0)
local pressed_ca = vmath.vector4(1, 0, 0, 0.3)
local hover_ca = vmath.vector4(1, 0, 0, 0.1)
local ca_highlight_red = vmath.vector4(1, 0, 0, 0.8)
local ca_default_red = vmath.vector4(1, 0, 0, 0)
local ca_highlight_white = vmath.vector4(1, 1, 1, 0.8)
local ca_default_white = vmath.vector4(1, 1, 1, 0)
local torture_action, whisky_action, prepare_button, make_torture_button, trigger_cabinet_animations, destroy_wall = nil

function trigger_cabinet_animations(self, button, button_state, old_state, drawer_id)
	if self.keep_cabinet_state == button.tag then
		return
	end

	if store.subjects[state.current_subject].health > 0 then
		if (button_state == STATE_HOVER or button_state == STATE_PRESSED) and old_state == STATE_DEFAULT then
			dispatcher.dispatch(h_cabinet_open, {
				drawer_id = drawer_id
			})
		elseif button_state == STATE_DEFAULT and (old_state == STATE_HOVER or old_state == STATE_PRESSED) then
			dispatcher.dispatch(h_cabinet_close, {
				drawer_id = drawer_id
			})
		end
	end
end

function destroy_wall(self)
	sprite.play_flipbook(self.tortures.wall.node, h_crack_destroyed)
end

local function make_drawer(sprite, button_options)
	if not sys_config.is_mobile then
		return Button.new(sprite, button_options)
	end

	local is_enabled = false
	local is_using_touch = true
	local is_shown = false

	local function update_state()
		local shown = is_enabled and is_using_touch

		if shown == is_shown then
			return
		end

		is_shown = shown

		if shown then
			button_options:on_state_change(STATE_HOVER, STATE_DEFAULT)
		else
			button_options:on_state_change(STATE_DEFAULT, STATE_HOVER)
		end
	end

	local function set_enabled(self, enabled)
		is_enabled = enabled

		update_state()
	end

	local function switch_input_method()
		is_using_touch = input_state.input_method == input_state.INPUT_METHOD_MOUSE

		update_state()
	end

	switch_input_method()

	local function nop()
		return
	end

	return {
		set_enabled = set_enabled,
		on_input = nop,
		switch_input_method = switch_input_method
	}
end

function _env:init()
	self.drawer_hover_knife = make_drawer(msg.url("knife_hover_hitbox#sprite"), {
		is_sprite = true,
		tag = h_cut,
		on_state_change = function (button, button_state, old_state)
			trigger_cabinet_animations(self, button, button_state, old_state, DRAWER_KNIFE)
		end
	})
	self.drawer_hover_whisky = make_drawer(msg.url("whisky_hover_hitbox#sprite"), {
		is_sprite = true,
		tag = h_whisky,
		on_state_change = function (button, button_state, old_state)
			trigger_cabinet_animations(self, button, button_state, old_state, DRAWER_WHISKY)
		end
	})
	local button_settings = {
		wall = {
			has_particlefx = true,
			padding_left = -50,
			padding_top = -60,
			tooltip_padding = 20,
			padding_bottom = -80,
			id = "wall",
			padding_right = -50,
			action = torture_action(store.TORTURE_WALL),
			tooltip_position = Tooltip.POSITION_RIGHT,
			hover_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Hover Wall")
		},
		cut = {
			padding_top = 40,
			has_particlefx = true,
			padding_left = 60,
			tooltip_padding = 60,
			padding_bottom = 40,
			id = "cut",
			padding_right = 60,
			action = torture_action(store.TORTURE_CUT),
			tooltip_position = Tooltip.POSITION_TOP,
			hover_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Hover Knife"),
			highlighted_sprite = msg.url("cabinet#drawer_knife")
		},
		grab = {
			has_particlefx = true,
			padding_left = -25,
			padding_top = -50,
			tooltip_padding = 0,
			padding_bottom = -50,
			id = "grab",
			padding_right = -25,
			action = torture_action(store.TORTURE_GRAB),
			tooltip_position = Tooltip.POSITION_BOTTOM,
			hover_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Hover Grab"),
			disabled_tint = vmath.vector4(1, 0, 0, 0),
			idle_tint = vmath.vector4(1, 0, 0, 0.4),
			hover_tint = vmath.vector4(1, 0, 0, 0.6),
			pressed_tint = vmath.vector4(1, 0, 0, 1)
		},
		waterboard = {
			has_particlefx = true,
			padding_left = -30,
			id = "waterboard",
			tooltip_padding = 20,
			action = torture_action(store.TORTURE_WATERBOARD),
			tooltip_position = Tooltip.POSITION_TOP,
			hover_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Hover Waterboarding")
		},
		whisky = {
			padding_top = 45,
			padding_right = 80,
			padding_bottom = 45,
			keep_hover = true,
			has_particlefx = false,
			padding_left = 80,
			tooltip_padding = 15,
			id = "whisky",
			action = whisky_action,
			tooltip_position = Tooltip.POSITION_BOTTOM,
			hover_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Bottle Hover"),
			press_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Bottle Press"),
			release_sfx = fmod and fmod.studio.system:get_event("event:/Interrogation/Bottle Release"),
			highlighted_sprite = msg.url("cabinet#drawer_whisky"),
			highlight_colors = {
				ca_default_white,
				ca_highlight_white
			},
			hover_ca = vmath.vector4(1, 1, 1, 0.1),
			pressed_ca = vmath.vector4(1, 1, 1, 0.3),
			idle_ca = vmath.vector4(1, 1, 1, 0),
			disabled_ca = vmath.vector4(1, 1, 1, 0)
		}
	}
	local wall, waterboard, grab, cut, whisky = nil

	if perks.waterboarding then
		waterboard = Button.new(msg.url("waterboard#sprite"), make_torture_button(button_settings.waterboard, {
			on_pass_focus = function (button, nav_action)
				if nav_action == Button.NAVIGATE_LEFT then
					dispatcher.dispatch(h_cabinet_close)

					return wall:focus()
				elseif nav_action == Button.NAVIGATE_RIGHT then
					dispatcher.dispatch(h_cabinet_close)

					return grab:focus()
				end
			end
		}))
	else
		msg.post("waterboard", "disable")
	end

	if perks.host then
		whisky = Button.new(msg.url("whisky#sprite"), make_torture_button(button_settings.whisky, {
			on_pass_focus = function (button, nav_action)
				if perks.pacifist then
					return false
				end

				if nav_action == Button.NAVIGATE_UP or nav_action == Button.NAVIGATE_LEFT then
					dispatcher.dispatch(h_cabinet_close)
					dispatcher.dispatch(h_cabinet_open, {
						drawer_id = DRAWER_KNIFE
					})
					cut:focus()

					return true
				end
			end
		}))
	end

	wall = Button.new(msg.url("wall#sprite"), make_torture_button(button_settings.wall, {
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_RIGHT then
				dispatcher.dispatch(h_cabinet_close)

				return (waterboard or grab):focus()
			end
		end
	}))
	grab = Button.new(msg.url("grab#sprite"), make_torture_button(button_settings.grab, {
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_LEFT then
				dispatcher.dispatch(h_cabinet_close)

				return (waterboard or wall):focus()
			elseif nav_action == Button.NAVIGATE_RIGHT then
				dispatcher.dispatch(h_cabinet_open, {
					drawer_id = DRAWER_KNIFE
				})

				return cut:focus()
			end
		end
	}))
	cut = Button.new(msg.url("cut#sprite"), make_torture_button(button_settings.cut, {
		on_pass_focus = function (button, nav_action)
			if nav_action == Button.NAVIGATE_LEFT then
				dispatcher.dispatch(h_cabinet_close)

				return grab:focus()
			elseif nav_action == Button.NAVIGATE_RIGHT or nav_action == Button.NAVIGATE_DOWN then
				if whisky then
					dispatcher.dispatch(h_cabinet_close)
					dispatcher.dispatch(h_cabinet_open, {
						drawer_id = DRAWER_WHISKY
					})
				end

				return whisky and whisky:focus()
			end
		end
	}))
	self.tortures = {
		wall = wall,
		grab = grab,
		cut = cut,
		waterboard = waterboard,
		whisky = whisky
	}

	for id, button in pairs(self.tortures) do
		prepare_button(button, button_settings[id])
	end

	self.skip_next_torture_enable = false
	self.focus_giver = FocusGiver.new({
		focus_context = focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if state.torture_room_shown then
				if not nav_action then
					if perks.pacifist and whisky then
						dispatcher.dispatch(h_cabinet_open, {
							drawer_id = DRAWER_WHISKY
						})

						return whisky:focus()
					else
						return grab:focus()
					end
				elseif nav_action == Button.NAVIGATE_RIGHT then
					return wall:focus()
				elseif nav_action == Button.NAVIGATE_LEFT then
					local drawer_to_open = whisky and DRAWER_WHISKY or DRAWER_KNIFE

					dispatcher.dispatch(h_cabinet_open, {
						drawer_id = drawer_to_open
					})

					self.keep_cabinet_state = whisky and h_whisky or h_cut

					timer.delay(0, false, function ()
						self.keep_cabinet_state = false
					end)

					return whisky and whisky:focus() or cut:focus()
				end
			else
				return false
			end
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_torture_room_show,
		h_torture_room_hide,
		h_kill,
		h_init_level,
		h_level_set_tortures_enabled,
		h_level_skip_next_torture_enable,
		h_switch_input_method,
		h_go_off_record,
		h_set_subject,
		h_go_on_record
	})
end

function make_torture_button(settings, button_opts)
	local tooltip_state_change = nil

	if settings.id then
		tooltip_state_change = Tooltip.button_on_state_change({
			id = "torture_" .. settings.id,
			type = h_torture,
			payload = {
				id = settings.id
			},
			position = settings.tooltip_position,
			padding = settings.tooltip_padding
		}, false)
	end

	button_opts.is_sprite = true
	button_opts.keep_hover = settings.keep_hover or false
	button_opts.keyboard_focus = true
	button_opts.gamepad_focus = true
	button_opts.focus_context = focus_context
	button_opts.focus_simulates_hover = true
	button_opts.padding_left = settings.padding_left or 0
	button_opts.padding_right = settings.padding_right or 0
	button_opts.padding_top = settings.padding_top or 0
	button_opts.padding_bottom = settings.padding_bottom or 0
	button_opts.action = settings.action
	local hover_sfx = settings.hover_sfx or false
	local press_sfx = settings.press_sfx or false
	local release_sfx = settings.release_sfx or false
	button_opts.on_state_change = button_sound.with_sound({
		hover = hover_sfx,
		press = press_sfx,
		release = release_sfx
	}, function (button, button_state, old_state, did_click)
		local url = button.node
		local tint, color_add = nil

		if button_state == STATE_DISABLED then
			tint = button.disabled_tint or disabled_tint
			color_add = button.disabled_ca or disabled_ca
		elseif button_state == STATE_HOVER then
			tint = button.hover_tint or hover_tint
			color_add = button.hover_ca or hover_ca
		elseif button_state == STATE_PRESSED then
			tint = button.pressed_tint or pressed_tint
			color_add = button.pressed_ca or pressed_ca
		else
			tint = button.idle_tint or idle_tint
			color_add = button.idle_ca or idle_ca
		end

		local disabled_transition = button_state == STATE_DISABLED or button.state == STATE_DISABLED
		local duration = disabled_transition and disable_duration or hover_duration

		go.cancel_animations(url, h_tint)
		go.animate(url, h_tint, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, duration)

		if button.has_particlefx then
			local highlight = msg.url(url.socket, url.path, h_highlight)
			local highlight_alpha = (button_state == STATE_HOVER or button_state == STATE_PRESSED) and 1 or 0

			go.cancel_animations(highlight, h_alpha1)
			go.animate(highlight, h_alpha1, go.PLAYBACK_ONCE_FORWARD, highlight_alpha, go.EASING_LINEAR, duration)
		end

		if button.highlighted_sprite then
			local highlighted_sprite = button.highlighted_sprite

			go.cancel_animations(highlighted_sprite, h_color_add)
			go.animate(highlighted_sprite, h_color_add, go.PLAYBACK_ONCE_FORWARD, color_add, go.EASING_LINEAR, duration)
		end

		if tooltip_state_change then
			tooltip_state_change(button, button_state, old_state, did_click)
		end
	end)

	return button_opts
end

function prepare_button(button, settings)
	button:set_enabled(false)

	local node = button.node
	button.highlighted_sprite = settings.highlighted_sprite or button.node
	button.highlight_colors = settings.highlight_colors or {
		ca_default_red,
		ca_highlight_red
	}
	button.has_particlefx = settings.has_particlefx
	button.disabled_tint = settings.disabled_tint
	button.idle_tint = settings.idle_tint
	button.hover_tint = settings.hover_tint
	button.pressed_tint = settings.pressed_tint
	button.disabled_ca = settings.disabled_ca
	button.idle_ca = settings.idle_ca
	button.hover_ca = settings.hover_ca
	button.pressed_ca = settings.pressed_ca

	go.cancel_animations(node, h_tint)
	go.set(node, h_tint, settings.disabled_tint or disabled_tint)
end

function torture_action(torture_id)
	return function ()
		dispatcher.dispatch(h_torture_animation, {
			torture_id = torture_id
		})
	end
end

function whisky_action()
	if state.phase == state.PHASE_RUNNING and state.torture_room_shown then
		local whisky_question_id = store.get_triggered_question(state.current_subject, "whisky")

		if whisky_question_id then
			dispatcher.dispatch(h_ask_question, {
				question_id = whisky_question_id
			})
		end
	end
end

local function flash_button(button)
	local url = button.node
	local hilite_sprite = button.highlighted_sprite
	local hc_default = button.highlight_colors[1]
	local hc_highlight = button.highlight_colors[2]

	if button.has_particlefx then
		local highlight = msg.url(url.socket, url.path, h_highlight)

		go.animate(highlight, h_alpha2, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.3, 0.3, function ()
			go.animate(highlight, h_alpha2, go.PLAYBACK_ONCE_FORWARD, 0.6, go.EASING_LINEAR, 0.8, 0.2)
		end)
	end

	go.set(hilite_sprite, h_color_add, hc_default)
	go.animate(hilite_sprite, h_color_add, go.PLAYBACK_ONCE_FORWARD, hc_highlight, go.EASING_LINEAR, 0.3, 0.5, function ()
		go.animate(hilite_sprite, h_color_add, go.PLAYBACK_ONCE_FORWARD, hc_default, go.EASING_LINEAR, 0.5, 0.3)
	end)
end

local function hide_button(button)
	local url = button.node

	if button.has_particlefx then
		local highlight = msg.url(url.socket, url.path, h_highlight)

		go.cancel_animations(highlight, h_alpha2)
		go.animate(highlight, h_alpha2, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 1)
	end
end

local function enable_cabinet_hover_buttons(self, enabled)
	self.drawer_hover_knife:set_enabled(enabled and not perks.pacifist)
	self.drawer_hover_whisky:set_enabled(enabled and perks.host)
end

local function enable_tortures(self)
	if store.subjects[state.current_subject].health > 0 then
		if not perks.pacifist then
			for id, torture in pairs(self.tortures) do
				torture:set_enabled(true)
				flash_button(torture)
			end
		end

		if self.tortures.whisky then
			flash_button(self.tortures.whisky)
			self.tortures.whisky:set_enabled(true)
		end

		enable_cabinet_hover_buttons(self, true)
	end

	self.focus_timer = timer.delay(0.4, false, function ()
		self.focus_timer = nil

		self.focus_giver:try_focus_first()
	end)
end

local function disable_tortures(self)
	for id, torture in pairs(self.tortures) do
		torture:set_enabled(false)
		hide_button(torture)
	end

	enable_cabinet_hover_buttons(self, false)

	if self.focus_timer then
		timer.cancel(self.focus_timer)

		self.focus_timer = nil
	end

	dispatcher.dispatch(h_cabinet_close)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		enable_cabinet_hover_buttons(self, false)
	elseif message_id == h_torture_room_show then
		if self.skip_next_torture_enable then
			self.skip_next_torture_enable = false

			return
		end

		enable_tortures(self)
	elseif message_id == h_torture_room_hide then
		disable_tortures(self)
	elseif message_id == h_kill then
		disable_tortures(self)
	elseif message_id == h_switch_input_method then
		for id, button in pairs(self.tortures) do
			button:switch_input_method()
		end

		self.drawer_hover_knife:switch_input_method()
		self.drawer_hover_whisky:switch_input_method()

		if not sys_config.is_mobile or input_state.input_method ~= input_state.INPUT_METHOD_MOUSE then
			local close_message = nil
			local keep_cabinet_state = self.keep_cabinet_state

			if keep_cabinet_state then
				if keep_cabinet_state == h_cut then
					close_message = {
						drawer_id = DRAWER_WHISKY
					}
				else
					close_message = {
						drawer_id = DRAWER_KNIFE
					}
				end
			end

			dispatcher.dispatch(h_cabinet_close, close_message)
		end

		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_level_skip_next_torture_enable then
		self.skip_next_torture_enable = true
	elseif message_id == h_level_set_tortures_enabled then
		if message.enabled then
			enable_tortures(self)
		else
			disable_tortures(self)
		end
	end
end

function _env:on_input(action_id, action)
	if self.drawer_hover_whisky:on_input(action_id, action) then
		return true
	end

	if self.drawer_hover_knife:on_input(action_id, action) then
		return true
	end

	for id, button in pairs(self.tortures) do
		if button:on_input(action_id, action) then
			return true
		end
	end

	if self.focus_giver:on_input(action_id, action) then
		return true
	end

	if action_id == h_key_escape and action.pressed and not state.on_record and not state.recorder_disabled then
		dispatcher.dispatch(h_go_on_record)

		return true
	end

	if state.torture_room_shown then
		return true
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
