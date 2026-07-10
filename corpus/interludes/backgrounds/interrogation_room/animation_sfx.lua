local h_elias_idle4_cut = hash("elias_idle4_cut")
local h_elias_idle4_draw_knife = hash("elias_idle4_draw_knife")
local h_elias_idle3_to_idle4 = hash("elias_idle3_to_idle4")
local h_elias_idle3_grab = hash("elias_idle3_grab")
local h_elias_idle2_to_idle3 = hash("elias_idle2_to_idle3")
local h_elias_idle4_put_away_knife = hash("elias_idle4_put_away_knife")
local h_elias_idle4_to_idle2 = hash("elias_idle4_to_idle2")
local h_elias_idle1_to_idle2 = hash("elias_idle1_to_idle2")

return {
	[h_elias_idle1_to_idle2] = {
		sfx = "Sit Down",
		delay = 0
	},
	[h_elias_idle2_to_idle3] = {
		sfx = "Rise",
		delay = 0
	},
	[h_elias_idle3_grab] = {
		sfx = "Grab",
		delay = 0.45
	},
	[h_elias_idle3_to_idle4] = {
		sfx = "Slam Table",
		delay = 0
	},
	[h_elias_idle4_draw_knife] = {
		sfx = "Draw Knife",
		delay = 0.2
	},
	[h_elias_idle4_cut] = {
		sfx = "Cut",
		delay = 0
	},
	[h_elias_idle4_put_away_knife] = {
		sfx = "Put Away Knife",
		delay = 0.1
	},
	[h_elias_idle4_to_idle2] = {
		sfx = "Sit Down",
		delay = 0.2
	}
}
