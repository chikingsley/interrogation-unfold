local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")
local stats = require("campaign.stats")
local variables = require("campaign.variables")
local Interview = require("lib.interview")
local interview2_data = require("main.progression.chapter2.interview2_data")
local intl = require("crit.intl")
local intl_campaign = intl.namespace("campaign")
intl = intl.namespace("interview2")
local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		fui.load_interlude("office_floor")
		fui.load_characters("tristan", "patricia")
		fui.wait(2)
		fui.show_character("tristan", "LEFT", "normal")
		fui.wait(1)
		fui.text("tristan", nil, intl("80035d.interview2.944751"))
		fui.text("tristan", "explain", intl("80035d.interview2.a7073f"))
		fui.show_character("patricia", "RIGHT", "normal")
		fui.text("patricia", "normal", intl("80035d.interview2.cf6365"))
		fui.animate("tristan", "normal")
		fui.text("patricia", "smile", intl("80035d.interview2.95b5d6"))
		fui.animate("tristan", "normal")
		fui.text("patricia", "asking_neutral", intl("80035d.interview2.d9d6dd"))
		fui.animate("tristan", "normal")
		fui.wait_for_input()
		fui.unset("interview2_skip")

		local choice24 = fui.choose({
			intl("80035d.interview2.8cf665"),
			intl("80035d.interview2.60ca63"),
			intl("80035d.interview2.3fa105")
		})

		if choice24 == 1 then
			fui.var_decrement("press", 15)
			fui.var_decrement("authorities", 5)
			fui.animate("tristan", "glasses")
			fui.animate("patricia", "disapproving")
			fui.set("interview2_skip")
		elseif choice24 == 2 then
			fui.var_decrement("press", 5)
			fui.var_increment("justice", 1)
			fui.animate("tristan", "glasses")
			fui.animate("patricia", "disapproving")
		elseif choice24 == 3 then
			fui.var_increment("press", 5)
			fui.animate("tristan", "normal")
			fui.animate("patricia", "asking_neutral")
		end

		fui.wait(1)
	end
end()
local pre_interlude = scenes.skippable(function ()
	func(fui.new())
end)
local interview = scenes.skippable(function ()
	interludes.hide_all_characters()

	if variables.interview2_skip then
		return
	end

	progression.wait(1)
	interludes.preload_characters({
		"patricia2"
	})
	interludes.show_character("patricia2", interludes.INTERVIEW, {
		nametag = intl_campaign("interlude.nametag.patricia")
	})
	interludes.animate_character("patricia2", "patricia2_default", true)
	progression.wait(1)

	local interview = Interview.new(interview2_data, "a1")

	while true do
		local question = interview:get_current_question()

		if not question then
			break
		end

		interludes.animate_character("patricia2", "patricia2_" .. question.animation)

		local idle_timeout = progression.fork(function ()
			progression.wait(8)
			interludes.animate_character("patricia2", "patricia2_" .. question.idle_animation)
		end)
		local texts = interview:get_texts(question.text, question)

		for i, text in ipairs(texts) do
			if i ~= 1 then
				interludes.wait_for_input()
			end

			interludes.show_bubble("patricia2", intl(text))
		end

		local answers = interview:get_answers()
		local choice = interludes.show_choices(answers, function (answer)
			return intl(answer.text)
		end)

		progression.cancel(idle_timeout)

		local answer = answers[choice]

		interview:pick_answer(answers[choice])
		interludes.animate_character("patricia2", "patricia2_" .. answer.animation)

		local replies = interview:get_texts(answer.reply, question, answer)

		if replies and replies[1] then
			for i = 1, #replies do
				interludes.show_bubble("patricia2", intl(replies[i]))
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
