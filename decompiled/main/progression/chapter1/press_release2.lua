local press_release = require("press_release.press_release")
local scenes = require("main.progression.scenes")
local stats = require("campaign.stats")
local variables = require("campaign.variables")
local intl = require("crit.intl")
local intl_campaign = intl.namespace("campaign")
intl = intl.namespace("chapter1")

return scenes.skippable(function ()
	press_release.header_text = ""
	press_release.options = {
		a = {
			intl("press_release2.option_a1"),
			intl("press_release2.option_a2")
		},
		b = {
			intl_campaign("press_release.squad_name.1"),
			intl_campaign("press_release.squad_name.2"),
			intl_campaign("press_release.squad_name.3")
		},
		c = {
			intl("press_release2.option_c1"),
			intl("press_release2.option_c2")
		},
		d = {
			intl("press_release2.option_d1"),
			intl("press_release2.option_d2")
		},
		e = {
			intl("press_release2.option_e1"),
			intl("press_release2.option_e2")
		}
	}
	press_release.text = {
		intl("press_release2.text1"),
		{
			id = "a"
		},
		intl("press_release2.text2"),
		{
			id = "b"
		},
		intl("press_release2.text3"),
		press_release.PARAGRAPH_BREAK,
		intl("press_release2.text4"),
		{
			id = "c"
		},
		intl("press_release2.text5"),
		{
			id = "d"
		},
		intl("press_release2.text6"),
		press_release.PARAGRAPH_BREAK,
		intl("press_release2.text7"),
		{
			id = "e"
		},
		intl("press_release2.text8")
	}

	press_release.init()
	scenes.load_scene("press_release")
	scenes.wait_for_end_scene()

	local choice_a = press_release.get_selected_option("a")
	local choice_b = press_release.get_selected_option("b")
	local choice_c = press_release.get_selected_option("c")
	local choice_d = press_release.get_selected_option("d")
	local choice_e = press_release.get_selected_option("e")

	if choice_a == 1 then
		stats.increment_authorities(-5)
		stats.increment_press(5)
		stats.increment_freedom(1)
		stats.increment_evolution(1)
		stats.increment_equity(1)
	elseif choice_a == 2 then
		stats.increment_authorities(5)
	end

	variables.squad_name = choice_b

	if choice_b == 1 then
		stats.increment_authorities(-5)
		stats.increment_popularity(5)
		stats.increment_equity(1)
		stats.increment_freedom(1)
	elseif choice_b == 2 then
		stats.increment_authorities(-5)
		stats.increment_press(-5)
		stats.increment_popularity(5)
		stats.increment_justice(1)
	elseif choice_b == 3 then
		stats.increment_authorities(5)
		stats.increment_popularity(-5)
		stats.increment_lawful(1)
	end

	if choice_c == 1 then
		stats.increment_authorities(-5)
		stats.increment_popularity(5)
		stats.increment_freedom(1)
		stats.increment_evolution(1)
		stats.increment_equity(1)
	end

	if choice_d == 1 then
		stats.increment_freedom(1)
	elseif choice_d == 2 then
		stats.increment_popularity(-5)
		stats.increment_lawful(1)
	end

	if choice_e == 2 then
		stats.increment_authorities(-10)
		stats.increment_press(5)
		stats.increment_freedom(1)
		stats.increment_evolution(1)
		stats.increment_equity(1)
	end

	stats.commit("press_release")
end)
