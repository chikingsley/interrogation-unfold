local M = {}
local STATE_STOPPED = 1
local STATE_LOGIN = 2
local STATE_READY = 3
M.STATE_STOPPED = STATE_STOPPED
M.STATE_LOGIN = STATE_LOGIN
M.STATE_READY = STATE_READY

function M.login()
	return
end

function M.stop()
	return
end

function M.update()
	return
end

function M.get_state()
	return STATE_STOPPED
end

function M.is_voting_enabled()
	return false
end

function M.is_voting_available()
	return false
end

function M.start_voting()
	return
end

local votes = {}

function M.get_votes()
	return votes
end

function M.stop_voting()
	return
end

function M.set_voting_options(options)
	return
end

M.unimplemented = true

return M
