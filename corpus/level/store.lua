local table_util = require("crit.table_util")
local perks = require("campaign.perks")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local intl = require("crit.intl")
local state = require("level.state")
local h_play_animation = hash("play_animation")
local TORTURE_GRAB = 1
local TORTURE_WALL = 2
local TORTURE_WATERBOARD = 3
local TORTURE_CUT = 4
local VN_ROOT = "vn0 root"
local TORTURE_EFFECTS = {
	[TORTURE_GRAB] = {
		torture_damage = 1,
		fear = 1,
		health = -1,
		empathy = -1,
		cruelty = 1,
		insanity = 0.5
	},
	[TORTURE_WALL] = {
		torture_damage = 2,
		fear = 2,
		health = -2,
		empathy = -2,
		cruelty = 2,
		insanity = 1
	},
	[TORTURE_WATERBOARD] = {
		torture_damage = 3,
		fear = 4,
		health = -3,
		empathy = -4,
		cruelty = 3,
		insanity = 1.5
	},
	[TORTURE_CUT] = {
		torture_damage = 3,
		fear = 3,
		health = -3,
		empathy = -3,
		cruelty = 3,
		insanity = 1.5
	}
}
local HISTORY_EVENTS = {
	LEVEL_END = 6,
	KILL = 5,
	RECORDER = 3,
	QUESTION = 1,
	SWITCH_SUBJECT = 2,
	TORTURE = 4
}
local store = {
	TORTURE_GRAB = TORTURE_GRAB,
	TORTURE_WALL = TORTURE_WALL,
	TORTURE_WATERBOARD = TORTURE_WATERBOARD,
	TORTURE_CUT = TORTURE_CUT,
	TORTURE_EFFECTS = TORTURE_EFFECTS,
	HISTORY_EVENTS = HISTORY_EVENTS,
	history = {}
}
local empty = {}
local play_animation, set_idle_animation = nil

local function solve_table_refs(table, ref_table)
	if not table then
		return
	end

	for key, value in ipairs(table) do
		table[key] = ref_table[value]
	end
end

local function solve_number_variance(x)
	if type(x) == "table" and x.from and x.to then
		return math.random(x.from, x.to)
	else
		return x
	end
end

local function revive_data(data)
	data.level_id = data.level_id or "unknown"
	data.questions = data.questions or empty
	data.answers = data.answers or empty
	data.subjects = data.subjects or empty
	data.hints = data.hints or empty
	data.common_texts = data.common_texts or empty

	if data.intl_namespace then
		data.intl_namespace = intl.namespace(data.intl_namespace)
	end

	for i, subject in ipairs(data.subjects) do
		solve_table_refs(subject.fake_answers, data.answers)
		solve_table_refs(subject.fake_answers_fallback, data.answers)

		for key, value in pairs(subject.questions) do
			solve_table_refs(value, data.questions)
		end

		solve_table_refs(subject.back_questions, data.questions)

		subject.page_settings = subject.page_settings or {}
		subject.triggered_questions = subject.triggered_questions or {}
		subject.triggered_questions.whisky = subject.triggered_questions.whisky or subject.whisky_question_id
	end

	for i, question in ipairs(data.questions) do
		solve_table_refs(question.answers, data.answers)
	end

	data.time_limit = data.time_limit or 420

	if perks.speed then
		data.time_limit = data.extended_time_limit or 600
	end

	if data.time_limit == 0 then
		data.time_limit = nil
	end

	if data.time_limit and data.vn_extra_time and store.has_flag("vn") then
		data.time_limit = data.time_limit + data.vn_extra_time
	end

	for i, question in ipairs(data.questions) do
		question.ask_count = 0
		question.visible = false
		question.new = false
		question.new_unseen = false
		question.new_indicated = false
		question.repeating_effects = question.repeating_effects or {}
	end

	for i, answer in ipairs(data.answers) do
		answer.answer_count = 0
		answer.repeating_effects = answer.repeating_effects or {}
	end

	for i, subject in ipairs(data.subjects) do
		subject.id = i
		subject.starting_health = solve_number_variance(subject.initial_health) or 7

		if perks.anatomy then
			subject.starting_health = subject.starting_health + 3
		end

		subject.visible_questions = {}
		subject.last_answer_id = nil
		subject.current_back_question = nil
	end
