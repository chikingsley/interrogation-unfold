local press_release = require("press_release.press_release")
local scenes = require("main.progression.scenes")

return function ()
	press_release.options = {
		cont = {
			"This example text is the best.",
			"Danks meow meow meow what the lol lmao text text text come on give me a " .. "new line please it's good thanks.",
			"Meow meow second meow do not read this blas bla.",
			underlines = 70
		},
		cont_2 = {
			"This is short text.",
			"Shorter text.",
			"Short.",
			underlines = 20
		}
	}
	press_release.header_text = "Important stuff happened, need to provide context fo the press"
	press_release.text = {
		press_release.PARAGRAPH_BREAK,
		"What the fuck did you just fucking say about me, you little bitch? ",
		"I'll have you know I graduated top of my class in the Navy Seals, ",
		"and I've been involved in numerous secret raids on Al-Quaeda, and I have ",
		"over 300 confirmed kills. I am trained in gorilla warfare and I'm the ",
		"top sniper in the entire US armed forces.",
		press_release.PARAGRAPH_BREAK,
		"You are nothing to me but just another target. I will wipe you the fuck out ",
		"with precision the likes of which has never been seen before on this Earth, ",
		"mark my fucking words. You think you can get away with saying that shit ",
		"to me over the Internet? ",
		{
			id = "cont"
		},
		press_release.PARAGRAPH_BREAK,
		"Think again, fucker. As we speak I am contacting my secret network of ",
		"spies across the USA and your IP is being traced right now so you better ",
		"prepare for the storm, maggot. The storm that wipes out the pathetic ",
		"little thing you call your life. ",
		{
			id = "cont_2"
		},
		" More text for you etc etc"
	}

	press_release.init()
	scenes.load_scene("press_release")
	scenes.wait_for_end_scene()
	scenes.run_progression("main")
end
