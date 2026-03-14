local all_animations = require("main.animations.animations")
local h_elias_idle1 = hash("elias_idle1")
local h_elias_idle1_blink = hash("elias_idle1_blink")
local h_elias_idle1_nod = hash("elias_idle1_nod")
local h_elias_idle1_glasses = hash("elias_idle1_glasses")
local h_elias_idle1_raise_eyebrow = hash("elias_idle1_raise_eyebrow")
local h_elias_idle1_to_idle2 = hash("elias_idle1_to_idle2")
local h_pixel = hash("pixel")
local h_elias_idle11 = hash("elias_idle11")
local h_elias_idle12 = hash("elias_idle12")
local h_elias_idle13 = hash("elias_idle13")
local h_elias_idle11b = hash("elias_idle11b")
local h_elias_idle1_nod1 = hash("elias_idle1_nod1")
local h_elias_idle1_nod2 = hash("elias_idle1_nod2")
local h_elias_idle1_nod3 = hash("elias_idle1_nod3")
local h_elias_idle1_glasses1 = hash("elias_idle1_glasses1")
local h_elias_idle1_glasses2 = hash("elias_idle1_glasses2")
local h_elias_idle1_glasses3 = hash("elias_idle1_glasses3")
local h_elias_idle1_glasses4 = hash("elias_idle1_glasses4")
local h_elias_idle1_glasses5 = hash("elias_idle1_glasses5")
local h_elias_idle1_glasses6 = hash("elias_idle1_glasses6")
local h_elias_idle1_raise_eyebrow1 = hash("elias_idle1_raise_eyebrow1")
local h_elias_idle1_raise_eyebrow2 = hash("elias_idle1_raise_eyebrow2")
local h_elias_idle1_raise_eyebrow3 = hash("elias_idle1_raise_eyebrow3")
local h_elias_idle1_to_idle21 = hash("elias_idle1_to_idle21")
local h_elias_idle1_to_idle22 = hash("elias_idle1_to_idle22")
local h_elias_idle1_to_idle23 = hash("elias_idle1_to_idle23")
local h_elias_idle1_to_idle24 = hash("elias_idle1_to_idle24")
local animations = {
	images = {
		[h_pixel] = {
			offset = vmath.vector3(0, 0, 0)
		},
		[h_elias_idle11] = {
			offset = vmath.vector3(0.5, 16.5, 0)
		},
		[h_elias_idle12] = {
			offset = vmath.vector3(-3, 18, 0)
		},
		[h_elias_idle13] = {
			offset = vmath.vector3(-2, 18.5, 0)
		},
		[h_elias_idle11b] = {
			offset = vmath.vector3(0.5, 16.5, 0)
		},
		[h_elias_idle1_nod1] = {
			offset = vmath.vector3(1.5, 17.5, 0)
		},
		[h_elias_idle1_nod2] = {
			offset = vmath.vector3(3.5, 14.5, 0)
		},
		[h_elias_idle1_nod3] = {
			offset = vmath.vector3(1, 10, 0)
		},
		[h_elias_idle1_glasses1] = {
			offset = vmath.vector3(-5.5, 15.5, 0)
		},
		[h_elias_idle1_glasses2] = {
			offset = vmath.vector3(-9, 15, 0)
		},
		[h_elias_idle1_glasses3] = {
			offset = vmath.vector3(-10.5, 16, 0)
		},
		[h_elias_idle1_glasses4] = {
			offset = vmath.vector3(-12, 17.5, 0)
		},
		[h_elias_idle1_glasses5] = {
			offset = vmath.vector3(-11.5, 14.5, 0)
		},
		[h_elias_idle1_glasses6] = {
			offset = vmath.vector3(-17, 7.5, 0)
		},
		[h_elias_idle1_raise_eyebrow1] = {
			offset = vmath.vector3(2, 16, 0)
		},
		[h_elias_idle1_raise_eyebrow2] = {
			offset = vmath.vector3(2.5, 16, 0)
		},
		[h_elias_idle1_raise_eyebrow3] = {
			offset = vmath.vector3(2, 16.5, 0)
		},
		[h_elias_idle1_to_idle21] = {
			offset = vmath.vector3(-3, 16.5, 0)
		},
		[h_elias_idle1_to_idle22] = {
			offset = vmath.vector3(0, 26.5, 0)
		},
		[h_elias_idle1_to_idle23] = {
			offset = vmath.vector3(-15, 17, 0)
		},
		[h_elias_idle1_to_idle24] = {
			offset = vmath.vector3(-13.5, 1, 0)
		}
	},
	animations = {
		[h_elias_idle1] = {
			fps = 3,
			frames = {
				h_elias_idle11,
				h_elias_idle11,
				h_elias_idle11,
				h_elias_idle11,
				h_elias_idle12,
				h_elias_idle12,
				h_elias_idle12,
				h_elias_idle13,
				h_elias_idle13,
				h_elias_idle13,
				h_elias_idle13,
				h_elias_idle12,
				h_elias_idle12,
				h_elias_idle12
			}
		},
		[h_elias_idle1_blink] = {
			fps = 3,
			frames = {
				h_elias_idle11,
				h_elias_idle11b,
				h_elias_idle11,
				h_elias_idle11,
				h_elias_idle12,
				h_elias_idle12,
				h_elias_idle12,
				h_elias_idle13,
				h_elias_idle13,
				h_elias_idle13,
				h_elias_idle13,
				h_elias_idle12,
				h_elias_idle12,
				h_elias_idle12
			}
		},
		[h_elias_idle1_nod] = {
			fps = 5,
			frames = {
				h_elias_idle1_nod1,
				h_elias_idle1_nod2,
				h_elias_idle1_nod3,
				h_elias_idle1_nod3,
				h_elias_idle1_nod3,
				h_elias_idle1_nod3,
				h_elias_idle1_nod2,
				h_elias_idle1_nod2,
				h_elias_idle1_nod1,
				h_elias_idle1_nod1
			}
		},
		[h_elias_idle1_glasses] = {
			fps = 5,
			frames = {
				h_elias_idle1_glasses1,
				h_elias_idle1_glasses2,
				h_elias_idle1_glasses3,
				h_elias_idle1_glasses4,
				h_elias_idle1_glasses5,
				h_elias_idle1_glasses6,
				h_elias_idle1_glasses6,
				h_elias_idle1_glasses6,
				h_elias_idle1_glasses4,
				h_elias_idle1_glasses2,
				h_elias_idle1_glasses1
			}
		},
		[h_elias_idle1_raise_eyebrow] = {
			fps = 5,
			frames = {
				h_elias_idle1_raise_eyebrow1,
				h_elias_idle1_raise_eyebrow1,
				h_elias_idle1_raise_eyebrow2,
				h_elias_idle1_raise_eyebrow2,
				h_elias_idle1_raise_eyebrow3,
				h_elias_idle1_raise_eyebrow3,
				h_elias_idle1_raise_eyebrow3,
				h_elias_idle1_raise_eyebrow3,
				h_elias_idle1_raise_eyebrow3,
				h_elias_idle1_raise_eyebrow2,
				h_elias_idle1_raise_eyebrow2,
				h_elias_idle1_raise_eyebrow1,
				h_elias_idle1_raise_eyebrow1
			}
		},
		[h_elias_idle1_to_idle2] = {
			fps = 2,
			frames = {
				h_elias_idle1_to_idle21,
				h_elias_idle1_to_idle22,
				h_elias_idle1_to_idle23,
				h_elias_idle1_to_idle24
			}
		}
	}
}
all_animations[hash("elias_idle1")] = animations

return animations
