local dispatcher = require("crit.dispatcher")
local h_animation = hash("animation")
local h_spine_event = hash("spine_event")
local h_gunshot = hash("gunshot")
local h_show_rewind = hash("show_rewind")
local h_switch_materials = hash("switch_materials")
local h_show_newspaper = hash("show_newspaper")
local h_play_sfx = hash("play_sfx")
local h_material = hash("material")
local h_assassinated_rewind = hash("assassinated_rewind")

function _env:init()
	local spine_scene = msg.url("#spine")

	spine.play_anim(spine_scene, h_animation, go.PLAYBACK_ONCE_FORWARD)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_spine_event then
		local event_id = message.event_id

		if event_id == h_gunshot then
			dispatcher.dispatch(h_play_sfx, {
				sfx = "get_shot"
			})
		elseif event_id == h_show_newspaper then
			timer.delay(0.3, false, function ()
				dispatcher.dispatch(h_play_sfx, {
					sfx = "newspaper_slide"
				})
			end)
		elseif event_id == h_show_rewind then
			dispatcher.dispatch(h_assassinated_rewind)
		elseif event_id == h_switch_materials then
			go.set("#spine", h_material, self.my_material)
		end
	end
end
