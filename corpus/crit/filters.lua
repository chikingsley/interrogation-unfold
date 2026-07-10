local M = {
	low_pass = function (cutoff_frequency)
		local RC = 1 / (cutoff_frequency * 2 * math.pi)

		return function (previous_output, input, dt)
			local alpha = dt / (dt + RC)

			return previous_output + alpha * (input - previous_output)
		end
	end,
	high_pass = function (cutoff_frequency)
		local RC = 1 / (cutoff_frequency * 2 * math.pi)

		return function (previous_output, delta_input, dt)
			local alpha = RC / (dt + RC)

			return alpha * (previous_output + delta_input)
		end
	end
}

return M
