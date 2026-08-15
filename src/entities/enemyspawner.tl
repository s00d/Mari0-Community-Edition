--[[ Teal port of root enemyspawner.lua ]]

rawset(_G, "enemyspawner", rawget(_G, "enemyspawner") or {})

function enemyspawner.new(_: enemyspawner, x: number, y: number, r: {any}): enemyspawner
	local self = setmetatable({}, { __index = enemyspawner }) as enemyspawner
	self:init(x, y, r)
	return self
end

function enemyspawner:init(x: number, y: number, r)
	self.x = x
	self.y = y
	self.cox = x
	self.coy = y
	self.r = {unpack(r as {any})}
	self.xspeed = 0
	self.yspeed = 0
	self.enemytospawn = "goomba"
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	
	--ENEMY NAME
	if #self.r > 0 and self.r[1] ~= "link" then
		self.enemytospawn = self.r[1] as string
		table.remove(self.r, 1)
	end
	
	--Xspeed
	if #self.r > 0 then
		local xs = self.r[1] as string
		if string.sub(xs, 1, 1) == "m" then
			self.xspeed = -tonumber(string.sub(xs, 2))
		else
			self.xspeed = tonumber(xs)
		end
		table.remove(self.r, 1)
	end
	
	--Yspeed
	if #self.r > 0 then
		local ys = self.r[1] as string
		if string.sub(ys, 1, 1) == "m" then
			self.yspeed = -tonumber(string.sub(ys, 2))
		else
			self.yspeed = tonumber(ys)
		end
		table.remove(self.r, 1)
	end
end

function enemyspawner:link(): any|nil
	while #self.r > 3 do
		for _, w in pairs(outputs) do
			for _, v in pairs(session.objects[w]) do
				if tonumber(self.r[3]) == v.cox and tonumber(self.r[4]) == v.coy then
					v:addoutput(self, self.r[2])
				end
			end
		end
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
	end
	return nil
end

function enemyspawner:input(t, _): any
	if t ~= "off" then
		if enemiesdata[self.enemytospawn] then
			local temp = enemy:new(self.cox, self.coy, self.enemytospawn, {session.map[self.cox][self.coy][1], self.enemytospawn})
			obj_insert("enemy", temp as Entity)
			temp.speedx = self.xspeed
			temp.speedy = self.yspeed
		end
	end
	return nil
end