if misc and misc.gettime then
	socket = socket or {}
	socket.gettime = socket.gettime or misc.gettime
end

local render_helper = require("lib.render_helper")
local Layout = require("crit.layout")
local Button = require("crit.button")
local Scroll = require("crit.scroll")
local ScrollBar = require("crit.scrollbar")
local dispatcher = require("crit.dispatcher")
local DragAndDrop = require("crit.drag_and_drop")
local save_file = require("lib.save_file")
local env = require("lib.environment")
local large_ui = require("lib.large_ui")
local render_settings = require("main.render.settings")
local sys_config = require("lib.sys_config")
local config = save_file.config
local h_clear_color = hash("clear_color")
local h_window_resized = hash("window_resized")
local h_window_change_size = hash("window_change_size")
local h_set_view_projection = hash("set_view_projection")
local h_set_view = hash("set_view")
local h_recalculate_projection = hash("recalculate_projection")
local configure_projection, set_resolution_scale, create_render_target, dequeue_render_target, release_render_target, collect_render_targets, z_clip_matrix, render_blur, render_bloom, push_render_target, pop_render_target, apply_render_target, apply_filter = nil
Layout.default_scale_by = "x"
Layout.design_go_left = -Layout.design_width * 0.5
Layout.design_go_bottom = -Layout.design_height * 0.5
Layout.design_go_right = Layout.design_width * 0.5
Layout.design_go_top = Layout.design_height * 0.5
Button.is_mobile = sys_config.is_mobile
Button.default_sprite_action_to_position = Layout.action_to_projection
Button.default_gui_action_to_position = Layout.action_to_offset_design
DragAndDrop.default_sprite_action_to_position = Layout.action_to_projection
DragAndDrop.default_gui_action_to_position = Layout.action_to_offset_design
ScrollBar.default_gui_action_to_position = Layout.action_to_offset_design

function Scroll.default_go_action_to_dy(action)
	return action.screen_dy * Layout.viewport_to_projection_scale_y
end

function _env:init()
	self.text_pred = render.predicate({
		"text"
	})
	self.tile_pred = render.predicate({
		"tile"
	})
	self.particle_pred = render.predicate({
		"particle"
	})
	self.tile_below_blur_pred = render.predicate({
		"tile_below_blur"
	})
	self.particle_below_blur_pred = render.predicate({
		"particle_below_blur"
	})
	self.gui_pred = render.predicate({
		"gui"
	})
	self.tile2_pred = render.predicate({
		"tile2"
	})
	self.particle2_pred = render.predicate({
		"particle2"
	})
	self.tile3_pred = render.predicate({
		"tile3"
	})
	self.particle3_pred = render.predicate({
		"particle3"
	})
	self.gui2_pred = render.predicate({
		"gui2"
	})
	self.gui3_pred = render.predicate({
		"gui3"
	})
	self.vignette_pred = render.predicate({
		"vignette"
	})
	render_helper.blur[1].horiz_pred = render.predicate({
		"blur1",
		"horiz"
	})
	render_helper.blur[1].vert_pred = render.predicate({
		"blur1",
		"vert"
	})
	render_helper.blur[2].horiz_pred = render.predicate({
		"blur2",
		"horiz"
	})
	render_helper.blur[2].vert_pred = render.predicate({
		"blur2",
		"vert"
	})
	self.bloom_treshold_pred = render.predicate({
		"bloom",
		"treshold"
	})
	self.bloom_horiz_pred = render.predicate({
		"bloom",
		"horiz"
	})
	self.bloom_vert_pred = render.predicate({
		"bloom",
		"vert"
	})
	self.filter1_pred = render.predicate({
		"filter1"
	})
	self.filter2_pred = render.predicate({
		"filter2"
	})
	self.post_pred = render.predicate({
		"post"
	})
	self.render_target_pool = {}
	self.quad_constants = render.constant_buffer()
	self.render_target_stack = {
		{
			render.RENDER_TARGET_DEFAULT
		},
		n = 1
	}
	self.current_render_target = self.render_target_stack[1]
	self.clear_color = vmath.vector4(0, 0, 0, 0)
	self.clear_color.x = sys.get_config("render.clear_color_red", 0)
	self.clear_color.y = sys.get_config("render.clear_color_green", 0)
	self.clear_color.z = sys.get_config("render.clear_color_blue", 0)
	self.clear_color.w = sys.get_config("render.clear_color_alpha", 0)
	self.view_matrix = vmath.matrix4()
	self.gui_view_matrix = vmath.matrix4()

	configure_projection(self)
