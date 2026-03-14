local progression = require("crit.progression")
local scenes = require("main.progression.scenes")
local snapshot = require("campaign.snapshot")
local sound_util = require("sound.util")
local save_file = require("lib.save_file")
local table_util = require("crit.table_util")
local env = require("lib.environment")
local campaign_options = require("main.progression.campaign_options")
local campaign_main = progression.lazy_load_function("campaign_main")

local function campaign(opts)
	opts = opts or {}
	local opts_save_file = opts.save_file

	if opts_save_file == true then
		opts_save_file = campaign_options.save_file
	end

	local profile = nil
	profile = opts_save_file and save_file.get_memory_profile(opts_save_file) or opts.profile or save_file.get_current_profile()

	if opts.new_game then
		local profile_data = profile.get()
		profile_data.history = {}
		profile_data.checkpoints = {}

		profile.save(profile_data)
	end

	if opts.rewind then
		local profile_data = profile.get()
		local new_history = {}
		local new_checkpoints = {}

		for i = 1, opts.rewind do
			local checkpoint = profile_data.checkpoints[i]
			local snap = profile_data.history[checkpoint]
			new_checkpoints[i] = checkpoint
			new_history[checkpoint] = snap
			new_history.latest = snap
		end

		profile_data.history = new_history
		profile_data.checkpoints = new_checkpoints

		profile.save(profile_data)
	end

	local debug = env.debug or not env.bundled
	local rewind_stack = nil

	snapshot.reset()

	local profile_data = profile.get()
	local first_snap = profile_data.history[opts.checkpoint or "latest"]

	if opts.route then
		first_snap = first_snap and table_util.clone(first_snap) or {}
		first_snap.route = opts.route
	end

	if first_snap ~= profile_data.history.latest then
		profile_data.history.latest = first_snap

		profile.save(profile_data)
	end

	if debug then
		rewind_stack = {
			snap = first_snap
		}
	end

	local function save_func(new_snap)
		profile_data.history.latest = new_snap

		profile.save(profile_data)

		if debug then
			rewind_stack = {
				snap = new_snap,
				prev = rewind_stack
			}
		end
	end

	local function pre_segment_hook(segment)
		local checkpoint = segment.checkpoint

		if checkpoint and profile_data.history[checkpoint] ~= profile_data.history.latest then
			local checkpoints = profile_data.checkpoints
			local checkpoint_count = #checkpoints

			if checkpoint_count < 1 or checkpoints[checkpoint_count] ~= checkpoint then
				checkpoints[checkpoint_count + 1] = checkpoint
				profile_data.history[checkpoint] = profile_data.history.latest
			end

			profile.save(profile_data)
		end
	end

	local main_thread = progression.fork(function ()
		snapshot.save_load_progress(first_snap, save_func, pre_segment_hook, campaign_main)
	end)
	local should_stop = nil

	if debug then
		progression.fork(function ()
			while true do
				progression.wait_for_message("campaign_print_history")
				pprint(profile_data.checkpoints)
				pprint(profile_data.history.latest)
			end
		end)
		progression.fork(function ()
			while true do
				local slot = progression.wait_for_message("campaign_save_to_slot").slot
				local debug_profile = save_file.get_profile_by_index("debug_" .. slot)

				debug_profile.save(profile_data)
				print("Saved state to slot " .. slot)
			end
		end)
		progression.fork(function ()
			while true do
				progression.wait_for_message("campaign_reset")

				local debug_profile = save_file.get_profile_by_index("debug_0")

				debug_profile.save(profile_data)

				profile_data.history = {}
				profile_data.checkpoints = {}

				profile.save(profile_data)
				scenes.run_progression("menu")
				print("Game reset. Saved state to slot 0")
			end
		end)
		progression.fork(function ()
			while true do
				local message = progression.wait_for_message("campaign_rewind")
				local route = message.route
				local slot = message.slot
				local snap = nil
				local skip_load = false

				if route then
					snap = snapshot.snap()
					snap.route = route
				elseif slot then
					local debug_profile = save_file.get_profile_by_index("debug_" .. slot)
					local loaded_data = debug_profile.get()
					snap = loaded_data.history.latest
					profile_data = loaded_data

					print("Loading state from slot " .. slot)
				elseif rewind_stack and rewind_stack.prev then
					snap = rewind_stack.prev.snap
					rewind_stack = rewind_stack.prev.prev
				else
					skip_load = true
				end

				if not skip_load then
					save_func(snap)

					local old_thread = main_thread
					main_thread = progression.create_fork(function ()
						snapshot.save_load_progress(snap, save_func, pre_segment_hook, campaign_main)
					end)
					should_stop = false

					progression.cancel(old_thread)

					progression.first_transition = true

					progression.resume(main_thread)
				end
			end
		end)
	end

	repeat
		should_stop = true

		progression.join(main_thread)
	until should_stop

	sound_util.set_music(nil)
	scenes.run_progression("main")
end

return campaign