end

local function init_new_questions(subject)
	for page in pairs(subject.questions) do
		store.get_visible_questions(subject.id, page, true)
	end
end

local function apply_data(data)
	store.questions = data.questions
	store.answers = data.answers
	store.subjects = data.subjects
	store.time_limit = data.time_limit
	store.level_id = data.level_id
	store.hints = data.hints
	store.intl_namespace = data.intl_namespace
	store.common_texts = data.common_texts
end

local function subject_is_vn(subject)
	return store.has_flag("vn") and subject.questions[VN_ROOT]
end

local function reset_subject(subject)
	subject.enabled = true
	subject.shown = not subject.starts_hidden
	subject.health = subject.starting_health
	subject.torture_damage = 0
	subject.times_tortured = 0
	subject.empathy = solve_number_variance(subject.initial_empathy) or 0
	subject.fear = solve_number_variance(subject.initial_fear) or 0

	if perks.pacifist then
		subject.empathy = subject.empathy + 1
		subject.fear = subject.fear - 1
	end

	if stats.is_high("popularity") then
		subject.fear = subject.fear + (subject.fear_hero_bonus or 0)
		subject.empathy = subject.empathy + (subject.empathy_hero_bonus or 0)
	end

	if stats.is_low("popularity") then
		subject.fear = subject.fear + (subject.fear_pig_bonus or 0)
		subject.empathy = subject.empathy + (subject.empathy_pig_bonus or 0)
	end

	for key, value in pairs(subject.stat_boost) do
		subject[key] = subject[key] + value
	end

	subject.last_low_hp_treshold = 0
	subject.page_stack = {
		subject_is_vn(subject) and VN_ROOT or "root"
	}
	subject.page_stack_top = 1

	init_new_questions(subject)
end

local function copy_subject(subject, old_subject)
	subject.enabled = old_subject.enabled
	subject.shown = old_subject.shown
	subject.health = old_subject.health
	subject.torture_damage = old_subject.torture_damage
	subject.times_tortured = old_subject.times_tortured
	subject.empathy = old_subject.empathy
	subject.fear = old_subject.fear
	subject.page_stack = old_subject.page_stack
	subject.page_stack_top = old_subject.page_stack_top
	subject.room_index = old_subject.room_index
	subject.casefile_index = old_subject.casefile_index
	subject.last_low_hp_treshold = old_subject.last_low_hp_treshold

	init_new_questions(subject)
end

function store.reset()
	store.history = {}
end

function store.reload(data)
	revive_data(data)

	local old_subjects = store.subjects

	apply_data(data)

	for id, subject in ipairs(data.subjects) do
		local old_subject = old_subjects[id]

		if not old_subject then
			reset_subject(subject)

			subject.shown = false

			store.show_subject(id)
		else
			copy_subject(subject, old_subject)
		end
	end
end

local function resolve_subject_id(subject_id_or_name)
	if type(subject_id_or_name) == "string" then
		for subject_id, subject in ipairs(store.subjects) do
			if subject.avatar == subject_id_or_name then
				return subject_id
			end
		end

		return nil
	end

	return subject_id_or_name
end

function store.init(data, options)
	local disabled_subjects = options and options.disabled_subjects
	local hidden_subjects = options and options.hidden_subjects
	local flags = options and options.flags
	local stat_boosts = options and options.stat_boosts
	store.event_handlers = {}
	store.event_queue = nil
	store.history = {}
	store.flags = {}

	for i, perk in ipairs(perks) do
		store.set_flag("perk-" .. perk)
	end

	if flags then
		for flag, value in pairs(flags) do
			if value then
				store.set_flag(flag)
			end
		end
	end

	revive_data(data)
	apply_data(data)

	for i, subject in ipairs(store.subjects) do
		local boost = stat_boosts and (stat_boosts[i] or stat_boosts[subject.avatar]) or {}
		subject.stat_boost = boost

		reset_subject(subject)
	end

	if disabled_subjects then
		for i, subject_id in ipairs(disabled_subjects) do
			local subject = store.subjects[resolve_subject_id(subject_id)]

			if subject then
				subject.enabled = false
				subject.shown = false
			end
		end
	end

	if hidden_subjects then
		for i, subject_id in ipairs(hidden_subjects) do
			local subject = store.subjects[resolve_subject_id(subject_id)]

			if subject then
				subject.shown = false
			end
		end
	end

	local subject_in_room = {}
	local subject_in_casefile = {
		0
	}
	local casefile_count = 1
	local room_count = 0

	for id, subject in ipairs(store.subjects) do
		if subject.shown then
			room_count = room_count + 1
			subject.room_index = room_count
			subject_in_room[room_count] = id
		end

		if subject.enabled and (subject.shown or not subject.delayed_casefile) then
			casefile_count = casefile_count + 1
			subject.casefile_index = casefile_count
			subject_in_casefile[casefile_count] = id
		end
	end

	store.room_count = room_count
	store.subject_in_room = subject_in_room
	store.casefile_count = casefile_count
	store.subject_in_casefile = subject_in_casefile
