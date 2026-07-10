local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local agents = require("campaign.agents")
local button_sound = require("sound.button")
local variables = require("campaign.variables")
local analog_to_digital = require("crit.analog_to_digital")
local intl = require("crit.intl")
local sprites = require("campaign.office.sprites")
local gesture = require("in.gesture")
local KeyPrompt = require("lib.key_prompt")
local large_ui = require("lib.large_ui")
local h_sprite = hash("sprite")
local h_label = hash("label")
local h_tab_mask_open = hash("tab_mask_open")
local h_tab_mask_close = hash("tab_mask_close")
local h_paperclip = hash("paperclip")
local h_position_x = hash("position.x")
local h_position_y = hash("position.y")
local h_tintw = hash("tint.w")
local h_tint = hash("tint")
local h_color = hash("color")
local h_colorw = hash("color.w")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_object_deselected = hash("office_object_deselected")
local h_office_object_selected = hash("office_object_selected")
local h_play_sfx = hash("play_sfx")
local h_disable = hash("disable")
local h_enable = hash("enable")
local h_gamepad_rshoulder = hash("gamepad_rshoulder")
local h_gamepad_lshoulder = hash("gamepad_lshoulder")
local h_gamepad_rpad_left = hash("gamepad_rpad_left")
local h_set_parent = hash("set_parent")
local h_click = hash("click")
local h_hr_report_set_enabled = hash("hr_report_set_enabled")
local h_office_object_set_zoom = hash("office_object_set_zoom")
local h_switch_input_method = hash("switch_input_method")
local h_window_change_size = hash("window_change_size")
local tab_spacing = 170
local default_tab_tint = vmath.vector4(0.5, 0.5, 0.5, 1)
local hover_tab_tint = vmath.vector4(1, 1, 1, 1)
local selected_tab_tint = vmath.vector4(1, 1, 1, 1)
local default_label_color = vmath.vector4(0.1, 0.1, 0.1, 1)
local selected_label_color = vmath.vector4(0.1, 0.1, 0.1, 1)
local ignored_zoom_action_ids = {
	[hash("gamepad_lstick_digital_up")] = true,
	[hash("gamepad_lstick_digital_down")] = true,
	[hash("gamepad_lstick_digital_left")] = true,
	[hash("gamepad_lstick_digital_right")] = true
}
local layout_labels = {
	"age",
	"badge",
	"complexion",
	"education",
	"eye",
	"height",
	"name",
	"rank",
	"special_agent",
	"status",
	"weight"
}
local set_page, enable_hr_report, disable_hr_report, disable_profile_page, enable_profile_page, tab_on_state_change, reset_tab_positions = nil

local function has_access(char)
	local agent = agents[char]

	if not agent then
		return false
	end

	local conditions_met = agent.has_classified

	return not not conditions_met
end

local function has_classified(char)
	return char ~= "hr_report" and char ~= "joseph"
end

function tab_on_state_change(self, button, state, node)
	local default_pos = 0
	local displacement = 10
	local duration = 0.1
	local pos = default_pos
	local tint = default_tab_tint
	local label_color = default_label_color

	if state == Button.STATE_PRESSED then
		pos = displacement
		tint = default_tab_tint
		label_color = selected_label_color
	elseif state == Button.STATE_HOVER then
		pos = displacement
		tint = hover_tab_tint
		label_color = selected_label_color
	elseif state == Button.STATE_DISABLED then
		pos = default_pos
		tint = default_tab_tint
	end

	local is_selected_tab = self.selected_page and msg.url(go.get_id("tab_" .. self.selected_page)) == node

	if is_selected_tab then
		pos = displacement
		label_color = selected_label_color
		tint = selected_tab_tint
	end

	local label = msg.url(node.socket, node.path, h_label)

	if not is_selected_tab then
		go.cancel_animations(node, h_position_x)
	end

	go.cancel_animations(label, h_colorw)
	go.cancel_animations(button.node, h_tint)
	go.animate(node, h_position_x, go.PLAYBACK_ONCE_FORWARD, pos, go.EASING_INOUTQUAD, duration, 0, function ()
		if is_selected_tab then
			go.animate(node, h_position_x, go.PLAYBACK_LOOP_PINGPONG, pos + 7, go.EASING_LINEAR, 0.7)
		end
	end)
	go.animate(label, h_color, go.PLAYBACK_ONCE_FORWARD, label_color, go.EASING_LINEAR, duration)
	go.animate(button.node, h_tint, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_INOUTQUAD, duration * 2)