end

local transient_depthstencil = {
	transient = {
		render.BUFFER_DEPTH_BIT,
		render.BUFFER_STENCIL_BIT
	}
}

local function render_settings_draw()
	render.set_stencil_mask(255)
	render.enable_state(render.STATE_BLEND)
end

local function render_settings_filter()
	render.set_stencil_mask(0)
	render.disable_state(render.STATE_BLEND)
end

local function apply_render_settings(self, settings)
	if self.render_settings == settings then
		return
	end

	self.render_settings = settings

	settings()
end

local function clear_if_needed(self)
	local render_target = self.current_render_target

	if render_target.cleared then
		return
	end

	render.clear({
		[render.BUFFER_COLOR_BIT] = self.clear_color,
		[render.BUFFER_STENCIL_BIT] = 0
	})

	render_target.cleared = true
end

local function mark_as_cleared(self)
	self.current_render_target.cleared = true
end

function _env:update()
	local resolution_scale = config.resolution_scale

	if resolution_scale ~= self.resolution_scale then
		set_resolution_scale(self, resolution_scale)
	end

	local proj_matrix = self.proj_matrix
	local gui_proj_matrix = self.gui_proj_matrix
	local view_matrix = self.view_matrix
	local gui_view_matrix = self.gui_view_matrix
	local camera_transform = render_helper.camera_transform

	if camera_transform then
		gui_proj_matrix = proj_matrix * camera_transform * self.gui_to_proj
		proj_matrix = proj_matrix * camera_transform
	end

	self.current_render_target.cleared = nil

	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
	render.disable_state(render.STATE_CULL_FACE)
	apply_render_settings(self, render_settings_draw)
	clear_if_needed(self)
	render.set_viewport(Layout.viewport_origin_x, Layout.viewport_origin_y, Layout.viewport_width, Layout.viewport_height)

	local function render_proj1()
		render.set_projection(proj_matrix)

		local blur1 = render_helper.blur[1]
		local blur2 = render_helper.blur[2]

		if not blur1.enabled then
			blur2 = blur1
			blur1 = blur2
		end

		local function render_below_blur_predicate()
			apply_render_target(self)
			apply_render_settings(self, render_settings_draw)
			clear_if_needed(self)
			render.set_view(view_matrix)
			render.draw(self.tile_below_blur_pred)
			render.draw(self.particle_below_blur_pred)
		end

		local z_threshold2 = -1

		if blur1.enabled then
			local z_threshold1 = blur1.z_threshold

			if blur1.use_below_blur_predicate then
				z_threshold1 = -1
			end

			z_threshold2 = z_threshold1
			local render_below_blur = nil

			if z_threshold1 <= -1 then
				render_below_blur = render_below_blur_predicate
			else
				function render_below_blur()
					render_below_blur_predicate()
					render.set_view(z_clip_matrix(-1, z_threshold1) * view_matrix)
					render.draw(self.tile_pred)
					render.draw(self.particle_pred)
				end
			end

			if blur2.enabled then
				z_threshold2 = blur2.z_threshold

				render_blur(self, blur2, function ()
					render_blur(self, blur1, render_below_blur)
					apply_render_target(self)
					apply_render_settings(self, render_settings_draw)
					clear_if_needed(self)
					render.set_view(z_clip_matrix(z_threshold1, z_threshold2) * view_matrix)
					render.draw(self.tile_pred)
					render.draw(self.particle_pred)
				end)
			else
				render_blur(self, blur1, render_below_blur)
			end

			render.set_view(z_clip_matrix(z_threshold2, 1) * view_matrix)
		else
			render_below_blur_predicate()
			render.set_view(view_matrix)
		end

		if z_threshold2 < 1 then
			apply_render_target(self)
			apply_render_settings(self, render_settings_draw)
			clear_if_needed(self)
			render.draw(self.tile_pred)
			render.draw(self.particle_pred)
		end
	end

	local function render_scene()
		if render_helper.bloom then
			render_bloom(self, render_proj1)
		else
			render_proj1()
		end

		apply_render_target(self)
		apply_render_settings(self, render_settings_draw)
		clear_if_needed(self)
		render.set_view(gui_view_matrix)
		render.set_projection(gui_proj_matrix)
		render.enable_state(render.STATE_STENCIL_TEST)
		render.draw(self.gui_pred)
		render.disable_state(render.STATE_STENCIL_TEST)
		render.set_view(view_matrix)
		render.set_projection(proj_matrix)
		render.draw(self.tile2_pred)
		render.draw(self.particle2_pred)
		render.set_view(gui_view_matrix)
		render.set_projection(gui_proj_matrix)
		render.enable_state(render.STATE_STENCIL_TEST)
		render.draw(self.gui2_pred)
		render.disable_state(render.STATE_STENCIL_TEST)
		render.draw(self.vignette_pred, self.quad_constants)
	end

	local filtered = false

	if render_helper.filter1 then
		render_scene = apply_filter(self, self.filter1_pred, render_scene)
		filtered = true
	end

	if render_helper.filter2 then
		render_scene = apply_filter(self, self.filter2_pred, render_scene)
		filtered = true
	end

	if not filtered and resolution_scale ~= 1 then
		render_scene = apply_filter(self, self.post_pred, render_scene)
	end

	render_scene()
	apply_render_target(self)
	apply_render_settings(self, render_settings_draw)
	clear_if_needed(self)
	render.set_view(view_matrix)
	render.set_projection(proj_matrix)
	render.draw(self.tile3_pred)
	render.draw(self.particle3_pred)
	render.set_view(gui_view_matrix)
	render.set_projection(gui_proj_matrix)
	render.enable_state(render.STATE_STENCIL_TEST)
	render.draw(self.gui3_pred)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.set_view(view_matrix)
	render.set_projection(proj_matrix)
	render.draw_debug3d()
	render.set_view(gui_view_matrix)
	render.set_projection(self.gui_proj_matrix)
	render.draw(self.text_pred)
	collect_render_targets(self)

	if self.render_target_stack.n ~= 1 then
		error("Unbalanced render target stack")
	end
