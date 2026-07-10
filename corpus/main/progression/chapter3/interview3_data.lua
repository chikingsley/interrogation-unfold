local stats = require("campaign.stats")
local agents = require("campaign.agents")
local perks = require("campaign.perks")
local variables = require("campaign.variables")
local missions = require("campaign.missions")

return {
	a1 = {
		idle_animation = "leaning_back",
		animation = "asking",
		text = {
			"interview3.a1.text0"
		},
		answers = {
			{
				text = "interview3.a1.answer1.text",
				next = "a2",
				animation = "writing_phone",
				effect = function ()
					stats.increment_authorities(5)
				end
			},
			{
				text = "interview3.a1.answer2.text",
				next = "a2",
				animation = "writing_phone",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview3.a1.answer3.text",
				next = "a2",
				animation = "writing_phone",
				effect = function ()
					stats.increment_authorities(5)
				end
			}
		}
	},
	a2 = {
		idle_animation = "pointing",
		animation = "leaning_back",
		text = {
			"interview3.a2.text0"
		},
		answers = {
			{
				text = "interview3.a2.answer1.text",
				next = "a3",
				animation = "leaning_back"
			},
			{
				text = "interview3.a2.answer2.text",
				next = "a3",
				animation = "leaning_back",
				reply = {
					"interview3.a2.answer2.reply0"
				},
				effect = function ()
					stats.increment_press(-5)
				end
			},
			{
				text = "interview3.a2.answer3.text",
				next = "a3",
				animation = "leaning_back"
			}
		}
	},
	a3 = {
		idle_animation = "asking",
		animation = "asking",
		text = {
			"interview3.a3.text0"
		},
		answers = {
			{
				text = "interview3.a3.answer1.text",
				next = "a4",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("jen", 5)
				end
			},
			{
				text = "interview3.a3.answer2.text",
				next = "a4",
				animation = "writing_phone"
			},
			{
				text = "interview3.a3.answer3.text",
				next = "a4",
				animation = "writing_phone",
				reply = {
					"interview3.a3.answer3.reply0"
				},
				effect = function ()
					agents.increment_approval("jen", 5)
				end
			}
		}
	},
	a4 = {
		idle_animation = "pointing",
		animation = "pointing",
		text = {
			"interview3.a4.text0"
		},
		answers = {
			{
				text = "interview3.a4.answer1.text",
				next = "a5",
				animation = "writing_phone",
				reply = {
					"interview3.a4.answer1.reply0"
				}
			},
			{
				text = "interview3.a4.answer2.text",
				next = "a5",
				animation = "leaning_back",
				effect = function ()
					agents.increment_approval("mordecai", 5)
				end
			},
			{
				text = "interview3.a4.answer3.text",
				next = "a5",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("mordecai", 5)
				end
			}
		}
	},
	a5 = {
		idle_animation = "leaning_back",
		animation = "surprised",
		text = {
			"interview3.a5.text0"
		},
		answers = {
			{
				text = "interview3.a5.answer1.text",
				next = "a6_nav",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("tab", 5)
				end
			},
			{
				text = "interview3.a5.answer2.text",
				next = "a6_nav",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("tab", 5)
				end
			},
			{
				text = "interview3.a5.answer3.text",
				next = "a6_nav",
				animation = "leaning_back",
				reply = {
					"interview3.a5.answer3.reply0"
				}
			}
		}
	},
	a6 = {
		idle_animation = "pointing",
		animation = "worried",
		text = {
			"interview3.a6.text0"
		},
		answers = {
			{
				text = "interview3.a6.answer1.text",
				next = "a7",
				animation = "writing_phone",
				reply = {
					"interview3.a6.answer1.reply0"
				},
				effect = function ()
					agents.increment_approval("joseph", 5)
				end
			},
			{
				text = "interview3.a6.answer2.text",
				next = "a7",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("joseph", 5)
				end
			},
			{
				text = "interview3.a6.answer3.text",
				next = "a7",
				animation = "surprised",
				reply = {
					"interview3.a6.answer3.reply0"
				},
				effect = function ()
					stats.increment_press(-5)
				end
			}
		}
	},
	a7 = {
		idle_animation = "leaning_back",
		animation = "leaning_back",
		text = {
			"interview3.a7.text0"
		},
		answers = {
			{
				text = "interview3.a7.answer1.text",
				next = "a8",
				animation = "writing_phone"
			},
			{
				text = "interview3.a7.answer2.text",
				next = "a8",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("tab", 5)
					agents.increment_approval("jen", -5)
				end
			},
			{
				text = "interview3.a7.answer3.text",
				next = "a8",
				animation = "worried",
				reply = {
					"interview3.a7.answer3.reply0"
				},
				effect = function ()
					agents.increment_approval("tab", -5)
					agents.increment_approval("jen", 5)
				end
			}
		}
	},
	a8 = {
		idle_animation = "asking",
		animation = "asking",
		text = {
			"interview3.a8.text0"
		},
		answers = {
			{
				text = "interview3.a8.answer1.text",
				next = "a9",
				animation = "writing_phone",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_popularity(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview3.a8.answer2.text",
				next = "a9",
				animation = "worried",
				effect = function ()
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview3.a8.answer3.text",
				next = "a9",
				animation = "surprised",
				effect = function ()
					stats.increment_press(-5)
				end
			}
		}
	},
	a9 = {
		idle_animation = "leaning_back",
		animation = "writing_phone",
		text = {
			"interview3.a9.text0"
		},
		answers = {
			{
				text = "interview3.a9.answer1.text",
				next = "a10",
				animation = "writing_phone",
				reply = {
					"interview3.a9.answer1.reply0"
				},
				effect = function ()
					stats.increment_evolution(1)
				end
			},
			{
				text = "interview3.a9.answer2.text",
				next = "a10",
				animation = "writing_phone",
				effect = function ()
					stats.increment_freedom(1)
				end
			},
			{
				text = "interview3.a9.answer3.text",
				next = "a10",
				animation = "writing_phone",
				effect = function ()
					stats.increment_equity(1)
				end
			}
		}
	},
	a10 = {
		idle_animation = "pointing",
		animation = "asking",
		text = {
			"interview3.a10.text0"
		},
		answers = {
			{
				text = "interview3.a10.answer1.text",
				next = "a11",
				animation = "leaning_back",
				effect = function ()
					agents.increment_approval("jen", 5)
					agents.increment_approval("mordecai", -5)
				end
			},
			{
				text = "interview3.a10.answer2.text",
				next = "a11",
				animation = "surprised",
				reply = {
					"interview3.a10.answer2.reply0"
				},
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(-5)
					stats.increment_popularity(5)
					agents.increment_approval("joseph", 5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview3.a10.answer3.text",
				next = "a11",
				animation = "surprised",
				effect = function ()
					agents.increment_approval("tab", 5)
					stats.increment_authorities(5)
					stats.increment_lawful(1)
				end
			}
		}
	},
	a11 = {
		idle_animation = "leaning_back",
		animation = "worried",
		text = {
			"interview3.a11.text0"
		},
		answers = {
			{
				text = "interview3.a11.answer1.text",
				next = "a12",
				animation = "worried",
				reply = {
					"interview3.a11.answer1.reply0"
				},
				effect = function ()
					stats.increment_justice(1)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview3.a11.answer2.text",
				next = "a12",
				animation = "writing_phone",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(5)
					stats.increment_freedom(2)
					stats.increment_equity(2)
					stats.increment_evolution(2)
				end
			},
			{
				text = "interview3.a11.answer3.text",
				next = "a12",
				animation = "writing_phone",
				effect = function ()
					agents.increment_approval("jen", 5)
					stats.increment_freedom(1)
					stats.increment_equity(1)
					stats.increment_evolution(1)
				end
			}
		}
	},
	a12 = {
		idle_animation = "leaning_back",
		animation = "pointing",
		text = {
			"interview3.a12.text0"
		},
		answers = {
			{
				text = "interview3.a12.answer1.text",
				next = "a13",
				animation = "surprised",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview3.a12.answer2.text",
				next = "a13",
				animation = "writing_phone",
				effect = function ()
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview3.a12.answer3.text",
				next = "a13",
				animation = "worried",
				effect = function ()
					stats.increment_popularity(-5)
					stats.increment_press(5)
				end
			}
		}
	},
	a13 = {
		idle_animation = "pointing",
		animation = "leaning_back",
		text = {
			"interview3.a13.text0"
		},
		answers = {
			{
				text = "interview3.a13.answer1.text",
				animation = "writing_phone",
				reply = {
					"interview3.a13.answer1.reply0"
				}
			},
			{
				text = "interview3.a13.answer2.text",
				animation = "writing_phone",
				reply = {
					"interview3.a13.answer2.reply0"
				},
				effect = function ()
					agents.increment_approval("tab", 5)
				end
			},
			{
				text = "interview3.a13.answer3.text",
				animation = "writing_phone",
				reply = {
					"interview3.a13.answer3.reply0"
				},
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(5)
				end
			}
		}
	},
	a6_nav = function ()
		if agents.joseph.present then
			return "a6"
		end

		return "a7"
	end
}
