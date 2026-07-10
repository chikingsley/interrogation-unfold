local Layout = require("crit.layout")
local perks = require("campaign.perks")
local Button = require("crit.button")
local KeyPrompt = require("lib.key_prompt")
local FocusGiver = require("crit.focus_giver")
local dispatcher = require("crit.dispatcher")
local pick = require("crit.pick")
local button_sound = require("sound.button")
local commentary = require("main.progression.commentary.index")
local input_state = require("crit.input_state")
local focus_distance = require("lib.focus_distance")
local intl = require("crit.intl")
local table_util = require("crit.table_util")
local h_init_office = hash("init_office")
local h_scale = hash("scale")
local h_tint = hash("tint")
local h_tintw = hash("tint.w")
local h_colorw = hash("color.w")
local h_position = hash("position")
local h_rotation = hash("rotation")
local h_click = hash("click")
local h_play_animation = hash("play_animation")
local h_polaroid = hash("polaroid")
local h_image = hash("image")
local h_label = hash("label")
local h_dismiss_bg = hash("dismiss_bg")
local h_dismiss_x = hash("dismiss_x")
local h_office_object_select = hash("office_object_select")
local h_office_object_selected = hash("office_object_selected")
local h_office_object_deselect = hash("office_object_deselect")
local h_office_object_deselect_attempt = hash("office_object_deselect_attempt")
local h_office_navigation_disable = hash("office_navigation_disable")
local h_perks_display_continue = hash("perks_display_continue")
local h_perks_enable_continue = hash("perks_enable_continue")
local h_perks_disable_continue = hash("perks_disable_continue")
local h_play_sfx = hash("play_sfx")
local h_perks = hash("perks")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_acquire_input_focus = hash("acquire_input_focus")
local h_release_input_focus = hash("release_input_focus")
local h_outer_glow = hash("outer_glow")
local h_shadow = hash("shadow")
local h_switch_input_method = hash("switch_input_method")
local h_gamepad_rpad_right = hash("gamepad_rpad_right")
local h_gamepad_rpad_down = hash("gamepad_rpad_down")
local h_key_escape = hash("key_escape")
local h_key_enter = hash("key_enter")
local h_key_space = hash("key_space")
local h_perks_details_enable = hash("perks_details_enable")
local h_perks_details_disable = hash("perks_details_disable")
local hover_zoom_duration = 0.2
local switch_slot_duration = 0.4
local new_perk_duration = 0.5
local new_perk_delay = 0.8
local new_perk_delay_stagger = 0.2
local src_slot_count = 12
local dst_slot_count = 8
local outer_glow_black = vmath.vector4(0, 0, 0, 1)
local outer_glow_disabled = vmath.vector4(0, 0, 0, 0)
local outer_glow_white = vmath.vector4(1, 1, 1, 1)
local shadow_disabled = vmath.vector4(0)
local shadow_black = vmath.vector4(0, 0, 0, 0.7)
local instructions_fade_delay = 1.8
local instructions_fade_duration = 0.5
local unavailable_tint = vmath.vector4(0.5, 0.5, 0.5, 1)
local available_tint = vmath.vector4(1)
local polaroid_hitbox_padding = {
	top = -47,
	bottom = -53,
	left = -52,
	right = -42
}
local polaroid_dismiss_button_padding = {
	top = 0,
	bottom = -707,
	left = 0,
	right = -538
}
local get_transform, handle_polaroid_state_change, handle_polaroid_action, hide_polaroid_details, handle_confirm_action, hide_completely_on_state_change, init_perks, get_next_polaroid, deselect_perk, move_to_slot, handle_dismiss_button_state_change = nil

