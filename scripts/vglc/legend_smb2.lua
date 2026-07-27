-- VGLC smb2 / Lost Levels (SMB2J) alphabet (WithEnemies).
-- p/P pipes handled by algorithm B, not this table.
return function(T)
	return {
		name = "smb2",
		height = 15,
		pipes = "pP",
		map = {
			["-"] = { tile = T.EMPTY },
			["#"] = { tile = T.GROUND },
			["B"] = { tile = T.BRICK },
			["?"] = { tile = T.QUESTION, entity = T.ENT_POWERUP },
			["c"] = { tile = T.EMPTY, coin = true },
			["e"] = { tile = T.EMPTY, enemy = "auto" },
			["g"] = { tile = T.GROUND }, -- parser artifact; treat as solid
		},
	}
end
