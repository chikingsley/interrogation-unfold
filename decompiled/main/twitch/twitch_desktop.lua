local optional_req = require("lib.optional_require")
local http_server = optional_req("defnet.http_server")
local irc = require("main.twitch.irc")
local dispatcher = require("crit.dispatcher")
local url_utils = require("lib.url_utils")
local h_twitch_change_state = hash("twitch_change_state")
local h_twitch_change_voting_enabled = hash("twitch_change_voting_enabled")
local h_twitch_change_voting_options = hash("twitch_change_voting_options")
local M = {}
local STATE_STOPPED = 1
local STATE_LOGIN = 2
local STATE_READY = 3
M.STATE_STOPPED = STATE_STOPPED
M.STATE_LOGIN = STATE_LOGIN
M.STATE_READY = STATE_READY
local LOGIN_PORT = 45678
local state = STATE_STOPPED
local login_server, irc_client, access_token, channel, bot_login = nil
local client_id = sys.get_config("twitch.client_id")
local retry_timer = nil
local retry_count = 0
local retries = {
	0,
	1,
	2,
	4,
	8,
	16
}
local voting_options = nil
local votes = {}
local votes_per_user = {}
local voting_enabled = false
local url_encode_component = url_utils.url_encode_component
local url_decode = url_utils.url_decode

function M.get_state()
	return state
end

local function set_state(new_state)
	if new_state ~= state then
		state = new_state

		dispatcher.dispatch(h_twitch_change_state, {
			state = new_state
		})
	end
end

local function set_voting_enabled(new_value)
	if new_value ~= voting_enabled then
		voting_enabled = new_value

		dispatcher.dispatch(h_twitch_change_voting_enabled, {
			enabled = new_value
		})
	end
end

function M.stop()
	if state == STATE_STOPPED then
		return
	end

	if login_server then
		login_server.stop()

		login_server = nil
	end

	if irc_client then
		irc_client.stop()

		irc_client = nil
	end

	if retry_timer then
		timer.cancel(retry_timer)

		retry_timer = nil
	end

	if access_token then
		access_token = nil
	end

	retry_count = 0

	set_voting_enabled(false)
	set_state(STATE_STOPPED)
end

local function start_bot()
	if not access_token or not channel or not bot_login then
		M.stop()

		return
	end

	if irc_client then
		irc_client.stop()
	end

	irc_client = irc.create({
		port = 6667,
		host = "irc.chat.twitch.tv",
		pass = "oauth:" .. access_token,
		nick = bot_login,
		channel = "#" .. channel,
		on_message = function (message, prefix)
			if not voting_enabled then
				return
			end

			local _, _, vote = message:find("^%s*(%S)%s*$")

			if not vote then
				return
			end

			vote = vote:upper()

			if not voting_options[vote] then
				return
			end

			local previous_vote = votes_per_user[prefix]

			if previous_vote then
				votes[previous_vote] = (votes[previous_vote] or 0) - 1
			end

			votes[vote] = (votes[vote] or 0) + 1
			votes_per_user[prefix] = vote
		end,
		on_join = function ()
			set_state(STATE_READY)
		end,
		on_disconnect = function ()
			retry_count = retry_count + 1
			local timeout = retries[retry_count]
			irc_client = nil

			if timeout then
				print("IRC chatbot disconnected. Retrying in " .. timeout .. "s")
			else
				print("IRC chatbot disconnected. Not retrying anymore")
				M.stop()

				return
			end

			if retry_timer then
				timer.cancel(retry_timer)
			end

			retry_timer = timer.delay(timeout, false, function ()
				retry_timer = nil

				start_bot()
			end)
		end
	})
	retry_timer = timer.delay(5, false, function ()
		retry_timer = nil
		retry_count = 0
	end)
end

local function parse_query_string(str)
	local result = {}

	for entry in str:gmatch("[^&?]+") do
		local _, _, key, value = entry:find("([^=]+)=(.*)")

		if key then
			result[key] = url_decode(value)
		end
	end

	return result
end

function M.login()
	M.stop()

	if not client_id then
		return
	end

	set_state(STATE_LOGIN)

	local redirect_uri = "http://localhost:" .. LOGIN_PORT .. "/twitch/oauth/redirect"
	local state_token = tostring(math.random())
	login_server = http_server.create(LOGIN_PORT)

	login_server.router.get("/twitch/oauth/redirect(.*)", function (matches)
		local redirect_page = require("main.twitch.redirect_page")

		return login_server.html(redirect_page(state_token))
	end)
	login_server.router.get("/twitch/login/(.*)", function (matches)
		local qs = parse_query_string(matches[1])

		if qs.state ~= state_token then
			return login_server.html("403 Unauthorized", 403)
		end

		access_token = qs.access_token

		if access_token == "" then
			access_token = nil
		end

		channel = qs.channel

		if channel == "" then
			channel = nil
		end

		bot_login = qs.login

		if bot_login == "" then
			bot_login = nil
		end

		if not access_token or not channel or not bot_login then
			return login_server.html("500 Expected access_token, channel and login", 403)
		end

		if defos and defos.activate then
			defos.activate()
		end

		timer.delay(0, false, function ()
			if login_server then
				login_server.stop()

				login_server = nil

				start_bot()
			end
		end)

		return login_server.json("{}")
	end)
	login_server.router.unhandled(function ()
		return login_server.html("404 Not Found", login_server.NOT_FOUND)
	end)
	login_server.start()

	local oauth_url = "https://id.twitch.tv/oauth2/authorize" .. "?client_id=" .. url_encode_component(client_id) .. "&redirect_uri=" .. url_encode_component(redirect_uri) .. "&state=" .. url_encode_component(state_token) .. "&response_type=token" .. "&scope=" .. url_encode_component("chat:read") .. "&force_verify=true"

	sys.open_url(oauth_url)
end

function M.update()
	if login_server then
		login_server.update()
	end

	if irc_client then
		irc_client.update()
	end
end

function M.get_state()
	return state
end

function M.is_voting_enabled()
	return voting_enabled
end

function M.is_voting_available()
	return state == STATE_READY and voting_options
end

function M.start_voting()
	if M.is_voting_available() then
		set_voting_enabled(true)

		votes = {}
		votes_per_user = {}
	end
end

function M.get_votes()
	return votes
end

function M.stop_voting()
	set_voting_enabled(false)

	votes = {}
	votes_per_user = {}
end

local function table_equals(a, b)
	if a == b then
		return true
	end

	if not a or not b then
		return false
	end

	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end

	for k, v in pairs(b) do
		if a[k] ~= v then
			return false
		end
	end

	return true
end

function M.set_voting_options(options)
	if table_equals(options, voting_options) then
		return
	end

	voting_options = options
	votes = {}
	votes_per_user = {}

	if not M.is_voting_available() then
		M.stop_voting()
	end

	dispatcher.dispatch(h_twitch_change_voting_options, {
		has_options = not not voting_options
	})
end

return M
