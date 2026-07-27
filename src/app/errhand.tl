--[[ love.errhand — crash screen (extracted from main.lua) ]]

function love.errhand(msg)
	msg = tostring(msg)

	local trace = debug.traceback()

	local err = {}

	table.insert(err, "FLAGRANT SYSTEM ERROR\n")
	table.insert(err, "Mari0 Over.")
	table.insert(err, "Crash = Very Yes.\n\n")
	if not versionerror then
		table.insert(err, "Tell us what happened at github.com/Mari0-CE/Mari0-Community-Edition/issues, that'd be swell.\nAlso send us a screenshot.\n")
	end
	table.insert(err, "Mari0 " .. tostring(marioversion or "UNKNOWN") .. ", LOVE " .. tostring(love._version or "UNKNOWN") .. " running on " .. tostring(love._os or "UNKNOWN") .. "\n")
	if love.graphics.getRendererInfo then
		local info = {love.graphics.getRendererInfo()}
		err[#err] = err[#err].."Graphics: "..info[1].." "..info[2].." ("..info[4]..", "..info[3]..")\n"
	end
	table.insert(err, (msg as string).."\n\n")

	if not versionerror then
		for l in string.gmatch(trace, "(.-)\n") do
			if not string.match(l, "boot.lua") then
				l = string.gsub(l, "stack traceback:", "Traceback\n")
				table.insert(err, l)
			end
		end
	end

	for m,p in ipairs(err) do
		print(p)
	end
	--error_printer(msg, 2)

	if versionerror then
		-- The rest of this code will only run on 0.9.0+.
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	local scale = scale or 2

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
	if love.joystick and love.joystick.getJoysticks then -- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end
	love.graphics.reset()
	love.graphics.setBackgroundColor(89 / 255, 157 / 255, 220 / 255)
	local font = love.graphics.setNewFont(scale*7)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.origin()
	--love.graphics.clear()

	local p = table.concat(err, "\n")

	p = string.gsub(p, "\t", "")
	p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

	local function draw()
		--love.graphics.clear()
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf(p, 35*scale, 15*scale-1, love.graphics.getWidth() - 35*scale)
		love.graphics.printf(p, 35*scale+1, 15*scale, love.graphics.getWidth() - 35*scale)
		love.graphics.printf(p, 35*scale-1, 15*scale, love.graphics.getWidth() - 35*scale)
		love.graphics.printf(p, 35*scale, 15*scale+1, love.graphics.getWidth() - 35*scale)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(p, 35*scale, 15*scale, love.graphics.getWidth() - 35*scale)
		love.graphics.present()
	end

	draw()

	while true do
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return
			end
			if e == "keypressed" and a == "escape" then
				return
			end
		end

		--love.graphics.present()

		if love.timer then
			love.timer.sleep(0.03)
		end
	end
end