end

function _env:init()
	self.has_hr_report = not not variables.has_hr_report
	self.selected_page = nil
	self.pending_page = nil
	self.pending_classified = false
	self.is_selected = false
	self.selected_classified = false
	self.other_object_selected = false
	self.active_pages = {}
	local folder_id = go.get_id("folder")
	local folder_url = msg.url(folder_id)
	local layout_id = go.get_id("layout")
	self.layout_url = msg.url(layout_id)
	self.paperclip = msg.url(folder_url.socket, folder_url.path, h_paperclip)

	msg.post(self.paperclip, h_disable)

	local hr_notice_id = go.get_id("hr_notice")
	local hr_tab_id = go.get_id("tab_hr_report")
	local tabs_go = go.get_id("tabs")
	local tabs_url = msg.url(tabs_go)
	self.tab_mask_open = msg.url(tabs_url.socket, tabs_url.path, h_tab_mask_open)
	self.tab_mask_close = msg.url(tabs_url.socket, tabs_url.path, h_tab_mask_close)

	msg.post(self.tab_mask_open, h_disable)
	msg.post(self.layout_url, h_disable)

	self.hr_notice_url = msg.url(hr_notice_id)
	self.hr_tab_url = msg.url(hr_tab_id)
	local agent_tabs_container = go.get_id("tabs_agents")
	local agent_tabs_container_url = msg.url(agent_tabs_container)

	for i, label_name in ipairs(layout_labels) do
		intl.translate_label(msg.url(nil, layout_id, label_name), "agent_files.label." .. label_name)
	end

	sprite.play_flipbook(msg.url(nil, layout_id, "title"), intl.select(sprites.agent_file_title))
	sprite.play_flipbook(msg.url(nil, layout_id, "subtitle"), intl.select(sprites.agent_file_subtitle))

	self.hover_paper_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Paper")

	if self.has_hr_report then
		go.set(agent_tabs_container_url, h_position_y, -tab_spacing)
		collectionfactory.create("hr_report_factory#collectionfactory", vmath.vector3(0), vmath.quat(), {
			[hash("/hr_report")] = {
				parent = msg.url(".")
			}
		}, vmath.vector3(1))
		table.insert(self.active_pages, "hr_report")

		local hr_button_sprite_url = msg.url(self.hr_tab_url.socket, self.hr_tab_url.path, h_sprite)
		local hr_button_label_url = msg.url(self.hr_tab_url.socket, self.hr_tab_url.path, h_label)

		go.set(hr_button_sprite_url, h_tint, default_tab_tint)
		go.set(hr_button_label_url, h_color, default_label_color)

		self.hr_tab_button = Button.new(hr_button_sprite_url, {
			is_sprite = true,
			padding_top = -32,
			keep_hover = true,
			padding_bottom = -32,
			action = function (button, state)
				set_page(self, "hr_report")
			end,
			on_state_change = button_sound.with_sound({
				press = false,
				release = false,
				hover = self.hover_paper_event
			}, function (button, state)
				tab_on_state_change(self, button, state, self.hr_tab_url)
			end)
		})
	else
		msg.post(self.hr_tab_url, h_disable)
		msg.post(self.hr_notice_url, h_disable)
	end

	self.tab_buttons = {}
	self.hr_notice_sprite = msg.url(self.hr_notice_url.socket, self.hr_notice_url.path, h_sprite)
	local hr_notice_label = msg.url(self.hr_notice_url.socket, self.hr_notice_url.path, h_label)

	if variables.classified_unlocked then
		label.set_text(hr_notice_label, intl("agent_files.postit.declassified"))
	else
		label.set_text(hr_notice_label, intl("agent_files.postit.ready"))
	end

	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect,
		h_office_object_selected,
		h_office_object_deselected,
		h_office_object_set_zoom,
		h_switch_input_method,
		h_window_change_size
	})

	local function toggle_classified()
		set_page(self, self.selected_page, not self.selected_classified)
	end

	self.next_button = Button.new(msg.url("next_button#sprite"), {
		is_sprite = true,
		keep_hover = true,
		on_state_change = button_sound.with_sound({
			release = false,
			press = false
		}),
		shortcut_actions = {
			h_gamepad_rpad_left
		},
		faded_nodes = {
			msg.url("next_button#label")
		},
		action = toggle_classified
	})

	self.next_button:set_enabled(false)

	self.next_button_go = msg.url("next_button")

	msg.post(self.next_button_go, h_disable)

	self.prev_button = Button.new(msg.url("prev_button#sprite"), {
		is_sprite = true,
		keep_hover = true,
		on_state_change = button_sound.with_sound({
			release = false,
			press = false
		}),
		shortcut_actions = {
			h_gamepad_rpad_left
		},
		faded_nodes = {
			msg.url("prev_button#label")
		},
		action = toggle_classified
	})

	self.prev_button:set_enabled(false)

	self.prev_button_go = msg.url("prev_button")

	msg.post(self.prev_button_go, h_disable)

	local function make_prompt(node, options)
		local prompt = KeyPrompt.new(node, options)

		prompt:set_enabled(false)

		return prompt
	end

	self.next_prompt = make_prompt(msg.url("next_button#prompt"), {
		is_sprite = true,
		halo = msg.url("next_button#prompt_halo"),
		action_id = h_gamepad_rpad_left
	})
	self.prev_prompt = make_prompt(msg.url("prev_button#prompt"), {
		is_sprite = true,
		halo = msg.url("prev_button#prompt_halo"),
		action_id = h_gamepad_rpad_left
	})
	self.tab_next_prompt = make_prompt(msg.url("tab_prompt_r#prompt"), {
		is_sprite = true,
		halo = msg.url("tab_prompt_r#prompt_halo"),
		action_id = h_gamepad_rshoulder
	})
	self.tab_prev_prompt = make_prompt(msg.url("tab_prompt_l#prompt"), {
		is_sprite = true,
		halo = msg.url("tab_prompt_l#prompt_halo"),
		action_id = h_gamepad_lshoulder
	})
	self.gesture = gesture.create({
		action_id = h_click
	})
	local agent_pages = {
		page1 = {},
		page2 = {},
		page3 = {},
		page3_classified = {}
	}
	self.agent_pages = agent_pages
	local factory_lang = intl.select({
		en = hash("en")
	})
	local page_left_id = go.get_id("page_left")
	local page_left = collectionfactory.create(msg.url(nil, page_left_id, factory_lang), vmath.vector3(), vmath.quat(), nil, 1)

	for key, go_id in pairs(page_left) do
		msg.post(go_id, h_set_parent, {
			keep_world_transform = 0,
			parent_id = page_left_id
		})
	end

	local page_right_id = go.get_id("page_right")
	local page_right = collectionfactory.create(msg.url(nil, page_right_id, factory_lang), vmath.vector3(), vmath.quat(), nil, 1)

	for key, go_id in pairs(page_right) do
		msg.post(go_id, h_set_parent, {
			keep_world_transform = 0,
			parent_id = page_right_id
		})
	end

	for i, agent in ipairs(agents) do
		agent_pages.page1[agent] = page_left[hash("/" .. agent .. "_page1")]
		agent_pages.page2[agent] = page_right[hash("/" .. agent .. "_page2")]
		agent_pages.page3[agent] = page_right[hash("/" .. agent .. "_page3")]
		agent_pages.page3_classified[agent] = page_right[hash("/" .. agent .. "_page3_classified")]

		msg.post(agent_pages.page1[agent], h_disable)
		msg.post(agent_pages.page2[agent], h_disable)
		msg.post(agent_pages.page3[agent], h_disable)
		msg.post(agent_pages.page3_classified[agent], h_disable)

		local agent_tab_url = msg.url("tab_" .. agent)

		msg.post(agent_tab_url, h_disable)

		if agents[agent].present then
			local agent_tab_sprite_url = msg.url(agent_tab_url.socket, agent_tab_url.path, h_sprite)
			local agent_tab_label_url = msg.url(agent_tab_url.socket, agent_tab_url.path, h_label)

			msg.post(agent_tab_url, h_enable)
			go.set(agent_tab_sprite_url, h_tint, default_tab_tint)
			go.set(agent_tab_label_url, h_color, default_label_color)
			table.insert(self.active_pages, agent)

			self.tab_buttons[agent] = Button.new(agent_tab_sprite_url, {
				is_sprite = true,
				padding_top = -32,
				keep_hover = true,
				padding_bottom = -32,
				action = function (button, state)
					set_page(self, agent)
				end,
				on_state_change = button_sound.with_sound({
					press = false,
					release = false,
					hover = self.hover_paper_event
				}, function (button, state)
					tab_on_state_change(self, button, state, agent_tab_url)
				end)
			})
		end
	end
