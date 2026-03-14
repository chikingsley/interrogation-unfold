local store = require("level.store")
local state = require("level.state")
local interface = require("level.interface")
local dispatcher = require("crit.dispatcher")
local controller = require("level.controller")
local save_file = require("lib.save_file")
local config = save_file.config
local PHASE_RUNNING = state.PHASE_RUNNING
local abs = math.abs
local max = math.max
local h_game_over = hash("game_over")

function _env:init()
	interface._reset()
	controller.init()

	self.sub_id = dispatcher.subscribe({
		h_game_over
	})
end

function _env:final()
	controller.final()
	dispatcher.unsubscribe(self.sub_id)
	interface._reset()
end

function _env:update(dt)
	if state.paused then
		return
	end

	if state.phase == PHASE_RUNNING then
		if config.real_time_interrogation then
			state.time_elapsed = state.time_elapsed + dt
		else
			local value = state.time_elapsed
			local target = state.turn_time_elapsed

			if value ~= target then
				local delta = target - value
				local velocity = max(5, abs(delta)) * 2

				if delta > 0 then
					value = value + dt * velocity

					if target < value then
						value = target
					end
				else
					value = value - dt * velocity

					if target > value then
						value = target
					end
				end
			end

			state.time_elapsed = value
		end

		if store.time_limit and store.time_limit <= state.time_elapsed then
			state.time_elapsed = store.time_limit

			store.fire_event("lose", {
				"timeout"
			})

			return
		end

		interface._check_timed_callbacks(state.time_elapsed)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_game_over and not message.has_won then
		timer.delay(3, false, function ()
			dispatcher.dispatch("end_scene", {
				has_won = false,
				reason = state.game_over_reason
			})
		end)
	end
end
