local h_acquire_input_focus = hash("acquire_input_focus")

function _env:init()
	msg.post("controller", h_acquire_input_focus)
	msg.post("gui_intro", h_acquire_input_focus)
	msg.post("gui_questions", h_acquire_input_focus)
	msg.post("gui_twitch", h_acquire_input_focus)
end
