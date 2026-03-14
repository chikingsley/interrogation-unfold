local FullScreenPanel = require("lib.full_screen_panel")
local Button = require("crit.button")
local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local Directional = require("lib.directional")
local analog_to_digital = require("crit.analog_to_digital")
local gesture = require("in.gesture")
local large_ui = require("lib.large_ui")
local ZoomPan = require("lib.zoom_and_pan")
local Layout = require("crit.layout")
local save_file = require("lib.save_file")
local sys_config = require("lib.sys_config")
local h_window_change_size = hash("window_change_size")
local h_drawer_casefile_set_open = hash("drawer_casefile_set_open")
local h_drawer_casefile_request_open = hash("drawer_casefile_request_open")
local h_drawer_casefile_will_autoopen = hash("drawer_casefile_will_autoopen")
local h_casefile_transition_state = hash("casefile_transition_state")
local h_table_set_position = hash("table_set_position")
local h_level_casefile_stand_in_set_enabled = hash("level_casefile_stand_in_set_enabled")
local h_colorw = hash("color.w")
local h_set_page_casefile = hash("set_page_casefile")
local h_level_casefile_init = hash("level_casefile_init")
local h_play_sfx = hash("play_sfx")
local h_game_over = hash("game_over")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_gamepad_rpad_left = hash("gamepad_rpad_left")
local h_gamepad_rpad_up = hash("gamepad_rpad_up")
local h_gamepad_rshoulder = hash("gamepad_rshoulder")
local h_gamepad_lshoulder = hash("gamepad_lshoulder")
local h_key_f = hash("key_f")
local h_key_z = hash("key_z")
local h_click = hash("click")
local h_go_on_record = hash("go_on_record")
local h_level_highlight_hide = hash("level_highlight_hide")
local h_level_highlight_show = hash("level_highlight_show")
local h_light_flicker_animate = hash("light_flicker_animate")
local h_casefile = hash("casefile")
local h_color = hash("color")
local h_show_subject = hash("show_subject")
local h_below = hash("below")
local h_above = hash("above")
local h_switch_input_method = hash("switch_input_method")
local h_level_highlight_set_enabled = hash("level_highlight_set_enabled")
local h_level_disable_controls = hash("level_disable_controls")
local h_level_enable_controls = hash("level_enable_controls")
local h_key_escape = hash("key_escape")
local casefile_frames = {
	"casefile1",
	"casefile2",
	"casefile3",
	"casefile5",
	"casefile7",
	"casefile9",
	"casefile10",
	"casefile11",
	"casefile12",
	"casefile14",
	"casefile16"
}
local hitbox_start = {
	top = 80,
	bottom = -80,
	left = -130,
	right = 125
}
local hitbox_hover = hitbox_start
local hitbox_end = {
	top = 515,
	bottom = -525,
	left = -860,
	right = 765
}
local hover_frame = 2
local casefile_hitboxes = {
	hitbox_start
}

for i = 2, hover_frame do
	casefile_hitboxes[i] = hitbox_hover
end

for i = hover_frame + 1, #casefile_frames do
	casefile_hitboxes[i] = hitbox_end
end

local casefile_offset = vmath.vector3(-290, -91, 0)
local large_ui_offset = vmath.vector3(0, 25, 0)
local update_prevnext_disabled, on_panel_state, button_quick_disable, next_subject, prev_subject, init_page, set_zoom, set_zoom_user, configure_zoom_bounds = nil

local function get_panel_position()
	local offset = casefile_offset

	if large_ui.enabled then
		offset = offset + large_ui_offset
	end

	local panel_position = state.table_position + offset * state.table_scale
	local scale = state.table_scale

	return panel_position, scale
end

