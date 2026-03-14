local h_ = hash("")
local h_position = hash("position")
local h_scalex = hash("scale.x")
local h_rotation = hash("rotation")
local h_positionz = hash("position.z")
local get_connected_objects_position, get_connector_metrics = nil

function get_connector_metrics(object1_pos, object2_pos, original_z)
	local dist_x = object1_pos.x - object2_pos.x
	local dist_y = object1_pos.y - object2_pos.y
	local pos = vmath.vector3()
	pos.x = object1_pos.x - 0.5 * dist_x
	pos.y = object1_pos.y - 0.5 * dist_y
	pos.z = original_z
	local len = math.sqrt(math.pow(math.abs(dist_x), 2) + math.pow(math.abs(dist_y), 2))
	local rot_z = math.asin(dist_y / len)

	if dist_x < 0 then
		rot_z = math.pi - rot_z or rot_z
	end

	local rot_z_deg = rot_z * 180 / math.pi
	local rot = vmath.quat_rotation_z(rot_z)

	return len, pos, rot, rot_z_deg
end

function get_connected_objects_position(this_url, object1, object2)
	local object1_pos = vmath.vector3(0)
	local object2_pos = vmath.vector3(0)

	if object1 ~= h_ then
		local object1_url = msg.url()
		object1_url.socket = this_url.socket
		object1_url.path = object1
		object1_url.fragment = ""
		object1_pos = go.get(object1_url, h_position)
	else
		print("Connector: " .. object1 .. " not found.")
	end

	if object2 ~= h_ then
		local object2_url = msg.url()
		object2_url.socket = this_url.socket
		object2_url.path = object2
		object2_url.fragment = ""
		object2_pos = go.get(object2_url, h_position)
	else
		print("Connector: " .. object2 .. " not found.")
	end

	return object1_pos, object2_pos
end

function _env:init()
	local this_url = msg.url(".")
	local this_sprite = msg.url("#sprite")
	local this_shadow = msg.url("#shadow")

	if self.flip_vertically then
		self.object2 = self.object1
		self.object1 = self.object2
	end

	self.this_go_z = go.get(this_url, h_positionz)
	local object1_pos, object2_pos = get_connected_objects_position(this_url, self.object1, self.object2)
	local connector_len, connector_pos, connector_rot = get_connector_metrics(object1_pos, object2_pos, self.this_go_z)
	connector_len = connector_len * 1 / self.image_width

	go.set(this_url, h_position, connector_pos)
	go.set(this_sprite, h_scalex, connector_len)
	go.set(this_shadow, h_scalex, connector_len)
	go.set(this_url, h_rotation, connector_rot)

	self.object1_pos = object1_pos
	self.object2_pos = object2_pos
end

function _env:final()
	return
end

function _env:on_message(message_id, message, sender)
	return
end
