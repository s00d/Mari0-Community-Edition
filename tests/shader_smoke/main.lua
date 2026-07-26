-- Headless Love smoke: compile all assets/shaders/*.frag then quit.
-- Run: make test-shaders

function love.load()
	local dir = "shaders"
	if not love.filesystem.getInfo(dir, "directory") then
		print("FAIL no shaders directory mounted")
		love.event.quit(1)
		return
	end

	local files = love.filesystem.getDirectoryItems(dir)
	local okc, failc = 0, 0
	for _, name in ipairs(files) do
		if name:match("%.frag$") then
			local path = dir .. "/" .. name
			local src = love.filesystem.read(path)
			local ok, err = pcall(function()
				love.graphics.newShader(src)
			end)
			if ok then
				okc = okc + 1
				print("OK  " .. name)
			else
				failc = failc + 1
				print("FAIL " .. name .. ": " .. tostring(err))
			end
		end
	end
	print(string.format("Shaders: %d ok, %d failed", okc, failc))
	love.event.quit(failc > 0 and 1 or 0)
end

function love.draw()
end
