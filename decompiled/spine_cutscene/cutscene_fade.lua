local dispatcher = require("crit.dispatcher")
local h_cutscene_fade_in = hash("cutscene_fade_in")
local h_cutscene_fade_out = hash("cutscene_fade_out")
local h_color = hash("color")

function _env:init()
	self.box = gui.get_node("box")

	gui.set_color(self.box, vmath.vector4(0, 0, 0, 1))
	gui.set_render_order(15)

	self.sub_id = dispatcher.subscribe({
		h_cutscene_fade_in,
		h_cutscene_fade_out
	})
end

function _env:on_message(message_id, message, sender)
	if message_id == h_cutscene_fade_in then
		gui.animate(self.box, h_color, vmath.vector4(0), gui.EASING_LINEAR, message.fade_duration, 0.5, function ()
			gui.set_enabled(self.box, false)
		end)
	elseif message_id == h_cutscene_fade_out then
		gui.set_color(self.box, vmath.vector4(0))
		gui.set_enabled(self.box, true)
		gui.animate(self.box, h_color, vmath.vector4(0, 0, 0, 1), gui.EASING_LINEAR, message.fade_duration)
	end
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end
