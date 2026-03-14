local tutorial = require("main.progression.chapter1.tutorial")
local interlude_a = require("main.progression.chapter1.interlude_a")
local interlude_b0 = require("main.progression.chapter1.interlude_b0")
local interlude_b1 = require("main.progression.chapter1.interlude_b1")
local interlude_b2 = require("main.progression.chapter1.interlude_b2")
local interlude_b3 = require("main.progression.chapter1.interlude_b3")
local interlude_c = require("main.progression.chapter1.interlude_c")
local interlude_c1_cptutorial = require("main.progression.chapter1.interlude_c1_cptutorial")
local interlude_c2 = require("main.progression.chapter1.interlude_c2")
local interlude_c2_1_jen = require("main.progression.chapter1.interlude_c2_1_jen")
local interlude_c3 = require("main.progression.chapter1.interlude_c3")
local interlude_c4 = require("main.progression.chapter1.interlude_c4")
local interview1 = require("main.progression.chapter1.interview1")
local episode1 = require("main.progression.chapter1.episode1")
local episode2 = require("main.progression.chapter1.episode2")
local episode3 = require("main.progression.chapter1.episode3")
local cutscene1 = require("main.progression.chapter1.cutscene1")
local perk_select1 = require("main.progression.chapter1.perk_select1")
local explosion_stat_loss = require("main.progression.chapter1.explosion_stat_loss")
local campaign_phase1 = require("main.progression.chapter1.campaign_phase1")
local press_release1 = require("main.progression.chapter1.press_release1")
local press_release2 = require("main.progression.chapter1.press_release2")
local triggered_torture_e1 = require("main.progression.triggered.triggered_torture_e1")
local triggered_torture = require("main.progression.triggered.triggered_torture")
local triggered_encounterless = require("main.progression.triggered.triggered_encounterless")
local triggered_loss = require("main.progression.triggered.triggered_loss")
local demo_wall = require("main.progression.demo_wall")
local title = require("title.interface")
local snapshot = require("campaign.snapshot")
local scenes = require("main.progression.scenes")
local sound_util = require("sound.util")
local with_cp_music = sound_util.with_preset_music("campaign")
local with_interview_music = sound_util.with_preset_music("interview")
local use_cp1_music = sound_util.with_preset_alias("campaign", "cp1")

local function intermission0()
	snapshot.segment("intermission0", {
		{
			"interlude_a",
			with_cp_music(interlude_a)
		}
	})
end

local function intermission1()
	snapshot.segment("intermission1", {
		{
			"episode1_outcome",
			with_cp_music(episode1.outcome)
		},
		{
			"interlude_b0",
			with_cp_music(interlude_b0)
		},
		{
			"press_release1",
			with_cp_music(press_release1)
		},
		{
			"triggered_torture_e1",
			triggered_torture_e1
		},
		{
			"perk_select1",
			with_cp_music(perk_select1)
		},
		{
			"interlude_b1",
			with_cp_music(interlude_b1)
		},
		{
			"interlude_b2",
			with_cp_music(interlude_b2)
		},
		{
			"interlude_b3",
			with_cp_music(interlude_b3)
		}
	})
end

local function intermission2()
	snapshot.segment("intermission2", {
		{
			"episode2_outcome",
			with_cp_music(episode2.outcome)
		},
		{
			"press_release2",
			with_cp_music(press_release2)
		},
		{
			"triggered_torture",
			triggered_torture
		},
		{
			"interlude_c",
			with_cp_music(interlude_c)
		},
		{
			"interlude_c1_cptutorial",
			with_cp_music(interlude_c1_cptutorial)
		},
		{
			"campaign_phase1",
			with_cp_music(campaign_phase1.run)
		},
		{
			"interview1",
			with_interview_music(interview1)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase1_expo",
			with_cp_music(campaign_phase1.expo)
		},
		{
			"interlude_c2_1_jen",
			with_cp_music(interlude_c2_1_jen)
		},
		{
			"interlude_c2",
			with_cp_music(interlude_c2)
		},
		{
			"interlude_c3",
			with_cp_music(interlude_c3)
		},
		{
			"triggered_encounterless",
			triggered_encounterless
		},
		{
			"interlude_c4",
			with_cp_music(interlude_c4)
		}
	})
end

local tutorial_with_slides = scenes.skippable(function (loaded_save)
	local anim = not loaded_save and "fade" or nil

	title.show_slides({
		"A few years ago"
	}, {
		delay = 1,
		animation_duration = 1
	}, {
		transition = anim
	})
	tutorial()
	title.show_slides({
		"Years later"
	})
end)
local chapter1 = use_cp1_music(function ()
	snapshot.segment("chapter1", {
		{
			"tutorial",
			tutorial_with_slides
		},
		{
			"intermission0",
			intermission0,
			checkpoint = "episode1"
		},
		{
			"episode1",
			episode1.run
		},
		{
			"intermission1",
			intermission1,
			checkpoint = "episode2"
		},
		{
			"episode2",
			episode2.run
		},
		{
			"intermission2",
			intermission2,
			checkpoint = "episode3"
		},
		{
			"episode3",
			episode3.run
		},
		{
			"explosion_stat_loss",
			explosion_stat_loss
		},
		{
			"cutscene1",
			demo_wall(cutscene1),
			checkpoint = "episode4"
		}
	})
end)

return chapter1
