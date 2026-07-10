local press_release = {
	PARAGRAPH_BREAK = "%",
	header_text = "",
	selected_options = {},
	options = {},
	text = {}
}
local press_release_init_underlines, press_release_init_selected_options = nil

function press_release.init()
	press_release_init_underlines()
	press_release_init_selected_options()
end

function press_release.get_selected_option_text(id)
	local selected_option = press_release.selected_options[id]

	return press_release.options[id][selected_option]
end

function press_release.get_selected_option(id)
	return press_release.selected_options[id]
end

function press_release.cycle_selected_option(id)
	local options = press_release.options[id]
	local option = press_release.selected_options[id]
	option = option + 1

	if option > #options then
		option = 1
	end

	press_release.selected_options[id] = option
end

function press_release.are_all_options_set()
	for id, option in pairs(press_release.options) do
		if press_release.selected_options[id] == 0 then
			return false
		end
	end

	return true
end

function press_release_init_selected_options()
	for id, option in pairs(press_release.options) do
		press_release.selected_options[id] = 0
	end
end

function press_release_init_underlines()
	for id, option in pairs(press_release.options) do
		local count = option.underlines

		if not count then
			local sum = 0

			for i, option_string in ipairs(option) do
				sum = sum + #option_string
			end

			count = math.ceil(sum / #option * 0.65)
			option.underlines = count
		end
	end
end

return press_release
