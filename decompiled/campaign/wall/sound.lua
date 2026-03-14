local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_play_sfx = hash("play_sfx")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_state_change = hash("wall_object_state_change")
local h_set_page_casefile = hash("set_page_casefile")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_office_object_deselect = hash("office_object_deselect")
local h_casefile = hash("casefile")
local h_newspaper = hash("newspaper")

function _env:init()
	self.bank_campaign = sound_util.load_bank("All Campaign.bank")
	self.bank_levels = sound_util.load_bank("All Levels.bank")

	if fmod then
		self.event_folder = fmod.studio.system:get_event("event:/Campaign/Folder")
		self.event_newspaper = fmod.studio.system:get_event("event:/Campaign/Newspaper")
		self.event_papers = fmod.studio.system:get_event("event:/Campaign/Papers")
		self.event_polaroids = fmod.studio.system:get_event("event:/Campaign/Polaroids")
		self.event_desk_rustles_light = fmod.studio.system:get_event("event:/Campaign/Desk Rustles Light")
		self.event_casefile_open_full = fmod.studio.system:get_event("event:/Casefile/Open Full")
		self.event_casefile_close_full = fmod.studio.system:get_event("event:/Casefile/Close Full")
		self.event_casefile_flip_page = fmod.studio.system:get_event("event:/Casefile/Flip Page")
		self.event_casefile_open_hover = fmod.studio.system:get_event("event:/Casefile/Open Hover")
		self.event_casefile_close_hover = fmod.studio.system:get_event("event:/Casefile/Close Hover")
	end

	self.sub_id = dispatcher.subscribe({
		h_wall_object_select,
		h_wall_object_state_change,
		h_play_sfx,
		h_set_page_casefile,
		h_wall_object_deselect,
		h_office_object_deselect
	})
end

function _env:final()
	sound_util.release_bank(self.bank_campaign)
	sound_util.release_bank(self.bank_levels)
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_wall_object_select then
		local object_type = message.object_type

		if object_type == h_casefile then
			if self.event_casefile_open_full then
				self.event_casefile_open_full:create_instance():start()
			end
		elseif object_type == h_newspaper and self.event_newspaper then
			local instance = self.event_newspaper:create_instance()

			instance:set_parameter_by_name("IsOpening", 1, false)
			instance:start()
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_newspaper and self.event_newspaper then
			local instance = self.event_newspaper:create_instance()

			instance:set_parameter_by_name("IsOpening", 0, false)
			instance:start()
		end
	elseif message_id == h_set_page_casefile then
		if self.event_casefile_flip_page then
			local instance = self.event_casefile_flip_page:create_instance()

			instance:set_parameter_by_name("IsForwards", message.next and 1 or 0, false)
			instance:start()
		end
	elseif message_id == h_play_sfx then
		local event = self["event_" .. message.sfx]

		if not event then
			return
		end

		local instance = event:create_instance()

		if message.parameters then
			for parameter, value in pairs(message.parameters) do
				instance:set_parameter_by_name(parameter, value, false)
			end
		end

		instance:start()
	end
end
