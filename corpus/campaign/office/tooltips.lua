local Tooltip = require("lib.tooltip")
local dispatcher = require("crit.dispatcher")
local stats = require("campaign.stats")
local families = require("main.fonts.families")
local intl = require("crit.intl")
local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_pr_stat_positive = hash("pr_stat_positive")
local h_pr_stat_negative = hash("pr_stat_negative")
local h_pr_stat_difference = hash("pr_stat_difference")
local h_perks_continue = hash("perks_continue")
local h_pause = hash("pause")

function _env:init()
	self.tooltip = Tooltip.new("tooltip", "text", {
		large_ui_scale = true,
		rich_fonts = families
	})
	self.tooltip_pr_stats = Tooltip.new("tooltip_pr", "text_pr", {
		large_ui_scale = true,
		rich_fonts = families
	})
	self.tooltip_perks_continue = Tooltip.new("tooltip_perks_continue", "text_perks_continue", {
		large_ui_scale = true,
		rich_fonts = families
	})
	self.sub_id = dispatcher.subscribe({
		h_tooltip_hide,
		h_tooltip_show
	})
end

local function get_perk_stat_description(stat_id, high, active)
	local high_str = high and "high" or "low"
	local active_str = active and "active" or "inactive"
	local title = intl("stats." .. stat_id .. "." .. high_str .. ".title")
	local body = intl("stats." .. stat_id .. "." .. high_str .. ".body." .. active_str)
	local description = intl("stats." .. stat_id .. "." .. high_str .. ".description." .. active_str)
	local active_suffix = active and "" or " <color=#ffffff80>(" .. intl("stats.perk.inactive") .. ")</color>"

	return "<b>" .. title .. "</b>" .. active_suffix .. "\n<color=#00000000>.</color>\n" .. body .. "\n\n<i>" .. description .. "</i>"
end

function _env:on_message(message_id, message, sender)
	if message_id == h_tooltip_show then
		local type = message.type

		if type == h_perks_continue then
			local text = nil

			if message.payload then
				text = intl("perks.tooltip.confirm")
			else
				text = intl("perks.tooltip.pick")
			end

			self.tooltip_perks_continue:show_tooltip(message, text)

			return
		elseif type == h_pause then
			self.tooltip:show_tooltip(message, intl("level.pause.tooltip"))

			return
		end

		local is_advanced = message.payload.is_advanced
		local stat_id = message.payload.entry_id
		local stat = stats[stat_id]

		if not stat then
			return
		end

		local text = nil

		if type == h_pr_stat_positive then
			text = get_perk_stat_description(stat_id, true, stats.is_high(stat_id))
		elseif type == h_pr_stat_negative then
			text = get_perk_stat_description(stat_id, false, stats.is_low(stat_id))
		elseif type == h_pr_stat_difference then
			local current_stat = stats[stat_id]
			local previous_stats = stats.get_commit(1)
			local previous_stat = previous_stats[stat_id]
			local checkmark_slot = stats.get_checkbox_slot(stats[stat_id])
			local previous_checkmark_slot = stats.get_checkbox_slot(previous_stats[stat_id])

			if is_advanced then
				if current_stat < previous_stat then
					text = intl("stats.decrease")
				elseif previous_stat < current_stat then
					text = intl("stats.increase")
				elseif current_stat == previous_stat then
					text = intl("stats.constant")
				end
			elseif checkmark_slot < previous_checkmark_slot then
				text = intl("stats.decrease")
			elseif previous_checkmark_slot < checkmark_slot then
				text = intl("stats.increase")
			elseif checkmark_slot == previous_checkmark_slot then
				text = intl("stats.constant")
			end
		end

		if text then
			self.tooltip_pr_stats:show_tooltip(message, text, true)
		end
	elseif message_id == h_tooltip_hide then
		self.tooltip:hide_tooltip(message)
		self.tooltip_pr_stats:hide_tooltip(message)
		self.tooltip_perks_continue:hide_tooltip(message)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
