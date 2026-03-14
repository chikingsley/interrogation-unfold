local default_snap_hitbox = {
	top = 4,
	bottom = 4,
	left = 4,
	right = 4
}
local default_extended_padding = 10
local config_jigsaw = {
	test_painting = {
		{
			columns = 5,
			screen_boundary_padding = 20,
			rows = 4,
			image_size = {
				x = 1000,
				y = 800
			},
			extended_padding = default_extended_padding,
			snap_hitbox = default_snap_hitbox
		}
	},
	airline_document = {
		{
			columns = 25,
			rows = 1,
			image_size = {
				x = 1325,
				y = 928
			},
			extended_padding = default_extended_padding,
			snap_hitbox = default_snap_hitbox
		}
	},
	elevator = {
		{
			columns = 6,
			extended_padding = 0,
			screen_boundary_padding = 65,
			rows = 5,
			image_size = {
				x = 1020,
				y = 765
			},
			snap_hitbox = default_snap_hitbox
		}
	}
}

return config_jigsaw
