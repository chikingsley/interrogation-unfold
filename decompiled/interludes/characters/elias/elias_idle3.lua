local all_animations = require("main.animations.animations")
local h_elias_idle3 = hash("elias_idle3")
local h_elias_idle3_grab = hash("elias_idle3_grab")
local h_elias_idle3_glasses = hash("elias_idle3_glasses")
local h_elias_idle3_headshake = hash("elias_idle3_headshake")
local h_elias_idle3_to_idle4 = hash("elias_idle3_to_idle4")
local h_elias_idle31 = hash("elias_idle31")
local h_elias_idle32 = hash("elias_idle32")
local h_elias_idle33 = hash("elias_idle33")
local h_elias_idle3_grab1 = hash("elias_idle3_grab1")
local h_elias_idle3_grab2 = hash("elias_idle3_grab2")
local h_elias_idle3_grab3 = hash("elias_idle3_grab3")
local h_elias_idle3_grab4 = hash("elias_idle3_grab4")
local h_elias_idle3_glasses1 = hash("elias_idle3_glasses1")
local h_elias_idle3_glasses2 = hash("elias_idle3_glasses2")
local h_elias_idle3_glasses3 = hash("elias_idle3_glasses3")
local h_elias_idle3_glasses4 = hash("elias_idle3_glasses4")
local h_elias_idle3_glasses5 = hash("elias_idle3_glasses5")
local h_elias_idle3_glasses6 = hash("elias_idle3_glasses6")
local h_elias_idle3_glasses7 = hash("elias_idle3_glasses7")
local h_elias_idle3_headshake1 = hash("elias_idle3_headshake1")
local h_elias_idle3_headshake2 = hash("elias_idle3_headshake2")
local h_elias_idle3_headshake3 = hash("elias_idle3_headshake3")
local h_elias_idle3_headshake4 = hash("elias_idle3_headshake4")
local h_elias_idle3_headshake5 = hash("elias_idle3_headshake5")
local h_elias_idle3_to_idle41 = hash("elias_idle3_to_idle41")
local h_elias_idle3_to_idle42 = hash("elias_idle3_to_idle42")
local h_elias_idle3_to_idle43 = hash("elias_idle3_to_idle43")
local h_elias_idle3_to_idle44 = hash("elias_idle3_to_idle44")
local h_elias_idle3_to_idle45 = hash("elias_idle3_to_idle45")
local animations = {
	images = {
		[h_elias_idle31] = {
			offset = vmath.vector3(21.5, 19.5, 0)
		},
		[h_elias_idle32] = {
			offset = vmath.vector3(21.5, 19.5, 0)
		},
		[h_elias_idle33] = {
			offset = vmath.vector3(21.5, 19.5, 0)
		},
		[h_elias_idle3_grab1] = {
			offset = vmath.vector3(38, 13.5, 0)
		},
		[h_elias_idle3_grab2] = {
			offset = vmath.vector3(39, 11, 0)
		},
		[h_elias_idle3_grab3] = {
			offset = vmath.vector3(67, 4.5, 0)
		},
		[h_elias_idle3_grab4] = {
			offset = vmath.vector3(102, -16.5, 0)
		},
		[h_elias_idle3_glasses1] = {
			offset = vmath.vector3(54, 2, 0)
		},
		[h_elias_idle3_glasses2] = {
			offset = vmath.vector3(63, -6.5, 0)
		},
		[h_elias_idle3_glasses3] = {
			offset = vmath.vector3(69, -1.5, 0)
		},
		[h_elias_idle3_glasses4] = {
			offset = vmath.vector3(71, -6, 0)
		},
		[h_elias_idle3_glasses5] = {
			offset = vmath.vector3(74.5, -5.5, 0)
		},
		[h_elias_idle3_glasses6] = {
			offset = vmath.vector3(79, -5, 0)
		},
		[h_elias_idle3_glasses7] = {
			offset = vmath.vector3(52.5, -12, 0)
		},
		[h_elias_idle3_headshake1] = {
			offset = vmath.vector3(22, 6, 0)
		},
		[h_elias_idle3_headshake2] = {
			offset = vmath.vector3(21, 3, 0)
		},
		[h_elias_idle3_headshake3] = {
			offset = vmath.vector3(21.5, -5, 0)
		},
		[h_elias_idle3_headshake4] = {
			offset = vmath.vector3(21.5, -5.5, 0)
		},
		[h_elias_idle3_headshake5] = {
			offset = vmath.vector3(21, -7, 0)
		},
		[h_elias_idle3_to_idle41] = {
			offset = vmath.vector3(30, -2.5, 0)
		},
		[h_elias_idle3_to_idle42] = {
			offset = vmath.vector3(-1.5, 7, 0)
		},
		[h_elias_idle3_to_idle43] = {
			offset = vmath.vector3(18.5, -26.5, 0)
		},
		[h_elias_idle3_to_idle44] = {
			offset = vmath.vector3(57, -34, 0)
		},
		[h_elias_idle3_to_idle45] = {
			offset = vmath.vector3(49, 13.5, 0)
		}
	},
	animations = {
		[h_elias_idle3] = {
			fps = 3,
			frames = {
				h_elias_idle31,
				h_elias_idle31,
				h_elias_idle31,
				h_elias_idle32,
				h_elias_idle32,
				h_elias_idle33,
				h_elias_idle33,
				h_elias_idle32,
				h_elias_idle32
			}
		},
		[h_elias_idle3_grab] = {
			fps = 8,
			frames = {
				h_elias_idle3_grab1,
				h_elias_idle3_grab1,
				h_elias_idle3_grab1,
				h_elias_idle3_grab2,
				h_elias_idle3_grab3,
				h_elias_idle3_grab4,
				h_elias_idle3_grab4,
				h_elias_idle3_grab4,
				h_elias_idle3_grab3,
				h_elias_idle3_grab3,
				h_elias_idle3_grab3,
				h_elias_idle3_grab2,
				h_elias_idle3_grab1,
				h_elias_idle3_grab1
			}
		},
		[h_elias_idle3_glasses] = {
			fps = 6,
			frames = {
				h_elias_idle3_glasses1,
				h_elias_idle3_glasses2,
				h_elias_idle3_glasses3,
				h_elias_idle3_glasses4,
				h_elias_idle3_glasses5,
				h_elias_idle3_glasses6,
				h_elias_idle3_glasses7,
				h_elias_idle3_glasses7,
				h_elias_idle3_glasses7,
				h_elias_idle3_glasses5,
				h_elias_idle3_glasses3,
				h_elias_idle3_glasses1,
				h_elias_idle3_glasses1
			}
		},
		[h_elias_idle3_headshake] = {
			fps = 5,
			frames = {
				h_elias_idle3_headshake1,
				h_elias_idle3_headshake2,
				h_elias_idle3_headshake3,
				h_elias_idle3_headshake4,
				h_elias_idle3_headshake5,
				h_elias_idle3_headshake4,
				h_elias_idle3_headshake3,
				h_elias_idle3_headshake4,
				h_elias_idle3_headshake5,
				h_elias_idle3_headshake3,
				h_elias_idle3_headshake2,
				h_elias_idle3_headshake1
			}
		},
		[h_elias_idle3_to_idle4] = {
			fps = 12,
			frames = {
				h_elias_idle3_to_idle41,
				h_elias_idle3_to_idle41,
				h_elias_idle3_to_idle41,
				h_elias_idle3_to_idle41,
				h_elias_idle3_to_idle42,
				h_elias_idle3_to_idle42,
				h_elias_idle3_to_idle42,
				h_elias_idle3_to_idle42,
				h_elias_idle3_to_idle43,
				h_elias_idle3_to_idle44,
				h_elias_idle3_to_idle44,
				h_elias_idle3_to_idle44,
				h_elias_idle3_to_idle45,
				h_elias_idle3_to_idle45,
				h_elias_idle3_to_idle45
			}
		}
	}
}
all_animations[hash("elias_idle3")] = animations

return animations
