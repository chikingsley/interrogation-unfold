local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local episode = require("main.progression.episode")
local dispatcher = require("crit.dispatcher")
local interludes = require("interludes.interface")
local intl = require("crit.intl")
local Interview = require("lib.interview")
local episode8_data = require("main.progression.chapter3.episode8_data")
local sound_util = require("sound.util")
local variables = require("campaign.variables")
local save_file = require("lib.save_file")
intl = intl.namespace("episode8")
local h_end_scene = hash("end_scene")
local h_game_over = hash("game_over")
local h_episode8_init = hash("episode8_init")
local h_start_game = hash("start_game")
local h_interrogation_room_animation_complete = hash("interrogation_room_animation_complete")

local function show_bubble(text, emote)
	emote = emote and intl(emote)
	emote = emote and "<i>" .. emote .. "</i>"

	interludes.set_name_tag("elias", emote or "", true)
	interludes.show_bubble("elias", text and intl(text) or "")
end

local animation_delays = {
	idle4_cut = 2,
	idle3_grab = 2
}
local health_loss_animations = {
	idle4_cut = 3,
	idle3_grab = 1
}

local function animate_elias(animation)
	interludes.animate_character("elias", "elias_" .. animation)

	local delay = animation_delays[animation]

	if delay then
		progression.wait(delay)
	end
end

local episode8 = scenes.skippable(function ()
	scenes.load_scene("interludes", {
		background = "interrogation_room"
	})
	progression.wait_for_message(h_interrogation_room_animation_complete)
	progression.wait(0.7)
	interludes.show_character("elias", interludes.INTERVIEW, {
		animate_movement = false,
		nametag = ""
	})
	dispatcher.dispatch(h_episode8_init)
	progression.wait(0)
	progression.wait(0)
	progression.wait(0)
	progression.wait(2)
	dispatcher.dispatch(h_start_game)

	local interview = Interview.new(episode8_data, "1a", {
		anger = 0,
		suspicion = 0,
		health = variables.narrative and 13 or 10
	})

	while true do
		local question = interview:get_current_question()

		if not question then
			break
		end

		if question.animation then
			animate_elias(question.animation)
		end

		local texts = interview:get_texts(question.text, question)
		local emotes = interview:get_texts(question.emote, question)

		if texts[1] then
			show_bubble(texts[1], emotes and emotes[1])
		end

		for i = 2, #texts do
			interludes.wait_for_input()
			show_bubble(texts[i], emotes and emotes[i])
		end

		local answers = interview:get_answers()
		local hp_lost = question.animation and health_loss_animations[question.animation] or 0

		if interview.state.health <= hp_lost then
			local function lose_hp(state)
				state.health = (state.health or 0) - hp_lost
			end

			answers = {
				{
					text = "episode8.death.1",
					next = "lose_health",
					effect = lose_hp
				},
				{
					text = "episode8.death.2",
					next = "lose_health",
					effect = lose_hp
				},
				{
					text = "episode8.death.3",
					next = "lose_health",
					effect = lose_hp
				}
			}
		end

		local choice = interludes.show_choices(answers, function (answer)
			return intl(answer.text)
		end)
		local answer = answers[choice]

		interview:pick_answer(answers[choice])

		if answer.animation then
			animate_elias(answer.animation)
		end

		local replies = interview:get_texts(answer.reply, question, answer)

		if replies and replies[1] and interview.state.health > 0 then
			local reply_emotes = interview:get_texts(answer.reply_emote, question, answer) or {}

			for i = 1, #replies do
				show_bubble(replies[i], reply_emotes[i])
				interludes.wait_for_input()
			end
		else
			interludes.hide_bubbles()
			progression.wait(2)
		end
	end

	interludes.hide_bubbles()

	local reason = interview.current_question_id or "null"

	dispatcher.dispatch(h_end_scene, {
		has_won = reason == "win",
		reason = reason
	})
end)

return episode.create_episode({
	level = "episode8",
	custom_level = function ()
		progression.fork(function ()
			local episode_thread = progression.fork(episode8)
			local game_over_thread = progression.fork(function ()
				local message = progression.wait_for_message(h_game_over)

				progression.cancel(episode_thread)
				dispatcher.dispatch(h_end_scene, message)
			end)

			progression.join(episode_thread)
			progression.cancel(game_over_thread)
		end)
	end,
	outcome_lose = function (reason)
		sound_util.set_music("event:/Campaign Music/Lose Theme", "All Campaign.bank", {
			slow_fade_in = true
		})

		local outcome_options = {
			outcome_id = "elias_hall",
			has_won = false,
			header_key = "outcome.lose",
			text_key = "outcome.episode8.lose",
			intl_namespace = "chapter3"
		}
		local transition_options = nil

		if reason == "lose_health" or reason == "death" then
			outcome_options = {
				outcome_id = "blank_retry",
				has_won = false
			}
			transition_options = {
				in_duration = 3,
				out_duration = 2,
				transition = hash("fade"),
				fade_color = vmath.vector4(0.4, 0.04, 0.04, 1)
			}
		end

		if reason == "lose_suspended" then
			save_file.set_global("lose_fired", true)
		end

		scenes.load_scene("outcome", outcome_options, transition_options)
		scenes.wait_for_end_scene()
	end,
	outcome_win = {
		outcome_id = "elias_hall",
		has_won = true,
		header_key = "outcome.win",
		text_key = "outcome.episode8.win",
		intl_namespace = "chapter3"
	}
})