end

local function update_prompts(self)
	local selected = not not self.selected_page
	local enabled = selected and (large_ui.enabled or self.zoomed)
	local anim_duration = not selected and 0 or nil

	self.prev_prompt:set_enabled(enabled and self.prev_button.state ~= Button.STATE_DISABLED, anim_duration)
	self.next_prompt:set_enabled(enabled and self.next_button.state ~= Button.STATE_DISABLED, anim_duration)
	self.tab_prev_prompt:set_enabled(enabled, anim_duration)
	self.tab_next_prompt:set_enabled(enabled, anim_duration)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if message.object_id == self.object_id then
			if self.has_hr_report then
				go.animate(self.hr_notice_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 0.1, 0, function ()
					msg.post(self.hr_notice_url, h_disable)
				end)
			end

			msg.post(self.tab_mask_close, h_disable)
		else
			self.other_object_selected = true

			for i, button in pairs(self.tab_buttons) do
				button:cancel_touch()
			end
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == self.object_id and self.selected_page then
			set_page(self, nil)
			msg.post(self.layout_url, h_disable)
			msg.post(self.tab_mask_open, h_disable)
			msg.post(self.paperclip, h_disable)
		end
	elseif message_id == h_office_object_selected then
		if message.object_id == self.object_id then
			self.is_selected = true

			update_prompts(self)

			local pending_page = self.pending_page

			if pending_page then
				set_page(self, pending_page, self.pending_classified, true)
			elseif self.has_hr_report then
				set_page(self, "hr_report", false, true)
			else
				set_page(self, agents[1], false, true)
			end

			msg.post(self.tab_mask_open, h_enable)

			if self.has_hr_report then
				msg.post(self.paperclip, h_enable)
			end
		end
	elseif message_id == h_office_object_deselected then
		if message.object_id == self.object_id then
			self.is_selected = false
			self.zoomed = false

			update_prompts(self)

			if self.has_hr_report then
				msg.post(self.hr_notice_url, h_enable)
				go.animate(self.hr_notice_sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.1)
			end

			msg.post(self.tab_mask_close, h_enable)
		else
			self.other_object_selected = false
		end
	elseif message_id == h_office_object_set_zoom then
		if message.object_id == self.object_id then
			self.zoomed = message.value

			update_prompts(self)
		end
	elseif message_id == h_switch_input_method then
		self.prev_prompt:switch_input_method()
		self.next_prompt:switch_input_method()
		self.tab_prev_prompt:switch_input_method()
		self.tab_next_prompt:switch_input_method()
		self.next_button:switch_input_method()
		self.prev_button:switch_input_method()

		for _, button in pairs(self.tab_buttons) do
			button:switch_input_method()
		end
	elseif message_id == h_window_change_size then
		update_prompts(self)
	end
