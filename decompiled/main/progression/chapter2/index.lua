local episode4 = require("main.progression.chapter2.episode4")
local episode5 = require("main.progression.chapter2.episode5")
local episode6 = require("main.progression.chapter2.episode6")
local episode7 = require("main.progression.chapter2.episode7")
local campaign_phase2 = require("main.progression.chapter2.campaign_phase2")
local campaign_phase3 = require("main.progression.chapter2.campaign_phase3")
local campaign_phase4 = require("main.progression.chapter2.campaign_phase4")
local campaign_phase5 = require("main.progression.chapter2.campaign_phase5")
local interlude_d1 = require("main.progression.chapter2.interlude_d1")
local interlude_d2 = require("main.progression.chapter2.interlude_d2")
local interlude_d3 = require("main.progression.chapter2.interlude_d3")
local interlude_d4 = require("main.progression.chapter2.interlude_d4")
local interlude_e1 = require("main.progression.chapter2.interlude_e1")
local interlude_e2 = require("main.progression.chapter2.interlude_e2")
local interlude_e2_1_tab = require("main.progression.chapter2.interlude_e2_1_tab")
local interlude_e3 = require("main.progression.chapter2.interlude_e3")
local interlude_e4 = require("main.progression.chapter2.interlude_e4")
local interlude_f1 = require("main.progression.chapter2.interlude_f1")
local interlude_f2 = require("main.progression.chapter2.interlude_f2")
local interlude_f3 = require("main.progression.chapter2.interlude_f3")
local interlude_g1 = require("main.progression.chapter2.interlude_g1")
local interlude_g2 = require("main.progression.chapter2.interlude_g2")
local hannigan1 = require("main.progression.chapter2.hannigan1")
local hannigan2 = require("main.progression.chapter2.hannigan2")
local triggered_torture = require("main.progression.triggered.triggered_torture")
local triggered_encounterless = require("main.progression.triggered.triggered_encounterless")
local triggered_sitdowns = require("main.progression.triggered.triggered_sitdowns")
local triggered_loss = require("main.progression.triggered.triggered_loss")
local perk_select2 = require("main.progression.chapter2.perk_select2")
local perk_select3 = require("main.progression.chapter2.perk_select3")
local press_release3 = require("main.progression.chapter2.press_release3")
local press_release4 = require("main.progression.chapter2.press_release4")
local press_release5 = require("main.progression.chapter2.press_release5")
local press_release6 = require("main.progression.chapter2.press_release6")
local interview2 = require("main.progression.chapter2.interview2")
local jigsaw_photo = require("main.progression.chapter2.jigsaw_photo")
local jigsaw_conclusion = require("main.progression.chapter2.jigsaw_conclusion")
local snapshot = require("campaign.snapshot")
local sound_util = require("sound.util")
local with_cp_music = sound_util.with_preset_music("campaign")
local with_interview_music = sound_util.with_preset_music("interview")
local use_cp1_music = sound_util.with_preset_alias("campaign", "cp1")
local use_cp2_music = sound_util.with_preset_alias("campaign", "cp2")
local intermission3 = use_cp2_music(function ()
	snapshot.segment("intermission3", {
		{
			"press_release3",
			with_cp_music(press_release3)
		},
		{
			"triggered_torture",
			with_cp_music(triggered_torture)
		},
		{
			"interlude_d1",
			with_cp_music(interlude_d1)
		},
		{
			"perk_select2",
			with_cp_music(perk_select2)
		},
		{
			"campaign_phase2",
			with_cp_music(campaign_phase2.run)
		},
		{
			"hannigan1",
			with_cp_music(hannigan1)
		},
		{
			"interlude_d2",
			with_cp_music(interlude_d2)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase2_expo",
			with_cp_music(campaign_phase2.expo)
		},
		{
			"triggered_sitdowns",
			triggered_sitdowns
		},
		{
			"interlude_d3",
			with_cp_music(interlude_d3)
		},
		{
			"jigsaw_photo",
			with_cp_music(jigsaw_photo)
		},
		{
			"jigsaw_conclusion",
			with_cp_music(jigsaw_conclusion)
		},
		{
			"triggered_encounterless",
			triggered_encounterless
		},
		{
			"interlude_d4",
			with_cp_music(interlude_d4)
		}
	})
end)
local intermission4 = use_cp1_music(function ()
	snapshot.segment("intermission4", {
		{
			"episode4_outcome",
			with_cp_music(episode4.outcome)
		},
		{
			"press_release4",
			with_cp_music(press_release4)
		},
		{
			"triggered_torture",
			triggered_torture
		},
		{
			"interlude_e1",
			with_cp_music(interlude_e1)
		},
		{
			"campaign_phase3",
			with_cp_music(campaign_phase3.run)
		},
		{
			"interlude_e2",
			with_cp_music(interlude_e2)
		},
		{
			"interlude_e2_1_tab",
			with_cp_music(interlude_e2_1_tab)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase3_expo",
			with_cp_music(campaign_phase3.expo)
		},
		{
			"interlude_e3",
			with_cp_music(interlude_e3)
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
			"interlude_e4",
			with_cp_music(interlude_e4)
		}
	})
end)
local intermission5 = use_cp2_music(function ()
	snapshot.segment("intermission5", {
		{
			"episode5_outcome",
			with_cp_music(episode5.outcome)
		},
		{
			"press_release5",
			with_cp_music(press_release5)
		},
		{
			"triggered_torture",
			triggered_torture
		},
		{
			"interlude_f1",
			with_cp_music(interlude_f1)
		},
		{
			"perk_select3",
			with_cp_music(perk_select3)
		},
		{
			"campaign_phase4",
			with_cp_music(campaign_phase4.run)
		},
		{
			"interview2",
			with_interview_music(interview2)
		},
		{
			"hannigan2",
			with_cp_music(hannigan2)
		},
		{
			"interlude_f2",
			with_cp_music(interlude_f2)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase4_expo",
			with_cp_music(campaign_phase4.expo)
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
			"interlude_f3",
			with_cp_music(interlude_f3)
		}
	})
end)
local intermission6 = use_cp2_music(function ()
	snapshot.segment("intermission6", {
		{
			"episode6_outcome",
			with_cp_music(episode6.outcome)
		},
		{
			"press_release6",
			with_cp_music(press_release6)
		},
		{
			"triggered_torture",
			triggered_torture
		},
		{
			"interlude_g1",
			with_cp_music(interlude_g1)
		},
		{
			"campaign_phase5",
			with_cp_music(campaign_phase5.run)
		},
		{
			"triggered_loss",
			triggered_loss
		},
		{
			"campaign_phase5_expo",
			with_cp_music(campaign_phase5.expo)
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
			"interlude_g2",
			with_cp_music(interlude_g2)
		}
	})
end)

local function chapter2()
	snapshot.segment("chapter2", {
		{
			"intermission3",
			intermission3
		},
		{
			"episode4",
			episode4.run
		},
		{
			"intermission4",
			intermission4,
			checkpoint = "episode5"
		},
		{
			"episode5",
			episode5.run
		},
		{
			"intermission5",
			intermission5,
			checkpoint = "episode6"
		},
		{
			"episode6",
			episode6.run
		},
		{
			"intermission6",
			intermission6,
			checkpoint = "episode7"
		},
		{
			"episode7",
			episode7.run
		},
		{
			"episode7_outcome",
			episode7.outcome,
			checkpoint = "episode8"
		}
	})
end

return chapter2
