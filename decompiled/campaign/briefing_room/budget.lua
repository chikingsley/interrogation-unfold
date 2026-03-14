local budget = require("campaign.budget")
local Button = require("crit.button")
local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local button_sound = require("sound.button")
local FocusGiver = require("crit.focus_giver")
local intl = require("crit.intl")
local h_budget_update = hash("budget_update")
local h_play_animation = hash("play_animation")
local h_switch_input_method = hash("switch_input_method")
local h_missions_gain_focus = hash("missions_gain_focus")
local h_budget_gain_focus = hash("budget_gain_focus")
local h_save_prompt_enable = hash("save_prompt_enable")
local h_save_prompt_disable = hash("save_prompt_disable")
local h_play_sfx = hash("play_sfx")
local h_label = hash("label")
local h_cost = hash("cost")
local h_label_cost = hash("label_cost")
local h_number = hash("number")
local h_label_no = hash("label_no")
local h_checkbox = hash("checkbox")
local h_budget = hash("budget")
local h_color = hash("color")
local h_position = hash("position")
local h_budget_set_focus_enabled = hash("budget_set_focus_enabled")
local option_height = 52
local max_first_page_options = 5
local color_red = vmath.vector4(1, 0, 0, 1)
local color_black = vmath.vector4(0, 0, 0, 1)

local function set_remaining_budget(amount)
	local text = amount < 0 and "-$" .. -amount or "$" .. amount

	label.set_text(msg.url("budget#amount"), text)
end

local function play_checkbox_sfx(checked)
	dispatcher.dispatch(h_play_sfx, {
		sfx = "checkmark",
		parameters = {
			IsEx = 1,
			IsCheck = checked and 1 or 0
		}
	})
end

local function update_budget_total(self)
	local budget_remaining = budget.capacity - budget.get_total_cost()
	local funds_url = msg.url("budget#funds")
	local total_amount_url = msg.url("budget#amount")

	if budget_remaining < 0 then
		go.set(funds_url, h_color, color_red)
		go.set(total_amount_url, h_color, color_red)
	else
		go.set(funds_url, h_color, color_black)
		go.set(total_amount_url, h_color, color_black)
	end

	dispatcher.dispatch(h_budget_update, {
		budget = budget_remaining
	})
	set_remaining_budget(budget_remaining)
end

local function set_checkbox_state(self, option, checked)
	local option_url = self.budget_option_urls[option.id]
	local checkbox_url = msg.url(option_url.socket, option_url.path, h_checkbox)
	local animation = checked and hash("tickbox_tick") or hash("tickbox")

	msg.post(checkbox_url, h_play_animation, {
		id = animation
	})
end

local function toggle_checkbox_state(self, option)
	local checked = budget.toggle_selected(option.id)

	set_checkbox_state(self, option, checked)
	play_checkbox_sfx(checked)
	update_budget_total(self)
end

