local dispatcher = require("crit.dispatcher")
local h_spine_event = hash("spine_event")
local h_play_sfx = hash("play_sfx")
local h_init_level = hash("init_level")
local h_cabinet_open = hash("cabinet_open")
local h_cabinet_close = hash("cabinet_close")
local h_cabinet_close_started = hash("cabinet_close_started")
local h_cabinet_open_started = hash("cabinet_open_started")
local h_cabinet_open_complete = hash("cabinet_open_complete")
local h_level_set_tortures_enabled = hash("level_set_tortures_enabled")
local h_level_skip_next_torture_enable = hash("level_skip_next_torture_enable")
local h_open = hash("open")
local h_close = hash("close")
local h_state_closed = hash("state_closed")
local h_state_open = hash("state_open_default")
local h_cursor = hash("cursor")
local h_drawer_clunk = hash("drawer_clunk")
local h_drawer_open = hash("drawer_open")
local h_drawer_close = hash("drawer_close")
local animation_playback_rate = 1.5

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_cabinet_open,
		h_cabinet_close,
		h_level_set_tortures_enabled,
		h_level_skip_next_torture_enable
	})
	local this_go = msg.url(".")
	self.drawer = msg.url(this_go.socket, this_go.path, self.spine_scene)
	self.current_animation = false
	self.current_loop_animation = h_state_closed
	self.current_timer = false
	self.open_pending = false
	self.closed = true

	spine.play_anim(self.drawer, h_state_closed, go.PLAYBACK_LOOP_FORWARD)
end

local function animate_cabinet(self, anim, post_anim_loop, is_close)
	if is_close and self.closed then
		return
	end

	local delay = is_close and self.close_delay or self.open_delay

	if is_close then
		self.closed = true

		dispatcher.dispatch(h_cabinet_close_started)
	else
		self.closed = false
		self.open_pending = true

		dispatcher.dispatch(h_cabinet_open_started)

		if not self.current_animation and self.drawer_id == 1 then
			dispatcher.dispatch(h_play_sfx, {
				sfx = "drawer_key",
				parameters = {
					IsOpening = 1
				}
			})
		end
	end

	if self.current_timer then
		timer.cancel(self.current_timer)

		self.current_timer = false
	end

	self.current_timer = timer.delay(delay, false, function ()
		self.current_timer = false
		local cabinet = self.drawer
		local play_properties = {
			playback_rate = animation_playback_rate
		}

		if self.current_animation then
			local cursor = go.get(cabinet, h_cursor)
			play_properties.offset = 1 - cursor
			play_properties.blend_duration = 0.25
		elseif is_close and self.open_pending then
			play_properties.offset = 1
		end

		self.current_loop_animation = false
		self.current_animation = anim
		self.open_pending = false

		spine.cancel(cabinet)
		spine.play_anim(cabinet, anim, go.PLAYBACK_ONCE_FORWARD, play_properties, function ()
			self.current_animation = false

			if post_anim_loop then
				self.current_loop_animation = post_anim_loop

				spine.play_anim(cabinet, post_anim_loop, go.PLAYBACK_LOOP_FORWARD)
			end

			if not is_close then
				dispatcher.dispatch(h_cabinet_open_complete)
			elseif self.drawer_id == 1 then
				timer.delay(0.2, false, function ()
					dispatcher.dispatch(h_play_sfx, {
						sfx = "drawer_key",
						parameters = {
							IsOpening = 0
						}
					})
				end)
			end
		end)
	end)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_cabinet_close then
		local drawer_id = message.drawer_id

		if drawer_id and drawer_id == self.drawer_id then
			animate_cabinet(self, h_close, h_state_closed, true)
		elseif not drawer_id then
			animate_cabinet(self, h_close, h_state_closed, true)
		end
	elseif message_id == h_cabinet_open then
		if message.drawer_id == self.drawer_id then
			if not self.closed then
				return
			end

			animate_cabinet(self, h_open, h_state_open)
		end
	elseif message_id == h_spine_event then
		local event_id = message.event_id

		if event_id == h_drawer_clunk then
			dispatcher.dispatch(h_play_sfx, {
				sfx = "drawer_hit"
			})
		elseif event_id == h_drawer_open then
			dispatcher.dispatch(h_play_sfx, {
				sfx = "drawer_roll",
				parameters = {
					IsOpening = 1
				}
			})
		elseif event_id == h_drawer_close then
			dispatcher.dispatch(h_play_sfx, {
				sfx = "drawer_roll",
				parameters = {
					IsOpening = 0
				}
			})
		end
	end
end
