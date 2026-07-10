local sitdown_informer1 = require("main.progression.triggered.sitdown_informer1")
local sitdown_informer2 = require("main.progression.triggered.sitdown_informer2")
local sitdown_marin = require("main.progression.triggered.sitdown_marin")
local sitdown_joseph = require("main.progression.triggered.sitdown_joseph")
local sitdown_fred = require("main.progression.triggered.sitdown_fred")
local snapshot = require("campaign.snapshot")

local function triggered_sitdowns()
	snapshot.segment("triggered_sitdowns", {
		{
			"sitdown_informer1",
			sitdown_informer1
		},
		{
			"sitdown_joseph",
			sitdown_joseph
		},
		{
			"sitdown_informer2",
			sitdown_informer2
		},
		{
			"sitdown_marin",
			sitdown_marin
		},
		{
			"sitdown_fred",
			sitdown_fred
		}
	})
end

return triggered_sitdowns
