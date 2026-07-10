local all_fonts = {
	"dialogue",
	"dialogue_italic",
	"dialogue_bold",
	"dialogue_bolditalic",
	"dialogue_small",
	"dialogue_italic_small",
	"dialogue_bold_small",
	"dialogue_bolditalic_small",
	"document",
	"document_italic",
	"document_bold",
	"document_serif",
	"document_serif_italic",
	"document_serif_bold",
	"document_serif_bolditalic",
	"title",
	"title_italic",
	"title_bold",
	"title_bolditalic",
	"timer"
}

local function prefix_layers(prefix, fonts)
	fonts = fonts or all_fonts
	local layers = {}

	for i = 1, #fonts do
		local font = fonts[i]
		layers[hash(font)] = hash(prefix .. font)
	end

	return layers
end

local M = {
	all_fonts = all_fonts,
	prefix_layers = prefix_layers,
	layers = prefix_layers("")
}

return M
