--[[ Teal port of root camera.lua — handbook `global record` (not middleclass). ]]

rawset(_G, "camera", rawget(_G, "camera") or {})

--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local cos, sin = math.cos, math.sin

function camera.new(_: camera, x: number|nil, y: number|nil, zoom: number|nil, rot: number|nil): camera
	local self = setmetatable({}, { __index = camera }) as camera
	self:init(x, y, zoom, rot)
	return self
end

function camera:init(x: number|nil, y: number|nil, zoom: number|nil, rot: number|nil)
	x, y = x or love.graphics.getWidth()/2, y or love.graphics.getHeight()/2
	zoom = zoom or 1
	rot = rot or 0
	self.x = x
	self.y = y
	self.scale = zoom
	self.rot = rot
end

function camera:lookAt(x: number, y: number): camera
	self.x, self.y = x, y
	return self
end

function camera:move(x: number, y: number): camera
	self.x, self.y = self.x + x, self.y + y
	return self
end

function camera:pos(): number, number
	return self.x, self.y
end

function camera:rotate(phi: number): camera
	self.rot = self.rot + phi
	return self
end

function camera:rotateTo(phi: number): camera
	self.rot = phi
	return self
end

function camera:zoom(mul: number): camera
	self.scale = self.scale * mul
	return self
end

function camera:zoomTo(zoom: number): camera
	self.scale = zoom
	return self
end

function camera:attach()
	local cx, cy = love.graphics.getWidth()/(2*self.scale), love.graphics.getHeight()/(2*self.scale)
	love.graphics.push()
	love.graphics.scale(self.scale)
	love.graphics.translate(cx, cy)
	love.graphics.rotate(self.rot)
	love.graphics.translate(-self.x, -self.y)
end

function camera:detach()
	love.graphics.pop()
end

function camera:draw(func: function())
	self:attach()
	func()
	self:detach()
end

function camera:cameraCoords(x: number, y: number): number, number
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local c, s = cos(self.rot), sin(self.rot)
	x, y = x - self.x, y - self.y
	x, y = c*x - s*y, s*x + c*y
	return x*self.scale + w/2, y*self.scale + h/2
end

function camera:worldCoords(x: number, y: number): number, number
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local c, s = cos(-self.rot), sin(-self.rot)
	x, y = (x - w/2) / self.scale, (y - h/2) / self.scale
	x, y = c*x - s*y, s*x + c*y
	return x+self.x, y+self.y
end

function camera:mousepos(): number, number
	return self:worldCoords(love.mouse.getPosition())
end
