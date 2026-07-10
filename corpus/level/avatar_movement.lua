local dispatcher = require("crit.dispatcher")
local filters = require("crit.filters")
local state = require("level.state")
local large_ui = require("lib.large_ui")
local Layout = require("crit.layout")
local filter = filters.low_pass(1)
local h_table_set_position = hash("table_set_position")
local h_init_level = hash("init_level")
local h_window_change_size = hash("window_change_size")
local panel_width = 730
local avatar_height = 470
local table_height = 216
local total_table_height = avatar_height + table_height
local table_original_position, position_y = nil

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_level,
		h_window_change_size
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function broadcast_position()
	local position_x = state.offset * panel_width * 0.5 * (state.lite and -1 or 1)
	state.table_position = vmath.vector3(position_x, position_y, table_original_position.z)

	dispatcher.dispatch(h_table_set_position)
end

function _env:update(dt)
	local last_offset = state.offset
	local offset = filter(last_offset, state.torture_room_shown and 0 or 1, dt)
	state.offset = offset

	if offset ~= last_offset then
		broadcast_position()
	end
end

local function on_change_size()
	local scale = 1
	position_y = table_original_position.y

	if large_ui.enabled then
		position_y = position_y + state.y_offset
	end

	if not state.lite then
		local extra_space = (Layout.projection_height - Layout.design_height) * 0.8
		scale = (total_table_height + extra_space) / total_table_height
		position_y = position_y - extra_space * 0.5 + table_height * (scale - 1)
	end

	state.table_scale = scale

	broadcast_position()
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_level then
		local table_url = msg.url("table")
		state.offset = 1
		table_original_position = go.get_position(table_url)
		state.table_original_position = table_original_position

		on_change_size()
	elseif message_id == h_window_change_size then
		on_change_size()
	end
end
