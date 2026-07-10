local sys_config = require("lib.sys_config")
local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local h_sound_delayed_bank_release = hash("sound_delayed_bank_release")
local banks_to_release = {}
local sound_util = {
	_banks_to_release = banks_to_release
}
local ref_counts = {}
local loaded_banks = {}
local bank_paths = {}
local presets = {}
local fade_duration = 1
local crossfade_duration = 20
local parameter_cache = nil

function sound_util.load_bank(path)
	if not fmod then
		return nil
	end

	local bank = loaded_banks[path]

	if not bank then
		local system_name = sys_config.system_name

		if env.bundled and not env.banks_from_resources and system_name ~= "HTML5" then
			local bank_path = nil

			if system_name == "Darwin" then
				bank_path = sys_config.bundle_root_path .. "/Contents/Resources/banks/" .. path
			elseif system_name == "Android" then
				bank_path = "file:///android_asset/banks/" .. path
			else
				local sep = sys_config.path_sep
				bank_path = sys_config.bundle_root_path

				if bank_path:sub(#bank_path) ~= sep then
					bank_path = bank_path .. sep
				end

				bank_path = bank_path .. "banks" .. sep .. path
			end

			bank = fmod.studio.system:load_bank_file(bank_path, fmod.STUDIO_LOAD_BANK_NORMAL)
		else
			local resource = resource.load("/sound/banks/" .. path)
			bank = fmod.studio.system:load_bank_memory(resource, fmod.STUDIO_LOAD_BANK_NORMAL)
		end

		loaded_banks[path] = bank
		bank_paths[bank] = path
	end

	ref_counts[bank] = (ref_counts[bank] or 0) + 1

	return bank
end

function sound_util.retain_bank(bank)
	local count = ref_counts[bank]

	if count then
		ref_counts[bank] = count + 1
	end
end

function sound_util.release_bank(bank)
	local count = ref_counts[bank]

	if count then
		if count > 1 then
			ref_counts[bank] = count - 1
		else
			bank:unload()

			ref_counts[bank] = nil
			local path = bank_paths[bank]
			bank_paths[bank] = nil
			loaded_banks[path] = nil
		end
	end
end

function sound_util.release_bank_delayed(bank, delay)
	local id = #banks_to_release + 1
	banks_to_release[id] = bank

	dispatcher.dispatch(h_sound_delayed_bank_release, {
		delay = delay,
		bank_id = id
	})
end

function sound_util.stop_event(event, bank, xfade)
	if not event then
		return
	end

	sound_util.retain_bank(bank)

	local fade_volume = nil

	pcall(function ()
		fade_volume = event:get_description():get_parameter_description_by_name("FadeVolume")
	end)

	if fade_volume then
		event:set_parameter_by_id(fade_volume.id, 0, false)
	end

	event:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)

	local delay = xfade and crossfade_duration or fade_duration

	sound_util.release_bank_delayed(bank, delay)
end

local function get_parameter_by_name(event, parameter_name, cache)
	local parameter = cache[parameter_name]

	if not parameter then
		pcall(function ()
			parameter = event:get_parameter_description_by_name(parameter_name)
		end)
	end

	cache[parameter_name] = parameter

	return parameter
end

