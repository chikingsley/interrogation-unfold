local store = require("level.store")
local state = require("level.state")
local dispatcher = require("crit.dispatcher")
local env = require("lib.environment")
local try = require("main.try")
local server = require("main.hot_reload_server")
local commentary = require("main.progression.commentary.index")
local level = require("level.interface")
local save_file = require("lib.save_file")
local scenes = require("main.progression.scenes")
local iap_utils = require("lib.iap_utils")
local config = save_file.config
local PHASE_UNINITIALIZED = state.PHASE_UNINITIALIZED
local PHASE_INTRO = state.PHASE_INTRO
local PHASE_RUNNING = state.PHASE_RUNNING
local PHASE_OVER = state.PHASE_OVER
local h_kill = hash("kill")
local h_win = hash("win")
local h_lose = hash("lose")
local h_set_subject = hash("set_subject")
local h_init_level = hash("init_level")
local h_init_level_lite = hash("init_level_lite")
local h_torture = hash("torture")
local h_ask_question = hash("ask_question")
local h_game_over = hash("game_over")
local h_start_game = hash("start_game")
local h_pause = hash("pause")
local h_resume = hash("resume")
local h_go_on_record = hash("go_on_record")
local h_go_off_record = hash("go_off_record")
local h_torture_room_show = hash("torture_room_show")
local h_torture_room_hide = hash("torture_room_hide")
local h_show_subject = hash("show_subject")
local h_level_event = hash("level_event")
local h_play_animation = hash("play_animation")
local h_level_avatar_play_animation = hash("level_avatar_play_animation")
local h_level_set_recorder_disabled = hash("level_set_recorder_disabled")
local h_hot_update_episode = hash("hot_update_episode")
local h_level_refresh_questions = hash("level_refresh_questions")
local h_add_time = hash("add_time")
local h_set_time = hash("set_time")
local h_delay = hash("delay")
local h_timer_changed = hash("timer_changed")
local h_update_insanity_question = hash("update_insanity_question")
local h_level_hints_check = hash("level_hints_check")
local h_level_toggle_flag = hash("level_toggle_flag")
local h_maybe_innocent = hash("maybe_innocent")
local sub_id, on_message, on_event = nil

local function init()
	state.phase = PHASE_UNINITIALIZED
	state.paused = false
	state.time_elapsed = 0
	state.turn_time_elapsed = 0
	state.current_subject = 1
	state.current_room = 1
	state.on_record = true
	state.torture_room_shown = false
	state.has_won = false
	state.game_over_reason = nil
	state.recorder_disabled = false
	state.immortal = false
	state.insanity_question_shown = false
	state.lite = false
	sub_id = dispatcher.subscribe_hook({
		h_init_level,
		h_init_level_lite,
		h_game_over,
		h_show_subject,
		h_set_subject,
		h_start_game,
		h_ask_question,
		h_pause,
		h_resume,
		h_torture,
		h_go_on_record,
		h_go_off_record,
		h_level_set_recorder_disabled,
		h_hot_update_episode,
		h_update_insanity_question,
		h_level_toggle_flag
	}, on_message)
end

local function final()
	dispatcher.unsubscribe(sub_id)
	store.remove_event_handler(on_event)

	server.loaded_level_id = nil
	state.phase = PHASE_UNINITIALIZED
end

local function perform_change(f)
	local subject_id = state.current_subject
	local subject = store.subjects[subject_id]
	local was_dead = subject.health <= 0

	f()

	local is_dead = subject.health <= 0

	if not was_dead and is_dead then
		dispatcher.dispatch(h_kill)

		local history_event = {
			type = store.HISTORY_EVENTS.KILL,
			timestamp = state.time_elapsed,
			subject_id = state.current_subject
		}

		store.add_history_event(history_event)
	end

	if not state.immortal and subject.empathy <= -10 then
		save_file.set_global("hate_your_guts", true)
	end

	if state.phase == PHASE_RUNNING and not store.is_any_subject_alive() then
		store.fire_event("lose", {
			"death"
		})
	end

	if state.phase == PHASE_RUNNING then
		dispatcher.dispatch(h_level_hints_check)
	end
