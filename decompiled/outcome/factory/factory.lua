local dispatcher = require("crit.dispatcher")
local h_background_day = hash("factory_background_day")
local h_background_night = hash("factory_background_night")
local h_buildings_intact = hash("factory_buildings_intact")
local h_buildings_destroyed = hash("factory_buildings_destroyed")
local h_sun = hash("factory_sun")
local h_moon = hash("factory_moon")
local h_pixel = hash("pixel")
local h_rubble = hash("factory_rubble")
local h_animation = hash("animation")
local h_outcome_set_options = hash("outcome_set_options")
local h_smoke_particles = hash("smoke_particles")
local h_position = hash("position")
local h_positionz = hash("position.z")
local h_show_button = hash("show_button")

local function set_night_time(night_time)
	local background = msg.url("background#sprite")
	local sun = msg.url("sun#sprite")

	sprite.play_flipbook(background, night_time and h_background_night or h_background_day)
	sprite.play_flipbook(sun, night_time and h_moon or h_sun)
end

local function destroy_factory(destroyed)
	local buildings = msg.url("scene#buildings")
	local rubble = msg.url("scene#rubble")
	local smokestack_spine = msg.url("smokestacks#spinemodel")

	sprite.play_flipbook(buildings, destroyed and h_buildings_destroyed or h_buildings_intact)
	sprite.play_flipbook(rubble, destroyed and h_rubble or h_pixel)
	spine.cancel(smokestack_spine)

	if destroyed then
		local building_smoke = msg.url("building_smoke#building_smoke")

		particlefx.play(building_smoke)

		local collapse_particles = msg.url("smokestacks#particles")

		particlefx.play(collapse_particles)
		timer.delay(3, false, function ()
			spine.play_anim(smokestack_spine, h_animation, go.PLAYBACK_ONCE_FORWARD)
		end)
	end
end

function _env:init()
	local smokestack_spine = msg.url("smokestacks#spinemodel")
	self.collapsing_tower_top = spine.get_go(smokestack_spine, h_smoke_particles)
	self.collapsing_tower_smoke_go = msg.url("collapsing_tower_smoke")
	self.collapsing_tower_smoke_z = go.get(msg.url(self.collapsing_tower_smoke_go), h_positionz)
	local smoke_particles1 = msg.url("smoke#smoke1")
	local smoke_particles2 = msg.url("smoke#smoke2")
	local smoke_particles3 = msg.url("smoke#smoke3")
	local clouds = msg.url("clouds#clouds")

	particlefx.play(smoke_particles1)
	particlefx.play(smoke_particles2)
	particlefx.play(smoke_particles3)
	particlefx.play(clouds)
	set_night_time(true)

	self.sub_id = dispatcher.subscribe({
		h_outcome_set_options
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:update(dt)
	local collapsing_tower_smoke_pos = go.get_world_position(self.collapsing_tower_top)
	collapsing_tower_smoke_pos = vmath.vector3(collapsing_tower_smoke_pos.x, collapsing_tower_smoke_pos.y, self.collapsing_tower_smoke_z)

	go.set(self.collapsing_tower_smoke_go, h_position, collapsing_tower_smoke_pos)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_outcome_set_options then
		local has_won = message.has_won

		destroy_factory(not has_won)

		local nav_button = msg.url("nav_button_lose")

		if has_won then
			nav_button = msg.url("nav_button_win")
		end

		msg.post(nav_button, h_show_button, {
			delay = 1
		})
	end
end
