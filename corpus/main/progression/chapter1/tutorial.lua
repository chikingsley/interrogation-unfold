local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local level = require("level.interface")
local FullScreenPanel = require("lib.full_screen_panel")
local store = require("level.store")
local dispatcher = require("crit.dispatcher")
local stats = require("campaign.stats")
local variables = require("campaign.variables")
local sound_util = require("sound.util")
local intl = require("crit.intl")
local save_file = require("lib.save_file")
intl = intl.namespace("chapter1")
local h_level_avatar_play_animation = hash("level_avatar_play_animation")

local function animate_tutor(animation)
	dispatcher.dispatch(h_level_avatar_play_animation, {
		subject_id = 1,
		companion = true,
		animation = animation
	})
end

return function ()
	sound_util.set_music(nil)
	scenes.load_scene("level", {
		no_casefile_auto_open = true,
		tutor = true,
		recorder_disabled = true,
		hide_intro_button = true,
		play_music_immediately = true,
		hide_meters = true,
		immortal = true,
		level = "episode0"
	})

	store.subjects[1].empathy = 0
	store.subjects[1].fear = 0
	local feedback_texts = {
		exit_fail = intl("tutorial.exit_fail"),
		exit_fail2 = intl("tutorial.exit_fail2"),
		exit_fail3 = intl("tutorial.exit_fail3"),
		exit_success = intl("tutorial.exit_success"),
		step2_q1 = intl("tutorial.step2_q1"),
		step2_q2 = intl("tutorial.step2_q2"),
		step2_q3_a1 = intl("tutorial.step2_q3_a1"),
		step2_q3_a2 = intl("tutorial.step2_q3_a2"),
		step2_q4 = intl("tutorial.step2_q4"),
		step3_q1_a1 = intl("tutorial.step3_q1_a1"),
		step3_q2 = intl("tutorial.step3_q2"),
		step3_q3 = intl("tutorial.step3_q3"),
		step3_q4_a1 = intl("tutorial.step3_q4_a1"),
		step3_q4_a2 = intl("tutorial.step3_q4_a2"),
		step3_q5 = intl("tutorial.step3_q5"),
		step4_q1 = intl("tutorial.step4_q1")
	}

	dispatcher.dispatch("level_disable_controls")
	progression.wait(1)
	dispatcher.dispatch("level_enable_controls")
	level.set_tutor_text(intl("tutorial.tutor1"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor2"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor3"), true)
	level.highlight_object(level.CASEFILE)
	progression.wait_for_message("drawer_casefile_set_open", function (message_id, message)
		return message.value
	end)
	level.cancel_highlight()
	progression.wait_for_message("casefile_transition_state", function (message_id, message)
		return message.new_state == FullScreenPanel.CLOSED
	end)
	level.set_tutor_text(intl("tutorial.tutor4"), true)
	dispatcher.dispatch("level_intro_show")
	progression.wait_for_message("start_game")
	level.set_tutor_text(intl("tutorial.tutor5"), true)
	store.replace_page(1, "step1")
	level.refresh_questions()

	local h_level_event = hash("level_event")
	local h_tutorial_feedback = hash("tutorial_feedback")

	local function feedback_predicate(message_id, message)
		return message.event_id == h_tutorial_feedback
	end

	while true do
		level.highlight_object(level.FIRST_QUESTION)

		local feedback_key = progression.wait_for_message(h_level_event, feedback_predicate).args[1]

		level.cancel_highlight()
		level.set_tutor_text(nil)
		level.wait_for_next_click()

		if store.has_flag("completed_intro") then
			break
		end

		level.set_tutor_text(feedback_texts[feedback_key], true)
	end

	level.set_tutor_text(intl("tutorial.tutor6"))
	level.wait_for_next_click()
	store.replace_page(1, "root")
	level.refresh_questions()
	level.set_tutor_text(intl("tutorial.tutor7"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor8"))
	level.highlight_object(level.EMPATHY_METER)
	level.wait_for_next_click()
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor9"))
	level.highlight_object(level.FEAR_METER)
	level.wait_for_next_click()
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor10"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor11"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor12"))
	level.wait_for_next_click()
	dispatcher.dispatch("level_tutor_remove_advance")
	animate_tutor("tutor_explain")
	store.replace_page(1, "step2")
	level.refresh_questions()

	while true do
		local feedback_key = progression.wait_for_message(h_level_event, feedback_predicate).args[1]

		level.set_tutor_text(nil)
		level.wait_for_next_click()

		if store.subjects[1].empathy >= 4 then
			break
		end

		level.set_tutor_text(feedback_texts[feedback_key], true)
	end

	level.set_tutor_text(intl("tutorial.tutor13"))
	level.highlight_object(level.EMPATHY_METER)
	level.wait_for_next_click()
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor14"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor15"), true)
	animate_tutor("tutor_explain")
	store.replace_page(1, "step3")
	level.refresh_questions()

	while true do
		local feedback_key = progression.wait_for_message(h_level_event, feedback_predicate).args[1]

		level.set_tutor_text(nil)
		level.wait_for_next_click()

		if store.subjects[1].fear >= 4 then
			break
		end

		level.set_tutor_text(feedback_texts[feedback_key], true)
	end

	level.set_tutor_text(intl("tutorial.tutor16"))
	level.highlight_object(level.FEAR_METER)
	store.replace_page(1, "root")
	level.refresh_questions()
	level.wait_for_next_click()
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor17"))
	animate_tutor("tutor_secret")
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor18"), true)
	dispatcher.dispatch("level_skip_next_torture_enable")
	level.set_recorder_disabled(false)
	level.highlight_object(level.RECORDER)
	progression.wait_for_message("go_off_record")
	level.cancel_highlight()
	level.set_recorder_disabled(true)
	level.set_tutor_text(intl("tutorial.tutor19"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor20"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor21"))
	level.wait_for_next_click()
	level.set_tutor_text(nil)

	local saved_cruelty = stats.cruelty
	local saved_insanity = stats.insanity
	local saved_torture_damage = stats.total_torture_damage

	dispatcher.dispatch("level_set_tortures_enabled", {
		enabled = true
	})
	progression.wait_for_message("torture")
	progression.wait_for_message("torture")
	dispatcher.dispatch("level_set_tortures_enabled", {
		enabled = false
	})
	stats.set_cruelty(saved_cruelty)
	stats.set_insanity(saved_insanity)
	stats.set_total_torture_damage(saved_torture_damage)
	level.set_tutor_text(intl("tutorial.tutor22"), true)
	level.highlight_object(level.RECORDER)
	level.set_recorder_disabled(false)
	progression.wait_for_message("go_on_record")
	level.set_recorder_disabled(true)
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor23"))
	level.highlight_object(level.TIMER)
	level.wait_for_next_click()
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor24"))
	level.highlight_object(level.SUBJECT_SWITCHER)
	level.wait_for_next_click()
	level.cancel_highlight()
	level.set_tutor_text(intl("tutorial.tutor25"))
	level.wait_for_next_click()
	level.set_tutor_text(intl("tutorial.tutor26"))
	animate_tutor("tutor_explain")
	store.unset_flag("fear_questions")
	store.set_flag("accusable")
	store.replace_page(1, "step3")
	level.refresh_questions()

	while true do
		local feedback_key = progression.wait_for_message(h_level_event, feedback_predicate).args[1]

		level.set_tutor_text(nil)

		if feedback_key == "exit_fail3" then
			level.set_tutor_text(feedback_texts[feedback_key], true)
		else
			level.wait_for_next_click()

			if store.has_flag("exit_success") then
				store.unset_flag("exit_success")
				store.replace_page(1, "exit_fork")
				level.refresh_questions()
			end

			if store.has_flag("tutorial_won") then
				break
			end

			level.set_tutor_text(feedback_texts[feedback_key], true)
		end
	end

	level.set_tutor_text(intl("tutorial.tutor27"), true)
	store.fire_event("win", {
		"win"
	})
	level.refresh_questions()

	local result = scenes.wait_for_end_scene()

	save_file.set_global("won_episode0", true)

	if not variables.narrative then
		save_file.set_global("won_challenge_episode0", true)
	end

	return result
end