function _env:init()
	local prompt_node, prompt_action_id = KeyPrompt.select_gui(gui.get_node("template/prompt_x"), {
		Switch = {
			hash("prompt_y"),
			h_gamepad_rpad_up
		},
		default = {
			hash("prompt_x"),
			h_gamepad_rpad_left
		}
	}, sys_config.system_name)
	self.panel = FullScreenPanel.new({
		fps = 15,
		closed_gui_order = 8,
		open_gui_order = 9,
		margin_horizontal = 145,
		container = gui.get_node("template/panel_container"),
		node = gui.get_node("template/panel"),
		background = gui.get_node("template/background"),
		frames = casefile_frames,
		hitboxes = casefile_hitboxes,
		hover_frame = hover_frame,
		action_map = {
			[h_click] = true,
			[prompt_action_id] = true,
			[h_key_f] = true
		},
		on_state_change = function (button_state, old_state)
			on_panel_state(self, button_state, old_state)
		end,
		on_drawer_set_open = function (value)
			dispatcher.dispatch(h_drawer_casefile_request_open, {
				value = value
			})
		end,
		on_frame_change = function (frame_index)
			local is_first = frame_index == 1

			gui.set_enabled(self.panel.node, not is_first)
			dispatcher.dispatch(h_level_casefile_stand_in_set_enabled, {
				enabled = is_first
			})
		end,
		easing = function (t)
			t = t - 1

			return 1 - t * t * t * t
		end
	})

	self.panel:set_position(get_panel_position())

	local on_state_change = button_sound.with_sound({
		release = false,
		press = false
	}, button_quick_disable)
	self.quit_button = Button.new(gui.get_node("template/quit"), {
		disabled_opacity = 1,
		faded_nodes = {
			gui.get_node("template/quit_times")
		},
		on_state_change = on_state_change,
		shortcut_actions = {
			h_gamepad_rpad_right,
			h_key_escape
		},
		action = function ()
			dispatcher.dispatch(h_drawer_casefile_request_open, {
				value = false
			})
		end
	})

	self.quit_button:set_enabled(false)

	self.quit_key_button = Button.new(nil, {
		shortcut_actions = {
			h_gamepad_rpad_right,
			h_key_escape
		},
		action = function ()
			dispatcher.dispatch(h_drawer_casefile_request_open, {
				value = false
			})
		end
	})

	self.quit_key_button:set_enabled(false)

	self.next_button = Button.new(gui.get_node("template/next"), {
		on_state_change = on_state_change,
		shortcut_actions = {
			h_gamepad_rshoulder
		},
		faded_nodes = {
			gui.get_node("template/next_chevron")
		},
		action = function ()
			next_subject(self)
		end
	})
	self.prev_button = Button.new(gui.get_node("template/prev"), {
		on_state_change = on_state_change,
		shortcut_actions = {
			h_gamepad_lshoulder
		},
		faded_nodes = {
			gui.get_node("template/prev_chevron")
		},
		action = function ()
			prev_subject(self)
		end
	})
	self.zoom_button = Button.new(gui.get_node("template/zoom"), {
		disabled_opacity = 1,
		on_state_change = on_state_change,
		faded_nodes = {
			gui.get_node("template/zoom_icon")
		},
		shortcut_actions = {
			h_gamepad_rpad_up,
			h_key_z
		},
		action = function ()
			if self.is_shown then
				set_zoom_user(self, not self.zoomed)
			end
		end
	})

	self.zoom_button:set_enabled(false)

	self.gesture = gesture.create({
		multi_touch = true,
		action_id = h_click
	})
	self.current_page = 1
	self.pages = {}

	init_page(self, "brief")

	for _, subject in ipairs(store.subjects) do
		init_page(self, subject.avatar)
	end

	self.toggle_key_prompt = KeyPrompt.new(prompt_node, {
		action_id = prompt_action_id,
		halo = gui.get_node("template/prompt_x_halo")
	})
	self.quit_key_prompt = KeyPrompt.new(gui.get_node("template/prompt_b"), {
		action_id = h_gamepad_rpad_right,
		halo = gui.get_node("template/prompt_b_halo")
	})
	self.zoom_key_prompt = KeyPrompt.new(gui.get_node("template/prompt_y"), {
		action_id = h_gamepad_rpad_up,
		halo = gui.get_node("template/prompt_y_halo")
	})
	self.lb_key_prompt = KeyPrompt.new(gui.get_node("template/prompt_lb"), {
		action_id = h_gamepad_lshoulder,
		halo = gui.get_node("template/prompt_lb_halo")
	})
	self.rb_key_prompt = KeyPrompt.new(gui.get_node("template/prompt_rb"), {
		action_id = h_gamepad_rshoulder,
		halo = gui.get_node("template/prompt_rb_halo")
	})

	gui.set_layer(self.toggle_key_prompt.node, h_above)
	gui.set_layer(self.toggle_key_prompt.halo, h_above)
	gui.set_render_order(8)

	local size = self.panel.panel_size
	local panel_node = self.panel.node
	self.zoom_pan = ZoomPan.new({
		min_zoom = 1,
		max_zoom = 2,
		content = {
			right = size.x * 0.5,
			left = -size.x * 0.5,
			top = size.y * 0.5,
			bottom = -size.y * 0.5
		},
		on_change = function (zoom, position)
			gui.set_scale(panel_node, vmath.vector3(zoom, zoom, 1))
			gui.set_position(panel_node, position)
		end
	})
	self.zoomed = false
	self.directional = Directional.new({
		gamepad = true,
		keyboard = true,
		pan_speed = 1500,
		on_pan = function (dx, dy)
			if not self.zoomed or self.zoom_pan.animating then
				return
			end

			self.zoom_pan.pan(-dx, -dy)
		end,
		on_begin = function ()
			self.zoom_pan.on_cancel_touch()
		end
	})

	update_prevnext_disabled(self)
	self.panel:place()
	configure_zoom_bounds(self)

	self.sub_id = dispatcher.subscribe({
		h_level_casefile_init,
		h_set_page_casefile,
		h_game_over,
		h_go_on_record,
		h_drawer_casefile_set_open,
		h_table_set_position,
		h_window_change_size,
		h_switch_input_method,
		h_light_flicker_animate,
		h_level_highlight_set_enabled,
		h_show_subject,
		h_level_disable_controls,
		h_level_enable_controls
	})
