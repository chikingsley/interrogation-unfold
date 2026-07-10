local stats = require("campaign.stats")
local agents = require("campaign.agents")

return function ()
	stats.increment_authorities(-20)
	stats.increment_popularity(-20)
	stats.increment_press(-20)

	for i, agent_id in ipairs(agents) do
		agents.increment_approval(agent_id, -10)
	end

	stats.commit("explosion")
end
