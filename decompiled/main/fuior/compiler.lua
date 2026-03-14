local function compile_string(data, filename)
	if not fuior then
		error("Fuior native extension not present")
	end

	local func_string = fuior.compile(data, filename)
	local chunk = assert(loadstring(func_string, filename))

	return chunk()
end

local function compile(filename)
	local data = assert(sys.load_resource(filename))

	return compile_string(data, filename)
end

return {
	compile = compile,
	compile_string = compile_string
}
