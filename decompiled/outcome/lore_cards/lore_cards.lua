local dispatcher = require("crit.dispatcher")
local cutscene_data = require("spine_cutscene.cutscene_final.cutscene_data")
local agents = require("campaign.agents")
local intl = require("crit.intl")
intl = intl.namespace("chapter3")
local h_lore_card_advance = hash("lore_card_advance")
local h_end_scene = hash("end_scene")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_tintw = hash("tint.w")
local h_colorw = hash("color.w")
local h_position = hash("position")
local h_positiony = hash("position.y")
local h_sprite = hash("sprite")
local h_scalex = hash("scale.x")
local h_click = hash("click")
local h_gamepad_rpad_down = hash("gamepad_rpad_down")
local h_key_space = hash("key_space")
local ending = cutscene_data.ending
local progression = {
	"anaba",
	"reed",
	"james",
	"jen",
	"tab",
	"mordecai",
	"joseph",
	"chief",
	"tristan",
	"eddie"
}

local function find_in_table(t, el)
	for i, value in ipairs(t) do
		if value == el then
			return i
		end
	end
end

if not agents.joseph.present then
	table.remove(progression, find_in_table(progression, "joseph"))
end

if ending ~= cutscene_data.endings.MARXIST then
	table.remove(progression, find_in_table(progression, "anaba"))
end

if ending ~= cutscene_data.endings.ANCAP then
	table.remove(progression, find_in_table(progression, "reed"))
end

if ending ~= cutscene_data.endings.APOCALYPTIC then
	table.remove(progression, find_in_table(progression, "james"))
end

local endings = {
	[cutscene_data.endings.GOOD] = "good",
	[cutscene_data.endings.VIGILANTE] = "vigilante",
	[cutscene_data.endings.MARXIST] = "marxist",
	[cutscene_data.endings.ANCAP] = "ancap",
	[cutscene_data.endings.APOCALYPTIC] = "apocalyptic"
}
local advance_padding = 100
local advance_bounce = 10
local advance_out_pos = 20
local advance_bounce_duration = 1
local text_bg_padding = 360
local bot_line_padding = 155
local advance_actions = {
	[h_gamepad_rpad_down] = true,
	[h_key_space] = true,
	[h_click] = true
}
local set_text, set_card, fade_text, show_character = nil

local function advance_to_next_card(self)
	self.current_card_no = self.current_card_no + 1

	if self.current_card_no > #progression then
		if self.auto_advance_timer then
			timer.cancel(self.auto_advance_timer)
		end

		self.sequence_end = true

		dispatcher.dispatch(h_lore_card_advance)
		fade_text(self, false, function ()
			dispatcher.dispatch(h_end_scene)
		end)

		return
	end

	set_card(self, self.current_card_no)
end

function set_text(card_id)
	local title_node = msg.url("text#title")
	local desc_node = msg.url("text#desc")
	local title_text = intl("lore_card." .. card_id .. ".name")
	local desc_text = intl("lore_card." .. card_id .. "." .. endings[ending])

	label.set_text(title_node, title_text)
	label.set_text(desc_node, desc_text)
end

function show_character(self, char_id, post_load_callback)
	local factory_url = msg.url("characters#" .. char_id)

	factory.load(factory_url, function ()
		self.shown_character = factory.create(factory_url)

		go.set_parent(self.shown_character, go.get_id("char_slot"), false)
		factory.unload(factory_url)
		post_load_callback()
	end)
end

