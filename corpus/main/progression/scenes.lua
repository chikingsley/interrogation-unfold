local dispatcher = require("crit.dispatcher")
local progression = require("crit.progression")
local h_load_scene = hash("load_scene")
local h_preload_scene = hash("preload_scene")
local h_end_scene = hash("end_scene")
local h_run_progression = hash("run_progression")
local h_skip_progression = hash("skip_progression")
local h_zoom = hash("zoom")
local M = {
	first_transition = true
}

function M.run_skippable(f)
	local work_thread = progression.fork(f)

	progression.fork(function ()
		local message = progression.wait_for_message(h_skip_progression)

		if not message.keep_transition then
			M.first_transition = true
		end

		progression.cancel(work_thread)
	end)
	progression.join(work_thread)
end

function M.skippable(f)
	return function ()
		M.run_skippable(f)
	end
end

function M.load_scene(scene, options, transition_options)
	transition_options = transition_options or {}
	local transition = transition_options.transition

	if transition == nil then
		transition = h_zoom or transition
	end

	if M.first_transition then
		transition = false
		M.first_transition = false
	end

	transition_options.transition = transition and hash(transition) or false

	dispatcher.dispatch(h_load_scene, {
		scene = scene,
		options = options,
		transition_options = transition_options
	})
	progression.wait_for_message("show_" .. scene)
end

function M.preload_scene(scene, options)
	dispatcher.dispatch(h_preload_scene, {
		scene = scene,
		options = options
	})
	progression.wait_for_message("init_" .. scene)
end

function M.wait_for_end_scene()
	return progression.wait_for_message(h_end_scene)
end

function M.run_progression(progression_id, options)
	dispatcher.dispatch(h_run_progression, {
		id = progression_id,
		options = options
	})
end

return M