function _env:init()
	self.focus_context = input_state.new_focus_context()
	self.layout = Layout.new({
		is_go = true,
		no_initial_place = true
	})
	self.this_go = msg.url(".")
	self.close_button = msg.url("close_button")
	self.details_polaroid = msg.url("polaroid")
	self.details_go = msg.url("details")
	self.title_label = msg.url("title#label")
	self.description_label = msg.url("description#label")
	self.flavor_label = msg.url("flavor#label")
	self.error_label = msg.url("error#label")
	self.polaroid_factory = msg.url("perk_slots#polaroid_factory")
	self.instructions_go = msg.url("instructions")
	self.instructions_label1 = msg.url("instructions#label1")
	self.instructions_label2 = msg.url("instructions#label2")
	self.details_blur_active = false
	local description_scale = go.get_scale(self.description_label).y
	local description_pos = go.get_position(self.description_label)
	local flavor_pos = go.get_position(self.flavor_label)
	local flavor_scale = go.get_scale(self.flavor_label).y
	self.description_pos = description_pos
	self.description_scale = description_scale
	self.flavor_scale = flavor_scale
	self.flavor_padding_top = description_pos.y - flavor_pos.y - label.get_text_metrics(self.description_label).height * description_scale
	self.error_padding_top = flavor_pos.y - go.get_position(self.error_label).y - label.get_text_metrics(self.flavor_label).height * flavor_scale

	go.set(self.title_label, h_colorw, 0)
	go.set(self.description_label, h_colorw, 0)
	go.set(self.flavor_label, h_colorw, 0)
	go.set(self.error_label, h_colorw, 0)

	self.confirm_button_label = msg.url("confirm#label")
	self.confirm_button = Button.new(msg.url("confirm#sprite"), {
		is_sprite = true,
		disabled_opacity = 0,
		container = msg.url("confirm"),
		shortcut_actions = {
			h_gamepad_rpad_down,
			h_key_enter,
			h_key_space
		},
		faded_nodes = {},
		faded_labels = {
			self.confirm_button_label
		},
		action = function ()
			handle_confirm_action(self)
		end,
		on_state_change = button_sound.with_sound(hide_completely_on_state_change)
	})
	self.confirm_key_prompt = KeyPrompt.new(msg.url("confirm#prompt"), {
		is_sprite = true,
		enabled = false,
		halo = msg.url("confirm#prompt_halo"),
		action_id = h_gamepad_rpad_down
	})
	self.cancel_button = Button.new(msg.url("cancel#sprite"), {
		is_sprite = true,
		disabled_opacity = 0,
		container = msg.url("cancel"),
		shortcut_actions = {
			h_gamepad_rpad_right,
			h_key_escape
		},
		faded_nodes = {
			msg.url("cancel#label")
		},
		action = function ()
			hide_polaroid_details(self)
		end,
		on_state_change = button_sound.with_sound({
			release = false,
			press = false
		}, hide_completely_on_state_change)
	})
	self.cancel_key_prompt = KeyPrompt.new(msg.url("cancel#prompt"), {
		is_sprite = true,
		enabled = false,
		halo = msg.url("cancel#prompt_halo"),
		action_id = h_gamepad_rpad_right
	})

	self.confirm_button:set_enabled(false)
	self.cancel_button:set_enabled(false)
	msg.post(self.title_label, h_disable)
	msg.post(self.description_label, h_disable)
	msg.post(self.flavor_label, h_disable)
	msg.post(self.error_label, h_disable)
	msg.post(self.confirm_button.container, h_disable)
	msg.post(self.cancel_button.container, h_disable)
	msg.post(self.instructions_go, h_disable)

	self.polaroids = {}
	self.focus_giver = FocusGiver.new({
		focus_context = self.focus_context,
		on_pass_focus = function (focus_giver, nav_action)
			if not nav_action and self.new_perks_animating then
				return false
			end

			local polaroid = get_next_polaroid(self, nil, nav_action)

			if polaroid then
				return polaroid.button:focus()
			end
		end
	})
	self.hover_polaroid_event = fmod and fmod.studio.system:get_event("event:/Button/Hover Polaroid")
	self.sub_id = dispatcher.subscribe({
		h_init_office,
		h_office_object_select,
		h_office_object_selected,
		h_office_object_deselect,
		h_office_object_deselect_attempt,
		h_switch_input_method
	})
end

local function queue_after_blur_animations(self, callback)
	if self.details_blur_active or self.new_perks_animating then
		self.on_details_hidden_queued_action = callback

		return true
	end

	return false
end

local function do_after_blur_animations(self, callback)
	local result = queue_after_blur_animations(self, callback)

	if not result then
		callback(self)
	end

	return result
end

local function execute_queued_action(self, callback)
	local queued_action = self.on_details_hidden_queued_action

	if queued_action then
		queued_action(self)

		self.on_details_hidden_queued_action = nil
	end
end

