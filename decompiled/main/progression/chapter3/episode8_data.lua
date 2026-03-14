local stats = require("campaign.stats")
local agents = require("campaign.agents")
local perks = require("campaign.perks")
local variables = require("campaign.variables")
local missions = require("campaign.missions")

return {
	["1a"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1a.text0"
		},
		emote = {
			"episode8.1a.emote0"
		},
		answers = {
			{
				text = "episode8.1a.answer1.text",
				next = "1b",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1a.answer1.reply0"
				},
				reply_emote = {
					"episode8.1a.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.1a.answer2.text",
				next = "1b",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1a.answer2.reply0"
				},
				reply_emote = {
					"episode8.1a.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_justice(1)
				end
			},
			{
				text = "episode8.1a.answer3.text",
				next = "1c",
				animation = "idle1_nod",
				reply = {
					"episode8.1a.answer3.reply0"
				},
				reply_emote = {
					"episode8.1a.answer3.emote0"
				},
				effect = function ()
					stats.increment_lawful(1)
				end
			}
		}
	},
	["1b"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1b.text0"
		},
		answers = {
			{
				text = "episode8.1b.answer1.text",
				next = "1c",
				reply = {
					"episode8.1b.answer1.reply0"
				},
				reply_emote = {
					"episode8.1b.answer1.emote0"
				},
				effect = function ()
					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.1b.answer2.text",
				next = "1c",
				reply = {
					"episode8.1b.answer2.reply0"
				},
				reply_emote = {
					"episode8.1b.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.anger = (state.anger or 0) + 1

					stats.increment_justice(1)
				end
			},
			{
				text = "episode8.1b.answer3.text",
				next = "1c",
				animation = "idle1_glasses",
				reply = {
					"episode8.1b.answer3.reply0"
				},
				reply_emote = {
					"episode8.1b.answer3.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.tab_1 = true
				end
			}
		}
	},
	["1c"] = {
		idle_animation = "idle1",
		animation = "idle1_glasses",
		text = {
			"episode8.1c.text0"
		},
		emote = {
			"episode8.1c.emote0"
		},
		answers = {
			{
				text = "episode8.1c.answer1.text",
				next = "1d",
				animation = "idle1_nod",
				reply = {
					"episode8.1c.answer1.reply0"
				},
				reply_emote = {
					"episode8.1c.answer1.emote0"
				},
				effect = function (state)
					state.tab_1 = true
				end
			},
			{
				text = "episode8.1c.answer2.text",
				next = "1e_special",
				animation = "idle1_nod",
				reply = {
					"episode8.1c.answer2.reply0"
				},
				reply_emote = {
					"episode8.1c.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.1c.answer3.text",
				next = "1d",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1c.answer3.reply0"
				},
				reply_emote = {
					"episode8.1c.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["1d"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1d.text0"
		},
		answers = {
			{
				text = "episode8.1d.answer1.text",
				next = "1e",
				animation = "idle1_nod",
				reply = {
					"episode8.1d.answer1.reply0"
				},
				reply_emote = {
					"episode8.1d.answer1.emote0"
				}
			},
			{
				text = "episode8.1d.answer2.text",
				next = "1e",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1d.answer2.reply0"
				},
				reply_emote = {
					"episode8.1d.answer2.emote0"
				}
			},
			{
				text = "episode8.1d.answer3.text",
				next = "1e",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1d.answer3.reply0"
				},
				reply_emote = {
					"episode8.1d.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["1d_special"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1d_special.text0"
		},
		answers = {
			{
				text = "episode8.1d_special.answer1.text",
				next = "1f",
				animation = "idle1_nod",
				reply = {
					"episode8.1d_special.answer1.reply0"
				},
				reply_emote = {
					"episode8.1d_special.answer1.emote0"
				}
			},
			{
				text = "episode8.1d_special.answer2.text",
				next = "1f",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1d_special.answer2.reply0"
				},
				reply_emote = {
					"episode8.1d_special.answer2.emote0"
				}
			},
			{
				text = "episode8.1d_special.answer3.text",
				next = "1f",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1d_special.answer3.reply0"
				},
				reply_emote = {
					"episode8.1d_special.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["1e"] = {
		idle_animation = "idle1",
		animation = "idle1_glasses",
		text = {
			"episode8.1e.text0"
		},
		answers = {
			{
				text = "episode8.1e.answer1.text",
				next = "1f",
				reply = {
					"episode8.1e.answer1.reply0"
				},
				reply_emote = {
					"episode8.1e.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_freedom(1)
					stats.increment_evolution(1)
				end
			},
			{
				text = "episode8.1e.answer2.text",
				next = "1f",
				reply_emote = {
					"episode8.1e.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1e.answer3.text",
				next = "1f",
				reply = {
					"episode8.1e.answer3.reply0"
				},
				effect = function (state)
					state.weiss_1 = true

					stats.increment_lawful(1)
				end
			}
		}
	},
	["1e_special"] = {
		idle_animation = "idle1",
		animation = "idle1_glasses",
		text = {
			"episode8.1e_special.text0"
		},
		answers = {
			{
				text = "episode8.1e_special.answer1.text",
				next = "1d_special",
				reply = {
					"episode8.1e_special.answer1.reply0"
				},
				reply_emote = {
					"episode8.1e_special.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_freedom(1)
					stats.increment_evolution(1)
				end
			},
			{
				text = "episode8.1e_special.answer2.text",
				next = "1d_special",
				reply_emote = {
					"episode8.1e_special.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1e_special.answer3.text",
				next = "1d_special",
				reply = {
					"episode8.1e_special.answer3.reply0"
				},
				effect = function (state)
					state.weiss_1 = true

					stats.increment_lawful(1)
				end
			}
		}
	},
	["1f"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1f.text0"
		},
		answers = {
			{
				text = "episode8.1f.answer1.text",
				next = "nav_1g",
				animation = "idle1_nod",
				reply = {
					"episode8.1f.answer1.reply0"
				},
				reply_emote = {
					"episode8.1f.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.suspicion = (state.suspicion or 0) + 1
					state.lf_close = true
					state.check1 = true
				end
			},
			{
				text = "episode8.1f.answer2.text",
				next = "nav_1g",
				reply = {
					"episode8.1f.answer2.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.check1 = true
				end
			},
			{
				text = "episode8.1f.answer3.text",
				next = "nav_1g",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1f.answer3.reply0"
				},
				reply_emote = {
					"episode8.1f.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 2
					state.check1 = true
				end
			}
		}
	},
	["1g"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1g.text0"
		},
		answers = {
			{
				text = "episode8.1g.answer1.text",
				next = "nav_1p",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1g.answer1.reply0"
				},
				reply_emote = {
					"episode8.1g.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.1g.answer2.text",
				next = "nav_1p",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1g.answer2.reply0"
				},
				reply_emote = {
					"episode8.1g.answer2.emote0"
				}
			},
			{
				text = "episode8.1g.answer3.text",
				next = "nav_1p",
				reply_emote = {
					"episode8.1g.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["1g2"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1g2.text0"
		},
		answers = {
			{
				text = "episode8.1g2.answer1.text",
				next = "nav_1p",
				reply = {
					"episode8.1g2.answer1.reply0"
				},
				reply_emote = {
					"episode8.1g2.answer1.emote0"
				},
				effect = function (state)
					state.incompetence1 = true
				end
			},
			{
				text = "episode8.1g2.answer2.text",
				next = "nav_1p",
				reply = {
					"episode8.1g2.answer2.reply0"
				},
				reply_emote = {
					"episode8.1g2.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1g2.answer3.text",
				next = "nav_1p",
				animation = "idle1_glasses",
				reply = {
					"episode8.1g2.answer3.reply0"
				},
				reply_emote = {
					"episode8.1g2.answer3.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["1p"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1p.text0"
		},
		answers = {
			{
				text = "episode8.1p.answer1.text",
				next = "nav_1h",
				reply = {
					"episode8.1p.answer1.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_equity(1)
					stats.increment_freedom(1)
					stats.increment_evolution(1)
				end
			},
			{
				text = "episode8.1p.answer2.text",
				next = "nav_1h",
				reply = {
					"episode8.1p.answer2.reply0"
				},
				reply_emote = {
					"episode8.1p.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1p.answer3.text",
				animation = "idle1_nod",
				next = "nav_1h",
				reply_emote = {
					"episode8.1p.answer3.emote0"
				}
			}
		}
	},
	["1h"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1h.text0"
		},
		answers = {
			{
				text = "episode8.1h.answer1.text",
				next = "nav_1i",
				animation = "idle1_raise_eyebrow",
				reply = {
					"episode8.1h.answer1.reply0"
				},
				reply_emote = {
					"episode8.1h.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.1h.answer2.text",
				next = "nav_1i",
				reply = {
					"episode8.1h.answer2.reply0"
				}
			},
			{
				text = "episode8.1h.answer3.text",
				next = "nav_1i",
				animation = "idle1_glasses",
				reply = {
					"episode8.1h.answer3.reply0"
				},
				reply_emote = {
					"episode8.1h.answer3.emote0"
				},
				effect = function (state)
					if variables.tight_paperwork then
						state.anger = (state.anger or 0) + 1
					else
						state.anger = (state.anger or 0) + 1
						state.suspicion = (state.suspicion or 0) + 1
					end
				end
			}
		}
	},
	["1h2"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1h2.text0"
		},
		answers = {
			{
				text = "episode8.1h2.answer1.text",
				next = "nav_1i",
				reply = {
					"episode8.1h2.answer1.reply0"
				},
				reply_emote = {
					"episode8.1h2.answer1.emote0"
				},
				effect = function (state)
					state.incompetence1 = true
				end
			},
			{
				text = "episode8.1h2.answer2.text",
				next = "nav_1i",
				reply = {
					"episode8.1h2.answer2.reply0"
				},
				reply_emote = {
					"episode8.1h2.answer2.emote0"
				},
				effect = function (state)
					state.incompetence1 = true
				end
			},
			{
				text = "episode8.1h2.answer3.text",
				next = "nav_1i",
				reply = {
					"episode8.1h2.answer3.reply0"
				},
				reply_emote = {
					"episode8.1h2.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["1i"] = {
		idle_animation = "idle1",
		text = {
			"episode8.1i.text0"
		},
		answers = {
			{
				text = "episode8.1i.answer1.text",
				next = "nav_1j",
				animation = "idle1_glasses",
				reply = {
					"episode8.1i.answer1.reply0"
				},
				reply_emote = {
					"episode8.1i.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.1i.answer2.text",
				next = "nav_1j",
				animation = "idle1_glasses",
				reply = {
					"episode8.1i.answer2.reply0"
				},
				reply_emote = {
					"episode8.1i.answer2.emote0"
				}
			},
			{
				text = "episode8.1i.answer3.text",
				next = "nav_1j",
				reply = {
					"episode8.1i.answer3.reply0"
				},
				reply_emote = {
					"episode8.1i.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["1ji"] = {
		idle_animation = "idle2",
		animation = "idle1_to_idle2",
		text = {
			"episode8.1ji.text0"
		},
		emote = {
			"episode8.1ji.emote0"
		},
		answers = {
			{
				text = "episode8.1ji.answer1.text",
				next = "2a",
				reply_emote = {
					"episode8.1ji.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1ji.answer2.text",
				next = "2a",
				reply = {
					"episode8.1ji.answer2.reply0"
				},
				reply_emote = {
					"episode8.1ji.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1ji.answer3.text",
				next = "2a",
				animation = "idle2_headshake",
				reply = {
					"episode8.1ji.answer3.reply0"
				},
				reply_emote = {
					"episode8.1ji.answer3.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["1j"] = {
		idle_animation = "idle2",
		animation = "idle1_to_idle2",
		text = {
			"episode8.1j.text0"
		},
		emote = {
			"episode8.1j.emote0"
		},
		answers = {
			{
				text = "episode8.1j.answer1.text",
				next = "2a",
				reply_emote = {
					"episode8.1j.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.1j.answer2.text",
				next = "2a",
				animation = "idle2_nod"
			},
			{
				text = "episode8.1j.answer3.text",
				next = "2a",
				animation = "idle2_nod",
				reply = {
					"episode8.1j.answer3.reply0"
				},
				reply_emote = {
					"episode8.1j.answer3.emote0"
				}
			}
		}
	},
	["2a"] = {
		idle_animation = "idle2",
		animation = "idle2_explain",
		text = {
			"episode8.2a.text0"
		},
		answers = {
			{
				text = "episode8.2a.answer1.text",
				next = "nav_2p",
				reply = {
					"episode8.2a.answer1.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.2a.answer2.text",
				animation = "idle2_nod",
				next = "nav_2p",
				reply_emote = {
					"episode8.2a.answer2.emote0"
				}
			},
			{
				text = "episode8.2a.answer3.text",
				next = "nav_2p",
				animation = "idle2_headshake",
				reply = {
					"episode8.2a.answer3.reply0"
				},
				reply_emote = {
					"episode8.2a.answer3.emote0"
				},
				effect = function (state)
					state.incompetence2 = true
				end
			}
		}
	},
	["2p"] = {
		idle_animation = "idle2",
		text = {
			"episode8.2p.text0"
		},
		answers = {
			{
				text = "episode8.2p.answer1.text",
				next = "nav_3p",
				reply = {
					"episode8.2p.answer1.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.2p.answer2.text",
				next = "nav_3p",
				animation = "idle2_headshake",
				reply_emote = {
					"episode8.2p.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2p.answer3.text",
				next = "nav_3p",
				reply = {
					"episode8.2p.answer3.reply0"
				}
			}
		}
	},
	["3p"] = {
		idle_animation = "idle2",
		text = {
			"episode8.3p.text0"
		},
		answers = {
			{
				text = "episode8.3p.answer1.text",
				next = "nav_2b",
				reply = {
					"episode8.3p.answer1.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_equity(1)
					stats.increment_freedom(1)
					stats.increment_evolution(1)
				end
			},
			{
				text = "episode8.3p.answer2.text",
				next = "nav_2b",
				animation = "idle2_headshake",
				reply_emote = {
					"episode8.3p.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.3p.answer3.text",
				next = "nav_2b",
				reply = {
					"episode8.3p.answer3.reply0"
				},
				effect = function ()
					stats.increment_lawful(1)
				end
			}
		}
	},
	["2b"] = {
		idle_animation = "idle2",
		animation = "idle2_explain",
		text = {
			"episode8.2b.text0"
		},
		answers = {
			{
				text = "episode8.2b.answer1.text",
				next = "2c",
				animation = "idle2_headshake",
				reply_emote = {
					"episode8.2b.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2b.answer2.text",
				next = "2c",
				animation = "idle2_headshake",
				reply = {
					"episode8.2b.answer2.reply0"
				},
				reply_emote = {
					"episode8.2b.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.2b.answer3.text",
				next = "2c",
				reply_emote = {
					"episode8.2b.answer3.emote0"
				},
				effect = function (state)
					state.guilt1 = true
				end
			}
		}
	},
	["2c"] = {
		idle_animation = "idle2",
		text = {
			"episode8.2c.text0"
		},
		answers = {
			{
				text = "episode8.2c.answer1.text",
				next = "2d",
				animation = "idle2_headshake",
				reply_emote = {
					"episode8.2c.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2c.answer2.text",
				next = "2d",
				reply = {
					"episode8.2c.answer2.reply0"
				},
				effect = function (state)
					state.guilt2 = true
				end
			},
			{
				text = "episode8.2c.answer3.text",
				next = "2d",
				animation = "idle2_headshake",
				reply = {
					"episode8.2c.answer3.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["2d"] = {
		idle_animation = "idle2",
		text = {
			"episode8.2d.text0"
		},
		emote = {
			"episode8.2d.emote0"
		},
		answers = {
			{
				text = "episode8.2d.answer1.text",
				next = "nav_2da",
				animation = "idle2_headshake",
				reply = {
					"episode8.2d.answer1.reply0"
				},
				effect = function (state)
					state.guilt2 = true
				end
			},
			{
				text = "episode8.2d.answer2.text",
				next = "nav_2da",
				reply = {
					"episode8.2d.answer2.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2d.answer3.text",
				next = "nav_2da",
				reply = {
					"episode8.2d.answer3.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["2da"] = {
		idle_animation = "idle2",
		animation = "idle2_explain",
		text = {
			"episode8.2da.text0"
		},
		answers = {
			{
				text = "episode8.2da.answer1.text",
				next = "nav_2db",
				animation = "idle2_headshake",
				reply = {
					"episode8.2da.answer1.reply0"
				},
				reply_emote = {
					"episode8.2da.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2da.answer2.text",
				next = "nav_2db",
				reply = {
					"episode8.2da.answer2.reply0"
				},
				effect = function (state)
					state.guilt2 = true
				end
			},
			{
				text = "episode8.2da.answer3.text",
				next = "nav_2db",
				reply = {
					"episode8.2da.answer3.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["2db"] = {
		idle_animation = "idle2",
		animation = "idle2_headshake",
		text = {
			"episode8.2db.text0"
		},
		answers = {
			{
				text = "episode8.2db.answer1.text",
				next = "nav_2e",
				reply = {
					"episode8.2db.answer1.reply0"
				},
				reply_emote = {
					"episode8.2db.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2db.answer2.text",
				next = "nav_2e",
				reply = {
					"episode8.2db.answer2.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.2db.answer3.text",
				next = "nav_2e",
				animation = "idle2_headshake",
				reply = {
					"episode8.2db.answer3.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["2e"] = {
		idle_animation = "idle2",
		animation = "idle2_explain",
		text = {
			"episode8.2e.text0"
		},
		emote = {
			"episode8.2e.emote0"
		},
		answers = {
			{
				text = "episode8.2e.answer1.text",
				next = "2f",
				reply_emote = {
					"episode8.2e.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2e.answer2.text",
				next = "2f",
				reply = {
					"episode8.2e.answer2.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.2e.answer3.text",
				next = "2f",
				animation = "idle2_nod",
				reply = {
					"episode8.2e.answer3.reply0"
				},
				reply_emote = {
					"episode8.2e.answer3.emote0"
				}
			}
		}
	},
	["2f"] = {
		idle_animation = "idle2",
		text = {
			"episode8.2f.text0"
		},
		answers = {
			{
				text = "episode8.2f.answer1.text",
				next = "2g",
				reply = {
					"episode8.2f.answer1.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.2f.answer2.text",
				animation = "idle2_nod",
				next = "2g",
				reply_emote = {
					"episode8.2f.answer2.emote0"
				}
			},
			{
				text = "episode8.2f.answer3.text",
				next = "2g",
				reply = {
					"episode8.2f.answer3.reply0"
				},
				reply_emote = {
					"episode8.2f.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["2g"] = {
		idle_animation = "idle2",
		animation = "idle2_explain",
		text = {
			"episode8.2g.text0"
		},
		emote = {
			"episode8.2g.emote0"
		},
		answers = {
			{
				text = "episode8.2g.answer1.text",
				next = "2h",
				reply = {
					"episode8.2g.answer1.reply0"
				},
				reply_emote = {
					"episode8.2g.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_justice(1)
				end
			},
			{
				text = "episode8.2g.answer2.text",
				next = "2h",
				reply = {
					"episode8.2g.answer2.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_lawful(1)
					stats.increment_equity(1)
				end
			},
			{
				text = "episode8.2g.answer3.text",
				next = "2h",
				animation = "idle2_nod",
				reply = {
					"episode8.2g.answer3.reply0"
				},
				reply_emote = {
					"episode8.2g.answer3.emote0"
				},
				effect = function ()
					stats.increment_lawful(1)
				end
			}
		}
	},
	["2h"] = {
		idle_animation = "idle3",
		animation = "idle2_to_idle3",
		text = {
			"episode8.2h.text0"
		},
		emote = {
			"episode8.2h.emote0"
		},
		answers = {
			{
				text = "episode8.2h.answer1.text",
				next = "3a",
				reply = {
					"episode8.2h.answer1.reply0"
				},
				effect = function (state)
					if state.anger > 3 then
						state.anger = (state.anger or 0) + 1
					end
				end
			},
			{
				text = "episode8.2h.answer2.text",
				next = "3a",
				animation = "idle3_headshake",
				reply = {
					"episode8.2h.answer2.reply0"
				},
				reply_emote = {
					"episode8.2h.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.2h.answer3.text",
				next = "3a",
				reply = {
					"episode8.2h.answer3.reply0"
				},
				reply_emote = {
					"episode8.2h.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["3a"] = {
		idle_animation = "idle3",
		text = {
			"episode8.3a.text0"
		},
		answers = {
			{
				text = "episode8.3a.answer1.text",
				next = "nav_4p",
				animation = "idle3_glasses",
				reply_emote = {
					"episode8.3a.answer1.emote0"
				},
				effect = function (state)
					state.guilt2 = true
				end
			},
			{
				text = "episode8.3a.answer2.text",
				next = "nav_4p",
				animation = "idle3_glasses",
				reply = {
					"episode8.3a.answer2.reply0"
				},
				reply_emote = {
					"episode8.3a.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_equity(1)
					stats.increment_evolution(1)
					stats.increment_freedom(1)
				end
			},
			{
				text = "episode8.3a.answer3.text",
				next = "nav_4p",
				reply = {
					"episode8.3a.answer3.reply0"
				},
				reply_emote = {
					"episode8.3a.answer3.emote0"
				}
			}
		}
	},
	["4p"] = {
		idle_animation = "idle3",
		text = {
			"episode8.4p.text0"
		},
		answers = {
			{
				text = "episode8.4p.answer1.text",
				next = "nav_5p",
				reply = {
					"episode8.4p.answer1.reply0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.4p.answer2.text",
				next = "nav_5p",
				animation = "idle3_glasses",
				reply = {
					"episode8.4p.answer2.reply0"
				},
				reply_emote = {
					"episode8.4p.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_justice(1)
				end
			},
			{
				text = "episode8.4p.answer3.text",
				next = "nav_5p",
				reply = {
					"episode8.4p.answer3.reply0"
				},
				reply_emote = {
					"episode8.4p.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_lawful(1)
				end
			}
		}
	},
	["5p"] = {
		idle_animation = "idle3",
		text = {
			"episode8.5p.text0"
		},
		answers = {
			{
				text = "episode8.5p.answer1.text",
				next = "nav_3b",
				reply = {
					"episode8.5p.answer1.reply0"
				},
				reply_emote = {
					"episode8.5p.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.5p.answer2.text",
				next = "nav_3b",
				animation = "idle3_glasses",
				reply = {
					"episode8.5p.answer2.reply0"
				},
				reply_emote = {
					"episode8.5p.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.guilt2 = true
				end
			},
			{
				text = "episode8.5p.answer3.text",
				next = "nav_3b",
				animation = "idle3_headshake",
				reply = {
					"episode8.5p.answer3.reply0"
				},
				reply_emote = {
					"episode8.5p.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["3b"] = {
		idle_animation = "idle3",
		animation = "idle3_grab",
		text = {
			"episode8.3b.text0"
		},
		emote = {
			"episode8.3b.emote0"
		},
		answers = {
			{
				text = "episode8.3b.answer1.text",
				next = "3c",
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.health = (state.health or 0) + -1

					stats.increment_freedom(1)
					stats.increment_equity(1)
					stats.increment_evolution(1)
				end
			},
			{
				text = "episode8.3b.answer2.text",
				next = "3c",
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.health = (state.health or 0) + -1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.3b.answer3.text",
				next = "3c",
				animation = "idle3_headshake",
				reply = {
					"episode8.3b.answer3.reply0"
				},
				reply_emote = {
					"episode8.3b.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 2
					state.suspicion = (state.suspicion or 0) + 1
					state.health = (state.health or 0) + -1

					stats.increment_lawful(1)
				end
			}
		}
	},
	["3c"] = {
		idle_animation = "idle3",
		text = {
			"episode8.3c.text0"
		},
		answers = {
			{
				text = "episode8.3c.answer1.text",
				next = "3d",
				reply_emote = {
					"episode8.3c.answer1.emote0"
				}
			},
			{
				text = "episode8.3c.answer2.text",
				next = "3d",
				animation = "idle3_glasses",
				reply_emote = {
					"episode8.3c.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.3c.answer3.text",
				next = "3d",
				reply_emote = {
					"episode8.3c.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["3d"] = {
		idle_animation = "idle3",
		text = {
			"episode8.3d.text0"
		},
		answers = {
			{
				text = "episode8.3d.answer1.text",
				next = "nav_3e",
				animation = "idle3_headshake",
				reply = {
					"episode8.3d.answer1.reply0"
				}
			},
			{
				text = "episode8.3d.answer2.text",
				next = "nav_3e",
				animation = "idle3_headshake",
				reply_emote = {
					"episode8.3d.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.3d.answer3.text",
				next = "nav_3e",
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["3e"] = {
		idle_animation = "idle3",
		animation = "idle3_grab",
		text = {
			"episode8.3e.text0"
		},
		emote = {
			"episode8.3e.emote0"
		},
		answers = {
			{
				text = "episode8.3e.answer1.text",
				next = "3f",
				reply = {
					"episode8.3e.answer1.reply0"
				},
				reply_emote = {
					"episode8.3e.answer1.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.health = (state.health or 0) + -1
				end
			},
			{
				text = "episode8.3e.answer2.text",
				next = "3f",
				animation = "idle3_glasses",
				reply_emote = {
					"episode8.3e.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.health = (state.health or 0) + -1
				end
			},
			{
				text = "episode8.3e.answer3.text",
				next = "3f",
				reply = {
					"episode8.3e.answer3.reply0"
				},
				reply_emote = {
					"episode8.3e.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.health = (state.health or 0) + -1
				end
			}
		}
	},
	["3f"] = {
		idle_animation = "idle3",
		text = {
			"episode8.3f.text0"
		},
		answers = {
			{
				text = "episode8.3f.answer1.text",
				next = "nav_3g",
				animation = "idle3_headshake",
				reply = {
					"episode8.3f.answer1.reply0"
				},
				reply_emote = {
					"episode8.3f.answer1.emote0"
				},
				effect = function (state)
					state.guilt1 = true
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_evolution(1)
					stats.increment_freedom(1)
					stats.increment_equity(1)
				end
			},
			{
				text = "episode8.3f.answer2.text",
				next = "nav_3g",
				reply_emote = {
					"episode8.3f.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.3f.answer3.text",
				next = "nav_3g",
				reply_emote = {
					"episode8.3f.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 2
				end
			}
		}
	},
	["3g"] = {
		idle_animation = "idle3",
		animation = "idle3_grab",
		text = {
			"episode8.3g.text0"
		},
		emote = {
			"episode8.3g.emote0"
		},
		answers = {
			{
				text = "episode8.3g.answer1.text",
				next = "nav_3h",
				reply = {
					"episode8.3g.answer1.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.health = (state.health or 0) + -1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.3g.answer2.text",
				next = "nav_3h",
				animation = "idle3_glasses",
				reply_emote = {
					"episode8.3g.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.anger = (state.anger or 0) + 1
					state.guilt1 = true
					state.health = (state.health or 0) + -1
				end
			},
			{
				text = "episode8.3g.answer3.text",
				next = "nav_3h",
				reply_emote = {
					"episode8.3g.answer3.emote0"
				},
				effect = function (state)
					state.health = (state.health or 0) + -1
				end
			}
		}
	},
	["3h"] = {
		idle_animation = "idle4",
		animation = "idle3_to_idle4",
		text = {
			"episode8.3h.text0"
		},
		emote = {
			"episode8.3h.emote0"
		},
		answers = {
			{
				text = "episode8.3h.answer1.text",
				next = "4a",
				animation = "idle4_point",
				reply = {
					"episode8.3h.answer1.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_justice(1)
				end
			},
			{
				text = "episode8.3h.answer2.text",
				next = "4a",
				reply = {
					"episode8.3h.answer2.reply0"
				},
				reply_emote = {
					"episode8.3h.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.3h.answer3.text",
				next = "4a",
				reply = {
					"episode8.3h.answer3.reply0"
				},
				effect = function (state)
					state.guilt1 = true
					state.guilt2 = true
				end
			}
		}
	},
	["3hi"] = {
		idle_animation = "idle4",
		animation = "idle3_to_idle4",
		text = {
			"episode8.3hi.text0"
		},
		emote = {
			"episode8.3hi.emote0"
		},
		answers = {
			{
				text = "episode8.3hi.answer1.text",
				next = "4a",
				animation = "idle4_point",
				reply = {
					"episode8.3hi.answer1.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.3hi.answer2.text",
				next = "4a",
				reply = {
					"episode8.3hi.answer2.reply0"
				},
				reply_emote = {
					"episode8.3hi.answer2.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.3hi.answer3.text",
				next = "4a",
				reply = {
					"episode8.3hi.answer3.reply0"
				},
				effect = function (state)
					state.guilt1 = true
					state.guilt2 = true
					state.anger = (state.anger or 0) + 1
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["4a"] = {
		idle_animation = "idle4",
		animation = "idle4_point",
		text = {
			"episode8.4a.text0"
		},
		emote = {
			"episode8.4a.emote0"
		},
		answers = {
			{
				text = "episode8.4a.answer1.text",
				next = "nav_4a2p6",
				animation = "idle4_look_away",
				reply = {
					"episode8.4a.answer1.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.4a.answer2.text",
				next = "nav_4a2p6",
				animation = "idle4_look_away",
				reply = {
					"episode8.4a.answer2.reply0"
				}
			},
			{
				text = "episode8.4a.answer3.text",
				next = "nav_4a2p6",
				animation = "idle4_look_away",
				reply = {
					"episode8.4a.answer3.reply0"
				},
				reply_emote = {
					"episode8.4a.answer3.emote0"
				},
				effect = function (state)
					state.guilt1 = true
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["4a2p6"] = {
		idle_animation = "idle4",
		animation = "idle4_look_away",
		text = {
			"episode8.4a2p6.text0"
		},
		emote = {
			"episode8.4a2p6.emote0"
		},
		answers = {
			{
				text = "episode8.4a2p6.answer1.text",
				next = "nav_4a2",
				reply = {
					"episode8.4a2p6.answer1.reply0"
				},
				reply_emote = {
					"episode8.4a2p6.answer1.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
					state.anger = (state.anger or 0) + -1

					stats.increment_evolution(1)
					stats.increment_freedom(1)
					stats.increment_equity(1)
				end
			},
			{
				text = "episode8.4a2p6.answer2.text",
				next = "nav_4a2",
				reply = {
					"episode8.4a2p6.answer2.reply0"
				},
				reply_emote = {
					"episode8.4a2p6.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1

					stats.increment_equity(2)
				end
			},
			{
				text = "episode8.4a2p6.answer3.text",
				next = "nav_4a2",
				reply_emote = {
					"episode8.4a2p6.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_lawful(1)
				end
			}
		}
	},
	["4a2p7"] = {
		idle_animation = "idle4",
		animation = "idle4_look_away",
		text = {
			"episode8.4a2p7.text0"
		},
		emote = {
			"episode8.4a2p7.emote0"
		},
		answers = {
			{
				text = "episode8.4a2p7.answer1.text",
				next = "nav_4a2",
				animation = "idle4_look_away",
				reply = {
					"episode8.4a2p7.answer1.reply0"
				},
				effect = function ()
					stats.increment_lawful(2)
					stats.increment_justice(1)
				end
			},
			{
				text = "episode8.4a2p7.answer2.text",
				next = "nav_4a2",
				reply = {
					"episode8.4a2p7.answer2.reply0"
				},
				reply_emote = {
					"episode8.4a2p7.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + -1
					state.anger = (state.anger or 0) + 1

					stats.increment_justice(2)
				end
			},
			{
				text = "episode8.4a2p7.answer3.text",
				next = "nav_4a2",
				reply_emote = {
					"episode8.4a2p7.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1

					stats.increment_lawful(1)
				end
			}
		}
	},
	["4a2"] = {
		idle_animation = "idle4",
		animation = "idle4_look_away",
		text = {
			"episode8.4a2.text0"
		},
		emote = {
			"episode8.4a2.emote0"
		},
		answers = {
			{
				text = "episode8.4a2.answer1.text",
				next = "nav_4b",
				animation = "idle4_look_away",
				reply = {
					"episode8.4a2.answer1.reply0"
				}
			},
			{
				text = "episode8.4a2.answer2.text",
				next = "nav_4b",
				reply = {
					"episode8.4a2.answer2.reply0"
				},
				reply_emote = {
					"episode8.4a2.answer2.emote0"
				},
				effect = function ()
					stats.increment_equity(1)
				end
			},
			{
				text = "episode8.4a2.answer3.text",
				next = "nav_4b",
				reply_emote = {
					"episode8.4a2.answer3.emote0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["4b"] = {
		idle_animation = "idle4",
		animation = "idle4_point",
		text = {
			"episode8.4b.text0"
		},
		emote = {
			"episode8.4b.emote0"
		},
		answers = {
			{
				text = "episode8.4b.answer1.text",
				next = "nav_4c",
				reply = {
					"episode8.4b.answer1.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.4b.answer2.text",
				next = "nav_4c",
				animation = "idle4_look_away",
				reply = {
					"episode8.4b.answer2.reply0"
				},
				reply_emote = {
					"episode8.4b.answer2.emote0"
				},
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.4b.answer3.text",
				next = "nav_4c",
				reply = {
					"episode8.4b.answer3.reply0"
				},
				effect = function ()
					agents.increment_approval("tab", -50)
				end
			}
		}
	},
	["4c"] = {
		idle_animation = "idle4",
		animation = "idle4_point",
		text = {
			"episode8.4c.text0",
			"episode8.4c.text1"
		},
		emote = {
			"episode8.4c.emote0"
		},
		answers = {
			{
				text = "episode8.4c.answer1.text",
				next = "lose_suspended",
				reply = {
					"episode8.4c.answer1.reply0"
				}
			},
			{
				text = "episode8.4c.answer2.text",
				next = "lose_suspended",
				reply = {
					"episode8.4c.answer2.reply0"
				},
				reply_emote = {
					"episode8.4c.answer2.emote0"
				}
			},
			{
				text = "episode8.4c.answer3.text",
				next = "lose_suspended",
				reply = {
					"episode8.4c.answer3.reply0"
				}
			}
		}
	},
	["4d"] = {
		idle_animation = "idle4",
		animation = "idle4_point",
		text = {
			"episode8.4d.text0",
			"episode8.4d.text1"
		},
		emote = {
			"episode8.4d.emote0"
		},
		answers = {
			{
				text = "episode8.4d.answer1.text",
				next = "lose_suspended",
				reply = {
					"episode8.4d.answer1.reply0"
				}
			},
			{
				text = "episode8.4d.answer2.text",
				next = "lose_suspended",
				reply = {
					"episode8.4d.answer2.reply0"
				},
				reply_emote = {
					"episode8.4d.answer2.emote0"
				}
			},
			{
				text = "episode8.4d.answer3.text",
				next = "lose_suspended",
				reply = {
					"episode8.4d.answer3.reply0"
				}
			}
		}
	},
	["4e"] = {
		idle_animation = "idle4",
		animation = "idle4_point",
		text = {
			"episode8.4e.text0",
			"episode8.4e.text1",
			"episode8.4e.text2"
		},
		emote = {
			"episode8.4e.emote0"
		},
		answers = {
			{
				text = "episode8.4e.answer1.text",
				next = "lose_suspended",
				reply = {
					"episode8.4e.answer1.reply0"
				}
			},
			{
				text = "episode8.4e.answer2.text",
				next = "lose_suspended",
				reply = {
					"episode8.4e.answer2.reply0"
				},
				reply_emote = {
					"episode8.4e.answer2.emote0"
				}
			},
			{
				text = "episode8.4e.answer3.text",
				next = "lose_suspended",
				reply = {
					"episode8.4e.answer3.reply0"
				}
			}
		}
	},
	["4f"] = {
		idle_animation = "idle4",
		animation = "idle4_point",
		text = {
			"episode8.4f.text0",
			"episode8.4f.text1",
			"episode8.4f.text2"
		},
		emote = {
			"episode8.4f.emote0"
		},
		answers = {
			{
				text = "episode8.4f.answer1.text",
				next = "lose_suspended",
				reply = {
					"episode8.4f.answer1.reply0"
				}
			},
			{
				text = "episode8.4f.answer2.text",
				next = "lose_suspended",
				reply = {
					"episode8.4f.answer2.reply0"
				},
				reply_emote = {
					"episode8.4f.answer2.emote0"
				}
			},
			{
				text = "episode8.4f.answer3.text",
				next = "lose_suspended",
				reply = {
					"episode8.4f.answer3.reply0"
				}
			}
		}
	},
	["4g"] = {
		idle_animation = "idle4",
		animation = "idle4_draw_knife",
		text = {
			"episode8.4g.text0",
			"episode8.4g.text1"
		},
		emote = {
			"episode8.4g.emote0"
		},
		answers = {
			{
				text = "episode8.4g.answer1.text",
				next = "4g2",
				reply = {
					"episode8.4g.answer1.reply0"
				},
				reply_emote = {
					"episode8.4g.answer1.emote0"
				}
			},
			{
				text = "episode8.4g.answer2.text",
				next = "4g2",
				reply = {
					"episode8.4g.answer2.reply0"
				},
				effect = function (state)
					state.anger = (state.anger or 0) + 1
				end
			},
			{
				text = "episode8.4g.answer3.text",
				next = "4g2",
				effect = function (state)
					state.suspicion = (state.suspicion or 0) + 1
				end
			}
		}
	},
	["4g2"] = {
		idle_animation = "idle4",
		animation = "idle4_cut",
		text = {
			"episode8.4g2.text0"
		},
		emote = {
			"episode8.4g2.emote0"
		},
		answers = {
			{
				text = "episode8.4g2.answer1.text",
				next = "nav_4h",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.anger = (state.anger or 0) + 1
					state.cut = true
				end
			},
			{
				text = "episode8.4g2.answer2.text",
				next = "nav_4h",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.4g2.answer3.text",
				next = "nav_4h",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
				end
			}
		}
	},
	["4h"] = {
		idle_animation = "idle4",
		animation = "idle4_cut",
		text = {
			"episode8.4h.text0",
			"episode8.4h.text1"
		},
		emote = {
			"episode8.4h.emote0"
		},
		answers = {
			{
				text = "episode8.4h.answer1.text",
				next = "nav_4i",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
					state.suspicion = (state.suspicion or 0) + 1
				end
			},
			{
				text = "episode8.4h.answer2.text",
				next = "nav_4i",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
				end
			},
			{
				text = "episode8.4h.answer3.text",
				next = "nav_4i",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
					state.anger = (state.anger or 0) + 1
				end
			}
		}
	},
	["4i"] = {
		idle_animation = "idle4",
		animation = "idle4_cut",
		text = {
			"episode8.4i.text0"
		},
		emote = {
			"episode8.4i.emote0"
		},
		answers = {
			{
				text = "episode8.4i.answer1.text",
				next = "nav_4j",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
				end
			},
			{
				text = "episode8.4i.answer2.text",
				next = "nav_4j",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
				end
			},
			{
				text = "episode8.4i.answer3.text",
				next = "nav_4j",
				effect = function (state)
					state.health = (state.health or 0) + -3
					state.cut = true
				end
			}
		}
	},
	["4j"] = {
		idle_animation = "idle4",
		animation = "idle4_put_away_knife",
		text = {
			"episode8.4j.text0"
		},
		emote = {
			"episode8.4j.emote0"
		},
		answers = {
			{
				text = "episode8.4j.answer1.text",
				next = "4x",
				reply = {
					"episode8.4j.answer1.reply0"
				},
				reply_emote = {
					"episode8.4j.answer1.emote0"
				}
			},
			{
				text = "episode8.4j.answer2.text",
				next = "4x",
				reply = {
					"episode8.4j.answer2.reply0",
					"episode8.4j.answer2.reply1"
				},
				reply_emote = {
					"episode8.4j.answer2.emote0"
				}
			},
			{
				text = "episode8.4j.answer3.text",
				next = "4x",
				reply = {
					"episode8.4j.answer3.reply0"
				}
			}
		}
	},
	["4x"] = {
		idle_animation = "idle4",
		animation = "idle4_to_idle2",
		text = {
			"episode8.4x.text0"
		},
		emote = {
			"episode8.4x.emote0"
		},
		answers = {
			{
				text = "episode8.4x.answer1.text",
				next = "win",
				reply = {
					"episode8.4x.answer1.reply0"
				},
				reply_emote = {
					"episode8.4x.answer1.emote0"
				},
				effect = function ()
					stats.increment_equity(1)
					stats.increment_freedom(1)
					stats.increment_evolution(1)
				end
			},
			{
				text = "episode8.4x.answer2.text",
				next = "win",
				reply = {
					"episode8.4x.answer2.reply0",
					"episode8.4x.answer2.reply1"
				},
				reply_emote = {
					"episode8.4x.answer2.emote0"
				},
				effect = function ()
					stats.increment_lawful(1)
				end
			},
			{
				text = "episode8.4x.answer3.text",
				next = "win",
				reply = {
					"episode8.4x.answer3.reply0"
				},
				reply_emote = {
					"episode8.4x.answer3.emote0"
				},
				effect = function ()
					stats.increment_justice(1)
				end
			}
		}
	},
	nav_1g = function ()
		if variables.daniel_lf then
			return "1g2"
		end

		return "1g"
	end,
	nav_1p = function ()
		if perks.profiler then
			return "1p"
		end

		return "nav_1h"
	end,
	nav_1h = function ()
		if variables.bob_lf then
			return "1h2"
		end

		return "1h"
	end,
	nav_1i = function ()
		if missions.completed.negotiate_with_da then
			return "1i"
		end

		return "nav_1j"
	end,
	nav_1j = function ()
		if stats.insanity > 1 then
			return "1ji"
		end

		return "1j"
	end,
	nav_2p = function ()
		if perks.pacifist then
			return "2p"
		end

		return "nav_3p"
	end,
	nav_3p = function ()
		if perks.ideology then
			return "3p"
		end

		return "nav_2b"
	end,
	nav_2b = function ()
		if stats.total_torture_damage > 0 then
			return "2b"
		end

		return "nav_2e"
	end,
	nav_2da = function ()
		if stats.total_torture_damage > 3 then
			return "2da"
		end

		return "nav_2e"
	end,
	nav_2db = function ()
		if stats.total_torture_damage > 6 then
			return "2db"
		end

		return "nav_2e"
	end,
	nav_2e = function ()
		if variables.pr_bought then
			return "2e"
		end

		return "2f"
	end,
	nav_4p = function ()
		if perks.framing then
			return "4p"
		end

		return "nav_5p"
	end,
	nav_5p = function ()
		if perks.waterboarding then
			return "5p"
		end

		return "nav_3b"
	end,
	nav_3b = function (state)
		return "3b"
	end,
	nav_3e = function (state)
		if state.suspicion > 6 then
			return "3e"
		end

		return "3f"
	end,
	nav_3g = function (state)
		if state.anger > 8 or state.suspicion > 8 then
			return "3g"
		end

		return "nav_3h"
	end,
	nav_3h = function ()
		if stats.insanity > 4 then
			return "3hi"
		end

		return "3h"
	end,
	nav_4a2p6 = function ()
		if perks.double then
			return "4a2p6"
		end

		return "nav_4a2p7"
	end,
	nav_4a2p7 = function ()
		if perks.messiah then
			return "4a2p7"
		end

		return "nav_4a2"
	end,
	nav_4a2 = function ()
		if not perks.double and not perks.messiah then
			return "4a2"
		end

		return "nav_4b"
	end,
	nav_4b = function (state)
		if state.tab_1 then
			return "4b"
		end

		return "nav_4c"
	end,
	nav_4c = function (state)
		if state.incompetence1 and state.anger > (variables.narrative and 6 or 5) then
			return "4c"
		end

		return "nav_4d"
	end,
	nav_4d = function (state)
		if state.incompetence2 and state.anger > (variables.narrative and 8 or 7) then
			return "4d"
		end

		return "nav_4e"
	end,
	nav_4e = function (state)
		if state.guilt1 and state.suspicion > (variables.narrative and 6 or 5) then
			return "4e"
		end

		return "nav_4f"
	end,
	nav_4f = function (state)
		if state.guilt2 and state.suspicion > (variables.narrative and 7 or 6) then
			return "4f"
		end

		return "nav_4g"
	end,
	nav_4g = function (state)
		if state.anger > (variables.narrative and 8 or 7) or state.suspicion > (variables.narrative and 8 or 7) then
			return "4g"
		end

		return "nav_4h"
	end,
	nav_4h = function (state)
		if state.anger > 10 or state.suspicion > 10 then
			return "4h"
		end

		return "nav_4i"
	end,
	nav_4i = function (state)
		if state.anger > 12 or state.suspicion > 12 then
			return "4i"
		end

		return "nav_4j"
	end,
	nav_4j = function (state)
		if state.cut then
			return "4j"
		end

		return "4x"
	end,
	_triggers = {
		function (state)
			if not variables.vn and state.health <= 0 then
				return "lose_health"
			end
		end
	}
}
