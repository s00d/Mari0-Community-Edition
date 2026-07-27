--[[ love.load body + scaled mouse helpers (thin main.lua entry). ]]

local LoveLoad = {}

function LoveLoad.install_mouse()
	local mouse = {}

	function mouse.getPosition(): number, number
		if fullscreen then
			if fullscreenmode == "full" then
				return love.mouse.getX() / (desktopsize.width / (width * 16 * scale)), love.mouse.getY() / (desktopsize.height / (height * 16 * scale))
			else
				return love.mouse.getX() / (touchfrominsidescaling / scale), love.mouse.getY() / (touchfrominsidescaling / scale) - touchfrominsidemissing / 2
			end
		else
			return love.mouse.getPosition()
		end
	end

	function mouse.getX(): number
		if fullscreen then
			if fullscreenmode == "full" then
				return love.mouse.getX() / (desktopsize.width / (width * 16 * scale))
			else
				return love.mouse.getX() / (touchfrominsidescaling / scale)
			end
		else
			return love.mouse.getX()
		end
	end

	function mouse.getY(): number
		if fullscreen then
			if fullscreenmode == "full" then
				return love.mouse.getY() / (desktopsize.height / (height * 16 * scale))
			else
				return love.mouse.getY() / (touchfrominsidescaling / scale) - touchfrominsidemissing / 2
			end
		else
			return love.mouse.getY()
		end
	end

	_G.mouse = mouse
end

