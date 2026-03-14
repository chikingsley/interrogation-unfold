local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local missions = require("campaign.missions")
local budget = require("campaign.budget")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_mission = hash("mission")
local h_budget = hash("budget")
local h_campaign_save = hash("campaign_save")
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
	self.additional_tooltip_ids = {}
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function format_success_rate(rate)
	return rate and intl("briefing_room.success_rate", {
		percentage = string.format("%d", rate)
	}) or intl("briefing_room.agent_not_eligible")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_tooltip_show then
		if message.type == h_mission then
			local payload = message.payload
			local hr_perk_active = payload.hr_perk_active
			local mission_id = payload.mission_id
			local mission = missions.get_option(mission_id)

			if not mission then
				return
			end

			local text = "<b>" .. missions.translate_option_text(mission, "title") .. "</b>\n\n" .. missions.translate_option_text(mission, "description")
			local dragged_character = payload.dragged_character

			if dragged_character then
				local rate = missions.get_success_rate(mission, dragged_character)
				local success_rate = format_success_rate(rate)

				if hr_perk_active or not rate then
					text = text and text .. "\n\n" .. success_rate or success_rate
				end
			end

			local char_bounding_boxes = payload.char_bounding_boxes

			if char_bounding_boxes and hr_perk_active then
				local id = message.id
				local additional_ids = {}
				self.additional_tooltip_ids[id] = additional_ids

				for char_id, bounding_box in pairs(char_bounding_boxes) do
					local char_text = format_success_rate(missions.get_success_rate(mission, char_id))
					local char_tooltip_id = "char_" .. char_id .. "_" .. id
					additional_ids[char_id] = char_tooltip_id

					self.tooltip:show_tooltip({
						padding = 0,
						id = char_tooltip_id,
						bounding_box = bounding_box,
						position = Tooltip.POSITION_BOTTOM
					}, char_text)
				end
			end

			if text then
				self.tooltip:show_tooltip({
					id = message.id,
					bounding_box = payload.mission_bounding_box
				}, text, true)
			end
		elseif message.type == h_budget then
			local budget_option_index = message.payload.budget_option_index

			if not budget_option_index then
				return
			end

			local budget_option = budget.options[budget_option_index]

			if not budget_option then
				return
			end

			local text = budget.translate_option_text(budget_option, "description")

			if not text then
				return
			end

			text = "<b>" .. budget.translate_option_text(budget_option, "title") .. "</b>\n\n" .. text

			self.tooltip:show_tooltip(message, text, true)
		elseif message.type == h_campaign_save then
			local text = intl("briefing_room.commit")

			if budget.capacity < budget.get_total_cost() then
				text = intl("briefing_room.commit.over_budget")
			end

			self.tooltip:show_tooltip(message, text)
		elseif message.type == h_pause then
			self.tooltip:show_tooltip(message, intl("level.pause.tooltip"))
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)

		local additional_ids = self.additional_tooltip_ids[message.id]

		if additional_ids then
			self.additional_tooltip_ids[message.id] = nil

			for k, id in pairs(additional_ids) do
				self.tooltip:hide_tooltip({
					id = id
				})
			end
		end
	end
end
