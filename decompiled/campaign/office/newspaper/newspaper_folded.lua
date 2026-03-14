local office = require("campaign.office")
local intl = require("crit.intl")
local h_set_parent = hash("set_parent")

function _env:init()
	local paper_node = intl.select(function (lang)
		local ok, node = pcall(function ()
			local paper_factory_url = msg.url("#" .. office.newspaper .. "." .. lang)

			return factory.create(paper_factory_url, vmath.vector3(), vmath.quat(), {}, 1)
		end)

		if not ok then
			return nil
		end

		return node
	end)

	if not paper_node then
		error("No folded newspaper factory found for " .. office.newspaper)
	end

	msg.post(paper_node, h_set_parent, {
		keep_world_transform = 0,
		parent_id = go.get_id()
	})
end
