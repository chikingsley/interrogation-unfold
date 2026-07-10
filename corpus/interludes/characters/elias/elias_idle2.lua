local all_animations = require("main.animations.animations")
local h_elias_idle2 = hash("elias_idle2")
local h_elias_idle2_blink = hash("elias_idle2_blink")
local h_elias_idle2_explain = hash("elias_idle2_explain")
local h_elias_idle2_to_idle3 = hash("elias_idle2_to_idle3")
local h_elias_idle2_headshake = hash("elias_idle2_headshake")
local h_elias_idle2_nod = hash("elias_idle2_nod")
local h_elias_idle2_to_idle35 = hash("elias_idle2_to_idle35")
local h_elias_idle21 = hash("elias_idle21")
local h_elias_idle22 = hash("elias_idle22")
local h_elias_idle23 = hash("elias_idle23")
local h_elias_idle21b = hash("elias_idle21b")
local h_elias_idle2_explain1 = hash("elias_idle2_explain1")
local h_elias_idle2_explain2 = hash("elias_idle2_explain2")
local h_elias_idle2_explain3 = hash("elias_idle2_explain3")
local h_elias_idle2_explain4 = hash("elias_idle2_explain4")
local h_elias_idle2_to_idle31 = hash("elias_idle2_to_idle31")
local h_elias_idle2_to_idle32 = hash("elias_idle2_to_idle32")
local h_elias_idle2_to_idle33 = hash("elias_idle2_to_idle33")
local h_elias_idle2_to_idle34 = hash("elias_idle2_to_idle34")
local h_elias_idle2_headshake1 = hash("elias_idle2_headshake1")
local h_elias_idle2_headshake2 = hash("elias_idle2_headshake2")
local h_elias_idle2_headshake3 = hash("elias_idle2_headshake3")
local h_elias_idle2_nod1 = hash("elias_idle2_nod1")
local h_elias_idle2_nod2 = hash("elias_idle2_nod2")
local h_elias_idle2_nod3 = hash("elias_idle2_nod3")
local animations = {
	images = {
		[h_elias_idle2_to_idle35] = {
			offset = vmath.vector3(0.5, 19, 0)
		},
		[h_elias_idle21] = {
			offset = vmath.vector3(-9.5, -104.5, 0)
		},
		[h_elias_idle22] = {
			offset = vmath.vector3(-9, -104.5, 0)
		},
		[h_elias_idle23] = {
			offset = vmath.vector3(-9, -100, 0)
		},
		[h_elias_idle21b] = {
			offset = vmath.vector3(-9.5, -104.5, 0)
		},
		[h_elias_idle2_explain1] = {
			offset = vmath.vector3(-17, -102, 0)
		},
		[h_elias_idle2_explain2] = {
			offset = vmath.vector3(-16, -99, 0)
		},
		[h_elias_idle2_explain3] = {
			offset = vmath.vector3(-13, -99.5, 0)
		},
		[h_elias_idle2_explain4] = {
			offset = vmath.vector3(-12, -98.5, 0)
		},
		[h_elias_idle2_to_idle31] = {
			offset = vmath.vector3(-13.5, -97.5, 0)
		},
		[h_elias_idle2_to_idle32] = {
			offset = vmath.vector3(1.5, -62, 0)
		},
		[h_elias_idle2_to_idle33] = {
			offset = vmath.vector3(6, -35.5, 0)
		},
		[h_elias_idle2_to_idle34] = {
			offset = vmath.vector3(12.5, -12.5, 0)
		},
		[h_elias_idle2_headshake1] = {
			offset = vmath.vector3(-6.5, -99.5, 0)
		},
		[h_elias_idle2_headshake2] = {
			offset = vmath.vector3(-6.5, -99.5, 0)
		},
		[h_elias_idle2_headshake3] = {
			offset = vmath.vector3(-7, -96.5, 0)
		},
		[h_elias_idle2_nod1] = {
			offset = vmath.vector3(-7.5, -99.5, 0)
		},
		[h_elias_idle2_nod2] = {
			offset = vmath.vector3(-5, -98.5, 0)
		},
		[h_elias_idle2_nod3] = {
			offset = vmath.vector3(-5.5, -98.5, 0)
		}
	},
	animations = {
		[h_elias_idle2] = {
			fps = 2,
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
		},
		[h_elias_idle2_blink] = {
			fps = 2,
			frames = {
				h_elias_idle21,
				h_elias_idle21b,
				h_elias_idle22,
				h_elias_idle22,
				h_elias_idle23,
				h_elias_idle23,
				h_elias_idle22,
				h_elias_idle22
			}
		},
		[h_elias_idle2_explain] = {
			fps = 5,
			frames = {
				h_elias_idle2_explain1,
				h_elias_idle2_explain1,
				h_elias_idle2_explain2,
				h_elias_idle2_explain2,
				h_elias_idle2_explain3,
				h_elias_idle2_explain3,
				h_elias_idle2_explain4,
				h_elias_idle2_explain4,
				h_elias_idle2_explain2,
				h_elias_idle2_explain2,
				h_elias_idle2_explain1,
				h_elias_idle2_explain1
			}
		},
		[h_elias_idle2_to_idle3] = {
			fps = 6,
			frames = {
				h_elias_idle2_to_idle31,
				h_elias_idle2_to_idle32,
				h_elias_idle2_to_idle33,
				h_elias_idle2_to_idle34,
				h_elias_idle2_to_idle35
			}
		},
		[h_elias_idle2_headshake] = {
			fps = 6,
			frames = {
				h_elias_idle2_headshake1,
				h_elias_idle2_headshake2,
				h_elias_idle2_headshake3,
				h_elias_idle2_headshake3,
				h_elias_idle2_headshake3,
				h_elias_idle2_headshake2,
				h_elias_idle2_headshake1,
				h_elias_idle2_headshake2,
				h_elias_idle2_headshake3,
				h_elias_idle2_headshake3,
				h_elias_idle2_headshake3,
				h_elias_idle2_headshake2,
				h_elias_idle2_headshake1
			}
		},
		[h_elias_idle2_nod] = {
			fps = 4,
			frames = {
				h_elias_idle2_nod1,
				h_elias_idle2_nod2,
				h_elias_idle2_nod3,
				h_elias_idle2_nod3,
				h_elias_idle2_nod2,
				h_elias_idle2_nod1
			}
		}
	}
}
all_animations[hash("elias_idle2")] = animations

return animations
