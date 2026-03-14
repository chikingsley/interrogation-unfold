local optional_req = require("lib.optional_require")
local tcp_client = optional_req("defnet.tcp_client")
local M = {}

local function parse_args(line, position)
	local _, pos_end = nil
	local args = {}

	while true do
		_, pos_end = line:find("^%s*", position)

		if not pos_end then
			return args
		end

		position = pos_end + 1

		if line:sub(position, position) == ":" then
			return args, line:sub(position + 1)
		end

		local arg = nil
		_, pos_end, arg = line:find("^(%S+)", position)

		if not pos_end then
			return args
		end

		args[#args + 1] = arg
		position = pos_end + 1
	end
end

function M.create(options)
	local instance = {}
	local client = nil

	local function on_data(line)
		local _, pos_end, prefix, command = nil
		_, pos_end, _ = line:find("^@(%S+)%s+")
		_, pos_end, prefix = line:find("^:(%S+)%s+", (pos_end or 0) + 1)
		_, pos_end, command = line:find("^(%S+)", (pos_end or 0) + 1)
		local args_pos = (pos_end or 0) + 1

		if command == "PRIVMSG" then
			local args, rest = parse_args(line, args_pos)

			if args[1] == options.channel and rest then
				options.on_message(rest, prefix)
			end
		elseif command == "PING" then
			client.send("PONG\r\n")
		elseif command == "JOIN" then
			local args = parse_args(line, args_pos)

			if args[1] == options.channel then
				options.on_join()
			end
		end
	end

	local function on_disconnect()
		client = nil

		options.on_disconnect()
	end

	client = tcp_client.create(options.host, options.port, on_data, on_disconnect)

	client.send("PASS " .. options.pass .. "\r\n")
	client.send("NICK " .. options.nick .. "\r\n")
	timer.delay(0.25, false, function ()
		if client then
			client.send("JOIN " .. options.channel .. "\r\n")
		end
	end)

	function instance.update()
		client.update()
	end

	function instance.stop()
		client.destroy()

		client = nil
	end

	return instance
end

return M