function fade_text(self, fade_in, callback)
	local title_node = msg.url("text#title")
	local desc_node = msg.url("text#desc")
	local text_bg = msg.url("text_bg")
	local text_bg_sprite = msg.url("text_bg#sprite")
	local top_line_sprite = msg.url("line_top#sprite")
	local bot_line_sprite = msg.url("line_bot#sprite")
	local once_forward = go.PLAYBACK_ONCE_FORWARD
	local linear = go.EASING_LINEAR
	local duration = self.transition_duration
	local adv_out_delay = 0
	local adv_fade_duration = advance_bounce_duration * 0.5
	local tint = 0

	if fade_in then
		tint = 1
		adv_out_delay = 1
		adv_fade_duration = duration
	end

	go.animate(title_node, h_colorw, once_forward, tint, linear, duration, 0, callback)
	go.animate(desc_node, h_colorw, once_forward, tint, linear, duration)
	go.animate(text_bg_sprite, h_tintw, once_forward, tint, linear, duration)
	go.animate(top_line_sprite, h_tintw, once_forward, tint, linear, duration)
	go.animate(bot_line_sprite, h_tintw, once_forward, tint, linear, duration)
	timer.delay(0, false, function ()
		local advance = self.advance
		local advance_sprite = msg.url(advance.socket, advance.path, h_sprite)
		local bot_line = msg.url("line_bot")
		local desc_metrics = label.get_text_metrics(desc_node)
		local adv_pos = self.advance_original_pos
		local adjusted_pos = vmath.vector3(adv_pos.x, adv_pos.y - desc_metrics.height - advance_padding, adv_pos.z)
		local bounce_pos_y = adjusted_pos.y + advance_bounce
		local out_pos = adjusted_pos.y - advance_out_pos

		go.set(advance, h_position, adjusted_pos)
		go.set(bot_line, h_positiony, -desc_metrics.height - bot_line_padding)
		go.set(text_bg, h_scalex, desc_metrics.height + text_bg_padding)
		go.cancel_animations(advance, h_positiony)

		if fade_in then
			go.animate(advance, h_positiony, go.PLAYBACK_LOOP_PINGPONG, bounce_pos_y, go.EASING_INOUTCUBIC, advance_bounce_duration)
		else
			go.animate(advance, h_positiony, once_forward, out_pos, go.EASING_INCUBIC, adv_fade_duration)
		end

		go.animate(advance_sprite, h_tintw, once_forward, tint, linear, adv_fade_duration, adv_out_delay)
	end)
end

function set_card(self, card_index)
	local card_id = progression[self.current_card_no]

	if self.auto_advance then
		if self.auto_advance_timer then
			timer.cancel(self.auto_advance_timer)

			self.auto_advance_timer = nil
		end

		self.auto_advance_timer = timer.delay(self.auto_advance_interval, false, function ()
			advance_to_next_card(self)
		end)
	end

	self.transition = true

	fade_text(self, false, function ()
		set_text(card_id)
		show_character(self, card_id, function ()
			fade_text(self, true, function ()
				self.transition = false
			end)
		end)
	end)
	dispatcher.dispatch(h_lore_card_advance)
end

function _env:init()
	self.auto_advance_interval = self.auto_advance_interval + self.transition_duration
	self.current_card_no = 1
	local title_node = msg.url("text#title")
	local desc_node = msg.url("text#desc")
	local text_bg_sprite = msg.url("text_bg#sprite")
	local top_line_sprite = msg.url("line_top#sprite")
	local bot_line_sprite = msg.url("line_bot#sprite")

	go.set(text_bg_sprite, h_tintw, 0)
	go.set(bot_line_sprite, h_tintw, 0)
	go.set(top_line_sprite, h_tintw, 0)
	go.set(title_node, h_colorw, 0)
	go.set(desc_node, h_colorw, 0)
	set_card(self, self.current_card_no)

	self.advance = msg.url("advance")
	self.advance_original_pos = go.get(self.advance, h_position)

	go.set(msg.url(self.advance.socket, self.advance.path, h_sprite), h_tintw, 0)
	msg.post(".", h_acquire_input_focus)
end

function _env:on_input(action_id, action)
	if not self.transition and not self.sequence_end and action.pressed and advance_actions[action_id] then
		advance_to_next_card(self)
	end
end
