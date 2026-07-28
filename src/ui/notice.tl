--[[ Teal port of root notice.lua ]]

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
	table.insert(notice.notices, {text=(text as string):lower(), color=color, life=duration, duration=duration})
end

function notice.update(dt: number)
	for i = #notice.notices, 1, -1 do
		local v = notice.notices[i] as {any:any}
		v["life"] = (v["life"] as number) - dt
		if (v["life"] as number) <= 0 then
			table.remove(notice.notices, i)
		end
	end
end

function notice.draw()
	local y: number = 0
	for i = #notice.notices, 1, -1 do
		local v = notice.notices[i] as {any:any}
		local text = v["text"] as string
		local life = v["life"] as number
		local duration = v["duration"] as number
		
		--get width by finding longest line
		local split = strsplit(text, "|")
		local longest = #split[1]
		for i = 2, #split do
			if #split[i] > longest then
				longest = #split[i]
			end
		end
		
		local height = #split*10+3
		
		actualy = notice.gety(y, life, height, duration)
		
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

function notice.gety(y: number, life: number, height: number, duration: number): number
	if life > duration-notice.fadetime then
		return y - height*((life-(duration-notice.fadetime))/notice.fadetime)^2
	elseif life < notice.fadetime then
		return y - height*((notice.fadetime-life)/notice.fadetime)^2
	else
		return y
	end
end
