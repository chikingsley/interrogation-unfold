local dispatcher = require("crit.dispatcher")
local Tooltip = require("lib.tooltip")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local h_tooltip_hide = hash("tooltip_hide")
local h_tooltip_show = hash("tooltip_show")
local h_torture = hash("torture")
local h_stats = hash("stats")
local h_hints = hash("hints")
local h_hints_notify_start = hash("hints_notify_start")
local h_hints_notify = hash("hints_notify")
local h_subject_panel = hash("subject_panel")
local h_pause = hash("pause")
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

	gui.set_render_order(7)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local torture_counts = {
	cut = 6,
	grab = 6,
	waterboard = 6,
	wall = 6,
	whisky = 4
}

local function get_torture_text(id)
	return intl("level.torture." .. id .. "." .. math.random(torture_counts[id]))
end

function _env:on_message(message_id, message, sender)
	if message_id == h_tooltip_show then
		if message.type == h_torture then
			local payload = message.payload
			local text = get_torture_text(payload.id)

			if text then
				self.tooltip:show_tooltip(message, text)
			end
		elseif message.type == h_stats then
			local payload = message.payload
			local text = intl("level." .. payload.id)

			if text then
				self.tooltip:show_tooltip(message, text)
			end
		elseif message.type == h_subject_panel then
			local payload = message.payload
			local text = payload.subject_name

			if payload.alive == false then
				text = text .. "\n<i><color=#ffffff80>(" .. intl("level.passed_out") .. ")</color></i>"
			end

			if text then
				self.tooltip:show_tooltip(message, text, true)
			end
		elseif message.type == h_hints then
			if message.payload then
				local text = intl("level.hints.request")

				self.tooltip:show_tooltip(message, text)
			end
		elseif message.type == h_hints_notify_start then
			local text = intl("level.hints.notify_start")

			self.tooltip:show_tooltip(message, text)
		elseif message.type == h_hints_notify then
			local text = intl("level.hints.notify")

			self.tooltip:show_tooltip(message, text)
		elseif message.type == h_pause then
			local text = intl("level.pause.tooltip")

			self.tooltip:show_tooltip(message, text)
		elseif message.type == h_twitch then
			local text = intl(message.payload and "twitch.start_voting" or "twitch.stop_voting")

			self.tooltip:show_tooltip(message, text)
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
	end
end
