local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local ConfirmModal = require("lib.confirm_modal")
local missions = require("campaign.missions")
local intl = require("crit.intl")
local h_window_change_size = hash("window_change_size")
local h_switch_input_method = hash("switch_input_method")
local h_save_prompt_enable = hash("save_prompt_enable")
local h_save_prompt_disable = hash("save_prompt_disable")
local h_end_scene = hash("end_scene")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")
	local button_cm_press = fmod and fmod.studio.system:get_event("event:/Campaign/Button CM Press")
	local button_cm_release = fmod and fmod.studio.system:get_event("event:/Campaign/Button CM Release")
	local door_office = fmod and fmod.studio.system:get_event("event:/Campaign/Door Office")
	self.modal = ConfirmModal.new({
		cancel_action = function ()
			dispatcher.dispatch(h_save_prompt_disable)
		end,
		ok_action = function ()
			dispatcher.dispatch(h_save_prompt_disable)
		end,
		confirm_action = function ()
			dispatcher.dispatch(h_end_scene)
			dispatcher.dispatch(h_save_prompt_disable)
		end,
		button_sound = {
			press = button_cm_press,
			release = button_cm_release
		},
		confirm_button_sound = {
			press = button_cm_press,
			release = door_office
		}
	})

	intl.translate_text_node("modal_button_confirm_text")
	intl.translate_text_node("modal_button_cancel_text")
	intl.translate_text_node("modal_button_ok_text")

	self.sub_id = dispatcher.subscribe({
		h_save_prompt_enable,
		h_save_prompt_disable,
		h_window_change_size,
		h_switch_input_method
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util.release_bank(self.bank)
	msg.post(".", "release_input_focus")
end

function _env:on_message(message_id, message, sender)
	if message_id == h_save_prompt_enable then
		local budget_set = message.budget_set
		local missions_set = message.missions_set
		local unmet_dependencies = message.unmet_dependencies
		local fatal = message.fatal
		local reason = nil

		if unmet_dependencies then
			local mission = missions.get_option(unmet_dependencies)
			local values = {
				mission = intl.namespace(mission.intl_namespace)("missions." .. mission.intl_key .. ".title")
			}

			if fatal then
				reason = intl("briefing_room.save_prompt.unmet_dependencies.fatal", values)
			else
				reason = intl("briefing_room.save_prompt.unmet_dependencies", values)
			end
		elseif not budget_set and missions_set then
			reason = intl("briefing_room.save_prompt.no_budget")
		elseif budget_set and not missions_set then
			reason = intl("briefing_room.save_prompt.no_missions")
		elseif not budget_set and not missions_set then
			reason = intl("briefing_room.save_prompt.no_budget_no_missions")
		else
			return
		end

		self.modal:show(reason, fatal)
		msg.post(".", "acquire_input_focus")
	elseif message_id == h_save_prompt_disable then
		self.modal:hide()
		msg.post(".", "release_input_focus")
	elseif message_id == h_window_change_size then
		self.modal:window_change_size()
	elseif message_id == h_switch_input_method then
		self.modal:switch_input_method(message)
	end
end

function _env:on_input(action_id, action)
	if self.modal:on_input(action_id, action) then
		return true
	end
end