end

local function page_index_to_name(index)
	local subject_id = store.subject_in_casefile[index]

	if subject_id == 0 then
		return "brief"
	end

	return store.subjects[subject_id].avatar
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function init_page(self, name)
	local node = nil
	local ok = pcall(function ()
		node = gui.get_node(name)
	end)

	if not ok then
		print("WARNING: Cannot find casefile page \"" .. name .. "\"")

		return
	end

	gui.set_parent(node, self.panel.node)
	gui.set_position(node, vmath.vector3(0))
	gui.set_color(node, vmath.vector3(1, 1, 1, 0))
	gui.set_enabled(node, false)

	self.pages[name] = node
end

function next_subject(self)
	if self.current_page < store.casefile_count then
		dispatcher.dispatch(h_set_page_casefile, {
			next = true,
			page = self.current_page + 1
		})
	end
end

function prev_subject(self)
	if self.current_page > 1 then
		dispatcher.dispatch(h_set_page_casefile, {
			next = false,
			page = self.current_page - 1
		})
	end
end

function update_prevnext_disabled(self)
	self.prev_button:set_enabled(self.is_shown and self.current_page ~= 1)
	self.next_button:set_enabled(self.is_shown and self.current_page ~= store.casefile_count)
end

function configure_zoom_bounds(self)
	local scale = self.panel.target_scale
	local half_width = Layout.viewport_width * 0.5 / scale
	local half_height = Layout.viewport_height * 0.5 / scale
	self.zoom_pan.viewport = {
		right = half_width,
		left = -half_width,
		top = half_height,
		bottom = -half_height
	}
end

