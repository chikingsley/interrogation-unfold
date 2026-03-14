local press_release = require("press_release.press_release")
local scenes = require("main.progression.scenes")
local stats = require("campaign.stats")
local get_squad_name = require("main.progression.squad_name")
local intl = require("crit.intl")
intl = intl.namespace("chapter3")

return scenes.skippable(function ()
	press_release.header_text = ""
	press_release.options = {
		a = {
			intl("press_release7.option_a1"),
			intl("press_release7.option_a2")
		},
		b = {
			intl("press_release7.option_b1"),
			intl("press_release7.option_b2"),
			intl("press_release7.option_b3", {
				squad_name = get_squad_name()
			})
		},
		c = {
			intl("press_release7.option_c1"),
			intl("press_release7.option_c2"),
			intl("press_release7.option_c3")
		},
		d = {
			intl("press_release7.option_d1"),
			intl("press_release7.option_d2"),
			intl("press_release7.option_d3")
		},
		e = {
			intl("press_release7.option_e1"),
			intl("press_release7.option_e2")
		},
		f = {
			intl("press_release7.option_f1"),
			intl("press_release7.option_f2"),
			intl("press_release7.option_f3")
		}
	}
	press_release.text = {
		intl("press_release7.text1"),
		{
			id = "a"
		},
		intl("press_release7.text2"),
		{
			id = "b"
		},
		intl("press_release7.text3"),
		press_release.PARAGRAPH_BREAK,
		intl("press_release7.text4"),
		{
			id = "c"
		},
		intl("press_release7.text5"),
		{
			id = "d"
		},
		intl("press_release7.text6"),
		{
			id = "e"
		},
		intl("press_release7.text7"),
		press_release.PARAGRAPH_BREAK,
		intl("press_release7.text8"),
		{
			id = "f"
		}
	}

	press_release.init()
	scenes.load_scene("press_release")
	scenes.wait_for_end_scene()

	local choice_a = press_release.get_selected_option("a")
	local choice_b = press_release.get_selected_option("b")
	local choice_c = press_release.get_selected_option("c")
	local choice_d = press_release.get_selected_option("d")
	local choice_e = press_release.get_selected_option("e")
	local choice_f = press_release.get_selected_option("f")

	if choice_a == 1 then
		stats.increment_popularity(-5)
	elseif choice_a == 2 then
		stats.increment_authorities(-5)
		stats.increment_lawful(1)
	end

	if choice_b == 1 then
		stats.increment_authorities(-5)
	elseif choice_b == 2 then
		stats.increment_popularity(-5)
	elseif choice_b == 3 then
		stats.increment_press(-5)
		stats.increment_justice(1)
	end

	if choice_c == 1 then
		stats.increment_press(-5)
		stats.increment_justice(1)
	elseif choice_c == 2 then
		stats.increment_press(-5)
		stats.increment_equity(1)
	elseif choice_c == 3 then
		stats.increment_popularity(-5)
		stats.increment_lawful(1)
	end

	if choice_d == 1 then
		stats.increment_press(-5)
		stats.increment_lawful(1)
	elseif choice_d == 2 then
		stats.increment_authorities(-5)
		stats.increment_freedom(1)
	elseif choice_d == 3 then
		stats.increment_authorities(-5)
	end

	if choice_e == 1 then
		stats.increment_press(-5)
	elseif choice_e == 2 then
		stats.increment_popularity(-5)
	end

	if choice_f == 1 then
		stats.increment_press(-5)
		stats.increment_freedom(1)
	elseif choice_f == 2 then
		stats.increment_press(-5)
		stats.increment_popularity(-5)
		stats.increment_justice(1)
	elseif choice_f == 3 then
		stats.increment_authorities(-5)
		stats.increment_press(5)
		stats.increment_lawful(1)
	end

	stats.commit("press_release")
end)
