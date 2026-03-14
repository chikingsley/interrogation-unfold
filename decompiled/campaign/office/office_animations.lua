local all_animations = require("main.animations.animations")
local h_album = hash("album")
local h_agent_files = hash("agent_files")
local h_manual = hash("manual")
local h_album1 = hash("album1")
local h_album2 = hash("album2")
local h_album3 = hash("album3")
local h_album4 = hash("album4")
local h_album5 = hash("album5")
local h_agent_folder1 = hash("agent_folder1")
local h_agent_folder2 = hash("agent_folder2")
local h_agent_folder3 = hash("agent_folder3")
local h_agent_folder4 = hash("agent_folder4")
local h_agent_folder5 = hash("agent_folder5")
local h_agent_folder6 = hash("agent_folder6")
local h_agent_folder7 = hash("agent_folder7")
local h_manual1 = hash("manual1")
local h_manual2 = hash("manual2")
local h_manual3 = hash("manual3")
local h_manual4 = hash("manual4")
local h_manual5 = hash("manual5")
local two3 = vmath.vector3(2)
local animations = {
	images = {
		[h_album1] = {
			offset = vmath.vector3(227, -19, 0)
		},
		[h_album2] = {
			offset = vmath.vector3(225, -5, 0),
			scale = two3
		},
		[h_album3] = {
			offset = vmath.vector3(222.5, -0, 0),
			scale = two3
		},
		[h_album4] = {
			offset = vmath.vector3(100, 3.5, 0),
			scale = two3
		},
		[h_album5] = {
			offset = vmath.vector3(-1, -22, 0)
		},
		[h_agent_folder1] = {
			offset = vmath.vector3(373, -21.5, 0)
		},
		[h_agent_folder2] = {
			offset = vmath.vector3(357, -2, 0),
			scale = two3
		},
		[h_agent_folder3] = {
			offset = vmath.vector3(357, -4, 0),
			scale = two3
		},
		[h_agent_folder4] = {
			offset = vmath.vector3(357, 10, 0),
			scale = two3
		},
		[h_agent_folder5] = {
			offset = vmath.vector3(201.5, -1, 0),
			scale = two3
		},
		[h_agent_folder6] = {
			offset = vmath.vector3(73.5, -3.5, 0),
			scale = two3
		},
		[h_agent_folder7] = {
			offset = vmath.vector3(-2, -20.5, 0)
		},
		[h_manual1] = {
			offset = vmath.vector3(326, -31.5, 0)
		},
		[h_manual2] = {
			offset = vmath.vector3(337, 0.5, 0),
			scale = two3
		},
		[h_manual3] = {
			offset = vmath.vector3(331, -0, 0),
			scale = two3
		},
		[h_manual4] = {
			offset = vmath.vector3(146, 19.5, 0),
			scale = two3
		},
		[h_manual5] = {
			offset = vmath.vector3(-5.5, -34.5, 0)
		}
	},
	animations = {
		[h_album] = {
			fps = 15,
			frames = {
				h_album1,
				h_album2,
				h_album3,
				h_album4,
				h_album5
			}
		},
		[h_agent_files] = {
			fps = 22,
			frames = {
				h_agent_folder1,
				h_agent_folder2,
				h_agent_folder3,
				h_agent_folder4,
				h_agent_folder5,
				h_agent_folder6,
				h_agent_folder7
			}
		},
		[h_manual] = {
			fps = 12,
			frames = {
				h_manual1,
				h_manual2,
				h_manual3,
				h_manual4,
				h_manual5
			}
		}
	}
}
all_animations[hash("office")] = animations

return animations
