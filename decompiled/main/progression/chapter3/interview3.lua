local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")
local stats = require("campaign.stats")
local variables = require("campaign.variables")
local Interview = require("lib.interview")
local interview2_data = require("main.progression.chapter3.interview3_data")
local intl = require("crit.intl")
local intl_campaign = intl.namespace("campaign")
intl = intl.namespace("interview3")
local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("tristan", "lisa")
		fui.wait(2)
		fui.show_character("tristan", "RIGHT", "normal")
		fui.wait(1)
		fui.text("tristan", nil, intl("81039c.interview3.02876a"))
		fui.text("tristan", "explain", intl("81039c.interview3.437347"))
		fui.text("tristan", "explain", intl("81039c.interview3.5f22bf"))
		fui.show_character("lisa", "LEFT", "default")
		fui.text("lisa", "interested", intl("81039c.interview3.a8f461"))
		fui.animate("tristan", "normal")
		fui.text("lisa", "phone_interested", intl("81039c.interview3.16afbd"))
		fui.unset("interview3_skip")

		local choice21 = fui.choose({
			intl("81039c.interview3.ae9403"),
			intl("81039c.interview3.2d5178"),
			intl("81039c.interview3.a609e6")
		})

		if choice21 == 1 then
			fui.var_decrement("press", 15)
			fui.var_decrement("authorities", 10)
			fui.var_increment("lawful", 1)
			fui.var_increment("justice", 1)
			fui.animate("tristan", "glasses")
			fui.animate("lisa", "turn_away")
			fui.set("interview3_skip")
		elseif choice21 == 2 then
			fui.var_decrement("press", 5)
			fui.var_decrement("authorities", 5)
			fui.var_increment("lawful", 1)
			fui.animate("tristan", "glasses")
			fui.animate("lisa", "turn_away")
			fui.set("interview3_skip")
		elseif choice21 == 3 then
			fui.var_increment("press", 5)
			fui.animate("tristan", "thumbs_up")
			fui.animate("lisa", "smile")
		end

		fui.wait(1)
	end
end()
local pre_interlude = scenes.skippable(function ()
	func(fui.new())
end)
local interview = scenes.skippable(function ()
	interludes.hide_all_characters()

	if variables.interview3_skip then
		return
	end

	progression.wait(1)
	interludes.preload_characters({
		"lisa2"
	})
	interludes.show_character("lisa2", interludes.INTERVIEW, {
		nametag = intl_campaign("interlude.nametag.lisa")
	})
	interludes.animate_character("lisa2", "lisa2_leaning_back", true)
	progression.wait(1)

	local interview = Interview.new(interview2_data, "a1")

	while true do
		local question = interview:get_current_question()

		if not question then
			break
		end

		interludes.animate_character("lisa2", "lisa2_" .. question.animation)

		local idle_timeout = progression.fork(function ()
			progression.wait(8)
			interludes.animate_character("lisa2", "lisa2_" .. question.idle_animation)
		end)
		local texts = interview:get_texts(question.text, question)

		for i, text in ipairs(texts) do
			if i ~= 1 then
				interludes.wait_for_input()
			end

			interludes.show_bubble("lisa2", intl(text))
		end

		local answers = interview:get_answers()
		local choice = interludes.show_choices(answers, function (answer)
			return intl(answer.text)
		end)

		progression.cancel(idle_timeout)

		local answer = answers[choice]

		interview:pick_answer(answers[choice])
		interludes.animate_character("lisa2", "lisa2_" .. answer.animation)

		local replies = interview:get_texts(answer.reply, question, answer)

		if replies and replies[1] then
			for i = 1, #replies do
				interludes.show_bubble("lisa2", intl(replies[i]))
				interludes.wait_for_input()
			end
		else
			interludes.hide_bubbles()
			progression.wait(2)
		end
	end

	stats.commit("interview")
	interludes.hide_all_characters()
	progression.wait(2)
end)

return function ()
	pre_interlude()
	interview()
end
