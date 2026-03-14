local stats = require("campaign.stats")
local agents = require("campaign.agents")
local perks = require("campaign.perks")
local variables = require("campaign.variables")
local missions = require("campaign.missions")

return {
	a1 = {
		idle_animation = "default",
		animation = "asking",
		text = {
			"interview2.a1.text0"
		},
		answers = {
			{
				text = "interview2.a1.answer1.text",
				next = "a2",
				animation = "thinking",
				reply = {
					"interview2.a1.answer1.reply0"
				},
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a1.answer2.text",
				next = "a2",
				animation = "surprised",
				effect = function ()
					stats.increment_press(5)
					stats.increment_authorities(-5)
				end
			},
			{
				text = "interview2.a1.answer3.text",
				next = "a2",
				animation = "surprised",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_lawful(1)
				end
			}
		}
	},
	a2 = {
		idle_animation = "writing",
		animation = "asking2",
		text = {
			"interview2.a2.text0"
		},
		answers = {
			{
				text = "interview2.a2.answer1.text",
				next = "a3",
				animation = "thinking",
				reply = {
					"interview2.a2.answer1.reply0"
				},
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
				end
			},
			{
				text = "interview2.a2.answer2.text",
				next = "a3",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(5)
					stats.increment_evolution(1)
					stats.increment_equity(1)
					stats.increment_freedom(1)
				end
			},
			{
				text = "interview2.a2.answer3.text",
				next = "a3",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_popularity(-5)
					stats.increment_lawful(1)
					stats.increment_justice(1)
				end
			}
		}
	},
	a3 = {
		idle_animation = "default",
		animation = "asking",
		text = {
			"interview2.a3.text0"
		},
		answers = {
			{
				text = "interview2.a3.answer1.text",
				next = "a4",
				animation = "surprised",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(5)
				end
			},
			{
				text = "interview2.a3.answer2.text",
				next = "a4",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(5)
				end
			},
			{
				text = "interview2.a3.answer3.text",
				next = "a4",
				animation = "thinking",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_press(-5)
					stats.increment_popularity(-5)
				end
			}
		}
	},
	a4 = {
		idle_animation = "writing",
		animation = "asking2",
		text = {
			"interview2.a4.text0"
		},
		answers = {
			{
				text = "interview2.a4.answer1.text",
				next = "a5",
				animation = "thinking",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a4.answer2.text",
				next = "a5",
				animation = "writing",
				effect = function ()
					stats.increment_press(5)
					stats.increment_freedom(1)
				end
			},
			{
				text = "interview2.a4.answer3.text",
				next = "a5",
				animation = "writing",
				effect = function ()
					stats.increment_evolution(1)
					stats.increment_equity(1)
				end
			}
		}
	},
	a5 = {
		idle_animation = "default",
		animation = "asking",
		text = {
			"interview2.a5.text0"
		},
		answers = {
			{
				text = "interview2.a5.answer1.text",
				next = "a6",
				animation = "writing",
				reply = {
					"interview2.a5.answer1.reply0"
				},
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a5.answer2.text",
				next = "a6",
				animation = "thinking",
				effect = function ()
					stats.increment_press(5)
				end
			},
			{
				text = "interview2.a5.answer3.text",
				next = "a6",
				animation = "thinking",
				effect = function ()
					stats.increment_authorities(5)
				end
			}
		}
	},
	a6 = {
		idle_animation = "writing",
		animation = "asking2",
		text = {
			"interview2.a6.text0"
		},
		answers = {
			{
				text = "interview2.a6.answer1.text",
				next = "a7",
				animation = "writing",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview2.a6.answer2.text",
				next = "a7",
				animation = "surprised",
				reply = {
					"interview2.a6.answer2.reply0"
				},
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a6.answer3.text",
				next = "a7",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_popularity(-5)
					stats.increment_press(5)
					stats.increment_evolution(1)
					stats.increment_freedom(1)
					stats.increment_equity(1)
				end
			}
		}
	},
	a7 = {
		idle_animation = "default",
		animation = "asking",
		text = {
			"interview2.a7.text0"
		},
		answers = {
			{
				text = "interview2.a7.answer1.text",
				next = "a8",
				animation = "surprised",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview2.a7.answer2.text",
				next = "a8",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_press(-5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview2.a7.answer3.text",
				next = "a8",
				animation = "writing",
				effect = function ()
					stats.increment_press(5)
					stats.increment_authorities(-5)
					stats.increment_evolution(1)
					stats.increment_freedom(1)
					stats.increment_equity(1)
				end
			}
		}
	},
	a8 = {
		idle_animation = "writing",
		animation = "asking2",
		text = {
			"interview2.a8.text0"
		},
		answers = {
			{
				text = "interview2.a8.answer1.text",
				next = "a9",
				animation = "thinking",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview2.a8.answer2.text",
				next = "a9",
				animation = "writing",
				reply = {
					"interview2.a8.answer2.reply0"
				},
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a8.answer3.text",
				next = "a9",
				animation = "writing",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
					stats.increment_evolution(-1)
					stats.increment_freedom(-1)
					stats.increment_equity(-1)
				end
			}
		}
	},
	a9 = {
		idle_animation = "writing",
		animation = "asking",
		text = {
			"interview2.a9.text0"
		},
		answers = {
			{
				text = "interview2.a9.answer1.text",
				next = "a10",
				animation = "thinking",
				reply = {
					"interview2.a9.answer1.reply0"
				},
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_press(-5)
				end
			},
			{
				text = "interview2.a9.answer2.text",
				next = "a10",
				animation = "thinking",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview2.a9.answer3.text",
				next = "a10",
				animation = "thinking",
				reply = {
					"interview2.a9.answer3.reply0"
				},
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
				end
			}
		}
	},
	a10 = {
		idle_animation = "default",
		animation = "asking2",
		text = {
			"interview2.a10.text0"
		},
		answers = {
			{
				text = "interview2.a10.answer1.text",
				next = "a11",
				animation = "surprised",
				effect = function ()
					stats.increment_press(5)
					stats.increment_authorities(-5)
					stats.increment_popularity(-5)
				end
			},
			{
				text = "interview2.a10.answer2.text",
				next = "a11",
				animation = "writing",
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_popularity(5)
				end
			},
			{
				text = "interview2.a10.answer3.text",
				next = "a11",
				animation = "thinking",
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_press(-5)
				end
			}
		}
	},
	a11 = {
		idle_animation = "writing",
		animation = "asking",
		text = {
			"interview2.a11.text0"
		},
		answers = {
			{
				text = "interview2.a11.answer1.text",
				next = "a12",
				animation = "thinking",
				effect = function ()
					stats.increment_authorities(-5)
					stats.increment_press(-5)
					stats.increment_popularity(5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a11.answer2.text",
				next = "a12",
				animation = "thinking",
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
					stats.increment_lawful(1)
				end
			},
			{
				text = "interview2.a11.answer3.text",
				next = "a12",
				animation = "thinking",
				reply = {
					"interview2.a11.answer3.reply0"
				},
				effect = function ()
					stats.increment_authorities(5)
					stats.increment_press(-5)
					stats.increment_lawful(1)
				end
			}
		}
	},
	a12 = {
		idle_animation = "default",
		animation = "asking2",
		text = {
			"interview2.a12.text0"
		},
		answers = {
			{
				text = "interview2.a12.answer1.text",
				animation = "default",
				reply = {
					"interview2.a12.answer1.reply0"
				},
				effect = function ()
					stats.increment_press(5)
					stats.increment_popularity(-5)
					stats.increment_justice(1)
				end
			},
			{
				text = "interview2.a12.answer2.text",
				animation = "default",
				reply = {
					"interview2.a12.answer2.reply0"
				},
				effect = function ()
					stats.increment_popularity(5)
					stats.increment_authorities(-5)
					stats.increment_freedom(1)
					stats.increment_equity(1)
				end
			},
			{
				text = "interview2.a12.answer3.text",
				animation = "default",
				reply = {
					"interview2.a12.answer3.reply0"
				},
				effect = function ()
					stats.increment_evolution(1)
					stats.increment_freedom(1)
					stats.increment_equity(1)
				end
			}
		}
	}
}
