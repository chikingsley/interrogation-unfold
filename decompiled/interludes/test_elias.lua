local scenes = require("main.progression.scenes")
local interludes = require("interludes.interface")
local dispatcher = require("crit.dispatcher")
local h_end_scene = hash("end_scene")
local progression = require("crit.progression")
local animations = {
	{
		"elias_idle1_nod",
		"elias_idle1_glasses",
		"elias_idle1_raise_eyebrow",
		"elias_idle1_to_idle2"
	},
	{
		"elias_idle2_nod",
		"elias_idle2_explain",
		"elias_idle2_headshake",
		"elias_idle2_to_idle3"
	},
	{
		"elias_idle3_grab",
		"elias_idle3_glasses",
		"elias_idle3_headshake",
		"elias_idle3_to_idle4"
	},
	{
		"elias_idle4_look_away",
		"elias_idle4_point",
		"elias_idle4_cut",
		"elias_idle4_draw_knife",
		"elias_idle4_put_away_knife",
		"elias_idle4_to_idle2"
	}
}

return function (opts)
	opts = opts or {}

	scenes.load_scene("interludes", {
		background = opts.background or "interrogation_room"
	})
	interludes.preload_characters({
		"elias"
	})
	interludes.show_character("elias", interludes.INTERVIEW, {
		animate_movement = false,
		nametag = ""
	})

	for i, animations_in_phase in ipairs(animations) do
		interludes.show_bubble("elias", "Switching to phase " .. i)

		if i > 1 then
			progression.wait(2)
		end

		interludes.hide_bubbles()

		repeat
			local choice = interludes.show_choices(animations_in_phase)

			interludes.animate_character("elias", animations_in_phase[choice])
		until choice == #animations_in_phase
	end

	interludes.show_bubble("elias", "End of sequence")
	interludes.wait_for_input()
	interludes.hide_all_characters()
	dispatcher.dispatch(h_end_scene)
end
