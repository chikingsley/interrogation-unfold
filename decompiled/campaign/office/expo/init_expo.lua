local dispatcher = require("crit.dispatcher")
local sound_util = require("sound.util")
local h_init_office = hash("init_office")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_scale = hash("scale")
local h_position = hash("position")
local h_rotation = hash("rotation")
local h_mission_report = hash("mission_report")
local h_pr_report = hash("pr_report")

local function play_sfx(event, delay, object_id)
	local pan = 0.5

	if object_id == h_mission_report then
		pan = 0
	elseif object_id == h_pr_report then
		pan = 1
	end

	timer.delay(delay, false, function ()
		local instance = event:create_instance()

		instance:set_parameter_by_name("PaperPan", pan, false)
		instance:start()
		instance:set_parameter_by_name("PaperPan", 0.5, false)
	end)
end

function _env:init()
	local this_go = msg.url(".")
	self.this_go = this_go
	self.sub_id = dispatcher.subscribe({
		h_init_office,
		h_office_object_select
	})
	self.bank = sound_util.load_bank("All Campaign.bank")
	self.event_paper_slide = fmod and fmod.studio.system:get_event("event:/Campaign/Paper Slide")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
	sound_util:release_bank(self.bank)
end

local function select_object(self)
	local this_go = self.this_go
	local duration = self.duration
	local delay = self.delay

	go.cancel_animations(this_go, h_position)
	go.cancel_animations(this_go, h_rotation)
	go.cancel_animations(this_go, h_scale)
	go.animate(this_go, h_position, go.PLAYBACK_ONCE_FORWARD, self.final_position, go.EASING_OUTQUART, duration, delay)
	go.animate(this_go, h_rotation, go.PLAYBACK_ONCE_FORWARD, self.final_rotation, go.EASING_OUTQUART, duration, delay)
	go.animate(this_go, h_scale, go.PLAYBACK_ONCE_FORWARD, self.final_scale, go.EASING_OUTQUART, duration, delay, function ()
		dispatcher.dispatch(h_office_object_selected, {
			expo = true,
			object_id = self.object_id
		})
	end)
	play_sfx(self.event_paper_slide, delay, self.object_id)
end

function _env:on_message(message_id, message)
	if message_id == h_init_office then
		if not message.no_expo and not message.new_perks then
			go.set_position(self.initial_position)
			go.set_rotation(self.initial_rotation)
			go.set_scale(self.initial_scale)
		end
	elseif message_id == h_office_object_select and message.expo and message.object_id == self.object_id then
		timer.delay(0, false, function ()
			timer.delay(0, false, select_object)
		end)
	end
end
