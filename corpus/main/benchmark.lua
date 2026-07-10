local save_file = require("lib.save_file")
local Layout = require("crit.layout")
local config = save_file.config
local sys_config = require("lib.sys_config")
local dispatcher = require("crit.dispatcher")
local on_benchmarked = nil
local system_name = sys_config.system_name
local benchmark_version = 2

local function benchmark(skip_frames)
	if system_name ~= "Windows" and system_name ~= "Darwin" and system_name ~= "Linux" then
		return
	end

	skip_frames = skip_frames or 3
	local time, start_time = nil
	local samples = {}
	local sample_count = 0

	local function analyze_samples()
		table.sort(samples)

		local start = sample_count - math.ceil(sample_count * 0.8) + 1
		local sum = 0

		for i = start, sample_count do
			sum = sum + samples[i]
		end

		local average_dt = sum / (sample_count - start + 1)
		local average_fps = 1 / average_dt

		on_benchmarked(average_fps)
	end

	timer.delay(0, true, function (self, timer_handle)
		if skip_frames > 0 then
			skip_frames = skip_frames - 1

			return
		end

		local last_time = time
		time = socket.gettime()

		if not last_time then
			start_time = time

			return
		end

		local dt = time - last_time

		if dt == 0 then
			return
		end

		sample_count = sample_count + 1
		samples[sample_count] = dt

		print("Sample: " .. tostring(dt))

		if time - start_time >= 0.5 and sample_count >= 10 then
			timer.cancel(timer_handle)
			analyze_samples()
		end
	end)
end

local function on_low_fps(fps)
	local scale = config.resolution_scale

	if scale > 0.75 then
		scale = 0.75
	elseif scale > 0.5 then
		scale = 0.5
	end

	if scale == config.resolution_scale or Layout.window_height * scale < 720 then
		return
	end

	print("Benchmark detected low FPS. Reducing resolution scale to " .. tostring(scale))
	save_file.config_set("resolution_scale", scale)
	benchmark(3)
end

function on_benchmarked(fps)
	print("Benchmarked FPS: " .. tostring(fps))
	save_file.config_set("benchmarked", benchmark_version)

	if fps <= 25 then
		on_low_fps(fps)
	end
end

function _env:init()
	self.sub_id = dispatcher.subscribe({
		self.start_message
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == self.start_message and config.benchmarked ~= benchmark_version then
		save_file.config_set("resolution_scale", 1)
		benchmark(10)
	end
end
