local store = require("level.store")
local level_dialogue = require("level.dialogue.dialogue")

local function compute_initial_metrics(answer_position, answer_size, reaction_position, reaction_size)
	local overlap = answer_position.y + answer_size.y - (reaction_position.y - reaction_size.y * 0.5)
	local indent = reaction_position.x - reaction_size.x * 0.5 - answer_position.x

	return overlap, indent
end

local function compute_metrics(answer_position, answer_size, reaction_size, overlap, indent)
	local answer_left = answer_position.x
	local x = answer_left + indent + reaction_size.x * 0.5
	local y = answer_position.y + answer_size.y - overlap + reaction_size.y * 0.5

	return x, y
end

local dialogue = level_dialogue.create_dialogue({
	init_now = true,
	compute_initial_metrics = compute_initial_metrics,
	compute_metrics = compute_metrics,
	predicate = function (subject_id)
		local subject = store.subjects[subject_id].avatar

		return subject == "helene"
	end
})

function _env:init()
	dialogue.init(self)
	gui.set_render_order(6)
end

function _env:final()
	dialogue.final(self)
end

function _env:on_message(message_id, message, sender)
	dialogue.on_message(self, message_id, message, sender)
end
