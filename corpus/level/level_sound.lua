local dispatcher = require("crit.dispatcher")
local state = require("level.state")
local store = require("level.store")
local sound_util = require("sound.util")
local stats = require("campaign.stats")
local env = require("lib.environment")
local h_init_level = hash("init_level")
local h_start_game = hash("start_game")
local h_torture = hash("torture")
local h_torture_animation = hash("torture_animation")
local h_set_subject = hash("set_subject")
local h_play_sfx = hash("play_sfx")
local h_game_over = hash("game_over")
local h_set_page_casefile = hash("set_page_casefile")
local h_scene_transition_start = hash("scene_transition_start")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_go_on_record = hash("go_on_record")
local h_go_off_record = hash("go_off_record")
local h_ask_question = hash("ask_question")
local h_update_insanity_question = hash("update_insanity_question")
local h_flash_twisted = hash("flash_twisted")
local h_timer_changed = hash("timer_changed")
local h_recorder_hover_sound = hash("recorder_hover_sound")
local h_drawer_casefile_set_open = hash("drawer_casefile_set_open")
local h_level_advance = hash("level_advance")
local h_level_hints_notify = hash("level_hints_notify")
local insanity_amount = 0.6
local idle_tinnitus_delay = 15
local cruelty_reactions = {
	{
		threshold = 1
	},
	{
		threshold = 3
	},
	{
		threshold = 5
	},
	{
		threshold = 9
	}
}

local function restart_idle_tinnitus_timer(self, disable)
	if not env.enable_tinnitus then
		return
	end

	if self.idle_tinnitus then
		sound_util.stop_event(self.idle_tinnitus, self.bank_common)

		self.idle_tinnitus = nil
	end

	if self.idle_timer then
		timer.cancel(self.idle_timer)
	end

	if not disable then
		self.idle_timer = timer.delay(idle_tinnitus_delay, false, function ()
			if self.event_idle_tinnitus then
				local idle_tinnitus = self.event_idle_tinnitus:create_instance()

				idle_tinnitus:start()

				self.idle_tinnitus = idle_tinnitus
			end
		end)
	end
end

