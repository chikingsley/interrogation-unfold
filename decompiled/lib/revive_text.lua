local shaky_text = require("lib.shaky_text")
local richtext = require("richtext.richtext")
local h_positiony = hash("position.y")

local function is_advance_indicator(word)
	return word.image and word.image.anim == "advance"
end

local function bounce_advance_indicator(node)
	local to = gui.get_position(node).y - 5

	gui.animate(node, h_positiony, to, gui.EASING_INOUTQUAD, 0.5, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

local function revive_advance_indicator(words)
	for i, word in ipairs(words) do
		if is_advance_indicator(word) then
			bounce_advance_indicator(word.node)
		end
	end

	return words
end

local function revive_insanity(words)
	local compress = false
	local words_count = #words
	local insane_nodes = nil
	local insane_nodes_count = 0
	local batshit_nodes = nil
	local batshit_nodes_count = 0

	for i = 1, words_count do
		local word = words[i]
		local is_batshit = word.tags and word.tags.batshit
		local is_insane = is_batshit or word.tags and word.tags.insanity

		if is_insane then
			local chars = richtext.characters(word)

			gui.delete_node(word.node)

			words[i] = nil
			compress = true

			if is_batshit then
				batshit_nodes = batshit_nodes or {}

				for j, char in ipairs(chars) do
					batshit_nodes_count = batshit_nodes_count + 1
					batshit_nodes[batshit_nodes_count] = char.node
					words_count = words_count + 1
					words[words_count] = char
				end
			else
				insane_nodes = insane_nodes or {}

				for j, char in ipairs(chars) do
					insane_nodes_count = insane_nodes_count + 1
					insane_nodes[insane_nodes_count] = char.node
					words_count = words_count + 1
					words[words_count] = char
				end
			end
		end
	end

	if compress then
		local j = 0

		for i = 1, words_count do
			j = j + 1

			while words_count >= j and not words[j] do
				j = j + 1
			end

			if i ~= j then
				words[i] = words[j]
			end
		end
	end

	if insane_nodes then
		shaky_text.shake_nodes(insane_nodes)
	end

	if batshit_nodes then
		shaky_text.shake_nodes(batshit_nodes, true)
	end

	return words
end

local function revive_words(words)
	words = revive_advance_indicator(words)
	words = revive_insanity(words)

	return words
end

local function richtext_safe_create(text, default_font, options)
	local ok, words, metrics = xpcall(function ()
		return richtext.create(text, default_font, options)
	end, debug.traceback)

	if not ok then
		print(debug.traceback("Rich Text parse error in string: " .. text))
		print(words)

		words, metrics = richtext.create("PARSE ERROR", default_font, options)
	end

	return words, metrics
end

return {
	is_advance_indicator = is_advance_indicator,
	bounce_advance_indicator = bounce_advance_indicator,
	revive_advance_indicator = revive_advance_indicator,
	revive_insanity = revive_insanity,
	revive_words = revive_words,
	richtext_safe_create = richtext_safe_create
}