function _env:init()
	self.budget_option_urls = {}
	self.labels = {}
	self.buttons = {}

	intl.translate_label("#funds", "budget.title")
	intl.translate_label("#header", "budget.header")

	local container = go.get_id()
	local container_pos = go.get_position(container)
	local page1_id = go.get_id("page1")
	local page2_id = go.get_id("page2")
	local page1_pos = go.get_position(page1_id)
	local page2_pos = go.get_position(page2_id)
	local options_factory = msg.url("budget#options_factory")
	local spans_two_pages = false
	local pos_x = container_pos.x + page1_pos.x
	local pos_y = container_pos.y + page1_pos.y
	self.hover_paper_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Paper")

	for i, option in ipairs(budget.options) do
		local option_id = factory.create(options_factory)
		local option_url = msg.url(option_id)
		local label_url = msg.url(option_url.socket, option_url.path, h_label)
		local number_url = msg.url(option_url.socket, option_url.path, h_number)
		local number_label_url = msg.url(option_url.socket, option_url.path, h_label_no)
		local checkbox_url = msg.url(option_url.socket, option_url.path, h_checkbox)
		local cost_url = msg.url(option_url.socket, option_url.path, h_cost)
		local cost_label_url = msg.url(option_url.socket, option_url.path, h_label_cost)

		intl.translate_label(number_label_url, "budget.no")
		intl.translate_label(cost_label_url, "budget.cost")
		label.set_text(cost_url, "$" .. option.cost)
		label.set_text(label_url, budget.translate_option_text(option, "title"))
		label.set_text(number_url, i)

		if not spans_two_pages and max_first_page_options < i then
			spans_two_pages = true
			pos_x = container_pos.x + page2_pos.x
			pos_y = container_pos.y + page2_pos.y
		end

		local pos_z = container_pos.z + 0.05
		local position = vmath.vector3(pos_x, pos_y, pos_z)

		go.set(option_url, h_position, position)

		pos_y = pos_y - option_height
		self.buttons[i] = Button.new(checkbox_url, {
			focus_simulates_hover = true,
			padding_left = -20,
			gamepad_focus = true,
			padding_top = 1,
			padding_right = 340,
			is_sprite = true,
			keyboard_focus = true,
			padding_bottom = 1,
			keep_hover = true,
			action = function ()
				toggle_checkbox_state(self, option)
			end,
			faded_labels = {
				label_url,
				number_url,
				number_label_url,
				cost_url,
				cost_label_url
			},
			on_pass_focus = function (button, nav_action)
				if nav_action == Button.NAVIGATE_RIGHT then
					dispatcher.dispatch(h_missions_gain_focus, {
						position = go.get_world_position(label_url),
						nav_action = nav_action
					})

					return true
				elseif nav_action == Button.NAVIGATE_UP and i > 1 then
					return self.buttons[i - 1]:focus()
				elseif nav_action == Button.NAVIGATE_DOWN and i < #self.buttons then
					return self.buttons[i + 1]:focus()
				end
			end,
			on_state_change = button_sound.with_sound({
				press = false,
				release = false,
				hover = self.hover_paper_event
			}, Tooltip.button_on_state_change({
				id = "budget_" .. i,
				type = h_budget,
				payload = {
					budget_option_index = i
				}
			}))
		})
		self.budget_option_urls[option.id] = option_url

		set_checkbox_state(self, option, budget.is_selected(option.id))
	end

	self.focus_giver = FocusGiver.new({
		on_pass_focus = function (focus_giver, nav_action)
			if self.save_prompt_active then
				return false
			end

			if not nav_action or nav_action == Button.NAVIGATE_DOWN or nav_action == Button.NAVIGATE_RIGHT then
				return self.buttons[1]:focus()
			elseif nav_action == Button.NAVIGATE_UP then
				return self.buttons[#self.buttons]:focus()
			elseif nav_action == Button.NAVIGATE_LEFT then
				dispatcher.dispatch(h_missions_gain_focus, {
					nav_action = nav_action
				})

				return true
			end
		end
	})

	self.focus_giver:try_focus_first()
	update_budget_total(self)

	self.sub_id = dispatcher.subscribe({
		h_switch_input_method,
		h_budget_gain_focus,
		h_budget_set_focus_enabled,
		h_save_prompt_enable,
		h_save_prompt_disable
	})

	msg.post(".", "acquire_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		for i, button in ipairs(self.buttons) do
			button:switch_input_method()
		end

		self.focus_giver:try_focus_first(message.nav_action)
	elseif message_id == h_budget_gain_focus then
		self.buttons[1]:focus()
	elseif message_id == h_save_prompt_enable then
		self.save_prompt_active = true

		for i, button in ipairs(self.buttons) do
			button:cancel_focus()
		end
	elseif message_id == h_save_prompt_disable then
		self.save_prompt_active = false

		self.focus_giver:try_focus_first()
	elseif message_id == h_budget_set_focus_enabled then
		self.focus_giver:set_enabled(message.enabled)
	end
end

function _env:on_input(action_id, action)
	if self.focus_giver:on_input(action_id, action) then
		return true
	end

	for i, button in ipairs(self.buttons) do
		if button:on_input(action_id, action) then
			return true
		end
	end
end

function _env:final()
	for i, button in ipairs(self.buttons) do
		button:cancel_focus()
	end

	dispatcher.unsubscribe(self.sub_id)
	msg.post(".", "release_input_focus")
end