end

function on_event(event_id, args, subject_id)
	if event_id == h_win or event_id == h_lose then
		dispatcher.dispatch(h_game_over, {
			has_won = event_id == h_win,
			reason = args[1]
		})
	elseif event_id == h_play_animation then
		dispatcher.dispatch(h_level_avatar_play_animation, args)
	elseif event_id == h_add_time then
		local value = tonumber(args[1])

		if store.time_limit and value then
			store.time_limit = store.time_limit + value

			dispatcher.dispatch(h_timer_changed, {
				timer_increased = value and value > 0
			})
		end
	elseif event_id == h_set_time then
		local value = args[1] and tonumber(args[1])

		if value == 0 then
			value = nil
		end

		local new_timer = not not value and not store.time_limit

		if value then
			store.time_limit = state.time_elapsed + value
		else
			store.time_limit = nil
		end

		dispatcher.dispatch(h_timer_changed, {
			new_timer = new_timer
		})
	elseif event_id == h_show_subject then
		local function show()
			local show_subject_id = nil
			local subject_name = args[1]

			for i, subject in ipairs(store.subjects) do
				if subject.avatar == subject_name and not subject.shown then
					show_subject_id = i
				end
			end

			if show_subject_id then
				dispatcher.dispatch(h_show_subject, {
					subject_id = show_subject_id
				})
			end
		end

		if args.after_delay then
			show()
		else
			timer.delay(1, false, show)
		end
	else
		if event_id == h_delay then
			local delay = args[1] and tonumber(args[1])
			local event_name = args[2]

			if not delay or not event_name then
				return
			end

			local new_args = {}

			for i = 3, #args do
				new_args[i - 2] = args[i]
			end

			new_args.after_delay = delay
			local current_time = config.real_time_interrogation and state.time_elapsed or state.turn_time_elapsed

			level.add_time_callback(current_time + delay, function ()
				on_event(hash(event_name), new_args, subject_id)
			end)

			return
		end

		if event_id == h_torture_room_show then
			if not state.on_record and not state.torture_room_shown then
				state.torture_room_shown = true

				dispatcher.dispatch(h_torture_room_show)
			end
		elseif event_id == h_go_on_record then
			if not state.on_record then
				dispatcher.dispatch(h_go_on_record, {
					from_event = true
				})
			end
		elseif event_id == h_go_off_record then
			if state.on_record then
				dispatcher.dispatch(h_go_off_record, {
					from_event = true
				})
			end
		elseif event_id == h_maybe_innocent then
			save_file.set_global("maybe_innocent", true)
		else
			dispatcher.dispatch(h_level_event, {
				event_id = event_id,
				args = args,
				subject_id = subject_id
			})
		end
	end
end

local h_conference_room = hash("conference_room")
local level_y_offset = {
	default = -115,
	[h_conference_room] = -50,
	[hash("prison")] = -50
}

local function get_y_offset(lite_background)
	local background = "default"

	if state.lite then
		background = hash(lite_background or h_conference_room)
	end

	return level_y_offset[background] or 0
end

