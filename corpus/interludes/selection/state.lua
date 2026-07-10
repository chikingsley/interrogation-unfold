local M = {
	selected_item_count = 0,
	required_item_count = 3,
	selections = {},
	options = {}
}

function M.set_options(required_item_count, options)
	M.options = options
	M.required_item_count = required_item_count
end

function M.reset()
	local selections = {}

	for i = 1, #M.options do
		selections[i] = false
	end

	M.selections = selections
	M.selected_item_count = 0
end

return M
