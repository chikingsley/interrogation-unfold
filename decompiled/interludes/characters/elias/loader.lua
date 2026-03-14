local dispatcher = require("crit.dispatcher")
local h_interludes_animate_character = hash("interludes_animate_character")
local h_transition_started = hash("transition_started")
local h_transition_completed = hash("transition_completed")
local create_next_sprite, load_next_sprite = nil
local factories = {
	hash("idle1"),
	hash("idle2"),
	hash("idle3"),
	hash("idle4"),
	hash("idle2")
}

function _env:init()
	self.unload_queued = {}
	self.next_factory_id = 1

	load_next_sprite(self)
	create_next_sprite(self)

	self.sub_id = dispatcher.subscribe({
		h_interludes_animate_character,
		h_transition_started,
		h_transition_completed
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function unload_factory(self, fact)
	if collectionfactory.get_status(fact) == collectionfactory.STATUS_LOADING then
		self.unload_queued[fact] = true
	else
		collectionfactory.unload(fact)
	end
end

function load_next_sprite(self)
	local fact = msg.url(nil, nil, factories[self.next_factory_id])
	self.next_factory_id = self.next_factory_id + 1

	collectionfactory.load(fact, function (self_, url, result)
		if result then
			if self.unload_queued[fact] then
				self.unload_queued[fact] = nil

				collectionfactory.unload(fact)
			end
		else
			error("load_next_sprite: Failed to load resources for: " .. fact)
		end
	end)

	if self.pending_factory then
		unload_factory(self, self.pending_factory)
	end

	self.pending_factory = fact
end

local h__go = hash("/go")

function create_next_sprite(self, initial_animation)
	local fact = self.pending_factory
	self.pending_factory = nil

	if fact then
		if self.active_sprite then
			go.delete(self.active_sprite, true)
		end

		self.active_sprite = collectionfactory.create(fact, nil, nil, {
			[h__go] = {
				animate_on_load = false,
				initial_animation = initial_animation,
				name = self.name
			}
		})[h__go]

		unload_factory(self, fact)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_transition_started then
		load_next_sprite(self)
	elseif message_id == h_transition_completed then
		create_next_sprite(self, message.initial_animation)
	end
end
