local dispatcher = require("crit.dispatcher")
local store = require("level.store")
local filters = require("crit.filters")
local state = require("level.state")
local Layout = require("crit.layout")
local h_init_level = hash("init_level")
local h_set_subject = hash("set_subject")
local h_place_sprite = hash("place_sprite")
local h_start_game = hash("start_game")
local h_run_animation = hash("run_animation")
local h_go_off_record = hash("go_off_record")
local h_kill = hash("kill")
local h_pause = hash("pause")
local h_drawer_casefile_set_open = hash("drawer_casefile_set_open")
local h_click = hash("click")
local h_sprite = hash("/sprite")
local h_companion = hash("/companion")
local h_set_parent = hash("set_parent")
local h_show_subject = hash("show_subject")
local h_level_avatar_play_animation = hash("level_avatar_play_animation")
local filter = filters.low_pass(2)

function _env:init()
	self.go = go.get_id()
	self.current_room = 1
	self.current_position = 1
	self.mouse_dx = {
		0,
		0
	}
	self.mouse_dt = {
		0,
		0
	}
	self.mouse_dx_frame = 1
	self.mouse_down = false
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_start_game,
		h_set_subject,
		h_show_subject,
		h_kill,
		h_pause,
		h_go_off_record,
		h_level_avatar_play_animation,
		h_drawer_casefile_set_open
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function place_sprite(self, subject_id, sprite, dt)
	local room_index = store.subjects[subject_id].room_index
	local offset = room_index and room_index - self.current_position

	msg.post(sprite, h_place_sprite, {
		offset = offset,
		dt = dt
	})
end

function _env:update(dt)
	local mouse_dx_frame = 3 - self.mouse_dx_frame
	self.mouse_dx_frame = mouse_dx_frame
	self.mouse_dx[mouse_dx_frame] = 0
	self.mouse_dt[mouse_dx_frame] = dt

	if not self.mouse_down then
		self.current_position = filter(self.current_position, self.current_room, dt)
	end

	for index, collection in pairs(self.collections) do
		for i, sprite in pairs(collection) do
			place_sprite(self, index, sprite, dt)
		end
	end
end

function _env:on_input(action_id, action)
	if action_id == h_click then
		if not action.pressed then
			if not self.mouse_down or state.phase ~= state.PHASE_RUNNING then
				return false
			end

			local mouse_dx_frame = self.mouse_dx_frame
			self.mouse_dx[mouse_dx_frame] = self.mouse_dx[mouse_dx_frame] + action.dx
			local d_pos = -action.screen_dx * Layout.viewport_to_projection_scale_x * 0.0025 / state.table_scale
			local current_position = self.current_position

			if current_position < 1 or store.room_count < current_position then
				d_pos = d_pos * 0.3
			end

			current_position = current_position + d_pos
			self.current_position = current_position
			local target = math.max(1, math.min(store.room_count, math.floor(current_position + 0.5)))

			if target ~= self.current_room then
				self.current_room = target

				dispatcher.dispatch(h_set_subject, {
					was_drag = true,
					subject_id = store.subject_in_room[target]
				})
			end
		end

		if action.pressed then
			if not state.on_record or state.phase ~= state.PHASE_RUNNING then
				return false
			end

			self.mouse_down = true
		elseif action.released then
			if not self.mouse_down or state.phase ~= state.PHASE_RUNNING then
				return false
			end

			self.mouse_down = false
			local velocity = -(self.mouse_dx[1] + self.mouse_dx[2]) / (self.mouse_dt[1] + self.mouse_dt[1])
			local current_room = self.current_room
			local current_position = self.current_position

			if math.abs(velocity) > 400 and (velocity < 0 and current_position < current_room or velocity >= 0 and current_room < current_position) then
				local target = self.current_room + (velocity < 0 and -1 or 1)

				if target >= 1 and target <= store.room_count then
					self.current_room = target

					dispatcher.dispatch(h_set_subject, {
						was_drag = true,
						subject_id = store.subject_in_room[target]
					})
				end
			end
		end

		return true
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_level_avatar_play_animation then
		for i, sprite in pairs(self.collections[message.subject_id]) do
			msg.post(sprite, h_run_animation, message)
		end
	elseif message_id == h_init_level then
		self.subjects = {}
		self.collections = {}

		for id, subject in ipairs(store.subjects) do
			if subject.enabled then
				local factory_url = "#" .. subject.avatar
				local new_collection = nil
				local ok, err = pcall(function ()
					new_collection = collectionfactory.create(factory_url, vmath.vector3(), vmath.quat(), {
						[h_sprite] = {
							subject_id = id
						},
						[h_companion] = {
							subject_id = id
						}
					})
				end)

				if not ok then
					print("ERROR: While loading avatar " .. subject.avatar .. ": " .. err)

					new_collection = collectionfactory.create("#actor", vmath.vector3(), vmath.quat(), {
						[h_sprite] = {
							subject_id = id
						},
						[h_companion] = {
							subject_id = id
						}
					})
				end

				new_collection = {
					[h_sprite] = new_collection[h_sprite],
					[h_companion] = new_collection[h_companion]
				}
				self.collections[id] = new_collection

				for i, sprite in pairs(new_collection) do
					msg.post(sprite, h_set_parent, {
						keep_world_transform = 0,
						parent_id = self.go
					})
					place_sprite(self, id, sprite)
				end
			end
		end
	elseif message_id == h_set_subject then
		self.current_room = state.current_room

		if not message.was_drag then
			self.mouse_down = false
		end
	elseif message_id == h_show_subject then
		if state.phase == state.PHASE_RUNNING then
			for i, sprite in pairs(self.collections[message.subject_id]) do
				msg.post(sprite, h_start_game)
			end
		end
	elseif message_id == h_start_game then
		for id, collection in pairs(self.collections) do
			if store.subjects[id].shown then
				for i, sprite in pairs(collection) do
					msg.post(sprite, h_start_game)
				end
			end
		end
	elseif message_id == h_kill then
		for i, sprite in pairs(self.collections[self.current_room]) do
			msg.post(sprite, h_kill)
		end
	elseif message_id == h_pause or message_id == h_go_off_record or message_id == h_drawer_casefile_set_open then
		self.mouse_down = false
	end
end
