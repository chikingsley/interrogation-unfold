local table_util = require("crit.table_util")
local office = {
	has_briefing_room = true,
	focus_map = "default",
	objects = {
		"agent_files",
		"mission_report",
		"pr_report",
		"perks",
		"newspaper",
		"manual"
	},
	decorative_objects = {
		"typewriter",
		"ash_tray",
		"coffee",
		"revolver",
		"pencil",
		"fountain_pen"
	},
	unavailable_agents = {}
}
local defaults = table_util.clone(office)

function office.reset()
	table_util.assign(office, defaults)

	office.newspaper = nil
	office.wall = nil
end

function office.configure(config)
	office.reset()
	table_util.assign(office, config)
end

function office.save()
	return table_util.deep_clone(office, table_util.no_functions)
end

office.load = office.configure

return office