function _env:init()
	self.bank_common = sound_util.load_bank("All Levels.bank")

	if fmod then
		self.event_torture = fmod.studio.system:get_event("event:/Interrogation/Torture")
		self.event_ambient = fmod.studio.system:get_event("event:/Ambiances/Room Noise")
		self.event_change_subject = fmod.studio.system:get_event("event:/Interrogation/Change Subject")
		self.event_casefile_open_hover = fmod.studio.system:get_event("event:/Casefile/Open Hover")
		self.event_casefile_open_full = fmod.studio.system:get_event("event:/Casefile/Open Full")
		self.event_casefile_close_hover = fmod.studio.system:get_event("event:/Casefile/Close Hover")
		self.event_casefile_close_full = fmod.studio.system:get_event("event:/Casefile/Close Full")
		self.event_casefile_flip_page = fmod.studio.system:get_event("event:/Casefile/Flip Page")
		self.event_ask_question = fmod.studio.system:get_event("event:/Interrogation/Ask Question")
		self.event_recorder_press = fmod.studio.system:get_event("event:/Interrogation/Recorder Press")
		self.event_recorder_release = fmod.studio.system:get_event("event:/Interrogation/Recorder Release")
		self.event_recorder_tape_stop = fmod.studio.system:get_event("event:/Interrogation/Recorder Tape Stop")
		self.event_recorder_tape_start = fmod.studio.system:get_event("event:/Interrogation/Recorder Tape Start")
		self.event_twisted = fmod.studio.system:get_event("event:/Interrogation/Twisted Flash")
		self.event_drawer_roll = fmod.studio.system:get_event("event:/Interrogation/Drawer Roll")
		self.event_drawer_hit = fmod.studio.system:get_event("event:/Interrogation/Drawer Hit")
		self.event_drawer_key = fmod.studio.system:get_event("event:/Interrogation/Drawer Key")
		self.event_bring_them_in = fmod.studio.system:get_event("event:/Interrogation/Bring Them In")
		self.event_report_findings = fmod.studio.system:get_event("event:/Interrogation/Report Findings")
		self.event_timer_start = fmod.studio.system:get_event("event:/Interrogation/Timer Start")
		self.event_timer_low = fmod.studio.system:get_event("event:/Interrogation/Timer Low")
		self.event_timer_end = fmod.studio.system:get_event("event:/Interrogation/Timer End")
		self.event_breathing_reactions = fmod.studio.system:get_event("event:/Interrogation/Off Record Reactions")
		self.event_insanity_ringing = fmod.studio.system:get_event("event:/Interrogation/Insanity Ringing")
		self.event_recorder_hover = fmod.studio.system:get_event("event:/Interrogation/Recorder Hover")
		self.event_cruelty_reactions = fmod.studio.system:get_event("event:/Interrogation/Cruelty Reactions")
		self.event_idle_tinnitus = fmod.studio.system:get_event("event:/Interrogation/Tinnitus")
		self.event_tutorial_advance = fmod.studio.system:get_event("event:/Interrogation/Tutorial Advance")
		self.event_hint_unlock = fmod.studio.system:get_event("event:/Interrogation/Hint Unlock")
		self.event_hint_halo = fmod.studio.system:get_event("event:/Interrogation/Hint Halo")
	end

	self.sub_id = dispatcher.subscribe({
		h_set_subject,
		h_torture,
		h_start_game,
		h_play_sfx,
		h_set_page_casefile,
		h_scene_transition_start,
		h_game_over,
		h_pause,
		h_resume,
		h_init_level,
		h_go_on_record,
		h_go_off_record,
		h_update_insanity_question,
		h_flash_twisted,
		h_timer_changed,
		h_recorder_hover_sound,
		h_torture_animation,
		h_ask_question,
		h_drawer_casefile_set_open,
		h_level_hints_notify,
		h_level_advance
	})

	for i = 1, #cruelty_reactions do
		if cruelty_reactions[i].threshold <= stats.cruelty then
			cruelty_reactions[i].played = true
		else
			cruelty_reactions[i].played = false
		end
	end
end

function _env:final()
	if self.idle_timer then
		timer.cancel(self.idle_timer)
	end

	if self.idle_tinnitus then
		sound_util.stop_event(self.idle_tinnitus, self.bank_common)
	end

	sound_util.release_bank(self.bank_common)
	sound_util.release_bank(self.bank)
	dispatcher.unsubscribe(self.sub_id)
end

local function start_music(self)
	local event = self.event_music

	if event and not self.music then
		local music = event:create_instance()

		music:start()

		self.music = music
	end
end

local function start_breathing_reaction(self, gender, severity)
	if not self.event_breathing_reactions then
		return
	end

	local breath_instance = self.event_breathing_reactions:create_instance()
	local dampen = math.min(stats.cruelty, 10)

	breath_instance:set_parameter_by_name("Gender", gender, false)
	breath_instance:set_parameter_by_name("Cruelty", dampen, false)
	breath_instance:set_parameter_by_name("TimesTortured", severity, false)
	breath_instance:start()
	sound_util.stop_event(self.ambient, self.bank_common)

	self.ambient = nil

	return breath_instance
end

local function get_breathing_severity(subject)
	local severity = 0

	if subject.torture_damage > 2 and subject.fear > 2 then
		severity = 2
	elseif subject.torture_damage > 0 and subject.fear > 0 then
		severity = 1
	end

	return severity
end

