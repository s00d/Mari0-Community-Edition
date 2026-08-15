--[[ Shared link/output helpers for logic gates. ]]

global function logicgate_init_xy(self: any, x: number, y: number, r: {any})
	local gate = self as {any:any}
	gate.x = x
	gate.y = y
	gate.cox = x
	gate.coy = y
	gate.visible = false
	local rem = {unpack(r as {any})} as {any}
	table.remove(rem, 1)
	table.remove(rem, 1)
	if #rem > 0 and rem[1] ~= "link" then
		gate.visible = (rem[1] == "true")
		table.remove(rem, 1)
	end
	gate.r = rem
end

global function logicgate_link(self: any): any|nil
	local gate = self as {any:any}
	local rem = gate.r as {any}
	while #rem > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(session.objects[w]) do
				if tonumber(rem[3] as string) == v.cox and tonumber(rem[4] as string) == v.coy then
					v:addoutput(gate, rem[2])
					if (gate.inputstate as {any:any}) and tonumber(rem[2] as string) then
						(gate.inputstate as {any:any})[tonumber(rem[2] as string) as integer] = "off"
					end
				end
			end
		end
		table.remove(rem, 1)
		table.remove(rem, 1)
		table.remove(rem, 1)
		table.remove(rem, 1)
	end
	gate.r = rem
	return nil
end

global function logicgate_addoutput(self: any, a, t)
	local gate = self as {any:any}
	local outtable = gate.outtable as {any}
	table.insert(outtable, {a, t} as {any})
	gate.outtable = outtable
end

global function logicgate_out(self: any, t)
	local gate = self as {any:any}
	local outtable = gate.outtable as {any}
	for i = 1, #outtable do
		if (outtable[i] as {Entity, any})[1].input then
			(outtable[i] as {Entity, any})[1]:input(t, (outtable[i] as {Entity, any})[2])
		end
	end
end

global function logicgate_draw_img(self: any, img: Image)
	local gate = self as {any:any}
	if gate.visible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(img, tile_draw_x((gate.x as number) - 1), tile_draw_y((gate.y as number) - 1, -8), 0, world_draw_scale(), world_draw_scale())
	end
end
