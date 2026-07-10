local dispatcher = require("crit.dispatcher")
local progression = require("crit.progression")
local level = {
	timed_callbacks = {},
	event_handlers = {},
	CASEFILE = hash("casefile"),
	RECORDER = hash("recorder"),
	EMPATHY_METER = hash("empathy_meter"),
	FEAR_METER = hash("fear_meter"),
	TIMER = hash("timer"),
	SUBJECT_SWITCHER = hash("subject_switcher"),
	FIRST_QUESTION = hash("first_question")
}
local h_level_highlight = hash("level_highlight")
local h_level_highlight_cancel = hash("level_highlight_cancel")
local h_level_tutor_set_text = hash("level_tutor_set_text")
local h_level_disable_controls = hash("level_disable_controls")
local h_level_enable_controls = hash("level_enable_controls")
local h_level_refresh_questions = hash("level_refresh_questions")
local h_level_set_recorder_disabled = hash("level_set_recorder_disabled")

function level.register_event_handler(event, handler)
	level.event_handlers[event] = handler
end

function level.add_time_callback(time, callback)
	table.insert(level.timed_callbacks, {
		time = time,
		callback = callback
	})
end

function level.highlight_object(object)
	dispatcher.dispatch(h_level_highlight, {
		object = hash(object)
	})
end

function level.cancel_highlight()
	dispatcher.dispatch(h_level_highlight_cancel)
end

function level.set_tutor_text(text, no_advance_indicator)
	if text and not no_advance_indicator then
		text = text .. "<nobr> <img=t:advance/></nobr>"
	end

	level.tutor_text = text

	dispatcher.dispatch(h_level_tutor_set_text)
end

function level.wait_for_next_click()
	dispatcher.dispatch(h_level_disable_controls, {
		until_next_click = true
	})
	progression.wait_for_message(h_level_enable_controls)
end

function level.refresh_questions()
	dispatcher.dispatch(h_level_refresh_questions)
end

function level.set_recorder_disabled(disabled)
	dispatcher.dispatch(h_level_set_recorder_disabled, {
		disabled = disabled
	})
end

function level._reset()
	level.timed_callbacks = {}
	level.event_handlers = {}
end

function level._check_timed_callbacks(time_elapsed)
	local timed_callbacks = level.timed_callbacks

	for key, descriptor in pairs(timed_callbacks) do
		if descriptor.time <= time_elapsed then
			timed_callbacks[key] = nil

			descriptor.callback()
		end
	end
end

return level
