local save_file = require("lib.save_file")
local M = {}
local review_spacing = 1209600

function M.try_review()
	if not defreview or not defreview.isSupported() then
		return
	end

	local version = sys.get_config("project.version")
	local timestamp = socket.gettime()
	local last_reviewed_version = save_file.config.last_reviewed_version
	local last_reviewed_date = save_file.config.last_reviewed_date

	if version == last_reviewed_version and type(last_reviewed_date) == "number" and timestamp <= last_reviewed_date + review_spacing then
		return
	end

	print("Requesting App Store review")
	defreview.requestReview()
	save_file.config_set("last_reviewed_version", version)
	save_file.config_set("last_reviewed_date", timestamp)
end

return M
