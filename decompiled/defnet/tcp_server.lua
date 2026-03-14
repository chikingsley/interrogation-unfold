local socket = require("socket.socket")
local tcp_send_queue = require("defnet.tcp_send_queue")
local M = {
	TCP_SEND_CHUNK_SIZE = 8192
}

function M.create(port, on_data, on_client_connected, on_client_disconnected)
	assert(port, "You must provide a port")
	assert(on_data, "You must provide an on_data function")
	print("Creating TCP server")

	local server = {}
	local co, server_socket = nil
	local clients = {}
	local queues = {}

	local function remove_client(connection_to_remove)
		for i, connection in pairs(clients) do
			if connection == connection_to_remove then
				table.remove(clients, i)

				queues[connection_to_remove] = nil

				if on_client_disconnected then
					local client_ip, client_port = connection:getsockname()

					on_client_disconnected(client_ip, client_port)
				end

				break
			end
		end
	end

	function server.start()
		print("Starting TCP server on port " .. port)

		local ok, err = pcall(function ()
			local skt, err = socket.bind("*", port)

			assert(skt, err)

			server_socket = skt

			server_socket:settimeout(0)
		end)

		if not server_socket or err then
			print("Unable to start TCP server", err)

			return false, err
		end

		return true
	end

	function server.stop()
		if server_socket then
			server_socket:close()
		end

		while #clients > 0 do
			local client = table.remove(clients)
			queues[client] = nil

			client:close()
		end
	end

	function server.receive(client)
		return client:receive("*l")
	end

	function server.send(data)
		for client, queue in pairs(queues) do
			queue.add(data)
		end
	end

	function server.update()
		if not server_socket then
			return
		end

		local client, err = server_socket:accept()

		if client then
			client:settimeout(0)
			table.insert(clients, client)

			queues[client] = tcp_send_queue.create(client, M.TCP_SEND_CHUNK_SIZE)

			if on_client_connected then
				local client_ip, client_port = client:getsockname()

				on_client_connected(client_ip, client_port)
			end
		end

		local read, write, err = socket.select(clients, nil, 0)

		for _, client in ipairs(read) do
			coroutine.wrap(function ()
				local data, err = server.receive(client)

				if data and on_data then
					local client_ip, client_port = client:getsockname()
					local response = on_data(data, client_ip, client_port, function (response)
						if not queues[client] then
							return false
						end

						queues[client].add(response)

						return true
					end)

					if response then
						queues[client].add(response)
					end
				end

				if err and err == "closed" then
					print("Client connection closed")
					remove_client(client)
				end
			end)()
		end

		local read, write, err = socket.select(nil, clients, 0)

		for _, client in ipairs(write) do
			coroutine.wrap(function ()
				queues[client].send()
			end)()
		end
	end

	return server
end

return M
