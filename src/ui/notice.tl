--[[ Teal port of root notice.lua — slide in/out via Flux ]]

notice = {}
notice.red = {1, 0.5, 0.5}
notice.white = {1, 1, 1}
notice.notices = {}
notice.duration = 5
notice.fadetime = 0.5

function notice.new(text: any, color: any, duration: any)
	local duration = (duration or notice.duration) as number
	local text = text or ""
	local color = color or notice.white
	local n = {
		text = (text as string):lower(),
		color = color,
		life = duration,
		duration = duration,
		y_factor = 1,
		fading = false,
	}
	Flux.to(n, notice.fadetime, { y_factor = 0 }):ease("quadout")
	table.insert(notice.notices, n)
end

function notice.update(dt: number)
	for i = #notice.notices, 1, -1 do
		local v = notice.notices[i] as {string:any}
		v["life"] = (v["life"] as number) - dt
		local life = v["life"] as number
		if life <= notice.fadetime and not (v["fading"] as boolean) then
			v["fading"] = true
			Flux.to(v, notice.fadetime, { y_factor = 1 }):ease("quadin")
		end
		if life <= 0 then
			table.remove(notice.notices, i)
		end
	end
end

function notice.draw()
	local y: number = 0
	for i = #notice.notices, 1, -1 do
		local v = notice.notices[i] as {string:any}
		local text = v["text"] as string
		local y_factor = v["y_factor"] as number
		
		--get width by finding longest line
		local split = strsplit(text, "|")
		local longest = #split[1]
		for i = 2, #split do
			if #split[i] > longest then
				longest = #split[i]
			end
		end
		
		local height = #split*10+3
		
		actualy = y - height * (y_factor * y_factor)
		
		local targetrect = {width*16 - longest*8-5, actualy, longest*8+5, height}
		local scissor = {(width*16 - longest*8-5)*scale, y*scale, (longest*8+5)*scale, (actualy-y+height)*scale}
		
		love.graphics.setScissor(unpack(scissor))
		
		local c = UI.COL.panel
		love.graphics.setColor(c[1], c[2], c[3], (c[4] or 0.9) * 0.95)
		love.graphics.rectangle("fill", targetrect[1]*scale, targetrect[2]*scale, targetrect[3]*scale, targetrect[4]*scale)
		
		ui_set_color("panel_edge")
		love.graphics.rectangle("line", (targetrect[1]+1)*scale, (targetrect[2]+1)*scale, (targetrect[3]-2)*scale, (targetrect[4]-2)*scale)
		
		love.graphics.setColor(v["color"])
		properprint(text, (targetrect[1]+2)*scale, (actualy+3)*scale)
		y = actualy+height
		love.graphics.setScissor()
	end
	
	love.graphics.setColor(1, 1, 1)
end