local function update_zoom_button(self)
	local enabled = self.is_shown and (large_ui.enabled or self.zoomed)

	self.zoom_button:set_enabled(enabled)
	self.lb_key_prompt:set_enabled(enabled)
	self.rb_key_prompt:set_enabled(enabled)
end

function on_panel_state(self, new_state, old_state)
	local is_shown = new_state == FullScreenPanel.OPEN
	local was_shown = nil

	if old_state ~= FullScreenPanel.INVALID then
		was_shown = old_state == FullScreenPanel.OPEN
	end

	if is_shown ~= was_shown then
		self.is_shown = is_shown

		self.quit_button:set_enabled(is_shown)
		update_prevnext_disabled(self)

		local page_image = self.pages[page_index_to_name(self.current_page)]

		if not page_image then
			return
		end

		gui.cancel_animation(page_image, h_colorw)

		if is_shown then
			self.shown_page = self.current_page

			gui.set_enabled(page_image, true)
			gui.animate(page_image, h_colorw, 1, gui.EASING_LINEAR, 0.1)
		else
			local color = gui.get_color(page_image)
			color.w = 0

			gui.set_color(page_image, color)
			gui.set_enabled(page_image, false)

			self.shown_page = nil
		end

		if is_shown and large_ui.enabled and save_file.config.zoomed_casefile then
			set_zoom(self, true)
		else
			set_zoom(self, false, nil, nil, 0)
		end

		update_zoom_button(self)
	end

	local open_or_opening = new_state == FullScreenPanel.OPEN or new_state == FullScreenPanel.ANIMATING_TO_OPEN
	local prompt = self.toggle_key_prompt
	local layer = open_or_opening and h_below or h_above

	gui.set_layer(prompt.node, layer)
	gui.set_layer(prompt.halo, layer)

	for node, v in pairs(prompt.halo_clones) do
		gui.set_layer(node, layer)
	end

	dispatcher.dispatch(new_state == FullScreenPanel.CLOSED and h_level_highlight_show or h_level_highlight_hide, {
		object = h_casefile
	})

	if new_state == FullScreenPanel.ANIMATING_TO_MIDWAY then
		local sfx = old_state < new_state and "casefile_open_hover" or "casefile_close_hover"

		dispatcher.dispatch(h_play_sfx, {
			sfx = sfx
		})
	elseif new_state == FullScreenPanel.ANIMATING_TO_OPEN then
		self.current_page = state.phase ~= state.PHASE_INTRO and store.subjects[state.current_subject].casefile_index or 1
		local sfx = old_state < new_state and "casefile_open_full" or "casefile_close_full"

		dispatcher.dispatch(h_play_sfx, {
			sfx = sfx
		})
	end

	dispatcher.dispatch(h_casefile_transition_state, {
		old_state = old_state,
		new_state = new_state
	})
end

function button_quick_disable(button, new_state)
	Button.default_on_state_change(button, new_state)

	local was_disabled = button.state == Button.STATE_DISABLED
	local is_disabled = new_state == Button.STATE_DISABLED

	if was_disabled == is_disabled then
		return
	end

	gui.cancel_animation(button.node, h_colorw)
	gui.animate(button.node, h_colorw, is_disabled and 0 or 1, gui.EASING_LINEAR, 0.0001)
end

function _env:update(dt)
	self.panel:update(dt)
	self.directional.update(dt)
	self.zoom_pan.update(dt)
end

function set_zoom_user(self, zoom_in, origin_x, origin_y)
	save_file.config_set("zoomed_casefile", zoom_in)
	set_zoom(self, zoom_in, origin_x, origin_y)
end

local function viewport_to_panel(self, v)
	local screen_center = vmath.vector3(Layout.viewport_width * 0.5, Layout.viewport_height * 0.5, 0)

	return (v - screen_center) / self.panel.target_scale
end

