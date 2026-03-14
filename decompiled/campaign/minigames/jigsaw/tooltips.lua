local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_jigsaw_continue = hash("jigsaw_continue")
local h_pause = hash("pause")

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

		if type == h_jigsaw_continue then
			self.tooltip:show_tooltip(message, intl("jigsaw.complete_to_continue"))
		elseif type == h_pause then
			self.tooltip:show_tooltip(message, intl("level.pause.tooltip"))
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