function get_next_polaroid(self, from_polaroid, nav_action)
	local function getter(polaroid)
		return self.slot_transforms[polaroid.current_slot].position
	end

	local position = nil

	if from_polaroid then
		position = getter(from_polaroid)
	end

	nav_action = nav_action or Button.NAVIGATE_RIGHT
	local min_positive_distance_polaroid, min_distance_polaroid = focus_distance.get_item_in_direction(position, nav_action, self.polaroids, getter, from_polaroid)

	return min_positive_distance_polaroid or min_distance_polaroid
end

local src_slot_offset6 = vmath.vector3(100, -100, 0)
local src_slot_offset8 = vmath.vector3(0, -100, 0)

local function offset_slots(slot_urls, new_perks_count)
	local offset = nil

	if new_perks_count <= 6 and new_perks_count ~= 4 and new_perks_count ~= 5 then
		offset = src_slot_offset6
		slot_urls[12] = table.remove(slot_urls, 4)
	elseif new_perks_count <= 8 then
		offset = src_slot_offset8
	else
		return
	end

	for _, slot in ipairs(slot_urls) do
		go.set_position(go.get_position(slot) + offset, slot)
	end
end

function init_perks(self, options)
	local new_perks = options.new_perks or {}
	self.select_count = options.select_count or 1
	new_perks = table_util.filter(new_perks, function (perk)
		return not perks[perk]
	end)
	local new_perks_count = #new_perks

	if options.test_add_perks then
		for k, perk in ipairs(options.test_add_perks) do
			perks.add_perk(perk)
		end
	end

	local src_urls = {}

	for i = 1, src_slot_count do
		src_urls[i] = msg.url("perk" .. i)
	end

	offset_slots(src_urls, new_perks_count)

	local dst_urls = {}

	for i = 1, dst_slot_count do
		dst_urls[i] = msg.url("slot" .. i)
	end

	local slot_transforms = {}
	self.slot_transforms = slot_transforms

	for i = 1, src_slot_count do
		slot_transforms[i] = get_transform(src_urls[i])
	end

	for i = 1, dst_slot_count do
		slot_transforms[i + src_slot_count] = get_transform(dst_urls[i])
	end

	go.delete(src_urls, true)
	go.delete(dst_urls, true)

	local slot_vacancy = {}
	local polaroids = {}
	self.slot_vacancy = slot_vacancy
	self.polaroids = polaroids

	for i = 1, new_perks_count do
		local perk = new_perks[i]

		if not perks[perk] then
			local polaroid = {
				perk = perk,
				original_slot = i,
				current_slot = i
			}
			slot_vacancy[i] = polaroid

			table.insert(polaroids, polaroid)
		end
	end

	for i = 1, perks.n do
		local perk = perks[i]
		local polaroid = {
			perk = perk,
			current_slot = i + src_slot_count
		}
		slot_vacancy[i + src_slot_count] = polaroid

		table.insert(polaroids, polaroid)
	end

	for k, polaroid in ipairs(polaroids) do
		local transform = slot_transforms[polaroid.current_slot]
		local url = factory.create(self.polaroid_factory, transform.position, transform.rotation, {}, transform.scale)
		url = msg.url(url)
		polaroid.url = url
		local button_url = msg.url(url.socket, url.path, h_polaroid)
		polaroid.button_url = button_url
		polaroid.button = Button.new(button_url, {
			focus_simulates_hover = true,
			is_sprite = true,
			gamepad_focus = true,
			keyboard_focus = true,
			on_state_change = button_sound.with_sound({
				press = false,
				release = false,
				hover = self.hover_polaroid_event
			}, handle_polaroid_state_change),
			action = handle_polaroid_action,
			focus_context = self.focus_context,
			padding = polaroid_hitbox_padding,
			on_pass_focus = function (button, nav_action)
				local next_polaroid = get_next_polaroid(self, polaroid, nav_action)

				if next_polaroid then
					return next_polaroid.button:focus()
				end
			end
		})
		local dismiss_bg_url = msg.url(url.socket, url.path, h_dismiss_bg)

		go.set(dismiss_bg_url, h_tintw, 0)

		local dismiss_x_url = msg.url(url.socket, url.path, h_dismiss_x)

		go.set(dismiss_x_url, h_tintw, 0)

		if polaroid.original_slot then
			polaroid.dismiss_button = Button.new(button_url, {
				is_sprite = true,
				keyboard_focus = false,
				gamepad_focus = false,
				on_state_change = button_sound.with_sound({
					release = false,
					press = false
				}, function (button, state)
					handle_dismiss_button_state_change(self, button, state)
				end),
				action = function ()
					deselect_perk(self, polaroid)
				end,
				padding = polaroid_dismiss_button_padding
			})

			polaroid.dismiss_button:set_enabled(false)
		end

		polaroid.button.polaroid = polaroid
		polaroid.button.owner = self
		local image_url = msg.url(url.socket, url.path, h_image)
		local label_url = msg.url(url.socket, url.path, h_label)

		label.set_text(label_url, intl("perks." .. polaroid.perk .. ".name"))

		polaroid.image_url = image_url
		polaroid.label_url = label_url

		msg.post(image_url, h_play_animation, {
			id = hash(polaroid.perk)
		})
		go.set(button_url, h_shadow, shadow_black)
		msg.post(url, h_disable)

		local available = perks[polaroid.perk] or perks.meets_dependencies(polaroid.perk)
		polaroid.available = available
		local tint = available and available_tint or unavailable_tint

		go.set(button_url, h_tint, tint)
		go.set(image_url, h_tint, tint)
	end

	for i = 1, src_slot_count do
		go.delete("polaroid" .. i, true)
	end

	if next(new_perks) then
		self.has_new_perks = true

		dispatcher.dispatch(h_perks_display_continue)
		dispatcher.dispatch(h_office_navigation_disable)
		dispatcher.dispatch(h_office_object_select, {
			cant_close = true,
			new_perks = true,
			blur_in_duration = 0,
			object_id = h_perks
		})
	end
