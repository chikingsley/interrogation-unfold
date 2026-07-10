local env = require("lib.environment")
local loader = require("main.loader.loader_progress")
local M = {}
local public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6h0nSNXONPkp2KC0CPQ47aiJg/S7F5isVy5ejLX0Y2cPtZN1OaSXsMmPaZp+7IGCZst7AAdZYijPfg4Oj6clUfn3Smxiuhu/jdnQvut8wSP/ppDri2cVPflp6q2inEOeaum2VB/eFtL5VwSqYzJI7sVDMAXaa0Jj8c/sNJjtmPSBDm859DVosFaZlzRZTzFz4o1TkYMOhhyrnYXCgD0j9aEefW2mYkNnpmPS8ESqp2GKvsCHUjBGDf7cBqJY/RZKIpxf32dy6pTLrI/aSXq7ZhbFkHxNaiigYWmdNheNv2xmHXKaSwolWHUqT0iXQZp4hEi9iAGdnmS8b5p1+AZuaQIDAQAB"
local salt = "\\xafu\\xf4\\xefWb]\\xb9\\xbf\\xfd>\\x90\\xe7\\x91\\xfc\\xbc\\xfc"
local memory_quota = 104857600
local time_quota = 0.25

local function delete_previous_resources()
	if not env.apkx_main_version or not misc then
		return false
	end

	local game_name = sys.get_config("project.title")
	local liveupdate_version_filename = sys.get_save_file(game_name, "liveupdate_version")
	local config = sys.load(liveupdate_version_filename)
	local liveupdate_version = config.liveupdate_version

	if liveupdate_version ~= env.apkx_main_version then
		local deleted_file1 = misc.delete_file(sys.get_save_file(game_name, "liveupdate.arcd"))
		local deleted_file2 = misc.delete_file(sys.get_save_file(game_name, "liveupdate.arci"))
		local deleted_file3 = misc.delete_file(sys.get_save_file(game_name, "liveupdate.arci.tmp"))
		config.liveupdate_version = env.apkx_main_version

		sys.save(liveupdate_version_filename, config)

		if deleted_file1 or deleted_file2 or deleted_file3 then
			sys.reboot()

			return true
		end
	end

	return false
end

local obb_files_expected = {}

if env.apkx_main_version then
	table.insert(obb_files_expected, {
		is_main = true,
		version = env.apkx_main_version
	})
end

if env.apkx_patch_version then
	table.insert(obb_files_expected, {
		is_main = false,
		version = env.apkx_patch_version
	})
end

local function obb_files_delivered()
	for _, file in ipairs(obb_files_expected) do
		local file_path = apkx.get_expansion_apk_file_path(file.is_main, file.version)
		local f = io.open(file_path, "r")

		if not f then
			return false
		end

		f:close()
	end

	return true
end

local function strip_zeroes(s)
	local n = s:len()

	for i = n, 1, -1 do
		local char = s:sub(i, i)

		if char == "." then
			return s:sub(1, i - 1)
		elseif char ~= "0" then
			return s:sub(1, i)
		end
	end

	return "0"
end

local function format2f(x)
	return strip_zeroes(string.format("%.2f", x))
end

local function format1f(x)
	return strip_zeroes(string.format("%.1f", x))
end

local function format_speed(bps)
	if bps < 1024 then
		return format2f(bps) .. " B/s"
	end

	bps = bps / 1024

	if bps < 1024 then
		return format2f(bps) .. " kB/s"
	end

	bps = bps / 1024

	return format2f(bps) .. " MB/s"
end

local function format_time(seconds)
	seconds = math.floor(seconds)

	if seconds < 60 then
		return seconds .. "s"
	end

	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

	if minutes < 60 then
		return minutes .. "m " .. seconds .. "s"
	end

	local hours = math.floor(minutes / 60)
	minutes = minutes - hours * 60

	return hours .. "h " .. minutes .. "m " .. seconds .. "s"
end

