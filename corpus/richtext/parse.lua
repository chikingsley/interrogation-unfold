local color = require("richtext.color")
local utf8 = require("richtext.utf8")
local M = {}

local function parse_tag(tag, params)
	local settings = {
		tags = {
			[tag] = params
		},
		tag = tag
	}

	if tag == "color" then
		settings.color = color.parse(params)
	elseif tag == "shadow" then
		settings.shadow = color.parse(params)
	elseif tag == "outline" then
		settings.outline = color.parse(params)
	elseif tag == "font" then
		settings.font = params
	elseif tag == "size" then
		settings.size = tonumber(params)
	elseif tag == "b" then
		settings.bold = true
	elseif tag == "i" then
		settings.italic = true
	elseif tag == "a" then
		settings.anchor = true
	elseif tag == "br" then
		settings.linebreak = true
	elseif tag == "img" then
		local texture, anim = params:match("(.-):(.*)")
		settings.image = {
			texture = texture,
			anim = anim
		}
	elseif tag == "spine" then
		local scene, anim = params:match("(.-):(.*)")
		settings.spine = {
			scene = scene,
			anim = anim
		}
	elseif tag == "nobr" then
		settings.nobr = true
	end

	return settings
end

local function add_word(text, settings, words)
	text = text:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&nbsp;", " ")
	local data = {
		text = text
	}

	for k, v in pairs(settings) do
		data[k] = v
	end

	words[#words + 1] = data
end

local function split_line(line, settings, words)
	assert(line)
	assert(settings)
	assert(words)

	local ws_start, trimmed_text, ws_end = line:match("^(%s*)(.-)(%s*)$")

	if trimmed_text == "" then
		add_word(ws_start .. ws_end, settings, words)
	else
		local wi = #words

		for word in trimmed_text:gmatch("%S+") do
			add_word(word .. " ", settings, words)
		end

		local first = words[wi + 1]
		first.text = ws_start .. first.text
		local last = words[#words]
		last.text = utf8.sub(last.text, 1, utf8.len(last.text) - 1) .. ws_end
	end
end

local function split_text(text, settings, words)
	assert(text)
	assert(settings)
	assert(words)

	if text == "" and settings.linebreak then
		add_word(text, settings, words)

		return
	end

	text = text:gsub("\r", "")
	local added_linebreak = false

	if text:sub(-1) ~= "\n" then
		added_linebreak = true
		text = text .. "\n"
	end

	for line in text:gmatch("(.-)\n") do
		split_line(line, settings, words)

		local last = words[#words]
		last.linebreak = true
	end

	if added_linebreak then
		local last = words[#words]
		last.linebreak = false
	end
end

local function merge_tags(dst, src)
	for k, v in pairs(src) do
		if k ~= "tags" then
			dst[k] = v
		end
	end

	for tag, params in pairs(src.tags or {}) do
		dst.tags[tag] = params == "" and true or params
	end
end

function M.parse(text, default_settings)
	assert(text)
	assert(default_settings)

	text = text:gsub("&zwsp;", "<zwsp>​</zwsp>")
	local all_words = {}
	local open_tags = {}

	while true do
		local word_settings = {
			tags = {}
		}

		merge_tags(word_settings, default_settings)

		for _, open_tag in ipairs(open_tags) do
			merge_tags(word_settings, open_tag)
		end

		local before_tag, tag, after_tag = text:match("(.-)(</?%S->)(.*)")

		if not before_tag or not tag or not after_tag then
			if text ~= "" then
				split_text(text, word_settings, all_words)
			end

			break
		end

		if before_tag ~= "" then
			split_text(before_tag, word_settings, all_words)
		end

		local endtag, name, params, empty = tag:match("<(/?)(%a+)=?(%S-)(/?)>")
		local is_endtag = endtag == "/"
		local is_empty = empty == "/"

		if is_empty then
			local tag_settings = parse_tag(name, params)

			merge_tags(word_settings, tag_settings)
			add_word("", word_settings, all_words)
		elseif not is_endtag then
			local tag_settings = parse_tag(name, params)
			open_tags[#open_tags + 1] = tag_settings
		else
			local found = false

			for i = #open_tags, 1, -1 do
				if open_tags[i].tag == name then
					table.remove(open_tags, i)

					found = true

					break
				end
			end

			if not found then
				print(("Found end tag '%s' without matching start tag"):format(name))
			end
		end

		text = after_tag
	end

	return all_words
end

function M.length(text)
	return utf8.len(text:gsub("<img.-/>", " "):gsub("<spine.-/>", " "):gsub("<.->", ""))
end

return M
