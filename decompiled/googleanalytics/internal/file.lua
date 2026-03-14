local M = {
	get_save_file_name = function (name)
		local application_name = sys.get_config("project.title"):gsub(" ", "_")

		return sys.get_save_file(application_name, name)
	end
}

function M.load(name)
	assert(name, "You must provide a file name")

	local filename = M.get_save_file_name(name)
	local file, err = io.open(filename, "r")

	if not file then
		return nil, err
	end

	local contents = file:read("*a")

	if not contents then
		return nil, "Unable to read file"
	end

	return contents
end

function M.save(name, data)
	assert(name, "You must provide a file name")
	assert(data, "You must provide some data")
	assert(type(data) == "string", "You can only write strings")

	local tmpname = M.get_save_file_name("__ga_tmp")
	local file, err = io.open(tmpname, "w+")

	if not file then
		return nil, err
	end

	file:write(data)
	file:close()

	local filename = M.get_save_file_name(name)

	os.remove(filename)

	return os.rename(tmpname, filename)
end

return M
