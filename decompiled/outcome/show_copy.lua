local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local h_outcome_set_options = hash("outcome_set_options")
local h_outcome_enable_transcript = hash("outcome_enable_transcript")
local h_outcome_disable_transcript = hash("outcome_disable_transcript")
local h_colorw = hash("color.w")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_outcome_set_options,
		h_outcome_enable_transcript,
		h_outcome_disable_transcript
	})
	self.header = msg.url("text#header")
	self.text = msg.url("text#text")

	go.set(self.header, h_colorw, 0)
	go.set(self.text, h_colorw, 0)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function fade_text(self, fade_out)
	go.animate(self.header, h_colorw, go.PLAYBACK_ONCE_FORWARD, fade_out and 0 or 1, go.EASING_LINEAR, self.animation_duration)
	go.animate(self.text, h_colorw, go.PLAYBACK_ONCE_FORWARD, fade_out and 0 or 1, go.EASING_LINEAR, self.animation_duration)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_outcome_set_options then
		local text = "NO TEXT"
		local header = "NO TEXT"

		if message.text then
			text = message.text
		elseif message.text_key and message.intl_namespace then
			text = intl.namespace(message.intl_namespace).t(message.text_key)
		end

		if message.header then
			header = message.header
		elseif message.header_key and message.intl_namespace then
			header = intl.namespace(message.intl_namespace).t(message.header_key)
		end

		label.set_text(self.text, text)
		label.set_text(self.header, header)
		go.animate(self.header, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, self.animation_duration, self.header_delay)
		go.animate(self.text, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, self.animation_duration, self.text_delay)
	elseif message_id == h_outcome_enable_transcript then
		fade_text(self, true)
	elseif message_id == h_outcome_disable_transcript then
		fade_text(self, false)
	end
end
