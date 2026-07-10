local Button = require("crit.button")
local h_agent_files = hash("agent_files")
local h_mission_report = hash("mission_report")
local h_pr_report = hash("pr_report")
local h_perks = hash("perks")
local h_newspaper = hash("newspaper")
local h_manual = hash("manual")
local navigation_map = {
	default = {
		default = {
			no_action = h_agent_files,
			[Button.NAVIGATE_LEFT] = h_perks,
			[Button.NAVIGATE_RIGHT] = h_agent_files,
			[Button.NAVIGATE_DOWN] = h_newspaper,
			[Button.NAVIGATE_UP] = h_agent_files
		},
		[h_agent_files] = {
			[Button.NAVIGATE_LEFT] = h_perks,
			[Button.NAVIGATE_RIGHT] = h_mission_report,
			[Button.NAVIGATE_UP] = h_newspaper
		},
		[h_mission_report] = {
			[Button.NAVIGATE_LEFT] = h_agent_files,
			[Button.NAVIGATE_RIGHT] = h_pr_report,
			[Button.NAVIGATE_UP] = h_newspaper
		},
		[h_pr_report] = {
			[Button.NAVIGATE_LEFT] = h_mission_report,
			[Button.NAVIGATE_RIGHT] = h_perks,
			[Button.NAVIGATE_UP] = h_newspaper
		},
		[h_perks] = {
			[Button.NAVIGATE_LEFT] = h_pr_report,
			[Button.NAVIGATE_RIGHT] = h_agent_files,
			[Button.NAVIGATE_UP] = h_manual
		},
		[h_newspaper] = {
			[Button.NAVIGATE_LEFT] = h_manual,
			[Button.NAVIGATE_RIGHT] = h_manual,
			[Button.NAVIGATE_DOWN] = h_pr_report
		},
		[h_manual] = {
			[Button.NAVIGATE_LEFT] = h_newspaper,
			[Button.NAVIGATE_RIGHT] = h_newspaper,
			[Button.NAVIGATE_DOWN] = h_perks
		}
	},
	episode1 = {
		default = {
			no_action = h_agent_files,
			[Button.NAVIGATE_LEFT] = h_perks,
			[Button.NAVIGATE_RIGHT] = h_agent_files,
			[Button.NAVIGATE_DOWN] = h_newspaper,
			[Button.NAVIGATE_UP] = h_agent_files
		},
		[h_agent_files] = {
			[Button.NAVIGATE_LEFT] = h_perks,
			[Button.NAVIGATE_RIGHT] = h_pr_report,
			[Button.NAVIGATE_UP] = h_newspaper
		},
		[h_pr_report] = {
			[Button.NAVIGATE_LEFT] = h_agent_files,
			[Button.NAVIGATE_RIGHT] = h_perks,
			[Button.NAVIGATE_UP] = h_newspaper
		},
		[h_perks] = {
			[Button.NAVIGATE_LEFT] = h_pr_report,
			[Button.NAVIGATE_RIGHT] = h_agent_files,
			[Button.NAVIGATE_UP] = h_manual
		},
		[h_newspaper] = {
			[Button.NAVIGATE_LEFT] = h_manual,
			[Button.NAVIGATE_RIGHT] = h_manual,
			[Button.NAVIGATE_DOWN] = h_pr_report
		},
		[h_manual] = {
			[Button.NAVIGATE_LEFT] = h_newspaper,
			[Button.NAVIGATE_RIGHT] = h_newspaper,
			[Button.NAVIGATE_DOWN] = h_perks
		}
	}
}

return navigation_map
