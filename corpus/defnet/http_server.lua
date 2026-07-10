local tcp_server = require("defnet.tcp_server")
local M = {
	OK = "200 OK",
	NOT_FOUND = "404 Not Found"
}

function M.create(port)
	local instance = {
		access_control = "*",
		server_header = "Server: Simple Lua Server v1"
	}
	local routes = {}
	local request_handlers = {}
	local unhandled_route_fn = nil
	local ss = tcp_server.create(port, function (data, ip, port, response_fn)
		if not data or #data == 0 then
			return
		end

		local ok, err = pcall(function ()
			local request_line = data[1] or ""
			local method, uri, protocol_version = request_line:match("^(%S+)%s(%S+)%s(%S+)")
			local header_only = method == "HEAD"

			if header_only then
				method = "GET"
			end

			local response = nil

			if uri then
				for _, route in ipairs(routes) do
					if not route.method or route.method == method then
						local matches = {
							uri:match(route.pattern)
						}

						if next(matches) then
							response = route.fn(matches, response_fn)

							break
						end
					end
				end
			end

			if not response and unhandled_route_fn then
				response = unhandled_route_fn(method, uri, response_fn)
			end

			if response then
				if type(response) == "function" then
					table.insert(request_handlers, response)
				else
					response_fn(response)
				end
			end
		end)

		if not ok then
			print(err)
		end
	end)

	function ss.receive(conn)
		assert(conn, "You must provide a connection")

		local request = {}
		local buf = ""

		while true do
			local data, err, buf = conn:receive("*l", buf)
			local closed = err == "closed"

			if closed or err ~= "timeout" and (not data or data == "\r\n" or data == "") then
				return request, err
			elseif data then
				table.insert(request, data)

				buf = ""
			end
		end
	end

	instance.router = {
		get = function (pattern, fn)
			assert(pattern, "You must provide a route pattern")
			assert(fn, "You must provide a route handler function")
			table.insert(routes, {
				method = "GET",
				pattern = pattern,
				fn = fn
			})
		end,
		post = function (pattern, fn)
			assert(pattern, "You must provide a route pattern")
			assert(fn, "You must provide a route handler function")
			table.insert(routes, {
				method = "POST",
				pattern = pattern,
				fn = fn
			})
		end,
		all = function (pattern, fn)
			assert(pattern, "You must provide a route pattern")
			assert(fn, "You must provide a route handler function")
			table.insert(routes, {
				pattern = pattern,
				fn = fn
			})
		end,
		unhandled = function (fn)
			assert(fn, "You must provide an unhandled route function")

			unhandled_route_fn = fn
		end
	}

	function instance.start()
		return ss.start()
	end

	function instance.stop()
		ss.stop()
	end

	function instance.update()
		ss.update()

		for k, handler in pairs(request_handlers) do
			if not handler() then
				request_handlers[k] = nil
			end
		end
	end

	instance.html = {
		header = function (document, status)
			local headers = {
				"HTTP/1.1 " .. (status or M.OK),
				instance.server_header,
				"Content-Type: text/html",
				document and "Content-Length: " .. tostring(#document) or "Transfer-Encoding: chunked"
			}

			if instance.access_control then
				headers[#headers + 1] = "Access-Control-Allow-Origin: " .. instance.access_control
			end

			headers[#headers + 1] = ""
			headers[#headers + 1] = ""

			return table.concat(headers, "\r\n")
		end,
		response = function (document, status)
			return instance.html.header(document, status) .. (document or "")
		end
	}

	setmetatable(instance.html, {
		__call = function (_, document, status)
			return instance.html.response(document, status)
		end
	})

	instance.json = {
		header = function (json, status)
			local headers = {
				"HTTP/1.1 " .. (status or M.OK),
				instance.server_header,
				"Content-Type: application/json; charset=utf-8",
				json and "Content-Length: " .. tostring(#json) or "Transfer-Encoding: chunked"
			}

			if instance.access_control then
				headers[#headers + 1] = "Access-Control-Allow-Origin: " .. instance.access_control
			end

			headers[#headers + 1] = ""
			headers[#headers + 1] = ""

			return table.concat(headers, "\r\n")
		end,
		response = function (json, status)
			return instance.json.header(json, status) .. (json or "")
		end
	}

	setmetatable(instance.json, {
		__call = function (_, json, status)
			return instance.json.response(json, status)
		end
	})

	instance.file = {
		header = function (file, filename, status)
			local headers = {
				"HTTP/1.1 " .. (status or M.OK),
				instance.server_header,
				"Content-Type: application/octet-stream",
				"Content-Disposition: attachment; filename=" .. filename,
				file and "Content-Length: " .. tostring(#file) or "Transfer-Encoding: chunked"
			}

			if instance.access_control then
				headers[#headers + 1] = "Access-Control-Allow-Origin: " .. instance.access_control
			end

			headers[#headers + 1] = ""
			headers[#headers + 1] = ""

			return table.concat(headers, "\r\n")
		end,
		response = function (file, filename, status)
			return instance.file.header(file, filename, status) .. (file or "")
		end
	}

	setmetatable(instance.file, {
		__call = function (_, file, filename, status)
			return instance.file.response(file, filename, status)
		end
	})

	function instance.to_chunk(data)
		return ("%x\r\n%s\r\n"):format(#data, data)
	end

	return instance
end

return M
