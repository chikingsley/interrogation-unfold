local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local env = require("lib.environment")
local save_file = require("lib.save_file")
local pause_menu = require("main.pause_menu.pause_menu")
local campaign = require("main.progression.campaign")
local single_level = require("main.progression.single_level")
local test_perks = require("campaign.office.perks.test_progression")
local test_interludes = require("interludes.test_progression")
local test_selection = require("interludes.selection.test_selection")
local test_interview = require("interludes.test_interview")
local test_campaign = require("campaign.test_progression")
local test_press_release = require("press_release.test_progression")
local test_level = require("level.test_progression")
local test_outcome = require("outcome.test_outcome")
local test_cutscene1 = require("spine_cutscene.cutscene1.test_progression")
local test_cutscene2 = require("spine_cutscene.cutscene_final.test_progression")
local test_cutscene3 = require("spine_cutscene.cutscene_intro.test_progression")
local test_jigsaw = require("campaign.minigames.jigsaw.test_progression")
local test_episode8 = require("main.progression.chapter3.test_episode8")
local cutscene_intro = require("main.progression.cutscene_intro")
local test_elias = require("interludes.test_elias")
local fuior_progression = require("main.fuior.progression")
local lose_fired = require("main.progression.triggered.lose_fired")
local lose_assassinated = require("main.progression.triggered.lose_assassinated")
local demo_cta = require("main.progression.demo_cta")
local h_run_progression = hash("run_progression")
local splash = scenes.skippable(function ()
	scenes.load_scene("splash_logos")
	scenes.wait_for_end_scene()
	scenes.load_scene("splash_audio", nil, {
		no_zoom_in = true,
		out_duration = 1,
		transition = hash("fade")
	})

	local end_scene_child = progression.fork(function ()
		scenes.wait_for_end_scene()
	end)
	local should_wait_for_preload_to_end = false
	local preload_end_child = progression.fork(function ()
		progression.wait_for_message("spine_cutscene_preload_end")
	end)
	local child = progression.fork(function ()
		progression.wait_for_message("scene_transition_end")

		should_wait_for_preload_to_end = true

		scenes.preload_scene("spine_cutscene", {
			preload = true,
			cutscene = "cutscene_intro"
		})
	end)

	progression.join(end_scene_child)
	progression.cancel(child)

	if should_wait_for_preload_to_end then
		progression.join(preload_end_child)
	else
		progression.cancel(preload_end_child)
	end
end)
local progressions = {
	main = function ()
		if env.entry_scene then
			scenes.load_scene(env.entry_scene.scene, env.entry_scene.options)
			scenes.wait_for_end_scene()
		end

		if not env.skip_intro then
			pause_menu.with_blocked_pause_menu(splash)()
		end

		if env.bundled and not env.debug and not save_file.get_current_profile().get().history.latest then
			campaign()
		else
			if not env.skip_intro then
				pause_menu.with_blocked_pause_menu(cutscene_intro)()
			end

			scenes.load_scene("menu")
		end
	end,
	menu = function ()
		scenes.load_scene("menu")
	end,
	campaign = campaign,
	single_level = single_level,
	test_perks = test_perks,
	test_interludes = test_interludes,
	test_campaign = test_campaign,
	test_press_release = test_press_release,
	test_interview = test_interview,
	test_selection = test_selection,
	test_level = test_level,
	test_outcome = test_outcome,
	test_cutscene1 = test_cutscene1,
	test_cutscene2 = test_cutscene2,
	test_cutscene3 = test_cutscene3,
	test_jigsaw = test_jigsaw,
	test_episode8 = test_episode8,
	fuior = fuior_progression,
	test_elias = test_elias,
	lose_fired = lose_fired,
	lose_assassinated = lose_assassinated,
	demo_cta = demo_cta
}

local function run_progression(progression_id, ...)
	local coroutine_function = nil

	if type(progression_id) == "function" then
		coroutine_function = progression_id
	else
		coroutine_function = progressions[progression_id]
	end

	if not coroutine_function then
		print("ERROR: There is no progression with id \"" .. progression_id .. "\"")

		return
	end

	return progression.detach(coroutine_function, ...)
end

local function entry_point()
	local co = run_progression(env.entry_progression or "main", env.entry_progression_arg)

	while true do
		local message = progression.wait_for_message(h_run_progression)

		progression.cancel(co)

		co = run_progression(message.id, message.options)
	end
end

progression.init_register_function(entry_point)
