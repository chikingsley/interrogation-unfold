local intl = require("crit.intl")
local sprites = require("campaign.office.sprites")

function _env:init()
	sprite.play_flipbook("#sprite", intl.select(sprites.internal_use))
end
