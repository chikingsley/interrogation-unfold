local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")

return function (opts)
	opts = opts or {}

	scenes.load_scene("interludes", {
		background = opts.background or "office_floor"
	})
	interludes.preload_characters({
		"chief",
		"mordecai",
		"tab",
		"jen"
	})
	interludes.wait_for_input()
	interludes.show_character("chief", interludes.RIGHT, {
		nametag = "Chief Anderson"
	})
	interludes.show_character("mordecai", interludes.CENTER_LEFT, {
		nametag = "Mordecai"
	})
	interludes.show_character("tab", interludes.LEFT_CENTER, {
		nametag = "Tab"
	})
	interludes.show_character("jen", interludes.LEFT, {
		nametag = "Jenniffer"
	})
	interludes.show_bubble("chief", "Between Ennis, Wilson's testimony, Adams, the details from Novak, and now Higgs and Romano, we've gathered lots of insights and are finally getting the critical mass to tie more of the leads together.")
	interludes.wait_for_input()

	local choice = interludes.show_choices({
		"I don't trust algorithms. Jennifer, look at their conversations and try to figure out what they've been talking about.",
		"Codes may be deceiving to the naked eye. Let the algorithms do the work. Tell me what pops up.",
		"Do both. Set up the algorithms and also try to figure things out manually."
	})

	interludes.show_bubble("chief", "Hello, world")
	interludes.wait_for_input()
	interludes.show_bubble("mordecai", "Mordecai Ennis, Wilson's testimony, Adams, the details from Novak, and now Higgs and Romano, we've gathered lots of insights and are finally getting the critical mass to tie more of the leads together.")
	interludes.wait_for_input()
	interludes.show_bubble("tab", "Between Ennis, Wilson's testimony, Adams, the details from Novak, and now Higgs and Romano, we've gathered lots of insights and are finally getting the critical mass to tie more of the leads together.")
	interludes.wait_for_input()
	interludes.show_bubble("jen", "Between Ennis, Wilson's testimony, Adams, the details from Novak, and now Higgs and Romano, we've gathered lots of insights and are finally getting the critical mass to tie more of the leads together.")
	interludes.wait_for_input()
	interludes.hide_all_characters()
	interludes.wait_for_input()
	interludes.hide_bubbles()
	interludes.wait_for_input()
	interludes.hide_all_characters()
end
