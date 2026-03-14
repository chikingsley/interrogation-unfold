local Jigsaw = require("campaign.minigames.jigsaw.jigsaw")
local Piece = require("campaign.minigames.jigsaw.piece")
local VirtualCursor = require("lib.virtual_cursor")
local config_jigsaw = require("campaign.minigames.jigsaw.config_jigsaw")
local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local h_switch_input_method = hash("switch_input_method")
local h_virtual_cursor_action = hash("virtual_cursor_action")
local h_virtual_cursor_set = hash("virtual_cursor_set")
local h_init_jigsaw = hash("init_jigsaw")
local h_play_sfx = hash("play_sfx")
local debug = env.debug or not env.bundled
local h_key_r = hash("key_r")
local h_tintw = hash("tint.w")
local jigsaw_on_input = nil

local function init_jigsaw(jigsaw_id)
	local puzzles = config_jigsaw[jigsaw_id]

	if not puzzles then
		print("Jigsaw: Jigsaw with id \"" .. jigsaw_id .. "\" not found.")

		return
	end

	local pieces_factory = msg.url("pieces#" .. jigsaw_id)
	local jigsaws = {}

	for n, puzzle in ipairs(puzzles) do
		local piece_id = 1
		local jigsaw = Jigsaw.new(n, {
			size = {
				x = puzzle.columns,
				y = puzzle.rows
			},
			image_size = {
				x = puzzle.image_size.x,
				y = puzzle.image_size.y
			},
			hitbox = puzzle.piece_hitbox,
			extended_padding = puzzle.extended_padding,
			snap_hitbox = puzzle.snap_hitbox
		})

		for i = 1, puzzle.rows do
			for j = 1, puzzle.columns do
				local id = factory.create(pieces_factory)
				local url = msg.url(id)
				local index = {
					puzzle_no = 1,
					x = j,
					y = i
				}
				local position = vmath.vector3(math.random(-400, 400), math.random(-1500, -1300), 0)
				local piece = Piece.new(piece_id, url, index, position, puzzle.screen_boundary_padding)

				jigsaw:insert_piece(piece)

				piece_id = piece_id + 1
			end
		end

		jigsaw:init()

		jigsaws[n] = jigsaw

		timer.delay(0.5, false, function ()
			jigsaw:reset()
		end)
	end

	return jigsaws
end

function _env:init()
	local background_sprite = msg.url("background#sprite")

	go.set(background_sprite, h_tintw, 0.4)

	self.virtual_cursor = VirtualCursor.new({
		on_generated_input = function (action_id, action)
			dispatcher.dispatch(h_virtual_cursor_action, {
				action_id = action_id,
				action = action
			})
			jigsaw_on_input(self, action_id, action)
		end,
		on_active_change = function (active)
			dispatcher.dispatch(h_virtual_cursor_set, {
				active = active
			})
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_init_jigsaw,
		h_switch_input_method
	})

	msg.post(".", "acquire_input_focus")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

function jigsaw_on_input(self, action_id, action)
	if debug and action_id == h_key_r and action.pressed then
		for i, jigsaw in ipairs(self.puzzles) do
			jigsaw:reset()
		end
	end

	for i, jigsaw in ipairs(self.puzzles) do
		local input, has_picked_up_piece = jigsaw:on_input(action_id, action)

		if input then
			if has_picked_up_piece then
				for j, jig in ipairs(self.puzzles) do
					jig:push_pieces_back()
				end
			end

			return true
		end
	end
end

function _env:on_input(action_id, action)
	if self.virtual_cursor:on_input(action_id, action) then
		return true
	end

	return jigsaw_on_input(self, action_id, action)
end

function _env:on_message(message_id, message, sender)
	if message_id == h_init_jigsaw then
		self.puzzles = init_jigsaw(message.jigsaw_id)
	elseif message_id == h_switch_input_method then
		self.virtual_cursor:switch_input_method()
	end
end

function _env:update(dt)
	self.virtual_cursor:update(dt)

	for i, jigsaw in pairs(self.puzzles) do
		jigsaw:update(dt)
	end
end
