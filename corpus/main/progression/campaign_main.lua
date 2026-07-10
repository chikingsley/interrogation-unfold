local progression = require("crit.progression")
local snapshot = require("campaign.snapshot")
local sound_util = require("sound.util")
local difficulty_select = require("main.progression.difficulty_select")
local chapter1 = require("main.progression.chapter1.index")
local chapter2 = require("main.progression.chapter2.index")
local chapter3 = require("main.progression.chapter3.index")
local cutscene_intro = require("main.progression.cutscene_intro")
local demo_wall = require("main.progression.demo_wall")

local function campaign_main()
	sound_util.set_preset("hannigan", "event:/Campaign Music/Hannigans", "Campaign 1.bank")
	sound_util.set_preset("interview", "event:/Campaign Music/Interview", "Campaign 1.bank")
	sound_util.set_preset("cp1", "event:/Campaign Music/Campaign 1", "Campaign 1.bank")
	sound_util.set_preset("cp2", "event:/Campaign Music/Campaign 2", "Campaign 1.bank")
	sound_util.set_preset("campaign", sound_util.get_preset("cp1"))
	snapshot.segment("campaign", {
		{
			"cutscene_intro",
			cutscene_intro,
			no_save = true
		},
		{
			"difficulty_select",
			difficulty_select,
			no_save = true
		},
		{
			"chapter1",
			chapter1
		},
		{
			"chapter2",
			demo_wall(chapter2)
		},
		{
			"chapter3",
			demo_wall(chapter3)
		}
	})
end

progression.init_register_function(campaign_main)
