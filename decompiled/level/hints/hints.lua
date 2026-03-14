local dispatcher = require("crit.dispatcher")
local variables = require("campaign.variables")
local h_level_hints_changed = hash("level_hints_changed")
local active_hint, store = nil

local function init(level_store)
	active_hint = nil
	store = level_store
end

local function enabled()
	return variables.narrative and not variables.vn and next(store.hints)
end

local function check_hints()
	if not enabled() then
		return false
	end

	local new_active_hint = nil

	for hint_index, hint in ipairs(store.hints) do
		if store.hint_is_active(hint) then
			new_active_hint = hint_index
		end
	end

	if new_active_hint ~= active_hint then
		active_hint = new_active_hint

		dispatcher.dispatch(h_level_hints_changed)

		return true
	end

	return false
end

local function get_current_hint()
	if not active_hint then
		return nil
	end

	return store.hint_text(store.hints[active_hint])
end

return {
	init = init,
	enabled = enabled,
	check_hints = check_hints,
	get_current_hint = get_current_hint
}
