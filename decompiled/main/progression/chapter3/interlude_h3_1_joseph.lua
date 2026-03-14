local fui = require("main.fuior.runtime")
local compiler = require("main.fuior.compiler")
local scenes = require("main.progression.scenes")
local func = function ()
	return function (fui)
		local intl = fui.intl(nil)

		if fui.var_get("has_joseph") then
			fui.set_preset_music("campaign")
			fui.load_interlude("office_floor")
			fui.load_characters("joseph")
			fui.wait(2)
			fui.show_character("joseph", "LEFT", "what")
			fui.wait(1)
			fui.text("joseph", "what", intl("81039c.interlude_h3_1_joseph.6c8c27"))
			fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.b9e157"))
			fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.ee7ad1"))
			fui.text("joseph", "explaining", intl("81039c.interlude_h3_1_joseph.c8ecd3"))
			fui.text("joseph", "explaining", intl("81039c.interlude_h3_1_joseph.d36ce8"))
			fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.aad13b"))
			fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.124e37"))
			fui.text("joseph", "what", intl("81039c.interlude_h3_1_joseph.3ad830"))
			fui.text("joseph", "angry_point", intl("81039c.interlude_h3_1_joseph.56c723"))

			if fui.var_get("joseph_approval") >= 70 then
				local choice31 = fui.choose({
					intl("81039c.interlude_h3_1_joseph.cfa9a4"),
					intl("81039c.interlude_h3_1_joseph.76b351"),
					intl("81039c.interlude_h3_1_joseph.84cef0")
				})

				if choice31 == 1 then
					fui.var_increment("lawful", 1)
					fui.text("joseph", "sad", intl("81039c.interlude_h3_1_joseph.4c1069"))
					fui.text("joseph", "explaining", intl("81039c.interlude_h3_1_joseph.5ff73e"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.659861"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5cd5fd"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.133650"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5927b0"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.026f39"))
				elseif choice31 == 2 then
					fui.var_increment("joseph_approval", 5)
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.4019ae"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5cd5fd"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.7a97d2"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5927b0"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.026f39"))
				elseif choice31 == 3 then
					fui.var_increment("joseph_approval", 5)
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.097b97"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.ae034a"))
					fui.text("joseph", "explaining", intl("81039c.interlude_h3_1_joseph.3afaa8"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.4019ae"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5cd5fd"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.7a97d2"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5927b0"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.026f39"))
				end
			else
				local choice82 = fui.choose({
					intl("81039c.interlude_h3_1_joseph.cfa9a4"),
					intl("81039c.interlude_h3_1_joseph.76b351"),
					intl("81039c.interlude_h3_1_joseph.378bd6")
				})

				if choice82 == 1 then
					fui.var_decrement("joseph_approval", 5)
					fui.var_increment("lawful", 1)
					fui.text("joseph", "sad", intl("81039c.interlude_h3_1_joseph.8aed06"))
					fui.text("joseph", "what", intl("81039c.interlude_h3_1_joseph.2f004d"))
					fui.text("joseph", "smile", intl("81039c.interlude_h3_1_joseph.dec1f8"))
				elseif choice82 == 2 then
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.4019ae"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.5cd5fd"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.7a97d2"))
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.94c334"))
					fui.text("joseph", "smile", intl("81039c.interlude_h3_1_joseph.dec1f8"))
				elseif choice82 == 3 then
					fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.c0b474"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.101e94"))
					fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.d9f375"))
					fui.text("joseph", "what", intl("81039c.interlude_h3_1_joseph.2844bb"))
					fui.text("joseph", "explaining", intl("81039c.interlude_h3_1_joseph.a137d5"))
				end
			end

			local choice117 = fui.choose({
				intl("81039c.interlude_h3_1_joseph.56cf2d"),
				intl("81039c.interlude_h3_1_joseph.8afbd3"),
				intl("81039c.interlude_h3_1_joseph.70292b")
			})

			if choice117 == 1 then
				fui.var_increment("joseph_approval", 5)
				fui.var_decrement("justice", 1)
				fui.text("joseph", "dismissive", intl("81039c.interlude_h3_1_joseph.75553b"))
			elseif choice117 == 2 then
				fui.var_increment("justice", 3)
				fui.text("joseph", "angry_point", intl("81039c.interlude_h3_1_joseph.091fb0"))
			elseif choice117 == 3 then
				fui.var_decrement("joseph_approval", 20)
				fui.var_decrement("justice", 4)
				fui.var_increment("lawful", 2)
				fui.text("joseph", "smile", intl("81039c.interlude_h3_1_joseph.e5209e"))
				fui.text("joseph", "what", intl("81039c.interlude_h3_1_joseph.3a351e"))
				fui.text("joseph", "smile", intl("81039c.interlude_h3_1_joseph.58e5f6"))
				fui.text("joseph", "concern", intl("81039c.interlude_h3_1_joseph.cb0cc6"))
				fui.text("joseph", "angry_point", intl("81039c.interlude_h3_1_joseph.b6d64e"))
			end
		end

		fui.wait_for_input()
		fui.hide_all_characters()
	end
end()

return scenes.skippable(function ()
	func(fui.new())
end)
