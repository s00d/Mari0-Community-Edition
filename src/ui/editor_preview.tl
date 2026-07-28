--[[ Editor live preview: platform ranges, turret cones, link lines. ]]

global function editor_draw_live_preview()
	if not map or not editormode then return end
	local xs = xscroll or 0
	local ys = yscroll or 0
	local sc = scale or 1

	-- Scan visible map cells for entities with previewable args
	local x0 = math.max(1, math.floor(xs))
	local y0 = math.max(1, math.floor(ys))
	local x1 = math.min(mapwidth or 0, math.ceil(xs + (width or 25) + 1))
	local y1 = math.min(mapheight or 0, math.ceil(ys + (height or 14) + 1))

	for x = x0, x1 do
		local col = map[x]
		if col then
			for y = y0, y1 do
				local cell = col[y]
				if cell and cell[2] then
					local ent_i = cell[2]
					local t: string|nil = nil
					if type(ent_i) == "string" then
						t = ent_i as string
					elseif entitylist and type(ent_i) == "number" and entitylist[ent_i as integer] then
						t = (entitylist[ent_i as integer] as EntityListEntry).t
					end
					if t == "platform" or t == "platformspawner" then
						local xd = tonumber(cell[4] as any) or 0
						local yd = tonumber(cell[5] as any) or 0
						-- handle "mN" style
						local sx = tostring(cell[4] or "")
						local sy = tostring(cell[5] or "")
						if string.sub(sx, 1, 1) == "m" then xd = -(tonumber(string.sub(sx, 2)) or 0) end
						if string.sub(sy, 1, 1) == "m" then yd = -(tonumber(string.sub(sy, 2)) or 0) end
						if xd ~= 0 or yd ~= 0 then
							love.graphics.setColor(0.2, 0.9, 1, 0.45)
							local px = (x - xs - 1) * 16 * sc + 8 * sc
							local py = (y - ys - 1.5) * 16 * sc + 8 * sc
							love.graphics.line(px, py, px + xd * 16 * sc, py + yd * 16 * sc)
							love.graphics.circle("line", px + xd * 16 * sc, py + yd * 16 * sc, 3 * sc)
						end
					elseif t == "turret" or (type(ent_i) == "string" and (ent_i as string) == "turret") then
						local facing = 1
						if tostring(cell[3] or "") == "left" then facing = -1 end
						local range = tonumber(cell[4] as any) or 9
						love.graphics.setColor(1, 0.3, 0.2, 0.25)
						local px = (x - xs - 1) * 16 * sc + 8 * sc
						local py = (y - ys - 1.5) * 16 * sc + 8 * sc
						local len = range * 16 * sc
						love.graphics.polygon("fill",
							px, py,
							px + facing * len, py - len * 0.45,
							px + facing * len, py + len * 0.45)
					end
					-- enemy modifier badges
					if type(ent_i) == "string" and enemy_modifier_ids_from_args then
						local mods = enemy_modifier_ids_from_args(cell as {any})
						if #mods > 0 then
							love.graphics.setColor(1, 1, 0.3, 0.9)
							local label = ""
							for i = 1, #mods do
								local m = ENEMY_MODIFIERS and ENEMY_MODIFIERS[mods[i]]
								label = label .. ((m and (m.icon as string)) or mods[i]:sub(1, 1))
							end
							properprint(label, (x - xs - 1) * 16 * sc, (y - ys - 1.5) * 16 * sc)
						end
					end
				end
			end
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
end
