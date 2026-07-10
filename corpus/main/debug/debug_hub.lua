local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local Layout = require("crit.layout")
local h_debug_hub_toggle = hash("debug_hub_toggle")
local h_window_change_size = hash("window_change_size")
local h_click = hash("click")

local function send_message(message_id, message)
	return function ()
		dispatcher.dispatch(message_id, message)
	end
end

function _env:init()
	if env.bundled and not env.debug then
		return
	end

	gui.set_render_order(15)

	self.enabled = false
	self.sub_id = dispatcher.subscribe({
		h_debug_hub_toggle,
		h_window_change_size
	})
	self.container = gui.get_node("container")
	self.layout = Layout.new()

	self.layout:add_node(self.container, {
		grav_y = 0.5,
		grav_x = 0.5
	})

	self.nodes = {
		{
			node = gui.get_node("skip_scene"),
			action = send_message("skip_progression")
		},
		{
			node = gui.get_node("rewind_scene"),
			action = send_message("campaign_rewind")
		},
		{
			node = gui.get_node("toggle_debug"),
			action = send_message("debug_info_toggle")
		},
		{
			node = gui.get_node("profiler"),
			action = function ()
				msg.post("@system:", "toggle_profile")
			end
		},
		{
			node = gui.get_node("misc"),
			action = send_message("debug_misc_key")
		},
		{
			node = gui.get_node("toggle_map"),
			action = send_message("debug_map_toggle")
		},
		{
			node = gui.get_node("win"),
			action = send_message("game_over", {
				reason = "win",
				has_won = true
			})
		},
		{
			node = gui.get_node("lose_timeout"),
			action = send_message("game_over", {
				reason = "timeout",
				has_won = false
			})
		},
		{
			node = gui.get_node("lose_death"),
			action = send_message("game_over", {
				reason = "death",
				has_won = false
			})
		},
		{
			node = gui.get_node("close"),
			action = function ()
				return
			end
		}
	}

	gui.set_enabled(self.container, false)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_debug_hub_toggle then
		self.enabled = not self.enabled

		gui.set_enabled(self.container, self.enabled)
		msg.post(".", self.enabled and "acquire_input_focus" or "release_input_focus")
	elseif message_id == h_window_change_size then
		self.layout:place()
	end
end

function _env:on_input(action_id, action)
	if action_id == h_click then
		if action.released then
			local x, y = Layout.action_to_offset_design(action)

			for i, node in ipairs(self.nodes) do
				if gui.pick_node(node.node, x, y) then
					node.action()
					dispatcher.dispatch(h_debug_hub_toggle)
				end
			end
		end

		return true
	end
end
