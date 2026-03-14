local function url_decode(str)
	str = str:gsub("+", " ")
	str = str:gsub("%%(%x%x)", function (h)
		return string.char(tonumber(h, 16))
	end)
	str = str:gsub("\r\n", "\n")

	return str
end

local function url_encode_component(str)
	if str then
		str = str:gsub("\n", "\r\n")
		str = str:gsub("([^%w%-%_%.%~])", function (c)
			return ("%%%02X"):format(string.byte(c))
		end)
	end

	return str
end

local function url_encode(str)
	if str then
		str = str:gsub("\n", "\r\n")
		str = str:gsub("([^%w%/#?:-%_%.%~])", function (c)
			return ("%%%02X"):format(string.byte(c))
		end)
	end

	return str
end

return {
	url_encode_component = url_encode_component,
	url_decode = url_decode,
	url_encode = url_encode
}
