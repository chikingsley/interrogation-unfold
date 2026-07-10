local triggered_civil_forfeiture = require("main.progression.triggered.triggered_civil_forfeiture")
local triggered_community_outreach = require("main.progression.triggered.triggered_community_outreach")
local triggered_recruited_joseph = require("main.progression.triggered.triggered_recruited_joseph")
local triggered_informer_found = require("main.progression.triggered.triggered_informer_found")
local snapshot = require("campaign.snapshot")

local function triggered_encounterless()
	snapshot.segment("triggered_encounterless", {
		{
			"triggered_civil_forfeiture",
			triggered_civil_forfeiture
		},
		{
			"triggered_community_outreach",
			triggered_community_outreach
		},
		{
			"triggered_recruited_joseph",
			triggered_recruited_joseph
		},
		{
			"triggered_informer_found",
			triggered_informer_found
		}
	})
end

return triggered_encounterless
