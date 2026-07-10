local h_set_parent = hash("set_parent")

function _env:init()
	local spine_compenent = msg.url("#scene")
	local flag_url = msg.url("flag")
	local smoke_url = msg.url("smoke_stack")
	local particlefx_dust = msg.url("#apocalyptic_dust")
	local particlefx_smoke = msg.url("smoke_stack#smoke")

	particlefx.play(particlefx_dust)
	particlefx.play(particlefx_smoke)

	local flag_bone = spine.get_go(spine_compenent, "flag_pole")
	local smoke_stack_bone = spine.get_go(spine_compenent, "smoke_stack")

	msg.post(flag_url, h_set_parent, {
		parent_id = flag_bone
	})
	msg.post(smoke_url, h_set_parent, {
		parent_id = smoke_stack_bone
	})
end