end

local function get_dpi(window_width)
	if misc and misc.get_dpi then
		return misc.get_dpi(window_width)
	end

	return 72
end

function configure_projection(self)
	local window_width = render.get_window_width()
	local window_height = render.get_window_height()
	local viewport_width = window_width
	local viewport_height = window_height

	if not env.no_letterboxing then
		local aspect = viewport_width / viewport_height
		local min_ar = render_settings.current.min_aspect_ratio
		local max_ar = render_settings.current.max_aspect_ratio

		if max_ar < aspect then
			viewport_width = math.ceil(viewport_height * max_ar)
		elseif aspect < min_ar then
			viewport_height = math.ceil(viewport_width / min_ar)
		end
	end

	local projection_width = Layout.design_width
	local projection_height = viewport_height * projection_width / viewport_width

	Layout.set_metrics({
		window_width = window_width,
		window_height = window_height,
		window_dpi = get_dpi(window_width),
		viewport_width = viewport_width,
		viewport_height = viewport_height,
		projection_left = -projection_width * 0.5,
		projection_bottom = -projection_height * 0.5,
		projection_right = projection_width * 0.5,
		projection_top = projection_height * 0.5
	})
	large_ui.set_dpi(get_dpi(window_width))

	self.proj_matrix = Layout.get_projection_matrix()
	self.gui_proj_matrix = Layout.get_gui_projection_matrix()
	self.gui_to_proj = vmath.inv(self.proj_matrix) * self.gui_proj_matrix
	self.quad_constants.window_size = vmath.vector4(viewport_width, viewport_height, 0, 0)
	self.quad_constants.inv_window_size = vmath.vector4(1 / viewport_width, 1 / viewport_height, 0, 0)
	self.quad_constants.projection_size = vmath.vector4(projection_width, projection_height, 0, 0)
	self.quad_constants.inv_projection_size = vmath.vector4(1 / projection_width, 1 / projection_height, 0, 0)
	render_helper.blur[1].cache = nil
	render_helper.blur[2].cache = nil

	set_resolution_scale(self, config.resolution_scale)
