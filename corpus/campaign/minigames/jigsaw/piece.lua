local Layout = require("crit.layout")
local Inertia = require("crit.inertia")
local Piece = {
	drag_factor = 0.8,
	at_rest_tolerance = 1,
	z_min = -0.8,
	z_max = 0.8,
	z_step = 0.02,
	__index = {},
	screen_boundary_x = Layout.design_width / 2,
	screen_boundary_y = Layout.design_height / 2
}
local h_up = hash("up")
local h_down = hash("down")
local h_right = hash("right")
local h_left = hash("left")
local h_position = hash("position")
local h_position_z = hash("position.z")
local h_sprite = hash("sprite")
local h_euler_z = hash("euler.z")
local h_hitbox = hash("hitbox")
local zero3 = vmath.vector3(0)

local function reflect(vector, normal)
	return vector - 2 * vmath.dot(vector, normal) * normal
end

local function reflect_incoming(vector, normal)
	if vmath.dot(vector, normal) < 0 then
		return reflect(vector, normal)
	end

	return vector
end

local function check_out_of_bounds(new_position, padding)
	local oob_x = math.abs(new_position.x) > Piece.screen_boundary_x + padding
	local oob_y = math.abs(new_position.y) > Piece.screen_boundary_y + padding

	return oob_x, oob_y
end

local function move_to_position(self, new_position)
	local current_position = self.position
	local dx = new_position.x - current_position.x
	local dy = new_position.y - current_position.y

	self:move(dx, dy)

	if self.linked_pieces then
		for i, piece in pairs(self.linked_pieces) do
			piece:move(dx, dy)
		end
	end
end

function Piece.new(id, url, index, position, screen_padding)
	local self = {
		linked_pieces = false,
		is_picked_up = false,
		id = id,
		index = index,
		url = url,
		sprite = msg.url(url.socket, url.path, h_sprite),
		hitbox = msg.url(url.socket, url.path, h_hitbox),
		image = hash("jigsaw" .. index.puzzle_no .. "_" .. index.y .. index.x),
		position = position,
		frame_movement = vmath.vector3(0),
		solved = {
			[h_right] = false,
			[h_left] = false,
			[h_up] = false,
			[h_down] = false
		},
		screen_boundary_padding = screen_padding or 0
	}
	self.inertia = Inertia.new({
		on_rest = function ()
			local is_out_of_bounds_x, is_out_of_bounds_y = check_out_of_bounds(self.position, self.screen_boundary_padding)

			if (is_out_of_bounds_x or is_out_of_bounds_y) and not self.is_picked_up then
				move_to_position(self, vmath.vector3(0))
			end
		end
	})

	setmetatable(self, Piece)
	go.set(self.url, h_position, self.position)
	sprite.play_flipbook(self.sprite, self.image)

	return self
end

function Piece.__index:reset(position)
	self.linked_pieces = false
	self.solved = {
		[h_right] = false,
		[h_left] = false,
		[h_up] = false,
		[h_down] = false
	}

	go.set(self.url, h_position_z, position.z)

	local original_rotation = go.get(self.url, h_euler_z)

	go.set(self.url, h_euler_z, math.random(-40, 130))
	go.animate(self.url, h_position, go.PLAYBACK_ONCE_FORWARD, position, go.EASING_OUTCUBIC, 1)
	go.animate(self.url, h_euler_z, go.PLAYBACK_ONCE_FORWARD, original_rotation, go.EASING_OUTCUBIC, 1)

	self.position = position
end

function Piece.__index:move(dx, dy)
	local pos = self.position
	local new_position = vmath.vector3(pos.x + dx, pos.y + dy, Piece.z_max)
	local collision_normal = nil
	local is_out_of_bounds_x, is_out_of_bounds_y = check_out_of_bounds(new_position, self.screen_boundary_padding)

	if is_out_of_bounds_x and is_out_of_bounds_y then
		collision_normal = vmath.vector3(new_position.x < 0 and 1 or -1, new_position.y < 0 and 1 or -1, 0)
	elseif is_out_of_bounds_x then
		collision_normal = vmath.vector3(new_position.x < 0 and 1 or -1, 0, 0)
	elseif is_out_of_bounds_y then
		collision_normal = vmath.vector3(0, new_position.y < 0 and 1 or -1, 0)
	end

	go.set(self.url, h_position, new_position)

	self.position = new_position

	return collision_normal
end

function Piece.__index:move_linked(dx, dy)
	self.frame_movement = self.frame_movement + vmath.vector3(dx, dy, 0)
	local collision_normal = self:move(dx, dy)

	if self.linked_pieces then
		for i, piece in pairs(self.linked_pieces) do
			local linked_collision_detected = piece:move(dx, dy)

			if not collision_normal and linked_collision_detected then
				collision_normal = linked_collision_detected
			end
		end
	end

	if collision_normal then
		self.frame_movement = reflect_incoming(self.frame_movement, collision_normal)
		self.inertia.velocity = reflect_incoming(self.inertia.velocity, collision_normal)
		self.inertia.last_velocity = reflect_incoming(self.inertia.last_velocity, collision_normal)
	end

	return collision_normal
end

function Piece.__index:update_inertia(dt)
	local frame_movement = self.frame_movement
	self.frame_movement = zero3
	local offset = self.inertia.update(dt, self.is_picked_up and frame_movement)

	if offset then
		self:move_linked(offset.x, offset.y)
	end
end

function Piece.__index:link_to(piece)
	if not self.linked_pieces then
		self.linked_pieces = {}
	end

	if not self.linked_pieces[piece.id] then
		self.linked_pieces[piece.id] = piece

		if piece.linked_pieces then
			for id, pc in pairs(piece.linked_pieces) do
				if not self.linked_pieces[id] and id ~= self.id then
					pc:link_to(self)

					self.linked_pieces[id] = pc
				end
			end
		end
	end
end

function Piece.__index:push_back()
	local pos = self.position
	local new_z = pos.z - Piece.z_step

	if new_z < Piece.z_min then
		new_z = Piece.z_min
	end

	go.set(self.url, h_position, vmath.vector3(pos.x, pos.y, new_z))

	self.position.z = new_z
end

return Piece
