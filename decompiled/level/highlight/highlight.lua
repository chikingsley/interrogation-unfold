local dispatcher = require("crit.dispatcher")
local h_level_highlight = hash("level_highlight")
local h_level_highlight_hide = hash("level_highlight_hide")
local h_level_highlight_show = hash("level_highlight_show")
local h_level_highlight_cancel = hash("level_highlight_cancel")
local h_level_highlight_set_enabled = hash("level_highlight_set_enabled")
local h_tintw = hash("tint.w")
local h_enable = hash("enable")
local h_disable = hash("disable")

function _env:init()
	self.highlighted = false
	self.hidden = false
	local sprite_url = msg.url()
	sprite_url = msg.url(sprite_url.socket, sprite_url.path, self.sprite_component)
	self.sprite = sprite_url

	msg.post(self.sprite, h_disable)
	go.set(self.sprite, h_tintw, 0)

	self.sub_id = dispatcher.subscribe({
		h_level_highlight,
		h_level_highlight_cancel,
		h_level_highlight_hide,
		h_level_highlight_show
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function get_duration(self)
	return (1 - go.get(self.sprite, h_tintw) / self.fade_alpha_max) * self.fade_duration
end

local function set_sprite_enabled(self, enabled)
	dispatcher.dispatch(h_level_highlight_set_enabled, {
		object_id = self.object_id,
		enabled = enabled
	})
	msg.post(self.sprite, enabled and h_enable or h_disable)
end

local function start_pulsating(self)
	local sprite = self.sprite

	set_sprite_enabled(self, true)
	go.cancel_animations(sprite, h_tintw)

	local duration = math.max(get_duration(self), 0.0001)

	go.animate(sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, self.fade_alpha_max, go.EASING_OUTQUAD, duration, 0, function ()
		go.animate(sprite, h_tintw, go.PLAYBACK_LOOP_PINGPONG, self.fade_alpha_min, go.EASING_INOUTQUAD, self.fade_period)
	end)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_level_highlight then
		if self.object_id == message.object and not self.highlighted then
			self.highlighted = true

			if not self.hidden then
				start_pulsating(self)
			end
		end
	elseif message_id == h_level_highlight_cancel then
		if self.highlighted then
			self.highlighted = false

			if not self.hidden then
				local sprite = self.sprite

				set_sprite_enabled(self, true)
				go.cancel_animations(sprite, h_tintw)

				local duration = math.max(self.fade_duration - get_duration(self), 0.0001)

				go.animate(sprite, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_OUTQUAD, duration, 0, function ()
					go.set(sprite, h_tintw, 0)
					set_sprite_enabled(self, false)
				end)
			end
		end
	elseif message_id == h_level_highlight_hide then
		if self.object_id == message.object and not self.hidden then
			self.hidden = true
			local sprite = self.sprite

			go.cancel_animations(sprite, h_tintw)

			if self.highlighted then
				go.set(sprite, h_tintw, 0)
			end

			set_sprite_enabled(self, false)
		end
	elseif message_id == h_level_highlight_show and self.object_id == message.object and self.hidden then
		self.hidden = false

		if self.highlighted then
			start_pulsating(self)
		end
	end
end
