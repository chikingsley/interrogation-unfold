local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")
local Interview = require("lib.interview")

return function ()
	scenes.load_scene("interludes")
	interludes.preload_characters({
		"michael",
		"jen"
	})
	interludes.wait_for_input()
	interludes.show_character("jen", interludes.INTERVIEW)
	interludes.animate_character("jen", "jen_1")
	interludes.wait_for_input()

	local interview = Interview.new({
		root = {
			text = "Are you a cat person or a dog person?",
			animation = "jen_3",
			answers = {
				{
					text = "I have a cat.",
					next = "love",
					effect = function (state)
						state.owns_cat = true
					end
				},
				{
					text = "I own a dog.",
					next = "love",
					effect = function (state)
						state.owns_dog = true
					end
				},
				{
					text = "I have a pet iguana named Gloria!",
					next = "love"
				}
			}
		},
		love = {
			text = "Oh! Me too! Don't you just love them? They're so cute!",
			animation = "jen_2",
			answers = {
				{
					text = "Yeah! Mr. Gibbons is my life!",
					condition = function (state)
						return state.owns_cat
					end
				},
				{
					text = "And smart, too! Spot learned how to open doors at 3 months of age.",
					condition = function (state)
						return state.owns_dog
					end
				},
				{
					text = "Oh! She's a charmer!",
					condition = function (state)
						return not state.owns_cat and not state.owns_dog
					end
				},
				{
					text = "Yeah, but they can get a bit annoying at times."
				}
			}
		}
	})

	while true do
		local question = interview:get_current_question()

		if not question then
			break
		end

		interludes.show_bubble("jen", question.text)

		local answers = interview:get_answers()
		local choice = interludes.show_choices(answers, function (answer)
			return answer.text
		end)

		interview:pick_answer(answers[choice])
	end

	interludes.hide_all_characters()
end
