local progression = require("crit.progression")
local dispatcher = require("crit.dispatcher")
local h_interludes_preload_characters = hash("interludes_preload_characters")
local h_interludes_show_character = hash("interludes_show_character")
local h_interludes_hide_character = hash("interludes_hide_character")
local h_interludes_set_nametag = hash("interludes_set_nametag")
local h_interludes_animate_character = hash("interludes_animate_character")
local h_interludes_show_bubble = hash("interludes_show_bubble")
local h_interludes_hide_bubbles = hash("interludes_hide_bubbles")
local h_interludes_show_choices = hash("interludes_show_choices")
local h_interludes_choice_picked = hash("interludes_choice_picked")
local h_interludes_advance = hash("interludes_advance")
local h_interludes_hide_all_characters = hash("interludes_hide_all_characters")
local h_interludes_wait_for_advance = hash("interludes_wait_for_advance")
local h_play_sfx_advance = hash("play_sfx_advance")
local interludes = {
	CENTER_RIGHT = 6,
	INTERVIEW = 7,
	CENTER_LEFT = 5,
	ELIAS = 9,
	CHIEF = 8,
	RIGHT = 2,
	RIGHT_CENTER = 4,
	LEFT_CENTER = 3,
	LEFT = 1,
	advance = function ()
		dispatcher.dispatch(h_interludes_advance)
	end,
	preload_characters = function (characters)
		for k, v in ipairs(characters) do
			characters[k] = hash(v)
		end

		dispatcher.dispatch(h_interludes_preload_characters, {
			characters = characters
		})
		progression.wait(0)
		progression.wait(0)
	end,
	show_character = function (character, slot, options)
		options = options or {}

		dispatcher.dispatch(h_interludes_show_character, {
			character = character,
			slot = slot,
			options = options
		})
	end,
	hide_character = function (character)
		dispatcher.dispatch(h_interludes_hide_character, {
			character = character
		})
	end,
	set_name_tag = function (character, nametag, unstyled)
		dispatcher.dispatch(h_interludes_set_nametag, {
			character = character,
			nametag = nametag,
			unstyled = unstyled
		})
	end,
	animate_character = function (character, animation, instant, flipped)
		dispatcher.dispatch(h_interludes_animate_character, {
			character = character,
			animation = hash(animation),
			instant = instant,
			flipped = flipped
		})
	end,
	hide_all_characters = function ()
		dispatcher.dispatch(h_interludes_hide_all_characters)
	end,
	show_bubble = function (character, message)
		dispatcher.dispatch(h_interludes_show_bubble, {
			character = character,
			text = message
		})
	end,
	hide_bubbles = function ()
		dispatcher.dispatch(h_interludes_hide_bubbles)
	end,
	show_choices = function (choices, choice_get_text)
		local choices_table = choices

		if choice_get_text then
			choices_table = {}

			for i, choice in ipairs(choices) do
				choices_table[i] = choice_get_text(choice, i)
			end
		end

		dispatcher.dispatch(h_interludes_show_choices, {
			choices = choices_table
		})

		return progression.wait_for_message(h_interludes_choice_picked).choice
	end,
	wait_for_input = function ()
		dispatcher.dispatch(h_interludes_wait_for_advance)
		progression.wait_for_message(h_interludes_advance)
		dispatcher.dispatch(h_play_sfx_advance)
	end
}

return interludes