end

function set_resolution_scale(self, scale)
	local buffer_width = math.ceil(Layout.viewport_width * scale)
	local buffer_height = math.ceil(Layout.viewport_height * scale)
	self.resolution_scale = scale
	self.buffer_width = buffer_width
	self.buffer_height = buffer_height

	for target, info in pairs(self.render_target_pool) do
		render.set_render_target_size(target, buffer_width, buffer_height)
	end
end

function apply_filter(self, pred, render_func)
	return function ()
		local random_id = math.random(1000, 9000)
		local render_target = dequeue_render_target(self, "filter" .. random_id)

		push_render_target(self, render_target)
		render_func()
		pop_render_target(self)
		apply_render_target(self)
		apply_render_settings(self, render_settings_filter)
		render.enable_texture(0, render_target, render.BUFFER_COLOR_BIT)
		render.draw(pred, self.quad_constants)
		render.disable_texture(0)
		release_render_target(self, render_target)
		mark_as_cleared(self)
	end
end

function render_blur(self, blur, render_func)
	local random_id = math.random(1000, 9000)
	local target1 = blur.cache
	local dirty = not target1 or blur.dirty

	if not target1 then
		local name = "blur_horiz_" .. random_id

		if blur.cacheable then
			target1 = create_render_target(self, name)
			blur.cache = target1
		else
			target1 = dequeue_render_target(self, name)
		end
	end

	if dirty then
		blur.dirty = false

		push_render_target(self, target1)
		render_func()
		pop_render_target(self)
	end

	local target2 = dequeue_render_target(self, "blur_vert_" .. random_id)

	push_render_target(self, target2, transient_depthstencil)
	apply_render_target(self)
	apply_render_settings(self, render_settings_filter)
	render.enable_texture(0, target1, render.BUFFER_COLOR_BIT)
	render.draw(blur.horiz_pred, self.quad_constants)
	render.disable_texture(0)
	release_render_target(self, target1)
	mark_as_cleared(self)
	pop_render_target(self)
	apply_render_target(self)
	render.enable_texture(0, target2, render.BUFFER_COLOR_BIT)
	render.draw(blur.vert_pred, self.quad_constants)
	render.disable_texture(0)
	release_render_target(self, target2)
	mark_as_cleared(self)
end

function render_bloom(self, render_func)
	local random_id = math.random(1000, 9000)
	local target1 = dequeue_render_target(self, "bloom_treshold_" .. random_id)

	push_render_target(self, target1)
	render_func()
	pop_render_target(self)

	local target2 = dequeue_render_target(self, "bloom_horiz_" .. random_id)

	push_render_target(self, target2, transient_depthstencil)
	apply_render_target(self)
	apply_render_settings(self, render_settings_filter)
	render.enable_texture(0, target1, render.BUFFER_COLOR_BIT)
	render.draw(self.bloom_treshold_pred, self.quad_constants)
	render.disable_texture(0)
	mark_as_cleared(self)
	pop_render_target(self)

	local target3 = dequeue_render_target(self, "bloom_vert_" .. random_id)

	push_render_target(self, target3, transient_depthstencil)
	apply_render_target(self)
	render.enable_texture(0, target2, render.BUFFER_COLOR_BIT)
	render.draw(self.bloom_horiz_pred, self.quad_constants)
	render.disable_texture(0)
	mark_as_cleared(self)
	release_render_target(self, target2)
	pop_render_target(self)
	apply_render_target(self)
	render.enable_texture(0, target3, render.BUFFER_COLOR_BIT)
	render.enable_texture(1, target1, render.BUFFER_COLOR_BIT)
	render.draw(self.bloom_vert_pred, self.quad_constants)
	render.disable_texture(0)
	render.disable_texture(1)
	mark_as_cleared(self)
	release_render_target(self, target3)
	release_render_target(self, target1)
