local dispatcher = require("crit.dispatcher")
local h_init_office = hash("init_office")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_expo_end = hash("office_expo_end")
local h_mission_report = hash("mission_report")
local h_pr_report = hash("pr_report")
local h_expo = hash("expo")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_init_office,
		h_office_expo_end,
		h_office_object_deselect
	})
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function _env:on_message(message_id, message)
	if message_id == h_init_office and not message.no_expo and not message.new_perks then
		dispatcher.dispatch(h_office_object_select, {
			cant_close = true,
			no_zoom = true,
			expo = true,
			blur_in_duration = 0,
			object_id = h_mission_report
		})
	elseif message_id == h_office_expo_end then
		if message.object_id == h_mission_report then
			dispatcher.dispatch(h_office_object_select, {
				cant_close = true,
				no_zoom = true,
				expo = true,
				no_blur = true,
				object_id = h_pr_report
			})
		elseif message.object_id == h_pr_report then
			dispatcher.dispatch(h_office_object_selected, {
				no_blur = true,
				object_id = h_expo
			})
		end
	elseif message_id == h_office_object_deselect and message.object_id == h_expo then
		dispatcher.dispatch(h_office_object_deselect, {
			no_blur = true,
			object_id = h_pr_report
		})
		dispatcher.dispatch(h_office_object_deselect, {
			no_blur = true,
			object_id = h_mission_report
		})
	end
end
