local all_animations = require("main.animations.animations")
local h_chief_asking = hash("chief_asking")
local h_chief_bossss = hash("chief_bossss")
local h_chief_cplm = hash("chief_cplm")
local h_chief_fuck_it = hash("chief_fuck_it")
local h_chief_get_out = hash("chief_get_out")
local h_chief_normal = hash("chief_normal")
local h_chief_smiling = hash("chief_smiling")
local h_chief_thinking = hash("chief_thinking")
local h_chief_worried = hash("chief_worried")
local animations = {
	images = {
		[h_chief_asking] = {
			offset = vmath.vector3(-53.5, -21, 0)
		},
		[h_chief_bossss] = {
			offset = vmath.vector3(13, -50, 0)
		},
		[h_chief_cplm] = {
			offset = vmath.vector3(-6, -49, 0)
		},
		[h_chief_fuck_it] = {
			offset = vmath.vector3(39, -1.5, 0)
		},
		[h_chief_get_out] = {
			offset = vmath.vector3(58.5, -39, 0)
		},
		[h_chief_normal] = {
			offset = vmath.vector3(105.5, -44.5, 0)
		},
		[h_chief_smiling] = {
			offset = vmath.vector3(173.5, -42.5, 0)
		},
		[h_chief_thinking] = {
			offset = vmath.vector3(213, -53, 0)
		},
		[h_chief_worried] = {
			offset = vmath.vector3(126, -41.5, 0)
		}
	},
	animations = {}
}
all_animations[hash("chief")] = animations

return animations
