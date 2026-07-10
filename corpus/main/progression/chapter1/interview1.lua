local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")
local stats = require("campaign.stats")
local Interview = require("lib.interview")
local interview1_data = require("main.progression.chapter1.interview1_data")
local commentary = require("main.progression.commentary.index")
local intl = require("crit.intl")
local intl_campaign = intl.namespace("campaign")
intl = intl.namespace("interview1")
local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("chief", "eddie", "eddie2")
		fui.wait(2)
		fui.show_character("chief", "LEFT", "normal")
		fui.wait(1)
		fui.text("chief", nil, intl("7f031e.interview1.1b4964"))
		fui.text("chief", "asking", intl("7f031e.interview1.b157e8"))
		fui.show_character("eddie", "RIGHT", "bye")
		fui.text("eddie", "skeptical", intl("7f031e.interview1.d483c6"))
		fui.animate("chief", "normal")
		fui.text("eddie", "writing_interested", intl("7f031e.interview1.a73403"))
		fui.text("chief", nil, intl("7f031e.interview1.bcc4ea"))
		fui.wait_for_input()
		fui.hide_character("chief")

		local choice22 = fui.choose({
			intl("7f031e.interview1.4411b2"),
			intl("7f031e.interview1.dc66e1"),
			intl("7f031e.interview1.586730")
		})

		if choice22 == 1 then
			fui.var_decrement("press", 5)
			fui.animate("chief", "thinking")
			fui.animate("eddie", "dunno")
		elseif choice22 == 2 then
			fui.var_increment("press", 5)
			fui.var_increment("lawful", 1)
			fui.animate("chief", "normal")
			fui.animate("eddie", "thinking")
		elseif choice22 == 3 then
			fui.var_increment("press", 5)
			fui.var_increment("authorities", 5)
			fui.var_decrement("jen_approval", 5)
			fui.var_decrement("tab_approval", 5)
			fui.animate("chief", "normal")
			fui.animate("eddie", "writing_interested")
		end

		fui.wait(1)
	end
end()
local pre_interlude = scenes.skippable(function ()
	func(fui.new())
end)
local interview = scenes.skippable(function ()
	interludes.hide_all_characters()
	progression.wait(1)
	interludes.preload_characters({
		"eddie2"
	})
	interludes.show_character("eddie2", interludes.INTERVIEW, {
		nametag = intl_campaign("interlude.nametag.eddie")
	})
	interludes.animate_character("eddie2", "eddie2_default", true)
	progression.wait(1)

	local interview = Interview.new(interview1_data, "a1")

	while true do
		local question = interview:get_current_question()

		if not question then
			break
		end

		interludes.animate_character("eddie2", "eddie2_" .. question.animation)

		local idle_timeout = progression.fork(function ()
			progression.wait(8)
			interludes.animate_character("eddie2", "eddie2_" .. question.idle_animation)
		end)
		local texts = interview:get_texts(question.text, question)

		for i, text in ipairs(texts) do
			if i ~= 1 then
				interludes.wait_for_input()
			end

			interludes.show_bubble("eddie2", intl(text))
		end

		local answers = interview:get_answers()
		local choice = interludes.show_choices(answers, function (answer)
			return intl(answer.text)
		end)

		progression.cancel(idle_timeout)
		commentary.interview.overlay_once()

		local answer = answers[choice]

		interview:pick_answer(answers[choice])
		interludes.animate_character("eddie2", "eddie2_" .. answer.animation)

		local replies = interview:get_texts(answer.reply, question, answer)

		if replies and replies[1] then
			for i = 1, #replies do
				interludes.show_bubble("eddie2", intl(replies[i]))
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
