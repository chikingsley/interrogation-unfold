local intl = require("crit.intl")

function _env:init()
	intl.translate_label("label1#label")
	intl.translate_label("label2#label")
end
