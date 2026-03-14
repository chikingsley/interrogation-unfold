local sys_config = require("lib.sys_config")

if sys_config.system_name == "Switch" then
	function _env:init()
		misc.configure_play_styles()

		self.handheld = misc.is_handheld()
	end

	function _env:update(dt)
		local handheld = misc.is_handheld()

		if handheld ~= self.handheld then
			self.handheld = handheld

			if not handheld then
				misc.change_controller_grip(false)
			end
		end
	end
end
