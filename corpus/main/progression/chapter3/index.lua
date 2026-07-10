local episode8 = require("main.progression.chapter3.episode8")
local episode9 = require("main.progression.chapter3.episode9")
local episode10 = require("main.progression.chapter3.episode10")
local hannigan3 = require("main.progression.chapter3.hannigan3")
local interlude_h1 = require("main.progression.chapter3.interlude_h1")
local interlude_h1_1_mordecai = require("main.progression.chapter3.interlude_h1_1_mordecai")
local interlude_h2 = require("main.progression.chapter3.interlude_h2")
local interlude_h3 = require("main.progression.chapter3.interlude_h3")
local interlude_h3_1_joseph = require("main.progression.chapter3.interlude_h3_1_joseph")
local interlude_i1 = require("main.progression.chapter3.interlude_i1")
local interlude_i2 = require("main.progression.chapter3.interlude_i2")
local interlude_i3 = require("main.progression.chapter3.interlude_i3")
local interlude_j = require("main.progression.chapter3.interlude_j")
local interlude_g3 = require("main.progression.chapter3.interlude_g3")
local campaign_phase6 = require("main.progression.chapter3.campaign_phase6")
local campaign_phase7 = require("main.progression.chapter3.campaign_phase7")
local campaign_phase8 = require("main.progression.chapter3.campaign_phase8")
local triggered_torture = require("main.progression.triggered.triggered_torture")
local triggered_encounterless = require("main.progression.triggered.triggered_encounterless")
local triggered_sitdowns = require("main.progression.triggered.triggered_sitdowns")
local triggered_loss = require("main.progression.triggered.triggered_loss")
local perk_select4 = require("main.progression.chapter3.perk_select4")
local press_release7 = require("main.progression.chapter3.press_release7")
local press_release9 = require("main.progression.chapter3.press_release9")
local interview3 = require("main.progression.chapter3.interview3")
local jigsaw_document = require("main.progression.chapter3.jigsaw_document")
local jigsaw_conclusion2 = require("main.progression.chapter3.jigsaw_conclusion2")
local final_cutscene = require("main.progression.chapter3.final_cutscene")
local snapshot = require("campaign.snapshot")
local sound_util = require("sound.util")
local scenes = require("main.progression.scenes")
local with_cp_music = sound_util.with_preset_music("campaign")
local with_interview_music = sound_util.with_preset_music("interview")
local use_cp1_music = sound_util.with_preset_alias("campaign", "cp1")
local use_cp2_music = sound_util.with_preset_alias("campaign", "cp2")
local intermission7 = use_cp2_music(function ()
	snapshot.segment("intermission7", {
		{
			"interlude_g3",
			with_cp_music(interlude_g3)
		},
		{
			"press_release7",
			with_cp_music(press_release7)
		},
		{
			"triggered_torture",
			triggered_torture
		},
		{
			"perk_select4",
			with_cp_music(perk_select4)
		},
		{
			"campaign_phase6",
			with_cp_music(campaign_phase6.run)
		},
		{
			"interview3",
			with_interview_music(interview3)
		},
		{
			"interlude_h1",
			with_cp_music(interlude_h1)
		},
		{
			"hannigan3",
			with_cp_music(hannigan3)
		},
		{
			"interlude_h1_1_mordecai",
			with_cp_music(interlude_h1_1_mordecai)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase6_expo",
			with_cp_music(campaign_phase6.expo)
		},
		{
			"triggered_sitdowns",
			triggered_sitdowns
		},
		{
			"triggered_encounterless",
			triggered_encounterless
		},
		{
			"interlude_h2",
			with_cp_music(interlude_h2)
		}
	})
end)
local intermission8 = use_cp1_music(function ()
	snapshot.segment("intermission8", {
		{
			"episode8_outcome",
			with_cp_music(episode8.outcome)
		},
		{
			"interlude_h3",
			with_cp_music(interlude_h3)
		},
		{
			"interlude_h3_1_joseph",
			interlude_h3_1_joseph
		},
		{
			"interlude_i1",
			with_cp_music(interlude_i1)
		},
		{
			"campaign_phase7",
			with_cp_music(campaign_phase7.run)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"interlude_i2",
			with_cp_music(interlude_i2)
		},
		{
			"jigsaw_document",
			with_cp_music(jigsaw_document)
		},
		{
			"jigsaw_conclusion2",
			with_cp_music(jigsaw_conclusion2)
		},
		{
			"campaign_phase7_expo",
			with_cp_music(campaign_phase7.expo)
		},
		{
			"triggered_sitdowns",
			triggered_sitdowns
		},
		{
			"triggered_encounterless",
			triggered_encounterless
		},
		{
			"interlude_i3",
			with_cp_music(interlude_i3)
		}
	})
end)
local intermission9 = use_cp2_music(function ()
	snapshot.segment("intermission9", {
		{
			"episode9_outcome",
			with_cp_music(episode9.outcome)
		},
		{
			"press_release9",
			with_cp_music(press_release9)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase8_expo",
			with_cp_music(campaign_phase8.expo)
		},
		{
			"interlude_j",
			with_cp_music(interlude_j)
		}
	})
end)

local function credits()
	scenes.load_scene("credits")
	scenes.wait_for_end_scene()
	scenes.run_progression("menu")
end

local function chapter3()
	snapshot.segment("chapter3", {
		{
			"intermission7",
			intermission7
		},
		{
			"episode8",
			episode8.run
		},
		{
			"intermission8",
			intermission8,
			checkpoint = "episode9"
		},
		{
			"episode9",
			episode9.run
		},
		{
			"intermission9",
			intermission9,
			checkpoint = "episode10"
		},
		{
			"episode10",
			episode10.run
		},
		{
			"final_cutscene",
			final_cutscene,
			no_save = true
		},
		{
			"credits",
			credits,
			no_save = true
		}
	})
end

return chapter3
