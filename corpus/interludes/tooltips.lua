local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local selection_state = require("interludes.selection.state")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_pause = hash("pause")
local h_selection_item = hash("selection_item")
local h_hints_notify_start = hash("hints_notify_start")
local h_hints_notify = hash("hints_notify")
local h_twitch = hash("twitch")

function _env:init()
	self.tooltip = Tooltip.new("tooltip", "text", {
		large_ui_scale = true,
		rich_fonts = families
	})
	self.sub_id = dispatcher.subscribe({
		h_tooltip_hide,
		h_tooltip_show
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_tooltip_show then
		local type = message.type

		if type == h_pause then
			self.tooltip:show_tooltip(message, intl("level.pause.tooltip"))
		elseif type == h_selection_item then
			self.tooltip:show_tooltip(message, selection_state.options[message.payload.index].tooltip)
		elseif message.type == h_hints_notify_start then
			local text = intl("level.hints.notify_start")

			self.tooltip:show_tooltip(message, text)
		elseif message.type == h_hints_notify then
			local text = intl("level.hints.notify")

			self.tooltip:show_tooltip(message, text)
		elseif message.type == h_twitch then
			local text = intl(message.payload and "twitch.start_voting" or "twitch.stop_voting")

			self.tooltip:show_tooltip(message, text)
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
