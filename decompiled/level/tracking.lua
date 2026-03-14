local tracker = require("lib.ga")
local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local state = require("level.state")
local h_set_subject = hash("set_subject")
local h_init_level = hash("init_level")
local h_torture = hash("torture")
local h_ask_question = hash("ask_question")
local h_game_over = hash("game_over")
local h_start_game = hash("start_game")

function _env:init()
	self.init_time = 0
	self.last_subject_switch = 0
	self.time_per_subject = {}
	self.current_subject = ""
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_game_over,
		h_start_game,
		h_set_subject,
		h_torture,
		h_ask_question
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function commit_subject_time(self)
	local time = state.time_elapsed
	local subject = self.current_subject
	local time_per_subject = self.time_per_subject
	time_per_subject[subject] = (time_per_subject[subject] or 0) + time - self.last_subject_switch
	self.last_subject_switch = time
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		tracker.event(store.level_id, "init")

		self.init_time = socket.gettime()
	elseif message_id == h_start_game then
		tracker.event(store.level_id, "start")
		tracker.timing(store.level_id, "start", math.floor(1000 * (socket.gettime() - self.init_time)))

		self.time_per_subject = {}
		self.last_subject_switch = state.time_elapsed
		self.current_subject = store.subjects[state.current_subject].avatar
	elseif message_id == h_game_over then
		local event = message.has_won and "win" or "lose"

		tracker.event(store.level_id, event)
		tracker.timing(store.level_id, event, math.floor(1000 * state.time_elapsed))
		commit_subject_time(self)

		for subject, time in pairs(self.time_per_subject) do
			tracker.timing(store.level_id, subject, math.floor(1000 * time))
		end
	elseif message_id == h_ask_question then
		local question_id = message.question_id
		local label = self.current_subject .. "_" .. (store.questions[question_id].tag or "q" .. question_id)

		tracker.event(store.level_id, "ask_question", label)
	elseif message_id == h_torture then
		tracker.event(store.level_id, "torture" .. message.torture_id, self.current_subject)
	elseif message_id == h_set_subject then
		commit_subject_time(self)

		self.current_subject = store.subjects[state.current_subject].avatar

		tracker.event(store.level_id, "switch_subject", self.current_subject)
	end
end
