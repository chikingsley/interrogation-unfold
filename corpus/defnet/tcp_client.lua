local socket = require("socket.socket")
local tcp_send_queue = require("defnet.tcp_send_queue")
local M = {
	TCP_SEND_CHUNK_SIZE = 8192
}

function M.create(server_ip, server_port, on_data, on_disconnect)
	assert(server_ip, "You must provide a server_ip")
	assert(server_port, "You must provide a server_port")
	assert(on_data, "You must provide an on_data callback function")
	assert(on_disconnect, "You must provide an on_disconnect callback function")
	print("Creating TCP client", server_ip, server_port)

	local client = {
		pattern = "*l"
	}
	local client_socket, send_queue, client_socket_table = nil
	local ok, err = pcall(function ()
		client_socket = socket.tcp()

		assert(client_socket:connect(server_ip, server_port))
		assert(client_socket:settimeout(0))

		client_socket_table = {
			client_socket
		}
		send_queue = tcp_send_queue.create(client_socket, M.TCP_SEND_CHUNK_SIZE)
	end)

	if not ok or not client_socket or not send_queue then
		print("tcp_client.create() error", err)

		return nil, ("Unable to connect to %s:%d"):format(server_ip, server_port)
	end

	function client.send(data)
		send_queue.add(data)
	end

	function client.update()
		if not client_socket then
			return
		end

		local receivet, sendt = socket.select(client_socket_table, client_socket_table, 0)

		if sendt[client_socket] then
			local ok, err = send_queue.send()

			if not ok and err == "closed" then
				client.destroy()
				on_disconnect()

				return
			end
		end

		if receivet[client_socket] then
			while client_socket do
				local data, err = client_socket:receive(client.pattern or "*l")

				if data then
					local response = on_data(data)

					if response then
						client.send(response)
					end
				elseif err == "closed" then
					client.destroy()
					on_disconnect()
				else
					break
				end
			end
		end
	end

	function client.destroy()
		if client_socket then
			client_socket:close()

			client_socket = nil
		end
	end

	return client
end

return M
