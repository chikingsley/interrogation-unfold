local agents = require("campaign.agents")
local variables = require("campaign.variables")
local dispatcher = require("crit.dispatcher")
local intl = require("crit.intl")
local thresholds = {
	25,
	45,
	75,
	90,
	100
}
local h_hr_report_set_enabled = hash("hr_report_set_enabled")
local h_enable = hash("enable")
local h_disable = hash("disable")

local function set_enabled(self, enabled)
	local message_id = enabled and h_enable or h_disable

	for _, component in ipairs(self.components) do
		msg.post(component, message_id)
	end
end

function _env:init()
	local components = {}
	self.components = components

	local function add_url(path)
		local url = msg.url(path)
		components[#components + 1] = url

		return url
	end

	local parent_url = self.parent

	local function parent(url)
		go.set_parent(url, parent_url, false)
	end

	intl.translate_label(add_url("header1#title"))
	intl.translate_label(add_url("header1#form_filed_by"))
	intl.translate_label(add_url("header1#form_gnga"))
	intl.translate_label(add_url("header1#form_supervisor"))
	intl.translate_label(add_url("header1#content_filed_by"))
	intl.translate_label(add_url("header1#content_gnga"))
	intl.translate_label(add_url("header1#content_supervisor"))
	intl.translate_label(add_url("header2#title"))
	intl.translate_label(add_url("header2#form_filed_by"))
	intl.translate_label(add_url("header2#form_gnga"))
	intl.translate_label(add_url("header2#form_supervisor"))
	parent("hr_report")

	for i, char in ipairs(agents) do
		intl.translate_label(add_url(char .. "/form#badge"))
		intl.translate_label(add_url(char .. "/form#name"))
		intl.translate_label(add_url(char .. "/form#motivation"))
		intl.translate_label(add_url(char .. "/form#observations"))
		parent(char .. "/form")

		local agent = agents[char]

		if agent.present then
			local approval = agent.approval
			local rating = 1

			for j, upper_threshold in ipairs(thresholds) do
				local lower_threshold = thresholds[j - 1] and thresholds[j - 1] or -1

				if approval > lower_threshold and approval <= upper_threshold then
					rating = j
				end
			end

			parent(char .. "/content")
			label.set_text(add_url(char .. "/content#badge"), intl("hr_report.badge." .. char))
			label.set_text(add_url(char .. "/content#name"), intl("hr_report.name." .. char))
			label.set_text(add_url(char .. "/content#rating"), intl("hr_report.rating." .. rating))
			label.set_text(add_url(char .. "/content#observations1"), intl("hr_report.observations." .. rating))

			local observations2 = intl(variables.classified_unlocked == char and "hr_report.observations2.unlocked" or "hr_report.observations2")

			label.set_text(add_url(char .. "/content#observations2"), observations2)
		else
			go.delete(char .. "/content")
		end
	end

	add_url("#sprite")
	set_enabled(self, false)

	self.sub_id = dispatcher.subscribe({
		h_hr_report_set_enabled
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message)
	if message_id == h_hr_report_set_enabled then
		set_enabled(self, message.enabled)
	end
end
