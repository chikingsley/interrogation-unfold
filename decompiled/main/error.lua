function init()
	pprint(_G.interrogation_exception)
	label.set_text("#label", "ERROR: " .. tostring(_G.interrogation_exception))
end
