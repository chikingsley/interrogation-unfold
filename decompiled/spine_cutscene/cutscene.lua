local dispatcher = require("crit.dispatcher")
local sys_config = require("lib.sys_config")
local h_init_spine_cutscene = hash("init_spine_cutscene")
local h_spine_cutscene_init_message = hash("spine_cutscene_init_message")
local h_show_spine_cutscene = hash("show_spine_cutscene")
local h_show_spine_cutscene_message = hash("show_spine_cutscene_message")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_spine_cutscene,
		h_show_spine_cutscene
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)

	if sys_config.system_name ~= "Switch" and self.dim_mode and self.dim_mode ~= window.DIMMING_UNKNOWN then
		window.set_dim_mode(self.dim_mode)
	end
end

local function play(self)
	if not self.played then
		self.played = true

		if sys_config.system_name ~= "Switch" then
			self.dim_mode = window.get_dim_mode()

			window.set_dim_mode(window.DIMMING_OFF)
		end
	end
end

function _env:on_message(message_id, message)
	if message_id == h_init_spine_cutscene then
		local factory_component = msg.url("#" .. message.cutscene)

		collectionfactory.create(factory_component)
		dispatcher.dispatch(h_spine_cutscene_init_message, message)
		msg.post(".", h_show_spine_cutscene_message, message)
	elseif message_id == h_show_spine_cutscene_message then
		if not message.preload and self.played then
			dispatcher.dispatch(h_show_spine_cutscene)
		end
	elseif message_id == h_show_spine_cutscene then
		play(self)
	end
end
