local Interview = {
	__index = {}
}

function Interview.new(questions, first_question_id, state)
	first_question_id = first_question_id or "root"
	state = state or {}
	local triggers = questions._triggers or {}
	local triggers_done = {}
	local self = {
		questions = questions,
		current_question_id = first_question_id,
		state = state,
		triggers = triggers,
		triggers_done = triggers_done
	}

	setmetatable(self, Interview)

	return self
end

function Interview.__index:get_current_question()
	return self.questions[self.current_question_id]
end

function Interview.__index:get_answers()
	local question = self.questions[self.current_question_id]

	if not question then
		return {}
	end

	local answers = {}
	local n = 1
	local state = self.state

	for i, answer in ipairs(question.answers) do
		if not answer.condition or answer.condition(state, answer, question) then
			answers[n] = answer
			n = n + 1
		end
	end

	return answers
end

function Interview.__index:pick_answer(answer)
	local state = self.state
	local questions = self.questions
	local question = questions[self.current_question_id]
	local effect = answer.effect

	if effect then
		effect(state, answer, question)
	end

	local next = nil

	for i, trigger in ipairs(self.triggers) do
		if not self.triggers_done[i] then
			next = trigger(state)

			if next then
				self.triggers_done[i] = true

				break
			end
		end
	end

	if not next then
		next = answer.next

		if type(next) == "function" then
			next = next(state, answer, question)
		end
	end

	while true do
		local next_question = questions[next]

		if type(next_question) == "function" then
			next = next_question(state, answer, question)
		else
			break
		end
	end

	self.current_question_id = next
end

function Interview.__index:get_texts(texts, ...)
	if type(texts) == "function" then
		texts = texts(self.state, ...)
	end

	if type(texts) == "string" then
		texts = {
			texts
		}
	end

	return texts
end

return Interview