end

function _env:final()
	for i, polaroid in pairs(self.polaroids) do
		local button = polaroid.button

		if button.focused then
			button:cancel_focus()
		end
	end

	dispatcher.unsubscribe(self.sub_id)
end

function get_transform(url)
	return {
		position = go.get_position(url),
		scale = go.get_scale(url),
		rotation = go.get_rotation(url)
	}
end

function hide_completely_on_state_change(self, state)
	local old_state = self.state

	if old_state == Button.STATE_DISABLED and state ~= Button.STATE_DISABLED then
		msg.post(self.container, h_enable)
		go.cancel_animations(self.node, h_tintw)
		go.animate(self.node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, self.fade_duration or 0.2)
	elseif old_state ~= Button.STATE_DISABLED and state == Button.STATE_DISABLED then
		go.cancel_animations(self.node, h_tintw)
		go.animate(self.node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, self.fade_duration or 0.2, 0, function ()
			msg.post(self.container, h_disable)
		end)
	end

	Button.default_on_state_change(self, state)
end

function handle_polaroid_state_change(button, state)
	local self = button.owner
	local polaroid = button.polaroid
	local url = polaroid.url
	local sprite_url = msg.url(url.socket, url.path, h_polaroid)
	local scale = self.slot_transforms[polaroid.current_slot].scale

	if polaroid.url ~= self.deselecting_polaroid then
		if button.state == Button.STATE_PRESSED then
			dispatcher.dispatch(h_play_sfx, {
				sfx = "polaroids",
				parameters = {
					IsPickedUp = 1
				}
			})
		end

		local zoom = (state == Button.STATE_HOVER or state == Button.STATE_PRESSED) and 1.1 or 1
		local outer_glow = (state == Button.STATE_HOVER or state == Button.STATE_PRESSED) and (perks[polaroid.perk] and outer_glow_black or outer_glow_white) or outer_glow_disabled
		local shadow = (state == Button.STATE_HOVER or state == Button.STATE_PRESSED) and shadow_disabled or shadow_black

		go.cancel_animations(url, h_scale)
		go.cancel_animations(sprite_url, h_outer_glow)
		go.cancel_animations(sprite_url, h_shadow)
		go.animate(url, h_scale, go.PLAYBACK_ONCE_FORWARD, scale * zoom, go.EASING_INOUTSINE, hover_zoom_duration)
		go.animate(sprite_url, h_outer_glow, go.PLAYBACK_ONCE_FORWARD, outer_glow, go.EASING_INOUTSINE, hover_zoom_duration)
		go.animate(sprite_url, h_shadow, go.PLAYBACK_ONCE_FORWARD, shadow, go.EASING_INOUTSINE, hover_zoom_duration)
	end
end

