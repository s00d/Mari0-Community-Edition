--[[ love.run extracted from main.lua ]]

function love.run(): function()|nil
	--I can't believe I had to write this function in the first place
	local function updateVersion(): number
		if love.getVersion then
			local major, minor = love.getVersion()
			if major > 0 then
				return major
			else
				return minor
			end
		else
			return love._version_minor
		end
	end

	LOVE_MAJOR = updateVersion()

	-- Love 11.x only (compat for 0.9/0.10 removed).
	LOVE_COLOR_MAX = 1
	DISK_COLOR_MAX = 255
	MUSIC_SOURCE_TYPE = "stream"

	local Rng = require("core.rng")
	local debug_seed: number|nil = nil
	if arg then
		for i = 1, #arg do
			local a = arg[i] as string
			local seed_str = a:match("^%-%-seed=(%d+)$") or a:match("^%-%-seed%-(%d+)$")
			if seed_str then
				debug_seed = tonumber(seed_str)
			end
		end
	end
	Rng.install(debug_seed)
	
	love.load(arg)

	-- Main loop time.
	while true do
		-- Process events.
		love.event.pump()
		for e,a,b,c,d in love.event.poll() do
			if e == "quit" then
				if not love.quit() then
					love.audio.stop()
					return function(): number return (a as number) or 0 end
				end
			end
			love.handlers[e](a,b,c,d)
		end

        -- Update dt, as we'll be passing it to update
		love.timer.step()
		local dt = love.timer.getDelta()

        -- Call update and draw
        love.update(dt) -- will pass 0 if love.timer is disabled
		love.graphics.clear()
		love.graphics.origin()
		--Fullscreen hack (Love 11 canvas + stencil)
		if not mkstation and fullscreen and gamestate ~= "intro" then
			love.graphics.setCanvas{completecanvas, stencil=true}
			love.graphics.clear()
			love.graphics.setScissor()
			love.graphics.setCanvas{completecanvas, stencil=true}
			love.draw()
			love.graphics.setCanvas()

			love.graphics.setScissor()
			love.graphics.setCanvas()
			if fullscreenmode == "full" then
				love.graphics.draw(completecanvas, 0, 0, 0, desktopsize.width/(width*16*scale), desktopsize.height/(height*16*scale))
			else
				love.graphics.draw(completecanvas, 0, touchfrominsidemissing/2, 0, touchfrominsidescaling/scale, touchfrominsidescaling/scale)
				love.graphics.setColor(0, 0, 0)
				love.graphics.rectangle("fill", 0, 0, desktopsize.width, touchfrominsidemissing/2)
				love.graphics.rectangle("fill", 0, desktopsize.height-touchfrominsidemissing/2, desktopsize.width, touchfrominsidemissing/2)
				love.graphics.setColor(1, 1, 1, 1)
			end
		else
			love.graphics.setScissor()
			love.draw()
		end
		
		love.graphics.present()
		love.timer.sleep(0.001)
	end
end