end

function store.add_event_handler(handler)
	local handlers = store.event_handlers
	handlers[#handlers + 1] = handler

	return handler
end

function store.remove_event_handler(handler)
	local handlers = store.event_handlers

	for i, h in ipairs(handlers) do
		if h == handler then
			table.remove(handlers, i)

			return
		end
	end
end

function store.fire_event(event_id, args, subject_id)
	event_id = hash(event_id)
	local event_queue = store.event_queue

	if event_queue then
		event_queue[#event_queue + 1] = {
			event_id = event_id,
			subject_id = subject_id,
			args = args
		}

		return
	end

	local handlers = store.event_handlers

	for i, handler in ipairs(handlers) do
		handler(event_id, args, subject_id)
	end
end

function store.next_subject_id(subject_id)
	local subjects = store.subjects
	local room_index = subjects[subject_id].room_index + 1

	return store.subject_in_room[room_index]
end

function store.prev_subject_id(subject_id)
	local subjects = store.subjects
	local room_index = subjects[subject_id].room_index - 1

	return store.subject_in_room[room_index]
end

function store.show_subject(subject_id)
	local subject = store.subjects[subject_id]

	if subject.shown or not subject.enabled then
		return
	end

	local room_count = store.room_count + 1
	store.room_count = room_count
	store.subject_in_room[room_count] = subject_id
	subject.room_index = room_count
	subject.shown = true

	if subject.delayed_casefile then
		local casefile_count = store.casefile_count + 1
		store.casefile_count = casefile_count
		store.subject_in_casefile[casefile_count] = subject_id
		subject.casefile_index = casefile_count
	end
end

local STAT_EMPATHY = 0
local STAT_FEAR = 1
local STAT_HEALTH = 2
local STAT_INSANITY = 3
local STAT_CRUELTY = 4
local STAT_INSANITY_CRUELTY = 5
local STAT_TIMES_ASKED = 6
local STAT_TIMES_ANSWERED = 7
local STAT_TORTURE_DAMAGE = 8
local STAT_POPULARITY = 9
local STAT_PRESS = 10
local STAT_AUTHORITIES = 11
local STAT_TAB_APPROVAL = 13
local STAT_JEN_APPROVAL = 14
local STAT_MORDECAI_APPROVAL = 15
local STAT_EQUITY = 16
local STAT_FREEDOM = 17
local STAT_EVOLUTION = 18
local STAT_LAWFUL = 19
local STAT_JUSTICE = 20
local stat_getters = {
	[STAT_EMPATHY] = function (subject)
		return subject.empathy
	end,
	[STAT_FEAR] = function (subject)
		return subject.fear
	end,
	[STAT_HEALTH] = function (subject)
		return subject.health
	end,
	[STAT_INSANITY] = function (subject)
		return stats.insanity
	end,
	[STAT_CRUELTY] = function (subject)
		return stats.cruelty
	end,
	[STAT_TIMES_ASKED] = function (subject, question)
		return question and question.ask_count
	end,
	[STAT_TIMES_ANSWERED] = function (subject, question, answer)
		return answer and answer.answer_count
	end,
	[STAT_TORTURE_DAMAGE] = function (subject)
		return subject.torture_damage
	end,
	[STAT_PRESS] = function ()
		return stats.press
	end,
	[STAT_POPULARITY] = function ()
		return stats.popularity
	end,
	[STAT_AUTHORITIES] = function ()
		return stats.authorities
	end,
	[STAT_TAB_APPROVAL] = function ()
		return agents.tab.approval
	end,
	[STAT_JEN_APPROVAL] = function ()
		return agents.jen.approval
	end,
	[STAT_MORDECAI_APPROVAL] = function ()
		return agents.mordecai.approval
	end,
	[STAT_EQUITY] = function ()
		return stats.equity
	end,
	[STAT_FREEDOM] = function ()
		return stats.freedom
	end,
	[STAT_EVOLUTION] = function ()
		return stats.evolution
	end,
	[STAT_LAWFUL] = function ()
		return stats.lawful
	end,
	[STAT_JUSTICE] = function ()
		return stats.justice
	end
}
local stat_incrementers = {
	[STAT_EMPATHY] = function (amount, subject)
		subject.empathy = subject.empathy + amount
	end,
	[STAT_FEAR] = function (amount, subject)
		subject.fear = subject.fear + amount
	end,
	[STAT_HEALTH] = function (amount, subject)
		subject.health = subject.health + amount
	end,
	[STAT_INSANITY] = function (amount)
		if amount > 0 and perks.nerves then
			amount = amount * 0.5
		end

		stats.increment_insanity(amount)
	end,
	[STAT_CRUELTY] = function (amount)
		stats.increment_cruelty(amount)
	end,
	[STAT_INSANITY_CRUELTY] = function (amount)
		stats.increment_cruelty(amount)

		if amount > 0 and perks.nerves then
			amount = amount * 0.5
		end

		stats.increment_insanity(amount)
	end,
	[STAT_PRESS] = function (amount)
		stats.increment_press(amount)
	end,
	[STAT_POPULARITY] = function (amount)
		stats.increment_popularity(amount)
	end,
	[STAT_AUTHORITIES] = function (amount)
		stats.increment_authorities(amount)
	end,
	[STAT_TAB_APPROVAL] = function (amount)
		agents.increment_approval("tab", amount)
	end,
	[STAT_JEN_APPROVAL] = function (amount)
		agents.increment_approval("jen", amount)
	end,
	[STAT_MORDECAI_APPROVAL] = function (amount)
		agents.increment_approval("mordecai", amount)
	end,
	[STAT_EQUITY] = function (amount)
		stats.increment_equity(amount)
	end,
	[STAT_FREEDOM] = function (amount)
		stats.increment_freedom(amount)
	end,
	[STAT_EVOLUTION] = function (amount)
		stats.increment_evolution(amount)
	end,
	[STAT_LAWFUL] = function (amount)
		stats.increment_lawful(amount)
	end,
	[STAT_JUSTICE] = function (amount)
		stats.increment_justice(amount)
	end
}
local AT_LEAST = 32
local AT_MOST = 33
local MORE_THAN = 36
local LESS_THAN = 37
local IS_EQUAL = 34
local FLAG_IS_SET = 6
local FLAG_IS_NOT_SET = 7
local OPERATOR_OR = 8
local OPERATOR_AND = 11
local OPERATOR_TERNARY = 35
local AS_SUBJECT = 31
local passes_condition, passes_conditions = nil
local condition_funcs = {
	[AT_LEAST] = function (condition, subject, question, answer)
		local value = stat_getters[condition.value.stat](subject, question, answer)

		return condition.value.operand <= value
	end,
	[AT_MOST] = function (condition, subject, question, answer)
		local value = stat_getters[condition.value.stat](subject, question, answer)

		return value <= condition.value.operand
	end,
	[MORE_THAN] = function (condition, subject, question, answer)
		local value = stat_getters[condition.value.stat](subject, question, answer)

		return condition.value.operand < value
	end,
	[LESS_THAN] = function (condition, subject, question, answer)
		local value = stat_getters[condition.value.stat](subject, question, answer)

		return value < condition.value.operand
	end,
	[IS_EQUAL] = function (condition, subject, question, answer)
		local value = stat_getters[condition.value.stat](subject, question, answer)

		return value == condition.value.operand
	end,
	[FLAG_IS_SET] = function (condition, subject)
		return store.has_flag(condition.value)
	end,
	[FLAG_IS_NOT_SET] = function (condition, subject)
		return not store.has_flag(condition.value)
	end,
	[OPERATOR_OR] = function (condition, subject, question, answer)
		for k, cond in ipairs(condition.value) do
			if passes_condition(cond, subject, question, answer) then
				return true
			end
		end

		return false
	end,
	[OPERATOR_AND] = function (condition, subject, question, answer)
		return passes_conditions(condition.value, subject, question, answer)
	end,
	[OPERATOR_TERNARY] = function (condition, subject, question, answer)
		if passes_conditions(condition.value.conditions, subject, question, answer) then
			return passes_conditions(condition.value.then_conditions, subject, question, answer)
		else
			return passes_conditions(condition.value.else_conditions, subject, question, answer)
		end
	end,
	[AS_SUBJECT] = function (condition, subject, question, answer)
		local subject_id = condition.value.subject_id

		if subject_id and subject_id >= 1 and subject_id <= #store.subjects then
			subject = store.subjects[subject_id]
		end

		for k, cond in ipairs(condition.value.conditions) do
			if not passes_condition(cond, subject, question, answer) then
				return false
			end
		end

		return true
	end
}

function passes_condition(condition, subject, question, answer)
	return condition_funcs[condition.type](condition, subject, question, answer)
end

function passes_conditions(conditions, subject, question, answer)
	if not conditions then
		return true
	end

	for i, condition in ipairs(conditions) do
		if not passes_condition(condition, subject, question, answer) then
			return false
		end
	end

	return true
end

store.passes_conditions = passes_conditions
local INCREMENT_STAT = 17
local SET_FLAG = 3
local UNSET_FLAG = 8
local WIN = 4
local LOSE = 7
local CONDITIONAL_EFFECT = 11
local NAVIGATE = 12
local REPLACE_PAGE = 16
local PLAY_ANIMATION = 14
local SET_IDLE = 15
local FIRE_EVENT = 13
local execute_effects = nil
local effect_funcs = {
	[INCREMENT_STAT] = function (effect, subject, question, answer)
		local incrementer = stat_incrementers[effect.value.stat]

		incrementer(effect.value.amount, subject, question, answer)
	end,
	[SET_FLAG] = function (effect, subject)
		store.set_flag(effect.value)
	end,
	[UNSET_FLAG] = function (effect, subject)
		store.unset_flag(effect.value)
	end,
	[WIN] = function (effect, subject)
		store.fire_event("win", {
			effect.value or "win"
		})
	end,
	[LOSE] = function (effect, subject)
		store.fire_event("lose", {
			effect.value or "lose"
		})
	end,
	[CONDITIONAL_EFFECT] = function (effect, subject, question, answer)
		local value = effect.value
		local conditions = value.conditions
		local effects = value.effects
		local else_effects = value.else_effects

		if not conditions or passes_conditions(conditions, subject, question, answer) then
			if effects then
				execute_effects(effects, subject, question, answer)
			end
		elseif else_effects then
			execute_effects(else_effects, subject, question, answer)
		end
	end,
	[NAVIGATE] = function (effect, subject)
		store.navigate_to(subject.id, effect.value)
	end,
	[REPLACE_PAGE] = function (effect, subject)
		store.replace_page(subject.id, effect.value)
	end,
	[FIRE_EVENT] = function (effect, subject)
		store.fire_event(effect.value.event, effect.value.args, subject.id)
	end,
	[PLAY_ANIMATION] = function (effect, subject)
		play_animation(subject, effect.value.animation, effect.value.companion)
	end,
	[SET_IDLE] = function (effect, subject)
		set_idle_animation(subject, effect.value.mode, effect.value.companion)
	end
}

function execute_effects(effects, subject, question, answer)
	for i, effect in ipairs(effects) do
		effect_funcs[effect.type](effect, subject, question, answer)
	end
end

local empty_question_list = {
	regular = {},
	exit = {}
}

function store.get_visible_questions(subject_id, page, unseen)
	local subject = store.subjects[subject_id]

	if subject.health <= 0 then
		return empty_question_list
	end

	local page_stack_top = 1

	if not page then
		page_stack_top = subject.page_stack_top
		page = subject.page_stack[page_stack_top]
	end

	local questions = subject.visible_questions[page]
	local regular_n, exit_n, back_n, mark_as_new = nil
	local previously_unseen = false

	if questions then
		regular_n = #questions.regular
		exit_n = #questions.exit
		back_n = #questions.back
		mark_as_new = true
		previously_unseen = not not questions.unseen
		questions.unseen = unseen
	else
		regular_n = 0
		exit_n = 0
		back_n = 0
		questions = {
			regular = {},
			exit = {},
			back = {},
			unseen = unseen
		}
		subject.visible_questions[page] = questions
		mark_as_new = false
	end

	local regular_questions = questions.regular
	local exit_questions = questions.exit
	local back_questions = questions.back

	for i = regular_n, 1, -1 do
		local question = regular_questions[i]

		if not passes_conditions(question.visibility_conditions, subject, question) then
			question.visible = false

			table.remove(regular_questions, i)

			regular_n = regular_n - 1
		end
	end

	for i = exit_n, 1, -1 do
		local question = exit_questions[i]

		if not passes_conditions(question.visibility_conditions, subject, question) then
			question.visible = false

			table.remove(exit_questions, i)

			exit_n = exit_n - 1
		end
	end

	for i = back_n, 1, -1 do
		local question = back_questions[i]

		if not passes_conditions(question.visibility_conditions, subject, question) then
			question.visible = false

			table.remove(back_questions, i)

			back_n = back_n - 1
		end
	end

	local is_vn = subject_is_vn(subject)

	for i, question in ipairs(subject.questions[page]) do
		if not question.visible and passes_conditions(question.visibility_conditions, subject, question) then
			question.new = mark_as_new
			question.new_unseen = mark_as_new and previously_unseen

			if is_vn then
				question.new_indicated = mark_as_new and not previously_unseen
			else
				question.new_indicated = mark_as_new
			end

			question.visible = true

			if question.exit_question then
				exit_n = exit_n + 1
				exit_questions[exit_n] = question
			elseif question.back_icon then
				back_n = back_n + 1
				back_questions[back_n] = question
			else
				regular_n = regular_n + 1
				regular_questions[regular_n] = question
			end
		end
	end

	local auto_back_question = questions.auto_back_question

	if not auto_back_question and page_stack_top > 1 and (not subject.page_settings[page] or not subject.page_settings[page].disable_back_question) then
		local back_questions_len = #subject.back_questions

		if back_questions_len ~= 0 then
			auto_back_question = subject.back_questions[math.random(back_questions_len)]
			auto_back_question.visible = true
			questions.auto_back_question = auto_back_question
		end
	end

	return questions
end

function store.is_free_question(question, subject)
	if type(question) ~= "table" then
		question = store.questions[question]
	end

	if type(subject) ~= "table" then
		subject = store.subjects[subject]
	end

	if question.back_icon then
		return true
	end

	for _, q in ipairs(subject.back_questions) do
		if q == question then
			return true
		end
	end

	return false
end

function store.get_question_text(question, subject)
	if type(question) ~= "table" then
		question = store.questions[question]
	end

	if type(subject) ~= "table" then
		subject = store.subjects[subject]
	end

	local alt_texts = question.alt_texts

	if alt_texts then
		for i, alt_text in ipairs(alt_texts) do
			if passes_conditions(alt_text.conditions, subject, question) then
				return alt_text.text, i
			end
		end
	end

	return question.text, nil
end

function store.get_question_text_by_alt_id(question, alt_id)
	if type(question) ~= "table" then
		question = store.questions[question]
	end

	if not alt_id then
		return question.text
	end

	local alt_texts = question.alt_texts

	if not alt_texts then
		return question.text
	end

	return alt_texts[alt_id].text
end

function store.get_alt_text(question, alt_text_id)
	if not alt_text_id then
		return question.text
	end

	return question.alt_texts[alt_text_id].text
end

local function answer_for_question(question, subject)
	if question.shuffle_answers then
		table_util.shuffle(question.answers)
	end

	for i, answer in ipairs(question.answers) do
		if answer.locked and answer.answer_count > 1 or passes_conditions(answer.conditions, subject, question, answer) then
			return answer
		end
	end

	table_util.shuffle(subject.fake_answers)

	for i, answer in ipairs(subject.fake_answers) do
		if passes_conditions(answer.conditions, subject, question, answer) then
			return answer
		end
	end

	table_util.shuffle(subject.fake_answers_fallback)

	for i, answer in ipairs(subject.fake_answers_fallback) do
		if passes_conditions(answer.conditions, subject, question, answer) then
			return answer
		end
	end
end

local function is_page_empty(subject, page)
	for i, question in ipairs(subject.questions[page]) do
		if passes_conditions(question.visibility_conditions, subject, question) then
			return false
		end
	end

	return true
end

local function reset_back_question(subject)
	local page = subject.page_stack[subject.page_stack_top]
	local questions = subject.visible_questions[page]

	if questions then
		questions.back_question = nil
	end
end

local function hash_animations(animation_or_animations)
	if not animation_or_animations then
		return nil
	end

	if type(animation_or_animations) == "string" then
		return hash(animation_or_animations)
	end

	if not animation_or_animations[1] then
		return nil
	end

	local first = nil

	for i = #animation_or_animations, 1, -1 do
		first = {
			hash(animation_or_animations[i]),
			first
		}
	end

	return first
end

function play_animation(subject, animation_id, companion, instant)
	local animation = subject.animations[animation_id]

	if not animation then
		return
	end

	local normal_animation, alt_animation = nil

	if type(animation) == "string" then
		normal_animation = hash(animation)
	else
		normal_animation = hash_animations(animation.normal)
		alt_animation = hash_animations(animation.alt)
	end

	if not animation and not alt_animation then
		return
	end

	local args = {
		animation = normal_animation,
		alt_animation = alt_animation,
		companion = not not companion,
		subject_id = subject.id,
		instant = not not instant
	}

	store.fire_event(h_play_animation, args, subject.id)
end

function set_idle_animation(subject, mode, companion)
	if not mode then
		return
	end

	local args = {
		idle_mode = hash(mode),
		companion = not not companion,
		subject_id = subject.id
	}

	store.fire_event(h_play_animation, args, subject.id)
end

function store.execute_question(question_id, subject_id)
	local question = store.questions[question_id]
	local subject = store.subjects[subject_id]
	local answer = answer_for_question(question, subject)
	local _, question_alt_id = store.get_question_text(question, subject)
	local history_event = {
		type = store.HISTORY_EVENTS.QUESTION,
		timestamp = state.time_elapsed,
		subject_id = subject.id,
		question_id = question_id,
		question_alt_id = question_alt_id,
		answer_id = answer.id
	}

	store.add_history_event(history_event)

	local page = subject.page_stack[subject.page_stack_top]

	for i, q in ipairs(subject.questions[page]) do
		q.new = false
		q.new_unseen = false
		q.new_indicated = false
	end

	store.event_queue = {}

	if question.ask_count == 0 then
		execute_effects(question.effects, subject, question)
	end

	execute_effects(question.repeating_effects, subject, question)

	if answer.answer_count == 0 then
		execute_effects(answer.effects, subject, question, answer)
	end

	execute_effects(answer.repeating_effects, subject, question, answer)
	store.navigate_to(subject_id, answer.navigate)

	if answer.animation then
		play_animation(subject, answer.animation, false)
	end

	if answer.companion_animation then
		play_animation(subject, answer.companion_animation, true)
	end

	question.ask_count = question.ask_count + 1
	answer.answer_count = answer.answer_count + 1
	subject.last_answer_id = answer.id
	local event_queue = store.event_queue
	store.event_queue = nil

	for i, event in ipairs(event_queue) do
		store.fire_event(event.event_id, event.args, event.subject_id)
	end

	return answer
end

function store.navigate_to(subject_id, navigate_to)
	local subject = store.subjects[subject_id]
	local page = subject.page_stack[subject.page_stack_top]

	if navigate_to and navigate_to ~= page then
		if navigate_to == "back" then
			store.navigate_back(subject_id)
		else
			store.push_page(subject_id, navigate_to)
		end
	end
end

function store.replace_page(subject_id, navigate_to)
	if not navigate_to or navigate_to == "" then
		return
	end

	local subject = store.subjects[subject_id]

	if not subject.questions[navigate_to] then
		error("No such page: " .. navigate_to)
	end

	subject.page_stack[subject.page_stack_top] = navigate_to

	reset_back_question(subject)
end

function store.navigate_back(subject_id)
	local subject = store.subjects[subject_id]
	local top = subject.page_stack_top

	if top <= 1 then
		print("WARNING: Can't go back from root")

		return
	end

	subject.page_stack_top = top - 1
	subject.page_stack[top] = nil

	reset_back_question(subject)
end

function store.push_page(subject_id, navigate_to, allow_empty)
	if not navigate_to or navigate_to == "" then
		return
	end

	local subject = store.subjects[subject_id]

	if not subject.questions[navigate_to] then
		error("No such page: " .. navigate_to)
	end

	if allow_empty or not is_page_empty(subject, navigate_to) then
		local top = subject.page_stack_top + 1
		subject.page_stack_top = top
		subject.page_stack[top] = navigate_to

		reset_back_question(subject)
	end
end

function store.page_exists(subject_id, page)
	local subject = store.subjects[subject_id]

	if not subject then
		return false
	end

	return subject.questions[page] and not not not is_page_empty(subject, page)
end

function store.is_any_subject_alive()
	for i, subj in ipairs(store.subjects) do
		if subj.health > 0 then
			return true
		end
	end

	return false
end

function store.torture(subject_id, torture_id)
	local effects = TORTURE_EFFECTS[torture_id]
	local subject = store.subjects[subject_id]
	subject.health = subject.health + effects.health
	subject.torture_damage = subject.torture_damage + effects.torture_damage
	subject.times_tortured = subject.times_tortured + 1
	subject.fear = subject.fear + effects.fear

	if perks.brutality then
		subject.fear = subject.fear + 1
	end

	subject.empathy = subject.empathy + effects.empathy

	stats.increment_cruelty(effects.cruelty)
	stats.increment_insanity(effects.insanity)
	stats.increment_total_torture_damage(effects.torture_damage)

	subject.last_answer_id = nil
	local reaction = subject.torture_reactions[torture_id]

	if reaction.animation then
		play_animation(subject, reaction.animation, false, true)
	end

	if reaction.effects then
		execute_effects(reaction.effects, subject)
	end
end

local low_hp_reactions = {
	{
		chance = 0.5,
		treshold = 0.5,
		reaction_count = 2,
		intl_prefix = "level.low_hp.50."
	},
	{
		chance = 0.75,
		treshold = 0.25,
		reaction_count = 2,
		intl_prefix = "level.low_hp.25."
	},
	{
		chance = 1,
		treshold = 0,
		reaction_count = 1,
		intl_prefix = "level.low_hp.0."
	}
}

function store.get_torture_reaction(subject_id, torture_id)
	local subject = store.subjects[subject_id]
	local hp_percentage = subject.health / subject.starting_health
	local low_hp_descriptor = nil

	for i = subject.last_low_hp_treshold + 1, #low_hp_reactions do
		local descriptor = low_hp_reactions[i]

		if descriptor.treshold < hp_percentage then
			break
		end

		low_hp_descriptor = descriptor
		subject.last_low_hp_treshold = i
	end

	if low_hp_descriptor and math.random() < low_hp_descriptor.chance then
		return intl.t(low_hp_descriptor.intl_prefix .. math.random(low_hp_descriptor.reaction_count))
	end

	return store.t(subject.torture_reactions[torture_id].reaction)
end

function store.get_history()
	local history = table_util.clone(store.history)

	return history
end

function store.add_history_event(history_event)
	table.insert(store.history, history_event)
end

function store.set_flag(flag)
	store.flags[flag] = true
end

function store.unset_flag(flag)
	store.flags[flag] = nil
end

function store.has_flag(flag)
	return not not store.flags[flag]
end

function store.translate(text)
	if not text then
		return text
	end

	if type(text) == "table" then
		if text._common then
			return store.translate(store.common_texts[text._common])
		end

		return intl.select(text)
	end

	local intl_namespace = store.intl_namespace

	if intl_namespace then
		return intl_namespace.translate(text)
	end

	return text
end

function store.get_subject(avatar)
	return table_util.find(store.subjects, function (s)
		return s.avatar == avatar
	end)
end

function store.get_triggered_question(subject_id, trigger)
	local subject = store.subjects[subject_id]

	if not subject then
		return
	end

	return subject.triggered_questions[trigger]
end

function store.hint_is_active(hint)
	return store.passes_conditions(hint.conditions)
end

function store.hint_text(hint)
	return store.t(hint.text)
end

store.t = store.translate

return store