end

local function gamepad_navigation(self, action_id, action, nav_action)
	if not action_id and not nav_action then
		return false
	end

	if self.zoomed and ignored_zoom_action_ids[action_id] then
		return false
	end

	nav_action = nav_action or Button.action_id_to_navigation_action(action_id)

	if not nav_action then
		if action_id == h_gamepad_rshoulder then
			nav_action = Button.NAVIGATE_DOWN
		elseif action_id == h_gamepad_lshoulder then
			nav_action = Button.NAVIGATE_UP
		end
	end

	if nav_action then
		local current_page = self.selected_page
		local pages = self.active_pages
		local current_page_index = nil

		for i, page in ipairs(pages) do
			if current_page == page then
				current_page_index = i
			end
		end

		if current_page_index then
			local next_page = pages[current_page_index + 1]
			local previous_page = pages[current_page_index - 1]

			if nav_action == Button.NAVIGATE_DOWN and next_page then
				set_page(self, next_page)
			elseif nav_action == Button.NAVIGATE_UP and previous_page then
				set_page(self, previous_page)
			elseif nav_action == Button.NAVIGATE_RIGHT then
				if not self.selected_classified and has_classified(current_page) then
					set_page(self, current_page, true)

					return true
				end

				if next_page then
					set_page(self, next_page)

					return true
				end
			elseif nav_action == Button.NAVIGATE_LEFT then
				if self.selected_classified then
					set_page(self, current_page, false)

					return true
				end

				if previous_page then
					set_page(self, previous_page, has_classified(previous_page))

					return true
				end
			end
		end
	end

	return false
end

