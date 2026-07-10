local twitch = require("main.twitch.twitch")
local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local h_twitch_login = hash("twitch_login")
local h_twitch_stop = hash("twitch_stop")

function _env:init()
	if env.twitch_login then
		twitch.login()
	end

	dispatcher.subscribe({
		h_twitch_login,
		h_twitch_stop
	})
end

function _env:on_message(message_id, message)
	if message_id == h_twitch_login then
		twitch.login()
	elseif message_id == h_twitch_stop then
		twitch.stop()
	end
end

function _env:final()
	twitch.stop()
end

function _env:update()
	twitch.update()
end