function handle_dismiss_button_state_change(self, button, state, old_state)
	local node = button.node
	local dismiss_bg_url = msg.url(node.socket, node.path, h_dismiss_bg)
	local dismiss_x_url = msg.url(node.socket, node.path, h_dismiss_x)
	local tint = 1
	local duration = 0.2
	local scale = vmath.vector3(1)

	if state == Button.STATE_DISABLED then
		tint = 0
	elseif state == Button.STATE_DEFAULT then
		tint = 1
	end

	if state == Button.STATE_DEFAULT and old_state == Button.STATE_HOVER then
		scale = vmath.vector3(1)
	elseif state == Button.STATE_HOVER and old_state == Button.STATE_DEFAULT then
		scale = vmath.vector3(1.3)
	end

	go.cancel_animations(dismiss_bg_url, h_tintw)
	go.cancel_animations(dismiss_bg_url, h_scale)
	go.cancel_animations(dismiss_x_url, h_tintw)
	go.cancel_animations(dismiss_x_url, h_scale)
	go.animate(dismiss_bg_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, duration)
	go.animate(dismiss_bg_url, h_scale, go.PLAYBACK_ONCE_FORWARD, scale, go.EASING_LINEAR, duration)
	go.animate(dismiss_x_url, h_tintw, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, duration)
	go.animate(dismiss_x_url, h_scale, go.PLAYBACK_ONCE_FORWARD, scale, go.EASING_LINEAR, duration)
end

local function animate_to_transform(transform, url, callback)
	go.cancel_animations(url, h_position)
	go.cancel_animations(url, h_rotation)
	go.cancel_animations(url, h_scale)

	local initial_pos = go.get_position(url)
	local initial_z = initial_pos.z
	local target_position = transform.position
	local target_z = target_position.z

	if target_z < initial_z then
		target_position = vmath.vector3(target_position.x, target_position.y, initial_z)
		local old_callback = callback

		function callback()
			go.set_position(transform.position, url)

			if old_callback then
				old_callback()
			end
		end
	else
		go.set_position(vmath.vector3(initial_pos.x, initial_pos.y, target_z), url)
	end

	go.animate(url, h_position, go.PLAYBACK_ONCE_FORWARD, target_position, go.EASING_OUTEXPO, switch_slot_duration, 0, callback)
	go.animate(url, h_rotation, go.PLAYBACK_ONCE_FORWARD, transform.rotation, go.EASING_OUTEXPO, switch_slot_duration)
	go.animate(url, h_scale, go.PLAYBACK_ONCE_FORWARD, transform.scale, go.EASING_OUTEXPO, switch_slot_duration)
end

function move_to_slot(self, polaroid, slot, callback)
	local slot_vacancy = self.slot_vacancy
	local old_slot = polaroid.current_slot
	slot_vacancy[old_slot] = nil
	slot_vacancy[slot] = polaroid
	polaroid.current_slot = slot

	animate_to_transform(self.slot_transforms[slot], polaroid.url, callback)
end

local function get_instruction_text(self)
	local count = self.select_count

	if count == 0 then
		return ""
	end

	if count == 1 then
		return intl("perks.pick.singular")
	end

	return intl("perks.pick.plural", {
		count = count
	})
end

local function update_instructions(self)
	local text = get_instruction_text(self)
	local label1 = self.instructions_label1
	local label2 = self.instructions_label2
	self.instructions_label1 = label2
	self.instructions_label2 = label1

	msg.post(label2, h_enable)
	label.set_text(label2, text)
	go.cancel_animations(label1, h_colorw)
	go.cancel_animations(label2, h_colorw)
	go.animate(label2, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, instructions_fade_duration)
	go.animate(label1, h_colorw, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, instructions_fade_duration, 0, function ()
		msg.post(label1, h_disable)
	end)
end

local function update_availability(self)
	for k, polaroid in ipairs(self.polaroids) do
		local available = perks[polaroid.perk] or perks.meets_dependencies(polaroid.perk)
		polaroid.available = available
		local tint = available and available_tint or unavailable_tint
		local button_url = polaroid.button_url
		local image_url = polaroid.image_url

		go.cancel_animations(button_url, h_tint)
		go.animate(button_url, h_tint, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, 0.3)
		go.cancel_animations(image_url, h_tint)
		go.animate(image_url, h_tint, go.PLAYBACK_ONCE_FORWARD, tint, go.EASING_LINEAR, 0.3)
	end
