local stats = require("campaign.stats")
local agents = require("campaign.agents")
local perks = require("campaign.perks")
local variables = require("campaign.variables")
local missions = require("campaign.missions")

return {
	a1 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a1.text0"
		},
		answers = {
			{
				text = "interview1.a1.answer1.text",
				next = "a3",
				animation = "writing",
				reply = {
					"interview1.a1.answer1.reply0"
				},
				effect = function ()
					stats.increment_press(-5)
					stats.increment_popularity(-5)
					stats.increment_authorities(5)
					agents.increment_approval("tab", 5)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview1.a1.answer2.text",
				next = "a2",
				animation = "sceptic",
				effect = function ()
					agents.increment_approval("jen", -5)
					stats.increment_press(-5)
					stats.increment_popularity(5)
					stats.increment_authorities(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview1.a1.answer3.text",
				next = "a2",
				animation = "cute",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(5)
					stats.increment_authorities(-5)
				end
			}
		}
	},
	a2 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a2.text0"
		},
		answers = {
			{
				text = "interview1.a2.answer1.text",
				next = "a4",
				animation = "writing",
				effect = function ()
					agents.increment_approval("tab", 5)
					agents.increment_approval("jen", 5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview1.a2.answer2.text",
				next = "a4",
				animation = "writing",
				reply = {
					"interview1.a2.answer2.reply0"
				},
				effect = function ()
					agents.increment_approval("tab", 5)
					stats.increment_authorities(5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview1.a2.answer3.text",
				next = "a4",
				animation = "sceptic",
				reply = {
					"interview1.a2.answer3.reply0"
				},
				effect = function ()
					agents.increment_approval("jen", -10)
					stats.increment_press(-5)
					stats.increment_authorities(5)
				end
			}
		}
	},
	a3 = {
		idle_animation = "writing",
		animation = "sceptic",
		text = {
			"interview1.a3.text0"
		},
		answers = {
			{
				text = "interview1.a3.answer1.text",
				next = "a4",
				animation = "writing",
				effect = function ()
					agents.increment_approval("tab", 5)
					agents.increment_approval("jen", 5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview1.a3.answer2.text",
				next = "a4",
				animation = "writing",
				effect = function ()
					agents.increment_approval("tab", 5)
					stats.increment_authorities(5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview1.a3.answer3.text",
				next = "a4",
				animation = "sceptic",
				reply = {
					"interview1.a3.answer3.reply0"
				},
				effect = function ()
					agents.increment_approval("jen", -10)
					stats.increment_press(-5)
					stats.increment_authorities(5)
				end
			}
		}
	},
	a4 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a4.text0"
		},
		answers = {
			{
				text = "interview1.a4.answer1.text",
				next = "a5",
				animation = "writing",
				effect = function ()
					agents.increment_approval("tab", 5)
					agents.increment_approval("jen", -5)
				end
			},
			{
				text = "interview1.a4.answer2.text",
				next = "a5",
				animation = "writing",
				effect = function ()
					agents.increment_approval("jen", 5)
					agents.increment_approval("tab", -5)
				end
			},
			{
				text = "interview1.a4.answer3.text",
				next = "a5",
				animation = "sceptic",
				effect = function ()
					stats.increment_press(-5)
					stats.increment_popularity(5)
				end
			}
		}
	},
	a5 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a5.text0"
		},
		answers = {
			{
				text = "interview1.a5.answer1.text",
				next = "a6",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview1.a5.answer2.text",
				next = "a6",
				animation = "sceptic",
				reply = {
					"interview1.a5.answer2.reply0"
				},
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(-5)
					stats.increment_popularity(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview1.a5.answer3.text",
				next = "a6",
				animation = "cute",
				effect = function ()
					stats.increment_press(5)
				end
			}
		}
	},
	a6 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a6.text0"
		},
		answers = {
			{
				text = "interview1.a6.answer1.text",
				next = "a7_nav",
				animation = "writing",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_authorities(-5)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview1.a6.answer2.text",
				next = "a7_nav",
				animation = "writing",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
					stats.increment_authorities(-5)
					agents.increment_approval("tab", 5)
					agents.increment_approval("jen", 5)
				end
			},
			{
				text = "interview1.a6.answer3.text",
				next = "a7_nav",
				animation = "sceptic",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_press(-5)
					stats.increment_lawful(1)
				end
			}
		}
	},
	a7 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a7.text0"
		},
		answers = {
			{
				text = "interview1.a7.answer1.text",
				next = "a8",
				animation = "sceptic",
				reply = {
					"interview1.a7.answer1.reply0"
				},
				effect = function ()
					stats.increment_press(-5)
					stats.increment_popularity(-5)
					stats.increment_authorities(5)
				end
			},
			{
				text = "interview1.a7.answer2.text",
				next = "a8",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_popularity(-5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview1.a7.answer3.text",
				next = "a9",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(-5)
					agents.increment_approval("jen", -5)
					stats.increment_press(5)
					stats.increment_popularity(5)
					stats.increment_lawful(1)
				end
			}
		}
	},
	a8 = {
		idle_animation = "writing",
		animation = "sceptic",
		text = {
			"interview1.a8.text0"
		},
		answers = {
			{
				text = "interview1.a8.answer1.text",
				next = "a9",
				animation = "sceptic",
				effect = function ()
					stats.increment_press(-5)
					stats.increment_popularity(-5)
					stats.increment_authorities(5)
				end
			},
			{
				text = "interview1.a8.answer2.text",
				next = "a9",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview1.a8.answer3.text",
				next = "a9",
				animation = "sceptic",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
					stats.increment_authorities(-5)
					stats.increment_justice(1)
				end
			}
		}
	},
	a9 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a9.text0"
		},
		answers = {
			{
				text = "interview1.a9.answer1.text",
				next = "a11",
				animation = "cute",
				effect = function ()
					stats.increment_authorities(5)
					agents.increment_approval("tab", 5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview1.a9.answer2.text",
				next = "a10",
				animation = "cute",
				effect = function ()
					stats.increment_press(5)
					stats.increment_authorities(-5)
					stats.increment_evolution(1)
					stats.increment_equity(1)
					stats.increment_freedom(1)
				end
			},
			{
				text = "interview1.a9.answer3.text",
				next = "a10",
				animation = "sceptic",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
					stats.increment_authorities(-5)
					stats.increment_justice(1)
				end
			}
		}
	},
	a10 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a10.text0"
		},
		answers = {
			{
				text = "interview1.a10.answer1.text",
				next = "a11",
				animation = "sceptic",
				effect = function ()
					stats.increment_press(-5)
					stats.increment_popularity(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview1.a10.answer2.text",
				next = "a11",
				animation = "cute",
				effect = function ()
					stats.increment_press(5)
				end
			},
			{
				text = "interview1.a10.answer3.text",
				next = "a11",
				animation = "sceptic",
				reply = {
					"interview1.a10.answer3.reply0"
				},
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
					agents.increment_approval("tab", -5)
					stats.increment_justice(1)
				end
			}
		}
	},
	a11 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a11.text0"
		},
		answers = {
			{
				text = "interview1.a11.answer1.text",
				next = "a12",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
				end
			},
			{
				text = "interview1.a11.answer2.text",
				next = "a12",
				animation = "sceptic",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_press(-5)
					agents.increment_approval("tab", 5)
				end
			},
			{
				text = "interview1.a11.answer3.text",
				next = "a12",
				animation = "cute",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(5)
					agents.increment_approval("tab", 5)
					stats.increment_authorities(-5)
				end
			}
		}
	},
	a12 = {
		idle_animation = "writing",
		animation = "question",
		text = {
			"interview1.a12.text0"
		},
		answers = {
			{
				text = "interview1.a12.answer1.text",
				animation = "default",
				reply = {
					"interview1.a12.answer1.reply0"
				}
			},
			{
				text = "interview1.a12.answer2.text",
				animation = "sceptic",
				reply = {
					"interview1.a12.answer2.reply0"
				},
				effect = function ()
					stats.increment_press(-5)
					stats.increment_popularity(5)
					stats.increment_authorities(-5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview1.a12.answer3.text",
				animation = "default",
				reply = {
					"interview1.a12.answer3.reply0"
				},
				effect = function ()
					stats.increment_authorities(5)
				end
			}
		}
	},
	a7_nav = function ()
		if stats.total_torture_damage > 0 then
			return "a7"
		end

		return "a9"
	end
}
