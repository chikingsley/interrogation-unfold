local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local press_release = require("press_release.press_release")
local input_state = require("crit.input_state")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local sys_config = require("lib.sys_config")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_tooltip_update = hash("tooltip_update")
local h_tooltips_hide_all = hash("tooltips_hide_all")
local h_switch_input_method = hash("switch_input_method")
local h_press_release_save = hash("press_release_save")
local h_press_release_option = hash("press_release_option")
local h_pause = hash("pause")
local input_graphics = {
	gamepad = "<img=press_release:prompt_a/> <color=#00000000>.</color>"
}

function _env:init()
	self.tooltip = Tooltip.new("tooltip", "text", {
		large_ui_scale = true,
		rich_fonts = families
	})
	self.sub_id = dispatcher.subscribe({
		h_tooltip_hide,
		h_tooltip_show,
		h_tooltip_update,
		h_tooltips_hide_all,
		h_switch_input_method
	})
	self.additional_tooltip_ids = {}
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_tooltip_show then
		local type = message.type

		if type == h_press_release_save then
			local text = intl("press_release.tooltip.commit_enabled")

			if not press_release.are_all_options_set() then
				text = intl("press_release.tooltip.commit_disabled")
			end

			self.tooltip:show_tooltip(message, text)
		elseif type == h_press_release_option then
			local text = nil

			if input_state.input_method == input_state.INPUT_METHOD_GAMEPAD then
				text = intl("press_release.tooltip.cycle_options", {
					input_graphic = input_graphics.gamepad
				})
			elseif sys_config.is_mobile then
				text = intl("press_release.tooltip.cycle_options_touch")
			else
				text = intl("press_release.tooltip.cycle_options_mouse")
			end

			self.tooltip:show_tooltip(message, text, true)
		elseif type == h_pause then
			self.tooltip:show_tooltip(message, intl("level.pause.tooltip"))
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
	elseif message_id == h_tooltip_update then
		self.tooltip:update_position(message)
	elseif message_id == h_switch_input_method then
		self.tooltip:hide_all()
	elseif message_id == h_tooltips_hide_all then
		self.tooltip:hide_all()
	end
end
