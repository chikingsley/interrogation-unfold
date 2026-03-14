local all_animations = require("main.animations.animations")
local h_elias_idle4 = hash("elias_idle4")
local h_elias_idle4_cut = hash("elias_idle4_cut")
local h_elias_idle4_cut_hand = hash("elias_idle4_cut_hand")
local h_elias_idle4_point = hash("elias_idle4_point")
local h_elias_idle4_draw_knife = hash("elias_idle4_draw_knife")
local h_elias_idle4_look_away = hash("elias_idle4_look_away")
local h_knife_hidden = hash("knife_hidden")
local h_knife_shown = hash("knife_shown")
local h_elias_idle4_put_away_knife = hash("elias_idle4_put_away_knife")
local h_elias_idle4_to_idle2 = hash("elias_idle4_to_idle2")
local h_elias_idle2 = hash("elias_idle2")
local h_elias_idle4_cut7 = hash("elias_idle4_cut7")
local h_elias_idle4_cut7_hand = hash("elias_idle4_cut7_hand")
local h_pixel = hash("pixel")
local h_elias_idle4_draw_knife10 = hash("elias_idle4_draw_knife10")
local h_elias_idle4_cut1 = hash("elias_idle4_cut1")
local h_elias_idle41 = hash("elias_idle41")
local h_elias_idle42 = hash("elias_idle42")
local h_elias_idle43 = hash("elias_idle43")
local h_elias_idle4_cut2 = hash("elias_idle4_cut2")
local h_elias_idle4_cut3 = hash("elias_idle4_cut3")
local h_elias_idle4_cut4 = hash("elias_idle4_cut4")
local h_elias_idle4_cut5 = hash("elias_idle4_cut5")
local h_elias_idle4_cut6 = hash("elias_idle4_cut6")
local h_elias_idle4_cut8 = hash("elias_idle4_cut8")
local h_elias_idle4_draw_knife4 = hash("elias_idle4_draw_knife4")
local h_elias_idle4_cut8_hand = hash("elias_idle4_cut8_hand")
local h_elias_idle4_point1 = hash("elias_idle4_point1")
local h_elias_idle4_point2 = hash("elias_idle4_point2")
local h_elias_idle4_point3 = hash("elias_idle4_point3")
local h_elias_idle4_point4 = hash("elias_idle4_point4")
local h_elias_idle4_draw_knife1 = hash("elias_idle4_draw_knife1")
local h_elias_idle4_draw_knife2 = hash("elias_idle4_draw_knife2")
local h_elias_idle4_draw_knife3 = hash("elias_idle4_draw_knife3")
local h_elias_idle4_draw_knife5 = hash("elias_idle4_draw_knife5")
local h_elias_idle4_draw_knife6 = hash("elias_idle4_draw_knife6")
local h_elias_idle4_draw_knife7 = hash("elias_idle4_draw_knife7")
local h_elias_idle4_draw_knife8 = hash("elias_idle4_draw_knife8")
local h_elias_idle4_draw_knife9 = hash("elias_idle4_draw_knife9")
local h_elias_idle4_look_away1 = hash("elias_idle4_look_away1")
local h_elias_idle4_look_away2 = hash("elias_idle4_look_away2")
local h_elias_idle4_look_away3 = hash("elias_idle4_look_away3")
local h_elias_knife_separated = hash("elias_knife_separated")
local h_elias_idle2_to_idle35 = hash("elias_idle2_to_idle35")
local h_elias_idle2_to_idle34 = hash("elias_idle2_to_idle34")
local h_elias_idle2_to_idle33 = hash("elias_idle2_to_idle33")
local h_elias_idle2_to_idle32 = hash("elias_idle2_to_idle32")
local h_elias_idle2_to_idle31 = hash("elias_idle2_to_idle31")
local h_elias_idle21 = hash("elias_idle21")
local h_elias_idle22 = hash("elias_idle22")
local h_elias_idle23 = hash("elias_idle23")
local animations = {
	images = {
		[h_elias_idle4_cut7] = {
			offset = vmath.vector3(-12.5, -0.5, 0)
		},
		[h_elias_idle4_cut7_hand] = {
			offset = vmath.vector3(63.5, -11, 0)
		},
		[h_pixel] = {
			offset = vmath.vector3(0, 0, 0)
		},
		[h_elias_idle4_draw_knife10] = {
			offset = vmath.vector3(-12, -13, 0)
		},
		[h_elias_idle4_cut1] = {
			offset = vmath.vector3(50, -21.5, 0)
		},
		[h_elias_idle41] = {
			offset = vmath.vector3(-7.5, -11.5, 0)
		},
		[h_elias_idle42] = {
			offset = vmath.vector3(-7, -24.5, 0)
		},
		[h_elias_idle43] = {
			offset = vmath.vector3(-6.5, -22.5, 0)
		},
		[h_elias_idle4_cut2] = {
			offset = vmath.vector3(76, -24, 0)
		},
		[h_elias_idle4_cut3] = {
			offset = vmath.vector3(79.5, -21, 0)
		},
		[h_elias_idle4_cut4] = {
			offset = vmath.vector3(82.5, -11, 0)
		},
		[h_elias_idle4_cut5] = {
			offset = vmath.vector3(84.5, -1, 0)
		},
		[h_elias_idle4_cut6] = {
			offset = vmath.vector3(59.5, 2, 0)
		},
		[h_elias_idle4_cut8] = {
			offset = vmath.vector3(-14, -1, 0)
		},
		[h_elias_idle4_draw_knife4] = {
			offset = vmath.vector3(14.5, -15, 0)
		},
		[h_elias_idle4_cut8_hand] = {
			offset = vmath.vector3(0, 13.5, 0)
		},
		[h_elias_idle4_point1] = {
			offset = vmath.vector3(0, -13, 0)
		},
		[h_elias_idle4_point2] = {
			offset = vmath.vector3(59.5, -17.5, 0)
		},
		[h_elias_idle4_point3] = {
			offset = vmath.vector3(77, -17, 0)
		},
		[h_elias_idle4_point4] = {
			offset = vmath.vector3(83.5, -19, 0)
		},
		[h_elias_idle4_draw_knife1] = {
			offset = vmath.vector3(21.5, -1.5, 0)
		},
		[h_elias_idle4_draw_knife2] = {
			offset = vmath.vector3(59.5, -6, 0)
		},
		[h_elias_idle4_draw_knife3] = {
			offset = vmath.vector3(96.5, -25.5, 0)
		},
		[h_elias_idle4_draw_knife5] = {
			offset = vmath.vector3(-19, 5.5, 0)
		},
		[h_elias_idle4_draw_knife6] = {
			offset = vmath.vector3(-9.5, 8.5, 0)
		},
		[h_elias_idle4_draw_knife7] = {
			offset = vmath.vector3(-6.5, 9, 0)
		},
		[h_elias_idle4_draw_knife8] = {
			offset = vmath.vector3(18, -1, 0)
		},
		[h_elias_idle4_draw_knife9] = {
			offset = vmath.vector3(24.5, -15, 0)
		},
		[h_elias_idle4_look_away1] = {
			offset = vmath.vector3(-7, -17.5, 0)
		},
		[h_elias_idle4_look_away2] = {
			offset = vmath.vector3(-7, -22.5, 0)
		},
		[h_elias_idle4_look_away3] = {
			offset = vmath.vector3(-7.5, -27.5, 0)
		},
		[h_elias_knife_separated] = {
			offset = vmath.vector3(0, 0, 0)
		},
		[h_elias_idle2_to_idle35] = {
			offset = vmath.vector3(0.5, 19, 0)
		},
		[h_elias_idle2_to_idle34] = {
			offset = vmath.vector3(12.5, -12.5, 0)
		},
		[h_elias_idle2_to_idle33] = {
			offset = vmath.vector3(6, -35.5, 0)
		},
		[h_elias_idle2_to_idle32] = {
			offset = vmath.vector3(1.5, -62, 0)
		},
		[h_elias_idle2_to_idle31] = {
			offset = vmath.vector3(-13.5, -97.5, 0)
		},
		[h_elias_idle21] = {
			offset = vmath.vector3(-9.5, -104.5, 0)
		},
		[h_elias_idle22] = {
			offset = vmath.vector3(-9, -104.5, 0)
		},
		[h_elias_idle23] = {
			offset = vmath.vector3(-9, -100, 0)
		}
	},
	animations = {
		[h_elias_idle4] = {
			fps = 4,
			frames = {
				h_elias_idle41,
				h_elias_idle41,
				h_elias_idle42,
				h_elias_idle42,
				h_elias_idle43,
				h_elias_idle43,
				h_elias_idle42,
				h_elias_idle42
			}
		},
		[h_elias_idle4_cut] = {
			fps = 19,
			frames = {
				h_elias_idle4_cut1,
				h_elias_idle4_cut1,
				h_elias_idle4_cut1,
				h_elias_idle4_cut1,
				h_elias_idle4_cut2,
				h_elias_idle4_cut2,
				h_elias_idle4_cut3,
				h_elias_idle4_cut3,
				h_elias_idle4_cut4,
				h_elias_idle4_cut4,
				h_elias_idle4_cut4,
				h_elias_idle4_cut4,
				h_elias_idle4_cut5,
				h_elias_idle4_cut6,
				h_elias_idle4_cut7,
				h_elias_idle4_cut8,
				h_elias_idle4_cut8,
				h_elias_idle4_cut8,
				h_elias_idle4_draw_knife4,
				h_elias_idle4_draw_knife4,
				h_elias_idle4_draw_knife4,
				h_elias_idle4_cut1,
				h_elias_idle4_cut1
			}
		},
		[h_elias_idle4_cut_hand] = {
			fps = 19,
			frames = {
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_elias_idle4_cut7_hand,
				h_elias_idle4_cut8_hand,
				h_elias_idle4_cut8_hand,
				h_elias_idle4_cut8_hand,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel,
				h_pixel
			}
		},
		[h_elias_idle4_point] = {
			fps = 5,
			frames = {
				h_elias_idle4_point1,
				h_elias_idle4_point2,
				h_elias_idle4_point3,
				h_elias_idle4_point4,
				h_elias_idle4_point3,
				h_elias_idle4_point4,
				h_elias_idle4_point2,
				h_elias_idle4_point1
			}
		},
		[h_elias_idle4_draw_knife] = {
			fps = 6,
			frames = {
				h_elias_idle4_draw_knife1,
				h_elias_idle4_draw_knife2,
				h_elias_idle4_draw_knife3,
				h_elias_idle4_draw_knife4,
				h_elias_idle4_draw_knife5,
				h_elias_idle4_draw_knife6,
				h_elias_idle4_draw_knife7,
				h_elias_idle4_draw_knife8,
				h_elias_idle4_draw_knife9,
				h_elias_idle4_draw_knife10
			}
		},
		[h_elias_idle4_look_away] = {
			fps = 5,
			frames = {
				h_elias_idle4_look_away1,
				h_elias_idle4_look_away1,
				h_elias_idle4_look_away1,
				h_elias_idle4_look_away2,
				h_elias_idle4_look_away2,
				h_elias_idle4_look_away3,
				h_elias_idle4_look_away3,
				h_elias_idle4_look_away3,
				h_elias_idle4_look_away2,
				h_elias_idle4_look_away2,
				h_elias_idle4_look_away1,
				h_elias_idle4_look_away1
			}
		},
		[h_knife_hidden] = {
			fps = 1,
			frames = {
				h_pixel
			}
		},
		[h_knife_shown] = {
			fps = 1,
			frames = {
				h_elias_knife_separated
			}
		},
		[h_elias_idle4_put_away_knife] = {
			fps = 6,
			frames = {
				h_elias_idle4_draw_knife10,
				h_elias_idle4_draw_knife9,
				h_elias_idle4_draw_knife8,
				h_elias_idle4_draw_knife7,
				h_elias_idle4_draw_knife6,
				h_elias_idle4_draw_knife5,
				h_elias_idle4_draw_knife4,
				h_elias_idle4_draw_knife3,
				h_elias_idle4_draw_knife2,
				h_elias_idle4_draw_knife1
			}
		},
		[h_elias_idle4_to_idle2] = {
			fps = 5,
			frames = {
				h_elias_idle2_to_idle35,
				h_elias_idle2_to_idle34,
				h_elias_idle2_to_idle33,
				h_elias_idle2_to_idle32,
				h_elias_idle2_to_idle31
			}
		},
		[h_elias_idle2] = {
			fps = 3,
			frames = {
				h_elias_idle21,
				h_elias_idle21,
				h_elias_idle22,
				h_elias_idle22,
				h_elias_idle23,
				h_elias_idle23,
				h_elias_idle22,
				h_elias_idle22
			}
		}
	}
}
all_animations[hash("elias_idle4")] = animations

return animations
