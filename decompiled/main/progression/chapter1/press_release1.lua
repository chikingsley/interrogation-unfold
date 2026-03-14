local press_release = require("press_release.press_release")
local scenes = require("main.progression.scenes")
local stats = require("campaign.stats")
local intl = require("crit.intl")
intl = intl.namespace("chapter1")

return scenes.skippable(function ()
	press_release.header_text = ""
	press_release.options = {
		a = {
			intl("press_release1.option_a1"),
			underlines = 34,
			intl("press_release1.option_a2")
		},
		b = {
			intl("press_release1.option_b1"),
			intl("press_release1.option_b2"),
			underlines = 21,
			intl("press_release1.option_b3")
		},
		c = {
			intl("press_release1.option_c1"),
			underlines = 15,
			intl("press_release1.option_c2")
		},
		d = {
			intl("press_release1.option_d1"),
			underlines = 102,
			intl("press_release1.option_d2")
		}
	}
	press_release.text = {
		intl("press_release1.text1"),
		{
			id = "a"
		},
		intl("press_release1.text2"),
		press_release.PARAGRAPH_BREAK,
		intl("press_release1.text3"),
		{
			id = "b"
		},
		intl("press_release1.text4"),
		{
			id = "c"
		},
		intl("press_release1.text5"),
		press_release.PARAGRAPH_BREAK,
		intl("press_release1.text6"),
		{
			id = "d"
		}
	}

	press_release.init()
	scenes.load_scene("press_release")
	scenes.wait_for_end_scene()

	local choice_a = press_release.get_selected_option("a")
	local choice_b = press_release.get_selected_option("b")
	local choice_c = press_release.get_selected_option("c")
	local choice_d = press_release.get_selected_option("d")

	if choice_a == 1 then
		stats.increment_authorities(5)
		stats.increment_lawful(1)
	elseif choice_a == 2 then
		stats.increment_authorities(-5)
		stats.increment_popularity(5)
		stats.increment_justice(1)
	end

	if choice_b == 1 then
		stats.increment_authorities(-5)
		stats.increment_popularity(5)
	elseif choice_b == 2 then
		stats.increment_authorities(-5)
		stats.increment_evolution(1)
	elseif choice_b == 3 then
		stats.increment_press(5)
		stats.increment_freedom(1)
	end

	if choice_c == 1 then
		stats.increment_press(-5)
		stats.increment_popularity(-5)
		stats.increment_authorities(5)
		stats.increment_freedom(1)
	end

	if choice_d == 1 then
		stats.increment_press(-5)
		stats.increment_popularity(5)
		stats.increment_justice(1)
		stats.increment_lawful(1)
	elseif choice_d == 2 then
		stats.increment_press(5)
		stats.increment_popularity(-5)
		stats.increment_freedom(1)
	end

	stats.commit("press_release")
end)
