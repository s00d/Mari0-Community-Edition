-- DEFAULT smbtiles.png IDs inferred from mappacks/smb/1-1.txt + tile props.
-- Grid: 22 cols × 6 rows, id = (row-1)*22 + col (1-based).
-- Verified: ground = bottom rows → 2; brick/breakable → 7; coinblock/? → 8;
-- pipe mouth → 16/17; pipe body → 38/39; used ? (spriteset 1) → 113; flag base → 78.

local T = {
	EMPTY = 1,
	GROUND = 2,
	BRICK = 7,
	QUESTION = 8,
	QUESTION_EMPTY = 113,
	PIPE_TL = 16,
	PIPE_TR = 17,
	PIPE_L = 38,
	PIPE_R = 39,
	HARD = 78,
	-- No dedicated cannon art in DEFAULT row; hard block + bulletbill entity.
	CANNON_TOP = 78,
	CANNON_BODY = 78,
}

-- entitylist indices (src/world/entitylist.tl)
T.ENT_POWERUP = 2
T.ENT_SPAWN = 8
T.ENT_FLAG = 11

return T