local function dampen_music(self, dampen)
	local value = nil

	if type(dampen) == "boolean" then
		if dampen then
			value = 0.5
		else
			value = 0
		end
	elseif type(dampen == "number") then
		value = dampen
	end

	local music = self.music

	if music then
		pcall(function ()
			music:set_parameter_by_name("Dampen", value, false)
		end)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		local ok, error = pcall(function ()
			self.bank = sound_util.load_bank(message.music_bank or "Level " .. store.level_id .. ".bank")
			self.event_music = fmod.studio.system:get_event(message.music or "event:/Level Music/" .. store.level_id)
		end)

		if not ok then
			print("Could not load music for " .. store.level_id .. ": " .. error)

			if self.bank then
				sound_util.release_bank(self.bank)

				self.bank = nil
			end
		end

		if message.play_music_immediately then
			start_music(self)
		elseif self.event_ambient then
			local instance = self.event_ambient:create_instance()
			self.ambient = instance

			instance:start()
		end
	elseif message_id == h_start_game then
		sound_util.stop_event(self.ambient, self.bank_common)

		self.ambient = nil

		start_music(self)
		restart_idle_tinnitus_timer(self)
	elseif message_id == h_game_over then
		restart_idle_tinnitus_timer(self, true)

		if self.music and message.reason ~= "timeout" then
			local parameter = nil

			pcall(function ()
				parameter = self.music:get_description():get_parameter_description_by_name("Game Over")
			end)

			if parameter then
				self.music:set_parameter_by_name("Game Over", 1, false)
			else
				sound_util.stop_event(self.music, self.bank)

				self.music = nil
			end
		end
	elseif message_id == h_scene_transition_start then
		if self.music then
			sound_util.stop_event(self.music, self.bank)

			self.music = nil
		end

		if self.ambient then
			sound_util.stop_event(self.ambient, self.bank_common)

			self.ambient = nil
		end

		if self.breathing_reaction then
			sound_util.stop_event(self.breathing_reaction, self.bank_common)

			self.breathing_reaction = nil
		end

		if self.pause_music then
			sound_util.stop_event(self.pause_music, self.bank_common)

			self.pause_music = nil
		end

		if self.recorder_hover then
			sound_util.stop_event(self.recorder_hover, self.bank_common)

			self.recorder_hover = nil
		end
	elseif message_id == h_pause then
		if self.music then
			self.music = sound_util.pause_event(self.music)
		end

		if self.ambient then
			self.ambient = sound_util.pause_event(self.ambient)
		end

		if self.breathing_reaction then
			self.breathing_reaction:set_parameter_by_name("FadeVolume", 0, false)
		end

		if self.insanity_ringing then
			self.insanity_ringing = sound_util.pause_event(self.insanity_ringing)
		end

		if self.event_pause_music then
			self.pause_music = self.event_pause_music:create_instance()

			self.pause_music:start()
		end

		if self.recorder_hover then
			self.recorder_hover = sound_util.pause_event(self.recorder_hover)
		end

		if self.idle_tinnitus then
			self.idle_tinnitus = sound_util.pause_event(self.idle_tinnitus)
		end
	elseif message_id == h_resume then
		if self.music then
			self.music:set_paused(false)
		end

		if self.ambient then
			self.ambient:set_paused(false)
		end

		if self.breathing_reaction then
			self.breathing_reaction:set_parameter_by_name("FadeVolume", 1, false)
		end

		if self.insanity_ringing then
			self.insanity_ringing:set_paused(false)
		end

		if self.pause_music then
			sound_util.stop_event(self.pause_music, self.bank_common)

			self.pause_music = nil
		end

		if self.recorder_hover then
			self.recorder_hover:set_paused(false)
		end

		if self.idle_tinnitus then
			self.idle_tinnitus:set_paused(false)
		end
	elseif message_id == h_timer_changed then
		if (message.new_timer or not message.timer_increased) and self.event_timer_start then
			self.event_timer_start:create_instance():start()
		end
	elseif message_id == h_level_hints_notify then
		if self.event_hint_unlock then
			self.event_hint_unlock:create_instance():start()
		end
	elseif message_id == h_torture_animation then
		local subject = store.subjects[state.current_subject]
		local gender_param = subject.gender == "female" and 1 or 0
		local will_die = subject.health + store.TORTURE_EFFECTS[message.torture_id].health <= 0
		local death_param = will_die and 1 or 0

		if self.event_torture then
			local torture_instance = self.event_torture:create_instance()

			torture_instance:set_parameter_by_name("Gender", gender_param, false)
			torture_instance:set_parameter_by_name("Gravity", message.torture_id, false)
			torture_instance:set_parameter_by_name("WillDie", death_param, false)
			torture_instance:start()
		end

		if self.breathing_reaction then
			self.breathing_reaction:set_parameter_by_name("IsRunning", 0, false)

			self.breathing_reaction = nil
		end

		if not will_die then
			local severity_param = message.torture_id > 2 and 2 or 1
			self.breathing_reaction = start_breathing_reaction(self, gender_param, severity_param)
		end

		restart_idle_tinnitus_timer(self)
	elseif message_id == h_torture then
		local cruelty = stats.cruelty

		if store.level_id ~= "episode0" then
			for i, reaction in ipairs(cruelty_reactions) do
				if reaction.threshold <= cruelty and not reaction.played then
					if self.event_cruelty_reactions then
						local cruelty_reaction_instance = self.event_cruelty_reactions:create_instance()

						cruelty_reaction_instance:set_parameter_by_name("Cruelty", cruelty, false)
						cruelty_reaction_instance:start()
					end

					cruelty_reactions[i].played = true
				end
			end
		end
	elseif message_id == h_set_subject then
		restart_idle_tinnitus_timer(self)

		if self.event_change_subject then
			local instance = self.event_change_subject:create_instance()

			instance:start()
		end
	elseif message_id == h_go_off_record then
		dampen_music(self, true)
		restart_idle_tinnitus_timer(self)

		if self.event_recorder_tape_stop then
			self.event_recorder_tape_stop:create_instance():start()
		end

		local subject = store.subjects[state.current_subject]
		local gender = subject.gender == "female" and 1 or 0
		self.breathing_reaction = start_breathing_reaction(self, gender, get_breathing_severity(subject))
	elseif message_id == h_go_on_record then
		dampen_music(self, false)
		restart_idle_tinnitus_timer(self)

		if self.event_recorder_tape_start then
			self.event_recorder_tape_start:create_instance():start()
		end

		if self.breathing_reaction then
			self.breathing_reaction:set_parameter_by_name("IsRunning", 0, false)
		end

		self.breathing_reaction = nil
	elseif message_id == h_ask_question then
		restart_idle_tinnitus_timer(self)
	else
		if message_id == h_update_insanity_question then
			local music = self.music
			local is_shown = message.shown

			if music then
				pcall(function ()
					music:set_parameter_by_name("Insanity", is_shown and insanity_amount or 0, false)
				end)
			end

			if is_shown then
				if not self.insanity_ringing then
					if self.event_insanity_ringing then
						local insanity_ringing = self.event_insanity_ringing:create_instance()

						insanity_ringing:set_parameter_by_name("Insanity", insanity_amount, false)
						insanity_ringing:start()

						self.insanity_ringing = insanity_ringing
					end
				else
					self.insanity_ringing:set_parameter_by_name("Insanity", insanity_amount, false)
				end
			elseif self.insanity_ringing then
				self.insanity_ringing:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)

				self.insanity_ringing = nil
			end

			return
		end

		if message_id == h_flash_twisted then
			if self.event_twisted then
				self.event_twisted:create_instance():start()
			end
		elseif message_id == h_set_page_casefile then
			if self.event_casefile_flip_page then
				local instance = self.event_casefile_flip_page:create_instance()

				instance:set_parameter_by_name("IsForwards", message.next and 1 or 0, false)
				instance:start()
			end
		elseif message_id == h_recorder_hover_sound then
			local is_hovering = message.is_hovering

			if is_hovering then
				if self.event_recorder_hover then
					self.recorder_hover = self.event_recorder_hover:create_instance()

					self.recorder_hover:start()
				end
			elseif self.recorder_hover then
				self.recorder_hover:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)

				self.recorder_hover = nil
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

			if instance then
				instance:start()
			end
		elseif message_id == h_drawer_casefile_set_open then
			if state.phase == state.PHASE_RUNNING then
				if message.value then
					dampen_music(self, 0.3)
					restart_idle_tinnitus_timer(self, true)
				else
					dampen_music(self, false)
					restart_idle_tinnitus_timer(self)
				end
			end
		elseif message_id == h_level_advance and self.event_tutorial_advance then
			self.event_tutorial_advance:create_instance():start()
		end
	end
end
