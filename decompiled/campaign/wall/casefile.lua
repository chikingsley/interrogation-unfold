local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local state = require("level.state")
local h_wall_object_select = hash("wall_object_select")
local h_wall_object_deselect = hash("wall_object_deselect")
local h_wall_object_loaded = hash("wall_object_loaded")
local h_get_input_focus = hash("get_input_focus")
local h_init_level = hash("init_level")
local h_drawer_casefile_request_open = hash("drawer_casefile_request_open")
local h_drawer_casefile_set_open = hash("drawer_casefile_set_open")
local h_casefile = hash("casefile")

function _env:init()
	self.factory = msg.url("#factory")
	self.close_button = msg.url("close_button")
	self.sub_id = dispatcher.subscribe({
		h_wall_object_select,
		h_wall_object_deselect,
		h_drawer_casefile_request_open
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_wall_object_select then
		if message.object_type == h_casefile then
			self.casefile_go = factory.create(self.factory)

			factory.unload(self.factory)

			state.phase = state.PHASE_INTRO
			local data = json.decode(sys.load_resource("/episodes/data/episode" .. message.casefile_episode_index .. ".json"))

			store.init(data)

			for subject_id, subject in ipairs(store.subjects) do
				store.show_subject(subject_id)

				if hash(subject.avatar) == message.casefile_subject_name then
					state.phase = state.PHASE_RUNNING
					state.current_room = subject.room_index
					state.current_subject = subject_id
				end
			end

			msg.post(self.casefile_go, h_init_level, {
				auto_open_delay = 0,
				ignore_open_requests = true,
				force_casefile = true,
				no_background = true,
				position = vmath.vector3(100, -1400, 0)
			})
			msg.post(self.casefile_go, h_get_input_focus)

			self.timer = timer.delay(0, false, function ()
				self.timer = timer.delay(0, false, function ()
					self.timer = timer.delay(0, false, function ()
						self.timer = nil

						dispatcher.dispatch(h_wall_object_loaded, message)
					end)
				end)
			end)
		end
	else
		if message_id == h_wall_object_deselect then
			local casefile_go = self.casefile_go

			if casefile_go then
				self.casefile_go = nil

				if self.timer then
					timer.cancel(self.timer)

					self.timer = nil
				end

				dispatcher.dispatch(h_drawer_casefile_set_open, {
					value = false
				})
				timer.delay(1, false, function ()
					go.delete(casefile_go, true)
				end)
			end

			return
		end

		if message_id == h_drawer_casefile_request_open and self.casefile_go then
			if message.value then
				dispatcher.dispatch(h_drawer_casefile_set_open, message)
			else
				dispatcher.dispatch(h_wall_object_deselect)
			end
		end
	end
end
