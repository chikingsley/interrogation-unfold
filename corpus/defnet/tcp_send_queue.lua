local M = {}

function M.create(client, chunk_size)
	assert(client, "You must provide a TCP client")

	chunk_size = chunk_size or 10000
	local instance = {}
	local queue = {}

	function instance.clear()
		queue = {}
	end

	function instance.add(data)
		assert(data, "You must provide some data")

		for i = 1, #data, chunk_size do
			table.insert(queue, {
				sent_index = 0,
				data = data:sub(i, i + chunk_size - 1)
			})
		end
	end

	function instance.send()
		while true do
			local first = queue[1]

			if not first then
				return true
			end

			local sent_index, err, sent_index_on_err = client:send(first.data, first.sent_index + 1, #first.data)

			if err then
				first.sent_index = sent_index_on_err

				return false, err
			end

			first.sent_index = sent_index

			if first.sent_index == #first.data then
				table.remove(queue, 1)
			end
		end
	end

	return instance
end

return M
