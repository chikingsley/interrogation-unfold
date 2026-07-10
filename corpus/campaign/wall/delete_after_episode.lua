local office = require("campaign.office")

function _env:init()
	if self.delete_after_episode > 0 and self.delete_after_episode < (office.wall or 1) then
		go.delete(".", self.recursive)
	end
end