function LoveLoad.run(_: any)
	marioversion = 1107
	versionstring = "version 1.0se"
	debugprints = false

	local math_ext = math as {string:any}
	math_ext.mod = math.fmod
	math_ext.random = love.math.random

	lastline = debug.getinfo(1).currentline
	starttime = love.timer.getTime()
	totaltime = 0
	Boot = require("app.boot")
	Boot.run_early(debugprints, MUSIC_SOURCE_TYPE or "stream")
	JSON = require("dkjson")
	require("ui.notice")

	local sizes = love.window.getFullscreenModes()
	desktopsize = sizes[1] as DesktopSize

	for i = 2, #sizes do
		local s = sizes[i] as DesktopSize
		if s.width > desktopsize.width or s.height > desktopsize.height then
			desktopsize = s
		end
	end

	recordtarget = 1 / 40
	recordskip = 1
	recordframe = 1

	magicdns_session_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	magicdns_session = ""
	for _ = 1, 8 do
		local rand = math.random(string.len(magicdns_session_chars))
		magicdns_session = magicdns_session .. string.sub(magicdns_session_chars, rand, rand)
	end
	local identity_parts = strsplit(love.filesystem.getSaveDirectory(), "/")
	magicdns_identity = string.upper(identity_parts[#identity_parts])

	shaderlist = love.filesystem.getDirectoryItems("assets/shaders/") as {number:string}
	local rem: integer | nil
	for i, v in pairs(shaderlist) do
		if v == "init.lua" then
			rem = i as integer
		else
			shaderlist[i] = string.sub(v, 1, string.len(v) - 5)
		end
	end

	table.remove(shaderlist, rem)

	table.insert(shaderlist, 1, "none")

	-- Love 11+: scancode keyboard + numeric mouse buttons
	lkisDown = love.keyboard.isDown
	lkisScancodeDown = love.keyboard.isScancodeDown
	lmisDown = love.mouse.isDown
	function love.keyboard.isDown(key: string): boolean
		if key == " " then
			key = "space"
		end
		if lkisScancodeDown then
			return lkisScancodeDown(key) as boolean
		end
		return lkisDown(key) as boolean
	end
	function love.mouse.isDown(button: any): boolean
		if button == "l" then
			button = 1
		elseif button == "r" then
			button = 2
		elseif button == "m" then
			button = 3
		end
		return lmisDown(button) as boolean
	end

	iconimg = love.image.newImageData("assets/graphics/icon.png")
	love.window.setIcon(iconimg)

	love.graphics.setDefaultFilter("nearest", "nearest")

	axisDeadZones = {}
	joysticks = love.joystick.getJoysticks() as {Joystick}
	if #joysticks > 0 then
		for i, v in ipairs(joysticks) do
			axisDeadZones[i] = {}
			for j = 1, v:getAxisCount() do
				(axisDeadZones[i] as {any:any})[j] = {stick=true, shoulder=true}
			end
			for _, j in pairs({ "leftx", "lefty", "rightx", "righty", "triggerleft", "triggerright" } as {number:string}) do
				(axisDeadZones[i] as {any:any})[j] = {stick=true, shoulder=true}
			end
		end
	end

	add("Variables, shaderlist")

	if not pcall(loadconfig) then
		players = 1
		defaultconfig()
		print("== FAILED TO LOAD CONFIG ==")
	end

	physicsdebug = false
	incognito = false
	portalwalldebug = false
	userectdebug = false
	speeddebug = false

	DEBUG = false

	editordebug = DEBUG
	skipintro = DEBUG
	skiplevelscreen = DEBUG
	debugbinds = DEBUG
	frameskip = false

	replaysystem = false
	drawreplays = false
	drawalllinks = false
	bdrawui = true
	skippedframes = 0

	width = 25
	height = 14
	fsaa = 0

	steptimer = 0
	targetdt = 1 / 60

	touchfrominsidescaling = math.min(desktopsize.width / (width * 16), desktopsize.height / (height * 16))
	touchfrominsidemissing = desktopsize.height - height * 16 * touchfrominsidescaling

	add("Variables")
	changescale(scale, true)
	add("Resolution change")
	require("assets.characterloader")
	add("Characterloader")

	dlclist = {}
	hatcount = #love.filesystem.getDirectoryItems("assets/graphics/standardhats")
	saveconfig()
	love.window.setTitle("Mari0: Community Edition")

	love.graphics.setBackgroundColor(0, 0, 0)

	fontimage = love.graphics.newImage("assets/graphics/font.png")
	fontimageback = love.graphics.newImage("assets/graphics/fontback.png")
	fontglyphs = "0123456789abcdefghijklmnopqrstuvwxyz.:/,\"C-_A* !{}?'()+=><#%"
	fontquads = {}
	for i = 1, string.len(fontglyphs) do
		fontquads[string.sub(fontglyphs, i, i)] = love.graphics.newQuad((i - 1) * 8, 0, 7, 8, fontimage:getWidth(), fontimage:getHeight())
	end
	fontquadsback = {}
	for i = 1, string.len(fontglyphs) do
		fontquadsback[string.sub(fontglyphs, i, i)] = love.graphics.newQuad((i - 1) * 10, 0, 10, 10, fontimageback:getWidth(), fontimageback:getHeight())
	end

	love.graphics.clear()
	love.graphics.setColor(0.4, 0.4, 0.4)
	loadingtexts = {
		"reticulating splines", "rendering important stuff", "01110000011011110110111001111001", "sometimes, i dream about cheese",
		"baking cake", "happy explosion day", "raising coolness by a fifth", "yay facepunch", "stabbing myself", "sharpening knives",
		"tanaka, thai kick", "slime will find you", "becoming self-aware", "it's a secret to everybody", "there is no minus world",
		"oh my god, jc, a bomb", "silly loading message here", "motivational art by jorichi", "love.graphics.print(\"loading..\", 200, 120)",
		"you're my favorite deputy", "licensed under wtfpl", "banned in australia", "loading anti-piracy module", "watch out there's a sni",
		"attack while its tail's up!", "what a horrible night to have a curse", "han shot first", "establishing connection to nsa servers..",
		"how do i programm", "making palette inaccurate..", "y cant mario crawl?",
	}

	loadingtext = loadingtexts[math.random(#loadingtexts)]

	if mariocharacter[1] == "rainbow dash-unfinished" then
		logo = love.graphics.newImage("assets/graphics/stabyourselfdash.png")
		logoblood = love.graphics.newImage("assets/graphics/stabyourselfblooddash.png")
	else
		logo = love.graphics.newImage("assets/graphics/stabyourself.png")
		logoblood = love.graphics.newImage("assets/graphics/stabyourselfblood.png")
	end

	local logoscale = scale
	if logoscale <= 1 then
		logoscale = 0.5
	else
		logoscale = 1
	end

	love.graphics.setColor(1, 1, 1)

	love.graphics.draw(logo, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, logoscale, logoscale, 142, 150)
	love.graphics.setColor(0.6, 0.6, 0.6)
	properprint("loading mari0 ce..", love.graphics.getWidth() / 2 - string.len("loading mari0 ce..") * 4 * scale, love.graphics.getHeight() / 2 - 170 * logoscale - 7 * scale)
	love.graphics.setColor(0.2, 0.2, 0.2)
	properprint(loadingtext, love.graphics.getWidth() / 2 - string.len(loadingtext) * 4 * scale, love.graphics.getHeight() / 2 + 165 * logoscale)
	love.graphics.present()

	add("Variables")

	Boot.run_load()

	firstload = true

	if skipintro then
		menu_load()
	else
		intro_load()
	end
	add("Intro Load")

	local GlobalFreeze = require("core.global_freeze")
	GlobalFreeze.install_writes_only()

	print("=======================\nDONE!")
	print("TOTAL: " .. totaltime .. "ms")
end

_G.LoveLoad = LoveLoad
return LoveLoad
