local sys_info = sys.get_sys_info()
local system_name = sys_info.system_name
local is_mobile = system_name == "iPhone OS" or system_name == "Android" or system_name == "Switch"
local path_sep = system_name == "Windows" and "\\" or "/"
local bundle_root_path = system_name ~= "Linux" and sys.get_application_path or fmod and fmod.get_bundle_root or defos and defos.get_bundle_root or function ()
	return "."
end()
local low_memory = false

if misc then
	local memory = misc.get_physical_memory_gb()

	if memory ~= 0 and memory < 1.8 then
		low_memory = true
	end
end

return {
	sys_info = sys_info,
	system_name = system_name,
	is_mobile = is_mobile,
	is_android = system_name == "Android",
	is_ios = system_name == "iPhone OS",
	low_memory = low_memory,
	path_sep = path_sep,
	bundle_root_path = bundle_root_path
}
