local M = {
	filter1 = false,
	filter2 = false,
	bloom = false,
	blur = {
		{
			cacheable = false,
			enabled = false,
			use_below_blur_predicate = false,
			z_threshold = 0,
			dirty = false
		},
		{
			cacheable = false,
			enabled = false,
			use_below_blur_predicate = false,
			z_threshold = 0,
			dirty = false
		}
	}
}

return M