end

function deselect_perk(self, polaroid)
	local slot = polaroid.original_slot
	local select_count = self.select_count + 1
	self.select_count = select_count

	update_instructions(self)
	perks.remove_perk(polaroid.perk)
	move_to_slot(self, polaroid, slot, function ()
		update_availability(self)
	end)
	dispatcher.dispatch(h_play_sfx, {
		sfx = "polaroids",
		parameters = {
			IsPickedUp = 0
		}
	})

	if polaroid.original_slot then
		polaroid.dismiss_button:set_enabled(false)
	end

	dispatcher.dispatch(h_perks_disable_continue)
end

local function select_perk(self, polaroid)
	local slot = nil
	local slot_vacancy = self.slot_vacancy

	for i = src_slot_count + 1, src_slot_count + dst_slot_count do
		if not slot_vacancy[i] then
			slot = i

			break
		end
	end

	local select_count = self.select_count - 1
	self.select_count = select_count

	update_instructions(self)
	perks.add_perk(polaroid.perk)
	move_to_slot(self, polaroid, slot, function ()
		update_availability(self)

		if select_count == 0 then
			dispatcher.dispatch(h_perks_enable_continue)
		end
	end)

	if polaroid.original_slot then
		polaroid.dismiss_button:set_enabled(true)
	end

	dispatcher.dispatch(h_play_sfx, {
		sfx = "perk_chosen"
	})
	commentary.perks.overlay_once()
end

local function set_details_enabled(self, enabled)
	local value = enabled and 1 or 0
	local easing = enabled and go.EASING_OUTSINE or go.EASING_INSINE
	local playback = go.PLAYBACK_ONCE_FORWARD
	local polaroid = self.shown_polaroid

	if enabled then
		msg.post(self.title_label, h_enable)
		msg.post(self.description_label, h_enable)
		msg.post(self.flavor_label, h_enable)
		msg.post(self.error_label, h_enable)

		self.details_blur_active = true
	end

	dispatcher.dispatch(enabled and h_perks_details_enable or h_perks_details_disable, {
		blur_in_duration = switch_slot_duration,
		blur_out_duration = switch_slot_duration
	})
	go.cancel_animations(self.title_label, h_colorw)
	go.cancel_animations(self.description_label, h_colorw)
	go.cancel_animations(self.flavor_label, h_colorw)
	go.cancel_animations(self.error_label, h_colorw)
	go.animate(self.title_label, h_colorw, playback, value, easing, switch_slot_duration)
	go.animate(self.description_label, h_colorw, playback, value, easing, switch_slot_duration)
	go.animate(self.flavor_label, h_colorw, playback, value, easing, switch_slot_duration)
	go.animate(self.error_label, h_colorw, playback, value, easing, switch_slot_duration, 0, function ()
		if not enabled then
			polaroid.button:focus()
			msg.post(self.title_label, h_disable)
			msg.post(self.description_label, h_disable)
			msg.post(self.flavor_label, h_disable)
			msg.post(self.error_label, h_disable)

			self.details_blur_active = false

			execute_queued_action(self)
		end
	end)

	local confirm_enabled = enabled and polaroid.original_slot and (self.select_count > 0 and perks.meets_dependencies(polaroid.perk) or perks[polaroid.perk])

	if confirm_enabled then
		local text = nil

		if perks[polaroid.perk] then
			text = intl("perks.deselect")
		else
			text = intl("perks.select")
		end

		label.set_text(self.confirm_button_label, text)
	end

	self.confirm_button:set_enabled(confirm_enabled)
	self.cancel_button:set_enabled(enabled)
	self.confirm_key_prompt:set_enabled(confirm_enabled)
	self.cancel_key_prompt:set_enabled(enabled)
end

