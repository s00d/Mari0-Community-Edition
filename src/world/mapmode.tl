-- SMB3-style overworld: grid steps on walkable tiles, centered camera on small maps.

local MAP_STEP_TIME = 0.14

global function mapmode_tile_y_off(): number
	return level_mapmode and 0 or -8
end

global function mapmode_update_view(_: mario)
	if not level_mapmode then
		mapmode_zoom = 1
		mapmode_pad_x = 0
		mapmode_pad_y = 0
		return
	end
	local mw = session.mapwidth as number
	local mh = session.mapheight as number
	-- Never use negative scroll on small maps — it shifts the whole map off-screen.
	session.xscroll = 0
	session.yscroll = 0
	if mw <= 0 or mh <= 0 then
		mapmode_zoom = 1
		mapmode_pad_x = 0
		mapmode_pad_y = 0
		return
	end
	mapmode_zoom = math.min(width / mw, height / mh)
	if mapmode_zoom < 1 then
		mapmode_zoom = 1
	end
	local content_w = mw * 16 * scale * mapmode_zoom
	local content_h = mh * 16 * scale * mapmode_zoom
	mapmode_pad_x = (width * 16 * scale - content_w) / 2
	mapmode_pad_y = (height * 16 * scale - content_h) / 2
end

global function mapmode_player_cell(pl: mario): integer, integer
	local cx = math.floor(pl.x + pl.width / 2)
	-- Feet sit on row cy when pl.y = cy - height; floor(y+height) == cy.
	local cy = math.floor(pl.y + pl.height)
	return cx, cy
end

global function mapmode_cell_center(cx: integer, cy: integer, pl: mario): number, number
	return cx + (1 - pl.width) / 2, cy - pl.height
end

global function mapmode_snap_to_start(pl: mario)
	local i = pl.playernumber
	local sx = startx[i] or startx[1]
	local sy = starty[i] or starty[1]
	if sx == nil or sy == nil then
		mapmode_snap_player(pl)
		return
	end
	pl.x = sx + (1 - pl.width) / 2
	pl.y = sy - pl.height
	pl.speedx = 0
	pl.speedy = 0
	pl.mapsteptimer = 0
	pl.mapstepfromx = pl.x
	pl.mapstepfromy = pl.y
	pl.mapsteptox = pl.x
	pl.mapsteptoy = pl.y
end

global function mapmode_try_enter_level(pl: mario): boolean
	if not pl.controlsenabled then
		return false
	end
	if not downkey(pl.playernumber) and not runkey(pl.playernumber) then
		return false
	end
	local cx, cy = mapmode_player_cell(pl)
	if not inmap(cx, cy) then
		return false
	end
	local r = session.map[cx][cy]
	if #r < 3 then
		return false
	end
	local ent = r[2]
	if entitylist[ent] == nil or entitylist[ent].t ~= "warppipe" then
		return false
	end
	local w = tonumber(r[3]) or 1
	local l = tonumber(r[4]) or 1
	local s = tonumber(r[5]) or 0
	warpzone(w, l, s)
	return true
end

global function mapmode_cell_walkable(cx: integer, cy: integer): boolean
	if not inmap(cx, cy) then
		return false
	end
	local cell = session.map[cx][cy]
	if cell == nil then
		return false
	end
	local tid = cell[1] as integer
	local tq = tilequads[tid]
	if tq == nil then
		return false
	end
	return tq:getproperty("collision") == true
end

global function mapmode_snap_player(pl: mario)
	local cx, cy = mapmode_player_cell(pl)
	if not mapmode_cell_walkable(cx, cy) then
		for radius = 1, 12 do
			local found = false
			for dx = -radius, radius do
				for dy = -radius, radius do
					if math.abs(dx) == radius or math.abs(dy) == radius then
						local nx, ny = cx + dx, cy + dy
						if mapmode_cell_walkable(nx, ny) then
							cx, cy = nx, ny
							found = true
							break
						end
					end
				end
				if found then
					break
				end
			end
			if found then
				break
			end
		end
	end
	pl.x, pl.y = mapmode_cell_center(cx, cy, pl)
	pl.speedx = 0
	pl.speedy = 0
	pl.mapsteptimer = 0
	pl.mapstepfromx = pl.x
	pl.mapstepfromy = pl.y
	pl.mapsteptox = pl.x
	pl.mapsteptoy = pl.y
end

global function mapmode_apply_movement(pl: mario, dt: number)
	pl.gravity = 0
	pl.falling = false
	pl.jumping = false

	if pl.mapsteptimer > 0 then
		pl.mapsteptimer = pl.mapsteptimer - dt
		local k = 1 - math.max(0, pl.mapsteptimer) / MAP_STEP_TIME
		pl.x = pl.mapstepfromx + (pl.mapsteptox - pl.mapstepfromx) * k
		pl.y = pl.mapstepfromy + (pl.mapsteptoy - pl.mapstepfromy) * k
		pl.speedx = 0
		pl.speedy = 0
		pl.animationstate = "running"
		if pl.mapsteptimer <= 0 then
			pl.x = pl.mapsteptox
			pl.y = pl.mapsteptoy
			pl.mapsteptimer = 0
			pl.animationstate = "idle"
		end
		return
	end

	local cx, cy = mapmode_player_cell(pl)
	if not mapmode_cell_walkable(cx, cy) then
		mapmode_snap_player(pl)
		return
	end

	local dirx, diry = 0, 0
	if pl.controlsenabled then
		if rightkey(pl.playernumber) then
			dirx = 1
		elseif leftkey(pl.playernumber) then
			dirx = -1
		end
		if upkey(pl.playernumber) then
			diry = -1
		elseif downkey(pl.playernumber) then
			diry = 1
		end
		if dirx ~= 0 and diry ~= 0 then
			diry = 0
		end
	end

	pl.speedx = 0
	pl.speedy = 0

	if dirx ~= 0 or diry ~= 0 then
		local tx, ty = cx + dirx, cy + diry
		if mapmode_cell_walkable(tx, ty) then
			pl.mapstepfromx = pl.x
			pl.mapstepfromy = pl.y
			pl.mapsteptox, pl.mapsteptoy = mapmode_cell_center(tx, ty, pl)
			pl.mapsteptimer = MAP_STEP_TIME
			if dirx > 0 then
				pl.animationdirection = "right"
			elseif dirx < 0 then
				pl.animationdirection = "left"
			end
			pl.animationstate = "running"
		end
	else
		pl.animationstate = "idle"
	end
end
