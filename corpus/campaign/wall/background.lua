function _env:init()
	local left_bg_sprite = msg.url("#background_l")
	local left_wall_sprite = msg.url("backwall#sprite_l")

	sprite.set_hflip(left_bg_sprite, true)
	sprite.set_hflip(left_wall_sprite, true)
end