on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
	if self.is_selected and not self.zoomed then
		local g = self.gesture.on_input(action_id, action)

		if g then
			if g.swipe_left then
				gamepad_navigation(self, nil, nil, Button.NAVIGATE_RIGHT)
			elseif g.swipe_right then
				gamepad_navigation(self, nil, nil, Button.NAVIGATE_LEFT)
			end
		end
	end

	self.prev_prompt:on_input(action_id, action)
	self.next_prompt:on_input(action_id, action)
	self.tab_prev_prompt:on_input(action_id, action)
	self.tab_next_prompt:on_input(action_id, action)

	if self.is_selected and (action.pressed or action.repeated) and gamepad_navigation(self, action_id, action) then
		return true
	end

	if self.has_hr_report and self.hr_tab_button:on_input(action_id, action) then
		return true
	end

	if not self.other_object_selected then
		for i, button in pairs(self.tab_buttons) do
			if button:on_input(action_id, action) then
				return true
			end
		end
	end

	if self.next_button:on_input(action_id, action) then
		return true
	end

	if self.prev_button:on_input(action_id, action) then
		return true
	end
end)

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function set_page(self, page, classified, no_sfx)
	classified = not not classified

	if not self.is_selected then
		self.pending_page = page
		self.pending_classified = classified

		return
	end

	if classified and has_classified(page) and has_access(page) then
		variables[page .. "_declassified"] = true
	end

	local old_page = self.selected_page
	local old_classified = self.selected_classified

	if old_page == page and old_classified == classified then
		return
	end

	self.selected_page = page
	self.selected_classified = classified

	if old_page then
		if old_page == "hr_report" then
			disable_hr_report(self)
		else
			disable_profile_page(self, old_page)
		end
	end

	if page then
		if not no_sfx then
			local forwards = math.random(2) - 1

			if old_page == page then
				if classified then
					forwards = 1
				else
					forwards = 0
				end
			end

			dispatcher.dispatch(h_play_sfx, {
				sfx = "papers",
				parameters = {
					IsPickedUp = forwards
				}
			})
		end

		if page == "hr_report" then
			enable_hr_report(self)
		else
			enable_profile_page(self, page, classified)
		end
	end

	reset_tab_positions(self)
end

function enable_hr_report(self)
	msg.post(self.layout_url, h_disable)
	dispatcher.dispatch(h_hr_report_set_enabled, {
		enabled = true
	})
end

function disable_hr_report(self)
	dispatcher.dispatch(h_hr_report_set_enabled, {
		enabled = false
	})
end

function disable_profile_page(self, page)
	local agent_pages = self.agent_pages

	msg.post(agent_pages.page1[page], h_disable)
	msg.post(agent_pages.page2[page], h_disable)
	msg.post(agent_pages.page3[page], h_disable)
	msg.post(agent_pages.page3_classified[page], h_disable)
	self.next_button:set_enabled(false)
	self.prev_button:set_enabled(false)
	msg.post(self.next_button_go, h_disable)
	msg.post(self.prev_button_go, h_disable)
	update_prompts(self)
end

function enable_profile_page(self, page, classified)
	local agent_pages = self.agent_pages

	msg.post(self.layout_url, h_enable)
	msg.post(agent_pages.page1[page], h_enable)

	if classified then
		msg.post(agent_pages.page2[page], h_disable)
		msg.post(agent_pages[has_access(page) and "page3" or "page3_classified"][page], h_enable)
		msg.post(self.next_button_go, h_disable)
		msg.post(self.prev_button_go, h_enable)
		self.next_button:set_enabled(false)
		self.prev_button:set_enabled(true)
	else
		msg.post(agent_pages.page2[page], h_enable)
		msg.post(agent_pages.page3[page], h_disable)
		msg.post(agent_pages.page3_classified[page], h_disable)
		msg.post(self.next_button_go, has_classified(page) and h_enable or h_disable)
		msg.post(self.prev_button_go, h_disable)
		self.next_button:set_enabled(has_classified(page))
		self.prev_button:set_enabled(false)
	end

	update_prompts(self)
end

function reset_tab_positions(self)
	if self.has_hr_report then
		tab_on_state_change(self, self.hr_tab_button, self.hr_tab_button.state, self.hr_tab_url)
	end

	for i, button in pairs(self.tab_buttons) do
		local node = msg.url(button.node.socket, button.node.path, nil)

		tab_on_state_change(self, button, button.state, node)
	end
end
