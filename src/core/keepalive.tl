--[[ Keep the window responsive during long sync work (level load).

Symptom: level 1→2 hangs until minimize/restore. Heavy loadlevel runs inside
love.update with no event pump; Love 12 + Metal can stall on texture uploads /
present until the window focus cycle flushes the GPU.

Call keepalive_pump() between heavy chunks so love.event.pump + a blank present
run, and focus/quit still work.
]]

global function keepalive_pump()
	if not love or not love.event then
		return
	end

	love.event.pump()
	for e, a, b, c, d in love.event.poll() do
		if e == "quit" then
			if not (love.quit and love.quit()) then
				if love.audio then
					love.audio.stop()
				end
				-- Signal outer love.run via a synthetic quit; fall through to handlers.
				if love.handlers and love.handlers.quit then
					love.handlers.quit(a)
				end
			end
		elseif love.handlers and love.handlers[e] then
			love.handlers[e](a, b, c, d)
		end
	end

	-- Blank present: flushes Metal/GL and shows the window is alive.
	if love.graphics and love.graphics.isActive and love.graphics.isActive() then
		love.graphics.origin()
		love.graphics.clear(0, 0, 0, 1)
		love.graphics.present()
	elseif love.timer then
		love.timer.sleep(0.001)
	end
end

return {
	pump = keepalive_pump,
}
