local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local content = require("campaign.wall.content")
local zoom_pan = require("campaign.wall.zoom_and_pan")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local wall_intl = intl.namespace("wall")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_zoom_in_started = hash("zoom_in_started")
local h_zoom_out_started = hash("zoom_out_started")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_tooltip_update = hash("tooltip_update")
local h_clickable_cancel_touch = hash("clickable_cancel_touch")
local h_wall = hash("wall")
local h_pause = hash("pause")

function _env:init()
	self.container = gui.get_node("tooltip")
	self.fullscreen_object = false
	self.tooltip = Tooltip.new("tooltip", "text", {
		large_ui_scale = true,
		rich_fonts = families
	})
	self.sub_id = dispatcher.subscribe({
		h_clickable_cancel_touch,
		h_tooltip_hide,
		h_tooltip_show,
		h_zoom_in_started,
		h_zoom_out_started,
		h_wall_object_select,
		h_wall_object_deselect,
		h_tooltip_update
	})
end

function _env:on_message(message_id, message, sender)
	local suppress_tooltips = self.fullscreen_object or zoom_pan.instance.is_user_panning and zoom_pan.instance.cancel_touch or zoom_pan.instance.animating

	if message_id == h_tooltip_show and not suppress_tooltips then
		local id = message.id
		local type = message.type

		if type == h_wall then
			local intl_key = content.copy[id]

			if not intl_key then
				return
			end

			local text = wall_intl(intl_key)

			self.tooltip:show_tooltip(message, text)
		elseif type == h_pause then
			self.tooltip:show_tooltip(message, intl("level.pause.tooltip"))
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
	elseif message_id == h_wall_object_select then
		self.tooltip:hide_all()

		self.fullscreen_object = true
	elseif message_id == h_wall_object_deselect then
		self.fullscreen_object = false
	elseif message_id == h_tooltip_update then
		self.tooltip:update_position(message)
	elseif message_id == h_clickable_cancel_touch or message_id == h_zoom_in_started or message_id == h_zoom_out_started then
		self.tooltip:hide_all()
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