function M:bootstrap(callback, proxy_container)
	local store_resources_and_start, launch_downloader, start_game = nil

	local function on_download_state_change(self_, state)
		if state == apkx.STATE_COMPLETED then
			store_resources_and_start()
		else
			loader.set_progress({
				label = apkx.get_downloader_string_from_state(state)
			})
		end
	end

	local function on_download_progress(self_, progress)
		local current_speed = format_speed(progress.current_speed * 1000)
		local time_remaining = format_time(progress.time_remaining / 1000)
		local fraction = format1f(math.floor(progress.overall_progress * 100 / progress.overall_total))
		local text = fraction .. "%"

		if progress.current_speed ~= 0 then
			text = text .. " (" .. current_speed .. ")"
		end

		text = text .. " ETA " .. time_remaining

		loader.set_progress({
			progress = text
		})
	end

	function launch_downloader()
		apkx.configure_download_service({
			public_key = public_key,
			salt = salt,
			on_download_state_change = on_download_state_change,
			on_download_progress = on_download_progress
		})

		if apkx.start_download_service_if_required() then
			loader.set_progress({
				progress = "",
				label = "Downloading additional data"
			})
		else
			store_resources_and_start()
		end
	end

	local function get_missing_resources()
		local collections = env.excluded_collections or {}
		local resources = {}

		for _, collection in ipairs(collections) do
			local proxy_url = msg.url(proxy_container.socket, proxy_container.path, hash(collection))
			local missing_resources = collectionproxy.missing_resources(proxy_url)

			for _, resource in ipairs(missing_resources) do
				resources[resource] = true
			end
		end

		local resources_array = {}
		local n = 0

		for resource, val in pairs(resources) do
			if val then
				n = n + 1
				resources_array[n] = resource
			end
		end

		return resources_array
	end

	function store_resources_and_start()
		if not obb_files_delivered() then
			loader.set_progress({
				progress = "",
				label = "Missing APK expansion files"
			})

			return
		end

		if self.entered_store_and_start then
			return
		end

		self.entered_store_and_start = true
		local missing_resources = get_missing_resources()
		local missing_resources_count = #missing_resources

		if missing_resources_count == 0 then
			start_game()

			return
		end

		loader.set_progress({
			label = "Installing resources",
			progress = "0/" .. missing_resources_count
		})

		local zip_files = {}

		for i, file in ipairs(obb_files_expected) do
			zip_files[i] = apkx.get_expansion_apk_file_path(file.is_main, file.version)
		end

		local zip = apkx.zip_open(zip_files)
		local manifest = resource.get_current_manifest()
		local loaded_resource_count = 0
		local processed_resource_count = 0
		local used_memory = 0
		local store_resource_errored = false
		local load_timer = nil

		local function update()
			local current_time = socket.gettime()

			while processed_resource_count < missing_resources_count and used_memory < memory_quota do
				processed_resource_count = processed_resource_count + 1
				local resource_hash = missing_resources[processed_resource_count]
				local file_content = apkx.zip_read(zip, resource_hash)

				if not file_content then
					loaded_resource_count = loaded_resource_count + 1
					store_resource_errored = true

					print("Could not find resource in zip: " .. resource_hash)
				else
					local size = string.len(file_content)
					used_memory = used_memory + size

					resource.store_resource(manifest, file_content, resource_hash, function (self_, hexdigest, status)
						used_memory = used_memory - size
						loaded_resource_count = loaded_resource_count + 1

						loader.set_progress({
							progress = loaded_resource_count .. "/" .. missing_resources_count
						})

						if not status then
							store_resource_errored = true

							print("Failed to store resource: " .. hexdigest)
						end

						if loaded_resource_count == missing_resources_count then
							if load_timer then
								timer.cancel(load_timer)

								load_timer = nil
							end

							if store_resource_errored then
								loader.set_progress({
									progress = "",
									label = "An error occured while installing resources"
								})
							else
								start_game()
							end
						end
					end)
				end

				if time_quota < socket.gettime() - current_time then
					break
				end
			end
		end

		load_timer = timer.delay(0, true, update)

		update()
	end

	function start_game()
		loader.destroy()
		callback(self)
	end

	if env.fake_loading then
		loader.set_progress({
			label = "Downloading additional data"
		})
		on_download_progress(self, {
			time_remaining = 30100,
			overall_progress = 314572800,
			overall_total = 734003200,
			current_speed = 0.0023
		})
		timer.delay(2.5, false, function ()
			on_download_progress(self, {
				time_remaining = 108360000,
				overall_progress = 641728512,
				overall_total = 734003200,
				current_speed = 2.3552
			})
		end)
		timer.delay(5, false, start_game)

		return
	end

	if not apkx or not env.apkx_main_version then
		callback(self)

		return
	end

	if delete_previous_resources() then
		return
	end

	if not obb_files_delivered() then
		launch_downloader()
	else
		store_resources_and_start()
	end
end

return M