local function show_polaroid_details(self, polaroid)
	if queue_after_blur_animations(self, function ()
		show_polaroid_details(self, polaroid)
	end) then
		return
	end

	local transform = get_transform(self.details_polaroid)

	for k, pol in ipairs(self.polaroids) do
		pol.button:set_enabled(false)
	end

	local meets_dependencies = true
	local reason, argument = nil

	if not perks[polaroid.perk] then
		meets_dependencies, reason, argument = perks.meets_dependencies(polaroid.perk)
	end

	local error_message = not meets_dependencies and intl("perks.error." .. (reason or "generic"), {
		arg = argument and intl("perks." .. argument .. ".name")
	}) or ""
	local perk_name = polaroid.perk

	label.set_text(self.title_label, intl("perks." .. perk_name .. ".name"))
	label.set_text(self.description_label, intl("perks." .. perk_name .. ".description"))
	label.set_text(self.flavor_label, intl("perks." .. perk_name .. ".flavor"))
	label.set_text(self.error_label, error_message)
	timer.delay(0.0001, false, function ()
		local metrics = label.get_text_metrics(self.description_label)
		local y_offset = -self.flavor_padding_top - metrics.height * self.description_scale
		local position = self.description_pos + vmath.vector3(0, y_offset, 0)

		go.set_position(position, self.flavor_label)

		metrics = label.get_text_metrics(self.flavor_label)
		y_offset = -self.error_padding_top - metrics.height * self.flavor_scale
		position = position + vmath.vector3(0, y_offset, 0)

		go.set_position(position, self.error_label)
	end)

	self.shown_polaroid = polaroid

	if polaroid.original_slot then
		polaroid.dismiss_button:set_enabled(false)
	end

	msg.post(self.close_button, h_release_input_focus)
	animate_to_transform(transform, polaroid.url)
	set_details_enabled(self, true)
end

function hide_polaroid_details(self)
	local polaroid = self.shown_polaroid

	if not polaroid then
		return
	end

	for k, pol in ipairs(self.polaroids) do
		pol.button:set_enabled(true)
	end

	local transform = self.slot_transforms[polaroid.current_slot]
	self.deselecting_polaroid = polaroid.url

	animate_to_transform(transform, polaroid.url, function ()
		self.deselecting_polaroid = nil
	end)
	set_details_enabled(self, false)

	if polaroid.original_slot then
		if perks[polaroid.perk] then
			polaroid.dismiss_button:set_enabled(true)
		else
			polaroid.dismiss_button:set_enabled(false)
		end
	end

	msg.post(self.close_button, h_acquire_input_focus)

	self.shown_polaroid = nil

	dispatcher.dispatch(h_play_sfx, {
		sfx = "polaroids",
		parameters = {
			IsPickedUp = 0
		}
	})
end

function handle_confirm_action(self, no_details)
	local polaroid = self.shown_polaroid

	if not polaroid then
		return
	end

	if perks[polaroid.perk] then
		deselect_perk(self, polaroid)
	else
		select_perk(self, polaroid)
	end

	for k, pol in ipairs(self.polaroids) do
		pol.button:set_enabled(true)
	end

	set_details_enabled(self, false)

	self.shown_polaroid = nil
end

function handle_polaroid_action(button)
	local self = button.owner
	local polaroid = button.polaroid

	show_polaroid_details(self, polaroid)
end