function set_zoom(self, zoom_in, origin_x, origin_y, duration, callback)
	local zoom_pan = self.zoom_pan

	if zoom_in then
		zoom_pan.set_enabled(true)
	end

	local zoom = zoom_in and 2 or 1
	local position = vmath.vector3()

	if zoom_in then
		if origin_x or origin_y then
			position = viewport_to_panel(self, vmath.vector3(origin_x or 0, origin_y or 0, 0))
			position = zoom_pan.zoom_around(zoom, position)
		else
			position = vmath.vector3(820, -400, 0)
		end
	end

	local function after_zoom()
		if not zoom_in then
			zoom_pan.set_enabled(false)
		end

		if callback then
			callback()
		end
	end

	self.zoomed = zoom_in
	duration = duration or 0.5

	if duration == 0 then
		zoom_pan.set_zoom_pan(zoom, position)
		after_zoom()
	else
		zoom_pan.animate_zoom_pan(zoom, position, duration or 0.5, after_zoom)
	end

	update_zoom_button(self)
	self.directional.reset()
end

on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
	if self.is_shown then
		local g = self.gesture.on_input(action_id, action)

		if g and not self.zoom_pan.animating then
			if not self.zoomed then
				if g.swipe_left then
					next_subject(self)
				elseif g.swipe_right then
					prev_subject(self)
				end
			end

			if large_ui.enabled or self.zoomed then
				if g.double_tap then
					if self.zoomed then
						set_zoom_user(self, false)
					else
						set_zoom_user(self, true, Layout.action_to_viewport(action))
					end
				elseif g.two_finger.pinch then
					if self.panning then
						self.panning = false

						self.zoom_pan.user_pan_end()
					end

					local ratio = g.two_finger.pinch.ratio

					if self.zoomed then
						if ratio <= 0.8 then
							set_zoom_user(self, false)
						end
					elseif ratio >= 1.2 then
						local center = g.two_finger.pinch.center

						set_zoom_user(self, true, Layout.design_to_viewport(center.x, center.y))
					end
				end
			end
		end
	end

	if self.toggle_key_prompt:on_input(action_id, action) then
		return true
	end

	if self.quit_key_prompt:on_input(action_id, action) then
		return true
	end

	if self.zoom_key_prompt:on_input(action_id, action) then
		return true
	end

	if self.lb_key_prompt:on_input(action_id, action) then
		return true
	end

	if self.rb_key_prompt:on_input(action_id, action) then
		return true
	end

	if self.is_shown and action_id then
		if self.zoomed then
			self.directional.on_input(action_id, action)
		else
			local nav_action = Button.action_id_to_navigation_action(action_id)

			if nav_action == Button.NAVIGATE_LEFT and action.pressed then
				prev_subject(self)

				return true
			end

			if nav_action == Button.NAVIGATE_RIGHT and action.pressed then
				next_subject(self)

				return true
			end
		end
	end

	if self.quit_button:on_input(action_id, action) then
		return true
	end

	if self.zoom_button:on_input(action_id, action) then
		return true
	end

	if self.quit_key_button:on_input(action_id, action) then
		return true
	end

	if self.prev_button:on_input(action_id, action) then
		return true
	end

	if self.next_button:on_input(action_id, action) then
		return true
	end

	if self.is_shown and action_id == h_click then
		local dx, dy = nil

		if action.pressed then
			self.panning = true
			dy = 0
			dx = 0
		else
			local scale = self.panel.target_scale
			dx = action.screen_dx / scale
			dy = action.screen_dy / scale
		end

		if self.panning then
			if not self.zoom_pan.animating then
				self.zoom_pan.user_pan(dx, dy)
			end

			if action.released then
				self.panning = false

				self.zoom_pan.user_pan_end()
			end
		end
	end

	if self.panel:on_input(action_id, action) then
		return true
	end
end)

