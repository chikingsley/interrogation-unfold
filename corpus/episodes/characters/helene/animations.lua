local all_animations = require("main.animations.animations")
local h_helene_idle = hash("helene_idle")
local h_helene_idle_blink = hash("helene_idle_blink")
local h_helene_idle_scared = hash("helene_idle_scared")
local h_helene_idle_scared_blink = hash("helene_idle_scared_blink")
local h_helene_idle_empathy = hash("helene_idle_empathy")
local h_helene_idle_empathy_blink = hash("helene_idle_empathy_blink")
local h_helene_nod = hash("helene_nod")
local h_helene_yoga_pose = hash("helene_yoga_pose")
local h_helene_headshake = hash("helene_headshake")
local h_helene_headshake_sign = hash("helene_headshake_sign")
local h_helene_headshake_plus_sign = hash("helene_headshake_plus_sign")
local h_helene_terrified = hash("helene_terrified")
local h_helene_shrug = hash("helene_shrug")
local h_helene_shrug_sign = hash("helene_shrug_sign")
local h_helene_shrug_plus_sign = hash("helene_shrug_plus_sign")
local h_helene_disgust = hash("helene_disgust")
local h_helene_upset = hash("helene_upset")
local h_helene_sad = hash("helene_sad")
local h_helene_of = hash("helene_of")
local h_helene_smile = hash("helene_smile")
local h_helene_idle1 = hash("helene_idle1")
local h_helene_idle2 = hash("helene_idle2")
local h_helene_idle3 = hash("helene_idle3")
local h_helene_idle1b = hash("helene_idle1b")
local h_helene_idle_scared1 = hash("helene_idle_scared1")
local h_helene_idle_scared2 = hash("helene_idle_scared2")
local h_helene_idle_scared3 = hash("helene_idle_scared3")
local h_helene_idle_scared1b = hash("helene_idle_scared1b")
local h_helene_idle_empathy1 = hash("helene_idle_empathy1")
local h_helene_idle_empathy2 = hash("helene_idle_empathy2")
local h_helene_idle_empathy3 = hash("helene_idle_empathy3")
local h_helene_idle_empathy1b = hash("helene_idle_empathy1b")
local h_helene_nod1 = hash("helene_nod1")
local h_helene_nod2 = hash("helene_nod2")
local h_helene_nod3 = hash("helene_nod3")
local h_helene_nod4 = hash("helene_nod4")
local h_helene_nod5 = hash("helene_nod5")
local h_helene_nod6 = hash("helene_nod6")
local h_helene_yoga_pose1 = hash("helene_yoga_pose1")
local h_helene_yoga_pose2 = hash("helene_yoga_pose2")
local h_helene_yoga_pose3 = hash("helene_yoga_pose3")
local h_helene_yoga_pose4 = hash("helene_yoga_pose4")
local h_helene_yoga_pose5 = hash("helene_yoga_pose5")
local h_helene_headshake1 = hash("helene_headshake1")
local h_helene_headshake3 = hash("helene_headshake3")
local h_helene_headshake_sign1 = hash("helene_headshake_sign1")
local h_helene_headshake_sign2 = hash("helene_headshake_sign2")
local h_helene_headshake_sign3 = hash("helene_headshake_sign3")
local h_helene_headshake_sign4 = hash("helene_headshake_sign4")
local h_helene_headshake_sign5 = hash("helene_headshake_sign5")
local h_helene_headshake_sign6 = hash("helene_headshake_sign6")
local h_helene_terrified1 = hash("helene_terrified1")
local h_helene_terrified2 = hash("helene_terrified2")
local h_helene_terrified3 = hash("helene_terrified3")
local h_helene_terrified4 = hash("helene_terrified4")
local h_helene_shrug1 = hash("helene_shrug1")
local h_helene_shrug2 = hash("helene_shrug2")
local h_helene_shrug3 = hash("helene_shrug3")
local h_helene_shrug_sign1 = hash("helene_shrug_sign1")
local h_helene_shrug_sign2 = hash("helene_shrug_sign2")
local h_helene_shrug_sign3 = hash("helene_shrug_sign3")
local h_helene_shrug_sign4 = hash("helene_shrug_sign4")
local h_helene_shrug_sign5 = hash("helene_shrug_sign5")
local h_helene_disgust1 = hash("helene_disgust1")
local h_helene_disgust2 = hash("helene_disgust2")
local h_helene_disgust3 = hash("helene_disgust3")
local h_helene_upset1 = hash("helene_upset1")
local h_helene_upset2 = hash("helene_upset2")
local h_helene_upset3 = hash("helene_upset3")
local h_helene_upset4 = hash("helene_upset4")
local h_helene_upset5 = hash("helene_upset5")
local h_helene_upset6 = hash("helene_upset6")
local h_helene_upset7 = hash("helene_upset7")
local h_helene_upset8 = hash("helene_upset8")
local h_helene_sad1 = hash("helene_sad1")
local h_helene_sad2 = hash("helene_sad2")
local h_helene_sad3 = hash("helene_sad3")
local h_helene_of1 = hash("helene_of1")
local h_helene_of2 = hash("helene_of2")
local h_helene_of3 = hash("helene_of3")
local h_helene_of4 = hash("helene_of4")
local h_helene_smile1 = hash("helene_smile1")
local h_helene_smile2 = hash("helene_smile2")
local h_helene_smile3 = hash("helene_smile3")
local h_helene_smile4 = hash("helene_smile4")
local animations = {
	images = {
		[h_helene_idle1] = {
			offset = vmath.vector3(7, -6, 0)
		},
		[h_helene_idle2] = {
			offset = vmath.vector3(7.5, -3.5, 0)
		},
		[h_helene_idle3] = {
			offset = vmath.vector3(5, -2.5, 0)
		},
		[h_helene_idle1b] = {
			offset = vmath.vector3(7, -6, 0)
		},
		[h_helene_idle_scared1] = {
			offset = vmath.vector3(6.5, -6, 0)
		},
		[h_helene_idle_scared2] = {
			offset = vmath.vector3(3, -4.5, 0)
		},
		[h_helene_idle_scared3] = {
			offset = vmath.vector3(7, -3, 0)
		},
		[h_helene_idle_scared1b] = {
			offset = vmath.vector3(6.5, -6, 0)
		},
		[h_helene_idle_empathy1] = {
			offset = vmath.vector3(8.5, 1.5, 0)
		},
		[h_helene_idle_empathy2] = {
			offset = vmath.vector3(9, -1.5, 0)
		},
		[h_helene_idle_empathy3] = {
			offset = vmath.vector3(8.5, 1, 0)
		},
		[h_helene_idle_empathy1b] = {
			offset = vmath.vector3(8.5, 1.5, 0)
		},
		[h_helene_nod1] = {
			offset = vmath.vector3(9, 3.5, 0)
		},
		[h_helene_nod2] = {
			offset = vmath.vector3(-0.5, 0, 0)
		},
		[h_helene_nod3] = {
			offset = vmath.vector3(-10.5, 4.5, 0)
		},
		[h_helene_nod4] = {
			offset = vmath.vector3(-20, 1, 0)
		},
		[h_helene_nod5] = {
			offset = vmath.vector3(-24, 4.5, 0)
		},
		[h_helene_nod6] = {
			offset = vmath.vector3(-24.5, 5.5, 0)
		},
		[h_helene_yoga_pose1] = {
			offset = vmath.vector3(5.5, 1, 0)
		},
		[h_helene_yoga_pose2] = {
			offset = vmath.vector3(3, 14, 0)
		},
		[h_helene_yoga_pose3] = {
			offset = vmath.vector3(3, 19, 0)
		},
		[h_helene_yoga_pose4] = {
			offset = vmath.vector3(3, 7.5, 0)
		},
		[h_helene_yoga_pose5] = {
			offset = vmath.vector3(3, 4, 0)
		},
		[h_helene_headshake1] = {
			offset = vmath.vector3(5, 2, 0)
		},
		[h_helene_headshake3] = {
			offset = vmath.vector3(5.5, 4, 0)
		},
		[h_helene_headshake_sign1] = {
			offset = vmath.vector3(3, 2.5, 0)
		},
		[h_helene_headshake_sign2] = {
			offset = vmath.vector3(9, 3, 0)
		},
		[h_helene_headshake_sign3] = {
			offset = vmath.vector3(-5, 6, 0)
		},
		[h_helene_headshake_sign4] = {
			offset = vmath.vector3(-21.5, 9.5, 0)
		},
		[h_helene_headshake_sign5] = {
			offset = vmath.vector3(-23, 8.5, 0)
		},
		[h_helene_headshake_sign6] = {
			offset = vmath.vector3(-24, 6, 0)
		},
		[h_helene_terrified1] = {
			offset = vmath.vector3(41.5, 7.5, 0)
		},
		[h_helene_terrified2] = {
			offset = vmath.vector3(49.5, 11.5, 0)
		},
		[h_helene_terrified3] = {
			offset = vmath.vector3(65, 11, 0)
		},
		[h_helene_terrified4] = {
			offset = vmath.vector3(68, -7, 0)
		},
		[h_helene_shrug1] = {
			offset = vmath.vector3(14.5, -3.5, 0)
		},
		[h_helene_shrug2] = {
			offset = vmath.vector3(7, -1, 0)
		},
		[h_helene_shrug3] = {
			offset = vmath.vector3(8, -3.5, 0)
		},
		[h_helene_shrug_sign1] = {
			offset = vmath.vector3(5.5, -4, 0)
		},
		[h_helene_shrug_sign2] = {
			offset = vmath.vector3(7, -5.5, 0)
		},
		[h_helene_shrug_sign3] = {
			offset = vmath.vector3(-18.5, -4.5, 0)
		},
		[h_helene_shrug_sign4] = {
			offset = vmath.vector3(-18, -5, 0)
		},
		[h_helene_shrug_sign5] = {
			offset = vmath.vector3(-29, -11, 0)
		},
		[h_helene_disgust1] = {
			offset = vmath.vector3(4.5, 1.5, 0)
		},
		[h_helene_disgust2] = {
			offset = vmath.vector3(4.5, -4.5, 0)
		},
		[h_helene_disgust3] = {
			offset = vmath.vector3(3, -4, 0)
		},
		[h_helene_upset1] = {
			offset = vmath.vector3(-13.5, -3.5, 0)
		},
		[h_helene_upset2] = {
			offset = vmath.vector3(-15, -6, 0)
		},
		[h_helene_upset3] = {
			offset = vmath.vector3(-22, -5, 0)
		},
		[h_helene_upset4] = {
			offset = vmath.vector3(-24.5, -4, 0)
		},
		[h_helene_upset5] = {
			offset = vmath.vector3(-10.5, -6, 0)
		},
		[h_helene_upset6] = {
			offset = vmath.vector3(-11, -5, 0)
		},
		[h_helene_upset7] = {
			offset = vmath.vector3(-26, -4.5, 0)
		},
		[h_helene_upset8] = {
			offset = vmath.vector3(-29, -6, 0)
		},
		[h_helene_sad1] = {
			offset = vmath.vector3(8, 1, 0)
		},
		[h_helene_sad2] = {
			offset = vmath.vector3(6.5, -2.5, 0)
		},
		[h_helene_sad3] = {
			offset = vmath.vector3(7.5, -8, 0)
		},
		[h_helene_of1] = {
			offset = vmath.vector3(13, -6, 0)
		},
		[h_helene_of2] = {
			offset = vmath.vector3(9.5, 9, 0)
		},
		[h_helene_of3] = {
			offset = vmath.vector3(10, 9, 0)
		},
		[h_helene_of4] = {
			offset = vmath.vector3(13.5, 13, 0)
		},
		[h_helene_smile1] = {
			offset = vmath.vector3(5, -2, 0)
		},
		[h_helene_smile2] = {
			offset = vmath.vector3(-1, -5.5, 0)
		},
		[h_helene_smile3] = {
			offset = vmath.vector3(3.5, -0.5, 0)
		},
		[h_helene_smile4] = {
			offset = vmath.vector3(6, -2.5, 0)
		}
	},
	animations = {
		[h_helene_idle] = {
			fps = 3,
			frames = {
				h_helene_idle1,
				h_helene_idle1,
				h_helene_idle1,
				h_helene_idle2,
				h_helene_idle2,
				h_helene_idle2,
				h_helene_idle3,
				h_helene_idle3,
				h_helene_idle3,
				h_helene_idle2,
				h_helene_idle2,
				h_helene_idle2
			}
		},
		[h_helene_idle_blink] = {
			fps = 3,
			frames = {
				h_helene_idle1,
				h_helene_idle1b,
				h_helene_idle1,
				h_helene_idle2,
				h_helene_idle2,
				h_helene_idle2,
				h_helene_idle3,
				h_helene_idle3,
				h_helene_idle3,
				h_helene_idle2,
				h_helene_idle2,
				h_helene_idle2
			}
		},
		[h_helene_idle_scared] = {
			fps = 5,
			frames = {
				h_helene_idle_scared1,
				h_helene_idle_scared1,
				h_helene_idle_scared2,
				h_helene_idle_scared2,
				h_helene_idle_scared3,
				h_helene_idle_scared3,
				h_helene_idle_scared2,
				h_helene_idle_scared2,
				h_helene_idle_scared1
			}
		},
		[h_helene_idle_scared_blink] = {
			fps = 5,
			frames = {
				h_helene_idle_scared1b,
				h_helene_idle_scared1b,
				h_helene_idle_scared2,
				h_helene_idle_scared2,
				h_helene_idle_scared3,
				h_helene_idle_scared3,
				h_helene_idle_scared2,
				h_helene_idle_scared2,
				h_helene_idle_scared1b
			}
		},
		[h_helene_idle_empathy] = {
			fps = 1,
			frames = {
				h_helene_idle_empathy1,
				h_helene_idle_empathy2,
				h_helene_idle_empathy3,
				h_helene_idle_empathy2
			}
		},
		[h_helene_idle_empathy_blink] = {
			fps = 1,
			frames = {
				h_helene_idle_empathy1b,
				h_helene_idle_empathy2,
				h_helene_idle_empathy3,
				h_helene_idle_empathy2
			}
		},
		[h_helene_nod] = {
			fps = 5,
			frames = {
				h_helene_nod1,
				h_helene_nod2,
				h_helene_nod3,
				h_helene_nod4,
				h_helene_nod5,
				h_helene_nod6,
				h_helene_nod6,
				h_helene_nod5,
				h_helene_nod6,
				h_helene_nod5,
				h_helene_nod4,
				h_helene_nod3,
				h_helene_nod2,
				h_helene_nod1
			}
		},
		[h_helene_yoga_pose] = {
			fps = 5,
			frames = {
				h_helene_yoga_pose1,
				h_helene_yoga_pose1,
				h_helene_yoga_pose2,
				h_helene_yoga_pose2,
				h_helene_yoga_pose3,
				h_helene_yoga_pose3,
				h_helene_yoga_pose4,
				h_helene_yoga_pose4,
				h_helene_yoga_pose5,
				h_helene_yoga_pose5,
				h_helene_yoga_pose5,
				h_helene_yoga_pose5,
				h_helene_yoga_pose4,
				h_helene_yoga_pose4,
				h_helene_yoga_pose3,
				h_helene_yoga_pose3,
				h_helene_yoga_pose2,
				h_helene_yoga_pose2,
				h_helene_yoga_pose1,
				h_helene_yoga_pose1
			}
		},
		[h_helene_headshake] = {
			fps = 6,
			frames = {
				h_helene_headshake1,
				h_helene_headshake1,
				h_helene_headshake3,
				h_helene_headshake3,
				h_helene_headshake1,
				h_helene_headshake1
			}
		},
		[h_helene_headshake_sign] = {
			fps = 6,
			frames = {
				h_helene_headshake_sign1,
				h_helene_headshake_sign2,
				h_helene_headshake_sign3,
				h_helene_headshake_sign4,
				h_helene_headshake_sign5,
				h_helene_headshake_sign6,
				h_helene_headshake_sign5,
				h_helene_headshake_sign6,
				h_helene_headshake_sign5,
				h_helene_headshake_sign4,
				h_helene_headshake_sign3,
				h_helene_headshake_sign2,
				h_helene_headshake_sign1
			}
		},
		[h_helene_headshake_plus_sign] = {
			fps = 6,
			frames = {
				h_helene_headshake1,
				h_helene_headshake1,
				h_helene_headshake3,
				h_helene_headshake3,
				h_helene_headshake1,
				h_helene_headshake1,
				h_helene_headshake_sign1,
				h_helene_headshake_sign2,
				h_helene_headshake_sign3,
				h_helene_headshake_sign4,
				h_helene_headshake_sign5,
				h_helene_headshake_sign6,
				h_helene_headshake_sign5,
				h_helene_headshake_sign4,
				h_helene_headshake_sign5,
				h_helene_headshake_sign6,
				h_helene_headshake_sign5,
				h_helene_headshake_sign4,
				h_helene_headshake_sign3,
				h_helene_headshake_sign2,
				h_helene_headshake_sign1
			}
		},
		[h_helene_terrified] = {
			fps = 6,
			frames = {
				h_helene_idle_scared1,
				h_helene_terrified1,
				h_helene_terrified2,
				h_helene_terrified3,
				h_helene_terrified4,
				h_helene_terrified4,
				h_helene_terrified4,
				h_helene_terrified4,
				h_helene_terrified3,
				h_helene_terrified3,
				h_helene_terrified2,
				h_helene_terrified2,
				h_helene_terrified1,
				h_helene_terrified1,
				h_helene_idle_scared1,
				h_helene_idle_scared1
			}
		},
		[h_helene_shrug] = {
			fps = 4,
			frames = {
				h_helene_shrug1,
				h_helene_shrug2,
				h_helene_shrug3,
				h_helene_shrug3,
				h_helene_shrug3,
				h_helene_shrug2,
				h_helene_shrug1
			}
		},
		[h_helene_shrug_sign] = {
			fps = 4,
			frames = {
				h_helene_shrug_sign1,
				h_helene_shrug_sign2,
				h_helene_shrug_sign3,
				h_helene_shrug_sign4,
				h_helene_shrug_sign5,
				h_helene_shrug_sign4,
				h_helene_shrug_sign5,
				h_helene_shrug_sign4,
				h_helene_shrug_sign3,
				h_helene_shrug_sign2,
				h_helene_shrug_sign1
			}
		},
		[h_helene_shrug_plus_sign] = {
			fps = 4,
			frames = {
				h_helene_shrug1,
				h_helene_shrug2,
				h_helene_shrug3,
				h_helene_shrug3,
				h_helene_shrug3,
				h_helene_shrug2,
				h_helene_shrug1,
				h_helene_shrug_sign1,
				h_helene_shrug_sign2,
				h_helene_shrug_sign3,
				h_helene_shrug_sign4,
				h_helene_shrug_sign5,
				h_helene_shrug_sign4,
				h_helene_shrug_sign5,
				h_helene_shrug_sign4,
				h_helene_shrug_sign3,
				h_helene_shrug_sign2,
				h_helene_shrug_sign1
			}
		},
		[h_helene_disgust] = {
			fps = 5,
			frames = {
				h_helene_disgust1,
				h_helene_disgust1,
				h_helene_disgust2,
				h_helene_disgust2,
				h_helene_disgust3,
				h_helene_disgust3,
				h_helene_disgust3,
				h_helene_disgust3,
				h_helene_disgust2,
				h_helene_disgust1,
				h_helene_disgust1
			}
		},
		[h_helene_upset] = {
			fps = 5,
			frames = {
				h_helene_upset1,
				h_helene_upset2,
				h_helene_upset3,
				h_helene_upset4,
				h_helene_upset5,
				h_helene_upset4,
				h_helene_upset3,
				h_helene_upset4,
				h_helene_upset5,
				h_helene_upset6,
				h_helene_upset7,
				h_helene_upset8
			}
		},
		[h_helene_sad] = {
			fps = 4,
			frames = {
				h_helene_sad1,
				h_helene_sad1,
				h_helene_sad2,
				h_helene_sad2,
				h_helene_sad3,
				h_helene_sad3,
				h_helene_sad3,
				h_helene_sad3,
				h_helene_sad2,
				h_helene_sad2,
				h_helene_sad1,
				h_helene_sad1
			}
		},
		[h_helene_of] = {
			fps = 5,
			frames = {
				h_helene_of1,
				h_helene_of1,
				h_helene_of2,
				h_helene_of2,
				h_helene_of3,
				h_helene_of3,
				h_helene_of3,
				h_helene_of4,
				h_helene_of4,
				h_helene_of4,
				h_helene_of4,
				h_helene_of3,
				h_helene_of3,
				h_helene_of2,
				h_helene_of2,
				h_helene_of1,
				h_helene_of1
			}
		},
		[h_helene_smile] = {
			fps = 5,
			frames = {
				h_helene_smile1,
				h_helene_smile2,
				h_helene_smile3,
				h_helene_smile4,
				h_helene_smile4,
				h_helene_smile4,
				h_helene_smile3,
				h_helene_smile3,
				h_helene_smile2,
				h_helene_smile2,
				h_helene_smile1,
				h_helene_smile1
			}
		}
	}
}
all_animations[hash("helene")] = animations

return animations
