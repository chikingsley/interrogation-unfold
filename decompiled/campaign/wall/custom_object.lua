local dispatcher = require("crit.dispatcher")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_wall_object_loaded = hash("wall_object_loaded")
local h_custom = hash("custom")
local h_position = hash("position")
local h_scale = hash("scale")
local h__go = hash("/go")
local initial_position = vmath.vector3(0, -2000, 0.1)
local initial_scale_factor = 0.6
local animation_duration = 0.5

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_wall_object_select,
		h_wall_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_wall_object_select then
		if message.object_type ~= h_custom then
			return
		end

		local factory_url = msg.url(nil, nil, message.custom_object_id)
		local collection = collectionfactory.create(factory_url, vmath.vector3(0, 0, 0.1))
		local object_id = collection[h__go]
		self.collection = collection
		self.object_id = object_id
		local target_position, target_scale = nil

		if object_id then
			target_position = go.get(object_id, h_position)
			target_scale = go.get(object_id, h_scale)
			local initial_scale = vmath.vector3(target_scale.x * initial_scale_factor, target_scale.y * initial_scale_factor, target_scale.z)
			self.initial_scale = initial_scale

			go.set(object_id, h_scale, initial_scale)
			go.set(object_id, h_position, initial_position)
		end

		self.timer = timer.delay(0, false, function ()
			self.timer = timer.delay(0, false, function ()
				self.timer = nil

				if object_id then
					go.cancel_animations(object_id, h_position)
					go.cancel_animations(object_id, h_scale)
					go.animate(object_id, h_position, go.PLAYBACK_ONCE_FORWARD, target_position, go.EASING_OUTCUBIC, animation_duration, 0)
					go.animate(object_id, h_scale, go.PLAYBACK_ONCE_FORWARD, target_scale, go.EASING_OUTCUBIC, animation_duration, 0)
				end

				dispatcher.dispatch(h_wall_object_loaded, message)
			end)
		end)

		return
	end

	if message_id == h_wall_object_deselect then
		local collection = self.collection

		if not collection then
			return
		end

		if self.timer then
			timer.cancel(self.timer)

			self.timer = nil
		end

		local object_id = self.object_id
		self.collection = nil
		self.object_id = nil

		if object_id then
			go.cancel_animations(object_id, h_position)
			go.cancel_animations(object_id, h_scale)
			go.animate(object_id, h_scale, go.PLAYBACK_ONCE_FORWARD, self.initial_scale, go.EASING_INOUTCUBIC, animation_duration)
			go.animate(object_id, h_position, go.PLAYBACK_ONCE_FORWARD, initial_position, go.EASING_INOUTCUBIC, animation_duration, 0, function ()
				go.delete(collection, true)
			end)
		end
	end
end