local function set_panel_opened(self, open)
	if self.panning then
		self.panning = false

		self.zoom_pan.user_pan_end()
	end

	if not open and self.zoomed then
		set_zoom(self, false, nil, nil, 0.2, function ()
			self.panel:set_opened(false)
		end)
	else
		self.panel:set_opened(open)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_table_set_position then
		self.panel:set_position(get_panel_position())
	else
		if message_id == h_set_page_casefile then
			local old_page = self.shown_page
			local new_page = message.page
			self.current_page = new_page

			update_prevnext_disabled(self)

			if not self.is_shown then
				return
			end

			local old_image = old_page and self.pages[page_index_to_name(old_page)]
			local new_image = self.pages[page_index_to_name(new_page)]

			local function activate_new_image()
				if new_image and self.current_page == new_page and self.is_shown then
					self.shown_page = new_page

					gui.set_enabled(new_image, true)
					gui.cancel_animation(new_image, h_colorw)
					gui.animate(new_image, h_colorw, 1, gui.EASING_LINEAR, 0.1)
				end
			end

			if old_image and old_image ~= new_image then
				gui.cancel_animation(old_image, h_colorw)
				gui.animate(old_image, h_colorw, 0, gui.EASING_LINEAR, 0.1, 0, function ()
					gui.set_enabled(old_image, false)

					self.shown_page = nil

					activate_new_image()
				end)
			else
				activate_new_image()
			end

			return
		end

		if message_id == h_drawer_casefile_set_open then
			local is_opening = message.value
			local delay = is_opening == false and 0.7 or 0

			timer.delay(delay, false, function ()
				self.toggle_key_prompt:set_enabled(not is_opening, 0.1)
			end)
			set_panel_opened(self, is_opening)
			self.quit_key_button:set_enabled(is_opening)
		elseif message_id == h_go_on_record then
			if message.value then
				set_panel_opened(self, false)
			end
		elseif message_id == h_level_casefile_init then
			if message.position then
				self.panel:set_position(message.position)
			end

			if message.no_background then
				self.panel.background = nil
			end

			if not message.no_casefile_auto_open then
				dispatcher.dispatch(h_drawer_casefile_will_autoopen)
				timer.delay(0, false, function ()
					local delay = message.auto_open_delay or 1.7

					timer.delay(delay, false, function ()
						dispatcher.dispatch(h_drawer_casefile_request_open, {
							value = true
						})
					end)
				end)
			end
		elseif message_id == h_show_subject then
			local subject = store.subjects[message.subject_id]

			init_page(self, subject.avatar, subject.room_index)
		elseif message_id == h_window_change_size then
			self.panel:place()
			configure_zoom_bounds(self)
			update_zoom_button(self)
		elseif message_id == h_game_over then
			self.panel:set_enabled(false)
			set_panel_opened(self, false)
			self.toggle_key_prompt:set_enabled(false)
		elseif message_id == h_switch_input_method then
			self.toggle_key_prompt:switch_input_method()
			self.quit_key_prompt:switch_input_method()
			self.zoom_key_prompt:switch_input_method()
			self.lb_key_prompt:switch_input_method()
			self.rb_key_prompt:switch_input_method()
			self.panel:switch_input_method()
			self.quit_button:switch_input_method()
			self.quit_key_button:switch_input_method()
			self.next_button:switch_input_method()
			self.prev_button:switch_input_method()
			self.zoom_button:switch_input_method()
		elseif message_id == h_level_highlight_set_enabled then
			if message.object_id == h_casefile then
				local color = gui.get_color(self.panel.node)
				color.w = message.enabled and 0 or 1

				gui.set_color(self.panel.node, color)
			end
		elseif message_id == h_light_flicker_animate then
			local node = self.panel.node
			local color = message.object_tint

			gui.cancel_animation(node, h_color)
			gui.animate(node, h_color, color, gui.EASING_LINEAR, message.duration, message.delay)
		elseif message_id == h_level_disable_controls then
			self.toggle_key_prompt:set_enabled(false)
		elseif message_id == h_level_enable_controls then
			self.toggle_key_prompt:set_enabled(true)
		end
	end
end