end

function z_clip_matrix(far, near)
	local mat = vmath.matrix4()
	local scale = 2 / (near - far)
	mat.m22 = scale
	mat.m23 = 1 - near * scale

	return mat
end

function create_render_target(self, name)
	return render.render_target(name, {
		[render.BUFFER_COLOR_BIT] = {
			format = render.FORMAT_RGBA,
			width = self.buffer_width,
			height = self.buffer_height,
			min_filter = render.FILTER_LINEAR,
			mag_filter = render.FILTER_LINEAR,
			u_wrap = render.WRAP_CLAMP_TO_EDGE,
			v_wrap = render.WRAP_CLAMP_TO_EDGE
		},
		[render.BUFFER_STENCIL_BIT] = {
			format = render.FORMAT_STENCIL,
			width = self.buffer_width,
			height = self.buffer_height
		}
	})
end

function dequeue_render_target(self, name)
	local render_target_pool = self.render_target_pool

	for target, info in pairs(render_target_pool) do
		if not info.in_use then
			info.in_use = true
			info.unused_frames = 0

			return target
		end
	end

	local target = create_render_target(self, name)
	render_target_pool[target] = {
		unused_frames = 0,
		in_use = true
	}

	return target
end

function release_render_target(self, target)
	local def = self.render_target_pool[target]

	if def then
		def.in_use = false
	end
end

function collect_render_targets(self)
	local render_target_pool = self.render_target_pool

	for target, info in pairs(render_target_pool) do
		if not info.in_use then
			local unused_frames = info.unused_frames

			if unused_frames >= 1 then
				render_target_pool[target] = nil

				render.delete_render_target(target)
			else
				info.unused_frames = unused_frames + 1
			end
		end
	end
end

function push_render_target(self, target, options)
	local stack = self.render_target_stack
	local n = stack.n + 1
	stack[n] = {
		target,
		options
	}
	stack.n = n
end

function pop_render_target(self)
	local stack = self.render_target_stack
	local n = stack.n
	stack[n] = nil
	stack.n = n - 1
end

function apply_render_target(self)
	local stack = self.render_target_stack
	local n = stack.n
	local target = {
		render.RENDER_TARGET_DEFAULT
	}

	if n > 0 then
		target = stack[n]
	end

	if self.current_render_target == target then
		return
	end

	self.current_render_target = target
	local render_target = target[1]
	local target_options = target[2]

	if target_options then
		render.set_render_target(render_target, target_options)
	else
		render.set_render_target(render_target)
	end

	if render_target == render.RENDER_TARGET_DEFAULT then
		render.set_viewport(Layout.viewport_origin_x, Layout.viewport_origin_y, Layout.viewport_width, Layout.viewport_height)
	else
		render.set_viewport(0, 0, self.buffer_width, self.buffer_height)
	end
end

function _env:on_message(message_id, message, sender)
	if message_id == h_clear_color then
		self.clear_color = message.color
	elseif message_id == h_set_view_projection then
		self.view_matrix = message.view
	elseif message_id == h_set_view then
		self.view_matrix = message.view
	elseif message_id == h_window_resized or message_id == h_recalculate_projection then
		local old_large_ui = large_ui.enabled

		configure_projection(self)

		if large_ui.enabled == old_large_ui then
			message.large_ui_unchanged = true
		end

		dispatcher.dispatch(h_window_change_size, message)
	end
end
