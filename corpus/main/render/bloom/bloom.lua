local dispatcher = require("crit.dispatcher")
local render_helper = require("lib.render_helper")
local env = require("lib.environment")
local h_bloom_enable = hash("bloom_enable")
local h_bloom_disable = hash("bloom_disable")
local h_bloom_update = hash("bloom_update")
local h_radius = hash("radius")
local h_treshold = hash("treshold")
local h_tint = hash("tint")
local set_radius, set_treshold, set_tint = nil

function _env:init()
	self.treshold_model = msg.url("#treshold")
	self.horiz_model = msg.url("#horiz")
	self.vert_model = msg.url("#vert")

	if self.enabled and self.starts_enabled then
		render_helper.bloom = true
	end

	set_radius(self, self.bloom_radius)
	set_treshold(self, self.bloom_treshold)
	set_tint(self, self.bloom_tint)

	self.sub_id = dispatcher.subscribe({
		self.enable_message,
		self.disable_message,
		self.refresh_message
	})
end

function set_treshold(self, treshold)
	model.set_constant(self.treshold_model, h_treshold, vmath.vector4(treshold))
end

function set_tint(self, tint)
	model.set_constant(self.vert_model, h_tint, vmath.vector4(tint))
end

function set_radius(self, radius)
	model.set_constant(self.horiz_model, h_radius, vmath.vector4(radius))
	model.set_constant(self.vert_model, h_radius, vmath.vector4(radius))
end

function _env:final()
	render_helper.bloom = false

	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == self.enable_message or message_id == h_bloom_enable then
		if env.disable_bloom or not self.enabled then
			return
		end

		if message.no_bloom then
			return
		end

		render_helper.bloom = true
	elseif message_id == self.disable_message or message_id == h_bloom_disable then
		if message.no_bloom then
			return
		end

		render_helper.bloom = false
	elseif message_id == self.update_message or message_id == h_bloom_update then
		if message.no_bloom then
			return
		end

		if message.radius then
			set_radius(self, message.radius)
		end

		if message.treshold then
			set_treshold(self, message.treshold)
		end

		if message.tint then
			set_tint(self, message.tint)
		end
	end
end
