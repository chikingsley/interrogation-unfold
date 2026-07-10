local all_animations = require("main.animations.animations")
local h_james_idle = hash("james_idle")
local h_james_idle_blink = hash("james_idle_blink")
local h_james_idle_empathy = hash("james_idle_empathy")
local h_james_idle_empathy_blink = hash("james_idle_empathy_blink")
local h_james_idle_scared = hash("james_idle_scared")
local h_james_idle_scared_blink = hash("james_idle_scared_blink")
local h_james_dismissive = hash("james_dismissive")
local h_james_dunno = hash("james_dunno")
local h_james_headshake = hash("james_headshake")
local h_james_no_problem = hash("james_no_problem")
local h_james_point = hash("james_point")
local h_james_salute = hash("james_salute")
local h_james_smug = hash("james_smug")
local h_james_terrified = hash("james_terrified")
local h_james_smash_table = hash("james_smash_table")
local h_james_cough = hash("james_cough")
local h_james_idle1 = hash("james_idle1")
local h_james_idle2 = hash("james_idle2")
local h_james_idle3 = hash("james_idle3")
local h_james_idle1b = hash("james_idle1b")
local h_james_idle_empathy1 = hash("james_idle_empathy1")
local h_james_idle_empathy2 = hash("james_idle_empathy2")
local h_james_idle_empathy1b = hash("james_idle_empathy1b")
local h_james_idle_scared1 = hash("james_idle_scared1")
local h_james_idle_scared2 = hash("james_idle_scared2")
local h_james_idle_scared3 = hash("james_idle_scared3")
local h_james_idle_scared1b = hash("james_idle_scared1b")
local h_james_dismissive1 = hash("james_dismissive1")
local h_james_dismissive2 = hash("james_dismissive2")
local h_james_dismissive3 = hash("james_dismissive3")
local h_james_dunno1 = hash("james_dunno1")
local h_james_dunno2 = hash("james_dunno2")
local h_james_dunno3 = hash("james_dunno3")
local h_james_dunno4 = hash("james_dunno4")
local h_james_headshake3 = hash("james_headshake3")
local h_james_headshake4 = hash("james_headshake4")
local h_james_headshake2 = hash("james_headshake2")
local h_james_headshake1 = hash("james_headshake1")
local h_james_no_problem1 = hash("james_no_problem1")
local h_james_no_problem2 = hash("james_no_problem2")
local h_james_no_problem3 = hash("james_no_problem3")
local h_james_no_problem4 = hash("james_no_problem4")
local h_james_point1 = hash("james_point1")
local h_james_point2 = hash("james_point2")
local h_james_point3 = hash("james_point3")
local h_james_point4 = hash("james_point4")
local h_james_salute0 = hash("james_salute0")
local h_james_salute1 = hash("james_salute1")
local h_james_salute2 = hash("james_salute2")
local h_james_salute3 = hash("james_salute3")
local h_james_salute4 = hash("james_salute4")
local h_james_smug1 = hash("james_smug1")
local h_james_smug2 = hash("james_smug2")
local h_james_smug3 = hash("james_smug3")
local h_james_smug4 = hash("james_smug4")
local h_james_terrified1 = hash("james_terrified1")
local h_james_terrified2 = hash("james_terrified2")
local h_james_terrified3 = hash("james_terrified3")
local h_james_terrified4 = hash("james_terrified4")
local h_james_smash_table2 = hash("james_smash_table2")
local h_james_smash_table3 = hash("james_smash_table3")
local h_james_smash_table4 = hash("james_smash_table4")
local h_james_smash_table5 = hash("james_smash_table5")
local h_james_smash_table6 = hash("james_smash_table6")
local h_james_cough1 = hash("james_cough1")
local h_james_cough2 = hash("james_cough2")
local h_james_cough3 = hash("james_cough3")
local h_james_cough4 = hash("james_cough4")
local animations = {
	images = {
		[h_james_idle1] = {
			offset = vmath.vector3(48, 5, 0)
		},
		[h_james_idle2] = {
			offset = vmath.vector3(50, 5.5, 0)
		},
		[h_james_idle3] = {
			offset = vmath.vector3(49.5, 5.5, 0)
		},
		[h_james_idle1b] = {
			offset = vmath.vector3(48, 5, 0)
		},
		[h_james_idle_empathy1] = {
			offset = vmath.vector3(54.5, 4.5, 0)
		},
		[h_james_idle_empathy2] = {
			offset = vmath.vector3(55.5, 5, 0)
		},
		[h_james_idle_empathy1b] = {
			offset = vmath.vector3(54.5, 4.5, 0)
		},
		[h_james_idle_scared1] = {
			offset = vmath.vector3(52, 3.5, 0)
		},
		[h_james_idle_scared2] = {
			offset = vmath.vector3(53.5, 3.5, 0)
		},
		[h_james_idle_scared3] = {
			offset = vmath.vector3(51, 4, 0)
		},
		[h_james_idle_scared1b] = {
			offset = vmath.vector3(52, 3.5, 0)
		},
		[h_james_dismissive1] = {
			offset = vmath.vector3(53, 6.5, 0)
		},
		[h_james_dismissive2] = {
			offset = vmath.vector3(53, 7.5, 0)
		},
		[h_james_dismissive3] = {
			offset = vmath.vector3(52.5, 7, 0)
		},
		[h_james_dunno1] = {
			offset = vmath.vector3(50, 2, 0)
		},
		[h_james_dunno2] = {
			offset = vmath.vector3(49, 2.5, 0)
		},
		[h_james_dunno3] = {
			offset = vmath.vector3(43.5, 1.5, 0)
		},
		[h_james_dunno4] = {
			offset = vmath.vector3(39.5, 1.5, 0)
		},
		[h_james_headshake3] = {
			offset = vmath.vector3(56, 3, 0)
		},
		[h_james_headshake4] = {
			offset = vmath.vector3(59, 3, 0)
		},
		[h_james_headshake2] = {
			offset = vmath.vector3(57, 2.5, 0)
		},
		[h_james_headshake1] = {
			offset = vmath.vector3(54.5, 2.5, 0)
		},
		[h_james_no_problem1] = {
			offset = vmath.vector3(51.5, 5.5, 0)
		},
		[h_james_no_problem2] = {
			offset = vmath.vector3(54, 6, 0)
		},
		[h_james_no_problem3] = {
			offset = vmath.vector3(54.5, 5.5, 0)
		},
		[h_james_no_problem4] = {
			offset = vmath.vector3(54.5, 5, 0)
		},
		[h_james_point1] = {
			offset = vmath.vector3(55.5, 4, 0)
		},
		[h_james_point2] = {
			offset = vmath.vector3(62.5, 3, 0)
		},
		[h_james_point3] = {
			offset = vmath.vector3(49.5, 3.5, 0)
		},
		[h_james_point4] = {
			offset = vmath.vector3(47.5, 5, 0)
		},
		[h_james_salute0] = {
			offset = vmath.vector3(52.5, 4, 0)
		},
		[h_james_salute1] = {
			offset = vmath.vector3(42, 4, 0)
		},
		[h_james_salute2] = {
			offset = vmath.vector3(38.5, 4, 0)
		},
		[h_james_salute3] = {
			offset = vmath.vector3(37.5, 5.5, 0)
		},
		[h_james_salute4] = {
			offset = vmath.vector3(37, 3.5, 0)
		},
		[h_james_smug1] = {
			offset = vmath.vector3(57, 5, 0)
		},
		[h_james_smug2] = {
			offset = vmath.vector3(56, 9.5, 0)
		},
		[h_james_smug3] = {
			offset = vmath.vector3(58.5, 9.5, 0)
		},
		[h_james_smug4] = {
			offset = vmath.vector3(58.5, 5.5, 0)
		},
		[h_james_terrified1] = {
			offset = vmath.vector3(50.5, 5, 0)
		},
		[h_james_terrified2] = {
			offset = vmath.vector3(47.5, 2, 0)
		},
		[h_james_terrified3] = {
			offset = vmath.vector3(69.5, -7.5, 0)
		},
		[h_james_terrified4] = {
			offset = vmath.vector3(81.5, -12.5, 0)
		},
		[h_james_smash_table2] = {
			offset = vmath.vector3(-10.5, -2.5, 0)
		},
		[h_james_smash_table3] = {
			offset = vmath.vector3(-19.5, -1, 0)
		},
		[h_james_smash_table4] = {
			offset = vmath.vector3(-19.5, -1, 0)
		},
		[h_james_smash_table5] = {
			offset = vmath.vector3(-7.5, -11.5, 0)
		},
		[h_james_smash_table6] = {
			offset = vmath.vector3(32, 2.5, 0)
		},
		[h_james_cough1] = {
			offset = vmath.vector3(59.5, -0.5, 0)
		},
		[h_james_cough2] = {
			offset = vmath.vector3(49.5, -6, 0)
		},
		[h_james_cough3] = {
			offset = vmath.vector3(48, -0.5, 0)
		},
		[h_james_cough4] = {
			offset = vmath.vector3(50, -4.5, 0)
		}
	},
	animations = {
		[h_james_idle] = {
			fps = 5,
			frames = {
				h_james_idle1,
				h_james_idle1,
				h_james_idle1,
				h_james_idle1,
				h_james_idle1,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2,
				h_james_idle3,
				h_james_idle3,
				h_james_idle3,
				h_james_idle3,
				h_james_idle3,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2
			}
		},
		[h_james_idle_blink] = {
			fps = 5,
			frames = {
				h_james_idle1,
				h_james_idle1,
				h_james_idle1b,
				h_james_idle1b,
				h_james_idle1,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2,
				h_james_idle3,
				h_james_idle3,
				h_james_idle3,
				h_james_idle3,
				h_james_idle3,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2,
				h_james_idle2
			}
		},
		[h_james_idle_empathy] = {
			fps = 5,
			frames = {
				h_james_idle_empathy1,
				h_james_idle_empathy1,
				h_james_idle_empathy1,
				h_james_idle_empathy1,
				h_james_idle_empathy1,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2
			}
		},
		[h_james_idle_empathy_blink] = {
			fps = 5,
			frames = {
				h_james_idle_empathy1,
				h_james_idle_empathy1b,
				h_james_idle_empathy1b,
				h_james_idle_empathy1,
				h_james_idle_empathy1,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2,
				h_james_idle_empathy2
			}
		},
		[h_james_idle_scared] = {
			fps = 6,
			frames = {
				h_james_idle_scared1,
				h_james_idle_scared1,
				h_james_idle_scared1,
				h_james_idle_scared1,
				h_james_idle_scared2,
				h_james_idle_scared2,
				h_james_idle_scared2,
				h_james_idle_scared3,
				h_james_idle_scared3,
				h_james_idle_scared3,
				h_james_idle_scared3,
				h_james_idle_scared2,
				h_james_idle_scared2,
				h_james_idle_scared2
			}
		},
		[h_james_idle_scared_blink] = {
			fps = 6,
			frames = {
				h_james_idle_scared1b,
				h_james_idle_scared1b,
				h_james_idle_scared1b,
				h_james_idle_scared1b,
				h_james_idle_scared2,
				h_james_idle_scared2,
				h_james_idle_scared2,
				h_james_idle_scared3,
				h_james_idle_scared3,
				h_james_idle_scared3,
				h_james_idle_scared3,
				h_james_idle_scared2,
				h_james_idle_scared2,
				h_james_idle_scared2
			}
		},
		[h_james_dismissive] = {
			fps = 4,
			frames = {
				h_james_dismissive1,
				h_james_dismissive2,
				h_james_dismissive3,
				h_james_dismissive3,
				h_james_dismissive3,
				h_james_dismissive3,
				h_james_dismissive2,
				h_james_dismissive2,
				h_james_dismissive1,
				h_james_dismissive1
			}
		},
		[h_james_dunno] = {
			fps = 4,
			frames = {
				h_james_dunno1,
				h_james_dunno2,
				h_james_dunno3,
				h_james_dunno4,
				h_james_dunno4,
				h_james_dunno4,
				h_james_dunno3,
				h_james_dunno2,
				h_james_dunno1
			}
		},
		[h_james_headshake] = {
			fps = 4,
			frames = {
				h_james_headshake3,
				h_james_headshake4,
				h_james_headshake3,
				h_james_headshake2,
				h_james_headshake1,
				h_james_headshake2,
				h_james_headshake3,
				h_james_headshake4,
				h_james_headshake3
			}
		},
		[h_james_no_problem] = {
			fps = 4,
			frames = {
				h_james_no_problem1,
				h_james_no_problem2,
				h_james_no_problem3,
				h_james_no_problem4,
				h_james_no_problem4,
				h_james_no_problem4,
				h_james_no_problem4,
				h_james_no_problem3,
				h_james_no_problem2,
				h_james_no_problem1
			}
		},
		[h_james_point] = {
			fps = 5,
			frames = {
				h_james_point1,
				h_james_point2,
				h_james_point3,
				h_james_point4,
				h_james_point4,
				h_james_point4,
				h_james_point4,
				h_james_point3,
				h_james_point2,
				h_james_point1
			}
		},
		[h_james_salute] = {
			fps = 8,
			frames = {
				h_james_salute0,
				h_james_salute1,
				h_james_salute2,
				h_james_salute3,
				h_james_salute4,
				h_james_salute4,
				h_james_salute4,
				h_james_salute4,
				h_james_salute4,
				h_james_salute4,
				h_james_salute3,
				h_james_salute3,
				h_james_salute2,
				h_james_salute2,
				h_james_salute1,
				h_james_salute1,
				h_james_salute0,
				h_james_salute0
			}
		},
		[h_james_smug] = {
			fps = 5,
			frames = {
				h_james_smug1,
				h_james_smug2,
				h_james_smug3,
				h_james_smug4,
				h_james_smug4,
				h_james_smug4,
				h_james_smug4,
				h_james_smug4,
				h_james_smug3,
				h_james_smug2,
				h_james_smug1
			}
		},
		[h_james_terrified] = {
			fps = 5,
			frames = {
				h_james_terrified1,
				h_james_terrified2,
				h_james_terrified3,
				h_james_terrified4,
				h_james_terrified4,
				h_james_terrified4,
				h_james_terrified4,
				h_james_terrified4,
				h_james_terrified3,
				h_james_terrified3,
				h_james_terrified2,
				h_james_terrified2,
				h_james_terrified1,
				h_james_terrified1
			}
		},
		[h_james_smash_table] = {
			fps = 8,
			frames = {
				h_james_smash_table2,
				h_james_smash_table3,
				h_james_smash_table3,
				h_james_smash_table4,
				h_james_smash_table5,
				h_james_smash_table5,
				h_james_smash_table5,
				h_james_smash_table5,
				h_james_smash_table5,
				h_james_smash_table5,
				h_james_smash_table5,
				h_james_smash_table6,
				h_james_smash_table6
			}
		},
		[h_james_cough] = {
			fps = 4,
			frames = {
				h_james_cough1,
				h_james_cough2,
				h_james_cough3,
				h_james_cough4,
				h_james_cough4,
				h_james_cough4,
				h_james_cough4,
				h_james_cough4,
				h_james_cough1,
				h_james_cough1,
				h_james_cough1
			}
		}
	}
}
all_animations[hash("james")] = animations

return animations
