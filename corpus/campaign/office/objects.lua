local office = require("campaign.office")
local dispatcher = require("crit.dispatcher")
local h_office_object_acquire_focus = hash("office_object_acquire_focus")
local h_office_finish_acquire_focus = hash("office_finish_acquire_focus")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_office_focus_giver_init = hash("office_focus_giver_init")
local h_office_object_select = hash("office_object_select")
local h_office_object_select_attempt = hash("office_object_select_attempt")
local h_office_object_deselected = hash("office_object_deselected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_blur_disabled = hash("office_blur_disabled")

function _env:init()
	self.sub_id = dispatcher.subscribe({
		h_office_object_acquire_focus,
		h_office_finish_acquire_focus,
		h_office_object_select,
		h_office_object_select_attempt,
		h_office_object_deselect,
		h_office_object_deselected,
		h_office_blur_disabled
	})
	self.object_selected = false
	self.blur_animating = false
	local nav_button_briefing = go.get_id("nav_button_briefing")
	local nav_button_continue = go.get_id("nav_button_continue")
	local nav_button_wall = go.get_id("nav_button_wall")
	local pause_button = go.get_id("pause_button")
	local object_focus_giver = go.get_id("object_focus_giver")
	self.pending_focus = {
		{
			url = nav_button_briefing,
			z = go.get_position(nav_button_briefing).z
		},
		{
			url = nav_button_continue,
			z = go.get_position(nav_button_continue).z
		},
		{
			url = nav_button_wall,
			z = go.get_position(nav_button_wall).z
		},
		{
			url = pause_button,
			z = go.get_position(pause_button).z
		},
		{
			z = -9999,
			url = object_focus_giver
		}
	}

	for i, object in ipairs(office.objects) do
		collectionfactory.create("#" .. object)
	end

	for i, object in ipairs(office.decorative_objects) do
		collectionfactory.create("#" .. object)
	end

	msg.post(".", h_office_finish_acquire_focus)
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function resolve_queued_select(self)
	local queued_message = self.queued_select_message

	if queued_message then
		self.queued_select_message = nil

		dispatcher.dispatch(h_office_object_select, queued_message)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_office_object_acquire_focus then
		table.insert(self.pending_focus, {
			url = message.sender or sender,
			z = message.z
		})
	elseif message_id == h_office_finish_acquire_focus then
		local pending_focus = self.pending_focus

		table.sort(pending_focus, function (a, b)
			return a.z < b.z
		end)

		for i, desc in ipairs(pending_focus) do
			msg.post(desc.url, h_acquire_input_focus)
		end

		dispatcher.dispatch(h_office_focus_giver_init)
	elseif message_id == h_office_object_select_attempt then
		if self.object_selected or self.blur_animating then
			self.queued_select_message = message
		else
			dispatcher.dispatch(h_office_object_select, message)
		end
	elseif message_id == h_office_object_select then
		self.object_selected = true
	elseif message_id == h_office_object_deselect then
		self.blur_animating = true
	elseif message_id == h_office_blur_disabled then
		self.blur_animating = false

		if not self.object_selected then
			resolve_queued_select(self)
		end
	elseif message_id == h_office_object_deselected then
		self.object_selected = false

		if not self.blur_animating then
			resolve_queued_select(self)
		end
	end
end