function on_message(message_id, message)
	if message_id == h_init_level_lite then
		state.lite = true
	elseif message_id == h_init_level then
		state.y_offset = get_y_offset(message.background)
		state.demo_break = not not message.demo_break

		try(function ()
			local data = message.from_server and server.level_data or json.decode(sys.load_resource("/episodes/data/" .. message.level .. ".json"))
			data.level_id = data.level_id or message.level

			store.init(data, {
				flags = message.flags,
				disabled_subjects = message.disabled_subjects,
				hidden_subjects = message.hidden_subjects,
				stat_boosts = message.stat_boosts
			})

			server.loaded_level_id = store.level_id
		end)

		state.phase = PHASE_INTRO
		state.current_subject = store.subject_in_room[state.current_room]
		state.recorder_disabled = not not message.recorder_disabled
		state.immortal = message.immortal or not not env.immortal

		store.add_event_handler(on_event)

		if message.auto_start_game then
			timer.delay(message.auto_start_game or 1, false, function ()
				dispatcher.dispatch(h_start_game)
			end)
		end
	elseif message_id == h_start_game then
		state.phase = PHASE_RUNNING

		if iap_utils.is_demo() and state.demo_break then
			timer.delay(0.5, false, function ()
				scenes.run_progression("demo_cta")
			end)
		end
	elseif message_id == h_ask_question then
		perform_change(function ()
			local question_id = message.question_id
			local subject_id = state.current_subject
			local _, alt_text_id = store.get_question_text(question_id, subject_id)
			message.alt_text_id = alt_text_id

			if not store.is_free_question(question_id, subject_id) then
				state.turn_time_elapsed = state.turn_time_elapsed + 5
			end

			store.execute_question(question_id, subject_id)
		end)
	elseif message_id == h_set_subject then
		local subject_id = message.subject_id
		state.current_subject = subject_id
		state.current_room = store.subjects[subject_id].room_index
		local history_event = {
			type = store.HISTORY_EVENTS.SWITCH_SUBJECT,
			timestamp = state.time_elapsed,
			subject_id = subject_id
		}

		if #store.history > 0 and store.history[#store.history].type == store.HISTORY_EVENTS.SWITCH_SUBJECT then
			table.remove(store.history)
		end

		store.add_history_event(history_event)
	elseif message_id == h_show_subject then
		store.show_subject(message.subject_id)
	elseif message_id == h_torture then
		perform_change(function ()
			store.torture(state.current_subject, message.torture_id)

			if state.immortal then
				local subject = store.subjects[state.current_subject]
				subject.health = subject.starting_health
			end
		end)
		commentary.torture.overlay_once()

		local history_event = {
			type = store.HISTORY_EVENTS.TORTURE,
			timestamp = state.time_elapsed,
			subject_id = state.current_subject,
			torture_id = message.torture_id
		}

		store.add_history_event(history_event)
	elseif message_id == h_level_set_recorder_disabled then
		state.recorder_disabled = message.disabled
	elseif message_id == h_pause then
		state.paused = true
	elseif message_id == h_resume then
		state.paused = false
	elseif message_id == h_go_on_record then
		state.on_record = true

		if state.torture_room_shown then
			state.torture_room_shown = false

			dispatcher.dispatch(h_torture_room_hide)
		end

		if not message.from_event then
			local trigger_question_id = store.get_triggered_question(state.current_subject, "go_on_record")

			if trigger_question_id then
				dispatcher.dispatch(h_ask_question, {
					question_id = trigger_question_id
				})
			end
		end
	elseif message_id == h_go_off_record then
		state.on_record = false
		local trigger_question_id = store.get_triggered_question(state.current_subject, "go_off_record")

		if trigger_question_id then
			dispatcher.dispatch(h_ask_question, {
				question_id = trigger_question_id
			})
		else
			state.torture_room_shown = true

			dispatcher.dispatch(h_torture_room_show)
		end

		local subject_id = state.current_subject
		local history_event = {
			type = store.HISTORY_EVENTS.RECORDER,
			timestamp = state.time_elapsed,
			subject_id = subject_id
		}

		if #store.history > 0 then
			local previous_event = #store.history > 0 and store.history[#store.history]

			if previous_event.type == store.HISTORY_EVENTS.RECORDER and previous_event.subject_id == subject_id then
				table.remove(store.history)
			end
		end

		store.add_history_event(history_event)
	elseif message_id == h_game_over then
		state.phase = PHASE_OVER
		state.has_won = message.has_won
		state.game_over_reason = message.reason
		local history_event = {
			type = store.HISTORY_EVENTS.LEVEL_END,
			timestamp = state.time_elapsed,
			reason = message.reason
		}

		store.add_history_event(history_event)
	elseif message_id == h_update_insanity_question then
		state.insanity_question_shown = message.shown
	elseif message_id == h_hot_update_episode then
		try(function ()
			store.reload(server.level_data)
			dispatcher.dispatch(h_level_refresh_questions)
		end)
	elseif message_id == h_level_toggle_flag then
		local flag = message.flag

		if store.has_flag(flag) then
			store.unset_flag(flag)
		else
			store.set_flag(flag)
		end
	end
end

return {
	init = init,
	final = final
}
