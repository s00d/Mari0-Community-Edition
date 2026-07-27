-- VGLC Super Mario Bros / Super Mario Land alphabet (smb.json).
return function(T)
	return {
		name = "smb",
		height = 15,
		map = {
			["-"] = { tile = T.EMPTY },
			["X"] = { tile = T.GROUND },
			["S"] = { tile = T.BRICK },
			["?"] = { tile = T.QUESTION, entity = T.ENT_POWERUP },
			["Q"] = { tile = T.QUESTION_EMPTY },
			["o"] = { tile = T.EMPTY, coin = true },
			["<"] = { tile = T.PIPE_TL },
			[">"] = { tile = T.PIPE_TR },
			["["] = { tile = T.PIPE_L },
			["]"] = { tile = T.PIPE_R },
			["E"] = { tile = T.EMPTY, enemy = "auto" },
			["B"] = { tile = T.CANNON_TOP, enemy = "bulletbill" },
			["b"] = { tile = T.CANNON_BODY },
		},
	}
end
