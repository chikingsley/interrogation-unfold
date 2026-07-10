local budget = require("campaign.budget")
local missions = require("campaign.missions")
local variables = require("campaign.variables")
local perks = require("campaign.perks")
local scenes = require("main.progression.scenes")
local office = require("campaign.office")
local stats = require("campaign.stats")
local agents = require("campaign.agents")
local sound_util = require("sound.util")

local function set_random_stats()
	stats.set_press(math.random() * 100)
	stats.set_authorities(math.random() * 100)
	stats.set_popularity(math.random() * 100)

	for i, char in ipairs(agents) do
		local agent = agents[char]
		agent.approval = math.random(1, 100)
	end
end

local dummy_description = "Spaceflights cannot be stopped. This is not the work of any one man " .. "or even a group of men. It is a historical process which mankind " .. "is carrying out in accordance with the natural laws of human development."

local function set_missions(id)
	missions.set_options({
		{
			title = "Bribe the Mafia",
			id = "bribe_mafia" .. id,
			position = {
				x = 0.3,
				y = 0.75
			},
			description = dummy_description,
			ineligible = {
				jen = true
			},
			modifiers = {
				tab = -20
			}
		},
		{
			title = "Buy Milk",
			id = "buy_milk" .. id,
			position = {
				x = 0.7,
				y = 0.55
			},
			description = dummy_description
		},
		{
			title = "Contact Informer",
			id = "contact_informer" .. id,
			position = {
				x = 0.2,
				y = 0.3
			},
			description = dummy_description
		}
	})
end

return function (options)
	options = options or {}

	budget.reset()
	missions.reset()
	perks.reset()
	stats.reset()
	agents.reset()
	variables.reset()
	sound_util.set_music("event:/Campaign Music/Campaign 1", "Campaign 1.bank")

	for k, v in pairs(options.variables or {}) do
		variables[k] = v
	end

	set_random_stats()
	set_missions(0)
	missions.assign("tab", "bribe_mafia0")
	missions.assign("jen", "buy_milk0")
	missions.assign("mordecai", "contact_informer0")
	budget.set_selected("extend_pr1", true)

	for i, char in ipairs(agents) do
		agents[char].present = true

		agents.enable_classified_page(char)
	end

	stats.commit()
	missions.commit()
	agents.commit()

	for i = 1, 2 do
		for _, reason in ipairs({
			"interlude",
			"campaign",
			"press_release",
			"interview",
			"misc"
		}) do
			set_random_stats()
			stats.commit(reason)
		end

		budget.increment_capacity(2000)
		budget.set_options({
			{
				id = "pr",
				title = "Money to PR",
				cost = 1000,
				description = dummy_description
			},
			{
				id = "lobby",
				title = "Political lobby",
				cost = 500,
				description = dummy_description
			},
			{
				id = "staff",
				title = "Staffing costs",
				cost = 1000,
				description = dummy_description
			},
			{
				id = "memes",
				title = "Meme budget",
				cost = 300,
				description = dummy_description
			},
			{
				id = "hr",
				title = "Boost HR funding",
				cost = 1000,
				description = dummy_description
			},
			{
				id = "pizza",
				title = "Pizza costs and misc expenses",
				cost = 1000,
				description = dummy_description
			},
			{
				id = "cats",
				title = "Cat memes",
				cost = 300,
				description = dummy_description
			},
			{
				id = "extend_pr1",
				title = "Extended PR Report",
				cost = 300,
				description = dummy_description
			},
			{
				id = "order_hr1",
				title = "Order HR Report",
				cost = 300,
				description = dummy_description
			}
		})
		set_missions(i)
		perks.add_perk("speed")
		perks.add_perk("anatomy")
		perks.add_perk("pacifist")
		office.configure({
			objects = options.objects,
			decorative_objects = options.decorative_objects,
			newspaper = options.newspaper or "newspaper1",
			wall = options.wall or 10
		})

		if i == 1 and options.briefing then
			scenes.load_scene("briefing_room")
		elseif i == 1 and options.wall then
			scenes.load_scene("wall")
		else
			scenes.load_scene("office", {
				no_expo = i == 1 and options.no_expo
			})
		end

		scenes.wait_for_end_scene()
		missions.commit()
		stats.commit()
		agents.commit()
	end

	sound_util.set_music(nil)
	scenes.run_progression("main")
end
