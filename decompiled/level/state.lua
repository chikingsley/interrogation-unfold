local PHASE_UNINITIALIZED = 0
local PHASE_INTRO = 1
local PHASE_RUNNING = 2
local PHASE_OVER = 3
local state = {
	turn_time_elapsed = 0,
	has_won = false,
	torture_room_shown = false,
	insanity_question_shown = false,
	paused = false,
	current_room = 1,
	table_scale = 1,
	time_elapsed = 0,
	immortal = false,
	y_offset = 0,
	on_record = true,
	offset = 0,
	demo_break = false,
	current_subject = 1,
	lite = false,
	recorder_disabled = false,
	PHASE_UNINITIALIZED = PHASE_UNINITIALIZED,
	PHASE_INTRO = PHASE_INTRO,
	PHASE_RUNNING = PHASE_RUNNING,
	PHASE_OVER = PHASE_OVER,
	phase = PHASE_UNINITIALIZED,
	table_position = vmath.vector3(),
	table_original_position = vmath.vector3()
}

return state
