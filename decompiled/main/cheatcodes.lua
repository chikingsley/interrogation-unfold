local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local M = {}
local codes = {
	{
		text = "exmalobonum",
		progress = 1,
		action = function ()
			dispatcher.dispatch("skip_progression", {
				keep_transition = true
			})
		end
	},
	{
		text = "tempusfugit",
		progress = 1,
		action = function ()
			store.fire_event("add_time", {
				300
			}, 1)
		end
	}
}

function M.on_text(text)
	local len = #text

	for i = 1, len do
		local char = text:byte(i, i)

		for _, code in ipairs(codes) do
			if char == code.text:byte(code.progress) then
				code.progress = code.progress + 1

				if code.progress > #code.text then
					code.progress = 1

					code.action()
				end
			else
				code.progress = 1
			end
		end
	end
end

return M
