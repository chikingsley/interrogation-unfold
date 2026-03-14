local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_outcome_transcript = hash("outcome_transcript")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")

function _env:init()
	gui.set_render_order(2)

	self.tooltip = Tooltip.new("tooltip", "text", {
		large_ui_scale = true
	})
	self.transcript_enabled = false
	self.sub_id = dispatcher.subscribe({
		h_tooltip_hide,
		h_tooltip_show,
		h_outcome_enable_transcript,
		h_outcome_disable_transcript
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_tooltip_show then
		local type = message.type

		if type == h_outcome_transcript then
			local text_enabled = intl("outcome.transcript_tooltip_close")
			local text_disabled = intl("outcome.transcript_tooltip_open")
			local text = self.transcript_enabled and text_enabled or text_disabled

			self.tooltip:show_tooltip(message, text, true)
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
	elseif message_id == h_outcome_enable_transcript then
		self.transcript_enabled = true
	elseif message_id == h_outcome_disable_transcript then
		self.transcript_enabled = false
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