function sound_util.set_music(event, bank, opts)
	local options = opts or {}
	local old_music = sound_util.music
	local old_bank = sound_util.bank
	local old_parameter_cache = parameter_cache

	if type(bank) == "string" then
		bank = sound_util.load_bank(bank)
	elseif bank then
		sound_util.retain_bank(bank)
	end

	if type(event) == "string" then
		event = fmod and fmod.studio.system:get_event(event)
	end

	if not options.restart and event and old_music and event == old_music:get_description() and bank == old_bank then
		if bank then
			sound_util.release_bank(bank)
		end

		return
	end

	local start_position = nil

	if options.random_start_position then
		start_position = math.random(0, options.random_start_position * 1000)
	else
		start_position = 0
	end

	if options.start_position then
		start_position = options.start_position * 1000
	end

	parameter_cache = nil
	local music = nil

	if event then
		music = event:create_instance()

		music:set_timeline_position(start_position)

		parameter_cache = {}

		if options.slow_fade_in then
			local crossfade = get_parameter_by_name(event, "Crossfade", parameter_cache)

			if crossfade then
				local crossfade_id = crossfade.id

				music:set_parameter_by_id(crossfade_id, 0, false)
				music:start()
				music:set_parameter_by_id(crossfade_id, 1, false)
			end
		else
			music:start()
		end
	end

	sound_util.bank = bank
	sound_util.music = music
	sound_util.music_tag = options.tag

	if old_music then
		if options.slow_fade_out then
			local crossfade = get_parameter_by_name(old_music:get_description(), "Crossfade", old_parameter_cache)

			if crossfade then
				local crossfade_id = crossfade.id

				old_music:set_parameter_by_id(crossfade_id, 0, false)
				sound_util.stop_event(old_music, old_bank, true)
			else
				sound_util.stop_event(old_music, old_bank)
			end
		else
			sound_util.stop_event(old_music, old_bank)
		end
	end

	if old_bank then
		sound_util.release_bank(old_bank)
	end
end

function sound_util.set_music_parameter(parameter_name, value)
	local music = sound_util.music

	if music then
		local parameter = get_parameter_by_name(music:get_description(), parameter_name, parameter_cache)

		if parameter then
			music:set_parameter_by_id(parameter.id, value, false)
		end
	end
end

function sound_util.clone_event(event)
	if not event then
		return nil
	end

	local description = event:get_description()
	local volume = event:get_volume()
	local clone = description:create_instance()

	clone:set_volume(volume)

	local param_count = description:get_parameter_description_count()

	for i = 0, param_count - 1 do
		local param = description:get_parameter_description_by_index(i)
		local param_id = param.id
		local param_value = event:get_parameter_by_id(param_id)

		clone:set_parameter_by_id(param_id, param_value, false)
	end

	return clone
end

function sound_util.pause_event(event)
	if not event then
		return
	end

	local fade_volume = nil

	pcall(function ()
		fade_volume = event:get_description():get_parameter_description_by_name("FadeVolume")
	end)

	if fade_volume then
		local fade_volume_id = fade_volume.id
		local clone = sound_util.clone_event(event)

		clone:set_timeline_position(event:get_timeline_position())
		event:set_parameter_by_id(fade_volume_id, 0, false)
		event:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)
		clone:set_paused(true)
		clone:set_parameter_by_id(fade_volume_id, 0, false)
		clone:start()
		clone:set_parameter_by_id(fade_volume_id, 1, false)

		return clone
	end

	event:set_paused(true)

	return event
end

function sound_util.with_music(event, bank, opts)
	return function (f)
		return function (...)
			sound_util.set_music(event, bank, opts)

			return f(...)
		end
	end
end

function sound_util.with_preset_music(preset_id, opts)
	return function (f)
		return function (...)
			sound_util.set_preset_music(preset_id, opts)

			return f(...)
		end
	end
end

function sound_util.set_preset(preset_id, event, bank)
	presets[preset_id] = {
		event,
		bank
	}
end

function sound_util.get_preset(preset_id)
	local preset = presets[preset_id]

	if preset then
		return preset[1], preset[2]
	end

	return nil, nil
end

function sound_util.set_preset_music(preset_id, opts)
	local event, bank = sound_util.get_preset(preset_id)

	return sound_util.set_music(event, bank, opts)
end

function sound_util.with_preset_alias(from, to)
	return function (f)
		return function (...)
			local event, bank = sound_util.get_preset(from)

			sound_util.set_preset(from, sound_util.get_preset(to))

			local result = f(...)

			sound_util.set_preset(from, event, bank)

			return result
		end
	end
end

return sound_util
