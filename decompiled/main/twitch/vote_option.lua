local intl = require("crit.intl")
local h_colorw = hash("color.w")
local anim_duration = 0.3
local M = {}

local function votes_to_string(votes)
	votes = votes or 0

	if votes == 1 then
		return intl("twitch.votes.singular", {
			votes = votes
		})
	elseif votes <= 99 then
		return intl("twitch.votes.short", {
			votes = votes
		})
	else
		return tostring(votes)
	end
end

function M.set_votes(node, votes)
	gui.set_text(node, votes_to_string(votes))
end

function M.set_enabled(node, enabled, instant)
	local alpha = enabled and 1 or 0

	if instant then
		gui.cancel_animation(node, h_colorw)

		local color = gui.get_color(node)
		color.w = alpha

		gui.set_color(node, color)
		gui.set_enabled(node, enabled)
	else
		if enabled then
			gui.set_enabled(node, true)
		elseif not gui.is_enabled(node) then
			M.set_enabled(node, false, true)

			return
		end

		gui.cancel_animation(node, h_colorw)
		gui.animate(node, h_colorw, alpha, gui.EASING_LINEAR, anim_duration, 0, function ()
			if not enabled then
				gui.set_enabled(node, false)
			end
		end)
	end
end

return M