local function animate_new_perk(self, polaroid, callback)
	local transform = self.slot_transforms[polaroid.current_slot]
	local go_url = polaroid.url
	local button_url = polaroid.button_url
	local image_url = polaroid.image_url
	local label_url = polaroid.label_url
	local polaroid_button = polaroid.button

	polaroid_button:set_enabled(false)

	local function animation_callback()
		polaroid_button:set_enabled(true)

		if callback then
			callback()
		end
	end

	go.cancel_animations(go_url, h_position)
	go.cancel_animations(go_url, h_rotation)
	go.cancel_animations(go_url, h_scale)
	go.cancel_animations(button_url, h_tintw)
	go.cancel_animations(image_url, h_tintw)
	go.cancel_animations(label_url, h_colorw)
	go.set_position(transform.position + vmath.vector3(0, 70, 0), go_url)

	local rotation = transform.rotation

	go.set_rotation(vmath.quat(-rotation.x, -rotation.y, -rotation.z, rotation.w), go_url)
	go.set_scale(transform.scale * 1.5, go_url)
	go.set(button_url, h_tintw, 0)
	go.set(image_url, h_tintw, 0)
	go.set(label_url, h_colorw, 0)

	local forward = go.PLAYBACK_ONCE_FORWARD
	local delay = new_perk_delay + new_perk_delay_stagger * (polaroid.current_slot - 1)

	go.animate(go_url, h_position, forward, transform.position, go.EASING_OUTEXPO, new_perk_duration, delay)
	go.animate(go_url, h_rotation, forward, transform.rotation, go.EASING_OUTEXPO, new_perk_duration, delay)
	go.animate(go_url, h_scale, forward, transform.scale, go.EASING_OUTEXPO, new_perk_duration, delay)
	go.animate(button_url, h_tintw, forward, 1, go.EASING_LINEAR, new_perk_duration, delay)
	go.animate(image_url, h_tintw, forward, 1, go.EASING_LINEAR, new_perk_duration, delay)
	go.animate(label_url, h_colorw, forward, 1, go.EASING_LINEAR, new_perk_duration, delay, animation_callback)
	timer.delay(delay, false, function ()
		dispatcher.dispatch(h_play_sfx, {
			sfx = "polaroids",
			parameters = {
				IsPickedUp = 1
			}
		})
	end)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_office then
		init_perks(self, message)
	elseif message_id == h_office_object_select then
		if message.object_id == h_perks and self.has_new_perks then
			msg.post(self.instructions_go, h_enable)

			local label1 = self.instructions_label1
			local label2 = self.instructions_label2

			go.set(label1, h_colorw, 0)
			go.set(label2, h_colorw, 0)
			msg.post(label2, h_disable)
			label.set_text(label1, get_instruction_text(self))
			go.animate(label1, h_colorw, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, instructions_fade_duration, instructions_fade_delay)

			self.new_perks_animating = true
		end
	elseif message_id == h_office_object_selected then
		if message.object_id == h_perks then
			local new_perks = 0

			local function animate_new_perk_callback()
				new_perks = new_perks - 1

				if new_perks == 0 then
					self.new_perks_animating = false

					execute_queued_action(self)
					timer.delay(0, false, function ()
						self.focus_giver:try_focus_first()
					end)
				end
			end

			for k, polaroid in ipairs(self.polaroids) do
				msg.post(polaroid.url, h_enable)

				if polaroid.original_slot then
					new_perks = new_perks + 1

					animate_new_perk(self, polaroid, animate_new_perk_callback)
				end
			end

			msg.post(self.this_go, h_acquire_input_focus)

			if not self.has_new_perks then
				timer.delay(0, false, function ()
					self.focus_giver:try_focus_first()
				end)
			end
		end
	elseif message_id == h_office_object_deselect then
		if message.object_id == h_perks then
			for k, pol in ipairs(self.polaroids) do
				pol.button:cancel_focus()
				msg.post(pol.url, h_disable)
			end

			msg.post(self.this_go, h_release_input_focus)
		end
	elseif message_id == h_office_object_deselect_attempt then
		if message.object_id == h_perks then
			do_after_blur_animations(self, function ()
				dispatcher.dispatch(h_office_object_deselect, message)
			end)
		end
	elseif message_id == h_switch_input_method then
		for i, polaroid in pairs(self.polaroids) do
			local button = polaroid.button

			button:switch_input_method()

			if polaroid.dismiss_button then
				polaroid.dismiss_button:switch_input_method()
			end
		end

		self.confirm_key_prompt:switch_input_method()
		self.cancel_key_prompt:switch_input_method()
		self.confirm_button:switch_input_method()
		self.cancel_button:switch_input_method()
		self.focus_giver:try_focus_first(message.nav_action)
	end
end

function _env:on_input(action_id, action)
	if self.shown_polaroid then
		self.confirm_key_prompt:on_input(action_id, action)
		self.cancel_key_prompt:on_input(action_id, action)

		if self.cancel_button:on_input(action_id, action) then
			return true
		end

		if self.confirm_button:on_input(action_id, action) then
			return true
		end

		if action.released and action_id == h_click then
			local x, y = Layout.action_to_projection(action)
			local url = self.shown_polaroid.url
			local sprite = msg.url(url.socket, url.path, h_polaroid)

			if not pick.pick_sprite(sprite, x, y) then
				hide_polaroid_details(self)
			end

			return true
		end
	else
		local details_blur_active = self.details_blur_active

		if details_blur_active and not action_id then
			return true
		end

		if not details_blur_active and self.focus_giver:on_input(action_id, action) then
			return true
		end

		for k, polaroid in ipairs(self.polaroids) do
			if polaroid.original_slot and polaroid.dismiss_button:on_input(action_id, action) then
				return true
			end

			if polaroid.button:on_input(action_id, action) then
				return true
			end
		end
	end
end
