local sound_util = require("sound.util")
local dispatcher = require("crit.dispatcher")
local h_office_object_select = hash("office_object_select")
local h_office_object_deselect = hash("office_object_deselect")
local h_play_sfx = hash("play_sfx")
local h_init_office = hash("init_office")
local h_init_briefing_room = hash("init_briefing_room")
local h_office_object_on_hover_sound = hash("office_object_on_hover_sound")
local h_agent_files = hash("agent_files")
local h_pr_report = hash("pr_report")
local h_mission_report = hash("mission_report")
local h_newspaper = hash("newspaper")
local h_manual = hash("manual")
local h_perks = hash("perks")

function _env:init()
	self.bank = sound_util.load_bank("All Campaign.bank")

	if fmod then
		self.event_folder = fmod.studio.system:get_event("event:/Campaign/Folder")
		self.event_newspaper = fmod.studio.system:get_event("event:/Campaign/Newspaper")
		self.event_checkmark = fmod.studio.system:get_event("event:/Campaign/Checkmark")
		self.event_papers = fmod.studio.system:get_event("event:/Campaign/Papers")
		self.event_album = fmod.studio.system:get_event("event:/Campaign/Album")
		self.event_stamp = fmod.studio.system:get_event("event:/Campaign/Stamp")
		self.event_polaroids = fmod.studio.system:get_event("event:/Campaign/Polaroids")
		self.event_perk_chosen = fmod.studio.system:get_event("event:/Campaign/Perk Cue")
		self.event_paper_slide = fmod.studio.system:get_event("event:/Campaign/Paper Slide")
		self.event_paper_slide2 = fmod.studio.system:get_event("event:/Campaign/Paper Slide 2")
		self.event_manual = fmod.studio.system:get_event("event:/Campaign/Manual")
		self.event_desk_rustles_light = fmod.studio.system:get_event("event:/Campaign/Desk Rustles Light")
		self.event_desk_rustles_heavy = fmod.studio.system:get_event("event:/Campaign/Desk Rustles Heavy")
	end

	self.sub_id = dispatcher.subscribe({
		h_office_object_select,
		h_office_object_deselect,
		h_play_sfx,
		h_init_office,
		h_init_briefing_room,
		h_office_object_on_hover_sound
	})
end

function _env:final()
	sound_util.release_bank(self.bank)
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_select then
		if (message.object_id == h_pr_report or message.object_id == h_mission_report) and not message.expo then
			if self.event_papers then
				local instance = self.event_papers:create_instance()

				instance:set_parameter_by_name("IsPickedUp", 1, false)
				instance:start()
			end
		elseif message.object_id == h_agent_files then
			if self.event_folder then
				local instance = self.event_folder:create_instance()

				instance:set_parameter_by_name("IsOpening", 1, false)
				instance:start()
			end
		elseif message.object_id == h_newspaper then
			if self.event_newspaper then
				local instance = self.event_newspaper:create_instance()

				instance:set_parameter_by_name("IsOpening", 1, false)
				instance:start()
			end
		elseif message.object_id == h_manual and self.event_manual then
			local instance = self.event_manual:create_instance()

			instance:set_parameter_by_name("IsOpening", 1, false)
			instance:start()
		end
	elseif message_id == h_office_object_deselect then
		if (message.object_id == h_pr_report or message.object_id == h_mission_report) and not message.expo then
			if self.event_papers then
				local instance = self.event_papers:create_instance()

				instance:set_parameter_by_name("IsPickedUp", 0, false)
				instance:start()
			end
		elseif message.object_id == h_agent_files then
			if self.event_folder then
				local instance = self.event_folder:create_instance()

				instance:set_parameter_by_name("IsOpening", 0, false)
				instance:start()
			end
		elseif message.object_id == h_newspaper then
			if self.event_newspaper then
				local instance = self.event_newspaper:create_instance()

				instance:set_parameter_by_name("IsOpening", 0, false)
				instance:start()
			end
		elseif message.object_id == h_manual and self.event_manual then
			local instance = self.event_manual:create_instance()

			instance:set_parameter_by_name("IsOpening", 0, false)
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
	elseif message_id == h_office_object_on_hover_sound then
		local object_id = message.object_id

		if object_id == h_perks or object_id == h_manual then
			if self.event_desk_rustles_heavy then
				self.event_desk_rustles_heavy:create_instance():start()
			end
		elseif (object_id == h_agent_files or object_id == h_pr_report or object_id == h_mission_report or object_id == h_newspaper) and self.event_desk_rustles_light then
			self.event_desk_rustles_light:create_instance():start()
		end
	end
end
