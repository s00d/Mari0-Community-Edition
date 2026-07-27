--[[ Early boot: helpers + Logger / AssetStore / Gamestate / World.
     Called from love.load before the bulk require block.
]]

local Boot = {} as BootModule

function Boot.setup_core_helpers()
	require("core.stringutil")
	require("core.mathutil")
	require("core.tableutil")
end

function Boot.setup_services(debugprints: any, music_type: any): LoggerModule, AssetStore, GamestateModule, World, AssetStore, World
	local LoggerMod = require("app.logger") as LoggerModule
	LoggerMod.set_level(debugprints and "debug" or "info")
	local AssetStoreMod = require("assets.store") as AssetStore
	local GamestateMod = require("app.gamestate") as GamestateModule
	local WorldMod = require("world.session") as World
	local assets = AssetStoreMod.new((music_type or "stream") as string)
	local session = WorldMod.new()
	return LoggerMod, AssetStoreMod, GamestateMod, WorldMod, assets, session
end

function Boot.run_early(debugprints: any, music_type: any): LoggerModule, AssetStore, GamestateModule, World, AssetStore, World
	Boot.setup_core_helpers()
	local LoggerMod, AssetStoreMod, GamestateMod, WorldMod, assets, session = Boot.setup_services(debugprints, music_type)
	rawset(_G, "Logger", LoggerMod)
	rawset(_G, "AssetStore", AssetStoreMod)
	rawset(_G, "Gamestate", GamestateMod)
	rawset(_G, "World", WorldMod)
	rawset(_G, "assets", assets)
	rawset(_G, "session", session)
	LoggerMod.info("Loading Mari0 SE!")
	LoggerMod.info("=======================")
	return LoggerMod, AssetStoreMod, GamestateMod, WorldMod, assets, session
end


function Boot.require_game()
	--require ALL the files!
	
	require "assets.shaders"
	require "app.variables"
	require "core.tilekey"
	require "world.zones"
	require "world.globstate"
	require "world.bounceutil"
	require "core.listutil"
	require "core.gcpace"
	require "core.keepalive"
	gcpace_configure()
	require "util.updateutil"
	require "physics.late"
	require "physics.convert"
	require "physics.dir"
	require "physics.emance"
	require "core.maputil"
	require "util.playerutil"
	require "util.hatutil"
	require "util.portalutil"
	require "util.scrollutil"
	require "world.geltypes"
	require "world.gelreact"
	require "util.geldraw"
	require "util.enemyutil"
	require "world.spawnregistry"
	require "world.levelio"
	require "world.endless_gen"
	require "world.entity_remap"
	require "world.mappack_convert"
	require "util.userectutil"
	require "physics.collision"
	require "physics.checkrect"
	require "physics.portal"
	require "physics.handlegroup"
	require "physics.update"
	sha1 = require("sha1") as function(string): string
	-- camera kept for API compatibility; attach/detach unused (scrollutil handles view)
	require "app.camera"
	
	require "entities.animatedquad"
	require "ui.intro"
	require "util.menuutil"
	require "ui.menu"
	require "ui.levelscreen"
	require "app.game_update"
	require "app.draw_stencil"
	require "app.game_draw"
	require "app.game_load"
	require "app.game_runtime_globals"
	require "app.game_spawn"
	require "app.game_portal"
	require "weapons"
	require "util.editorutil"
	require "ui.editor"
	require "ui.animationguiline"
	require "physics"
	require "world.quad"
	require "world.entitylist"
	require "entities.portalwall"
	require "world.tile"
	require "entities.marioforms"
	require "entities.mario"
	require "entities.hatconfigs"
	require "entities.bighatconfigs"
	require "entities.customhats"
	require "entities.coinblockanimation"
	require "entities.scrollingscore"
	require "entities.scrollingtext"
	require "entities.platform"
	require "entities.platformspawner"
	require "entities.portalparticle"
	require "entities.portalprojectile"
	require "entities.box"
	require "entities.iceblock"
	require "entities.emancipationgrill"
	require "entities.door"
	require "entities.button"
	require "entities.groundlight"
	require "entities.wallindicator"
	require "entities.walltimer"
	require "entities.lightbridge"
	require "entities.faithplate"
	require "entities.laser"
	require "entities.laserdetector"
	require "entities.gel"
	require "entities.geldispenser"
	require "entities.cubedispenser"
	require "entities.pushbutton"
	require "entities.screenboundary"
	require "entities.bulletbill"
	require "entities.fireball"
	require "entities.gravityball"
	require "entities.hook"
	require "ui.gui"
	require "entities.blockdebris"
	require "entities.firework"
	require "entities.castlefire"
	require "entities.fire"
	require "entities.bowser"
	require "entities.vine"
	require "entities.spring"
	require "entities.seesaw"
	require "entities.seesawplatform"
	require "entities.bubble"
	require "entities.rainboom"
	require "entities.miniblock"
	require "entities.notgate"
	require "entities.rsflipflop"
	require "entities.andgate"
	require "entities.orgate"
	require "entities.musicentity"
	require "entities.enemyspawner"
	require "assets.musicloader"
	require "entities.magic"
	require "entities.ceilblocker"
	require "entities.funnel"
	require "entities.panel"
	require "ui.rightclickmenu"
	require "entities.emancipateanimation"
	require "entities.emancipationfizzle"
	require "entities.textentity"
	require "entities.squarewave"
	require "entities.scaffold"
	require "world.animation"
	require "world.animationsystem"
	require "entities.regiondrag"
	require "entities.regiontrigger"
	require "entities.zgbooltrigger"
	require "entities.zginttrigger"
	require "entities.checkpoint"
	require "entities.portal"
	require "entities.portalent"
	require "entities.pedestal"
	require "entities.actionblock"
	require "entities.animationtrigger"
	require "entities.dialogbox"
	require "entities.itemanimation"
	require "entities.animatedtimer"
	require "entities.animatedbooltimer"
	require "entities.animatedtiletrigger"
	require "entities.delayer"
	require "entities.entitylistitem"
	require "entities.entitytooltip"
	
	require "entities.enemy"
	require "entities.enemies"
	require "ui.lobby"
	require "ui.onlinemenu"
	require "net.facade"
	require "net.session"
	add("Requires")

end


function Boot.load_media()
	--IMAGES-- (via AssetStore; still exported as legacy *img globals)
	overwrittenimages = {}
	local function boot_image(id: string, global_name: string)
		local path = "assets/graphics/" .. id .. ".png"
		assets:register_image(id, path)
		rawset(_G, global_name, assets:get_image(id))
	end
	imagelist = {"blockdebris", "coinblockanimation", "coinanimation", "coinblock", "coin", "axe", "spring", "toad", "peach", "platform", 
	"platformbonus", "scaffold", "seesaw", "vine", "bowser", "decoys", "box", "flag", "castleflag", "bubble", "fizzle", "emanceparticle", "emanceside", "doorpiece", "doorcenter", 
	"button", "pushbutton", "wallindicator", "walltimer", "lightbridge", "lightbridgeglow", "lightbridgeside", "laser", "laserside", "excursionbase", "excursionfunnel", "excursionfunnel2", "excursionfunnelend", 
	"excursionfunnelend2", "faithplateplate", "laserdetector", "gel1", "gel2", "gel3", "gel4", "gel5", "gel1ground", "gel2ground", "gel3ground", "gel4ground", "geldispenser", "cubedispenser", "panel", "pedestalbase",
	"pedestalgun", "actionblock", "portal", "markbase", "markoverlay", "andgate", "notgate", "orgate", "squarewave", "rsflipflop", "portalglow", "fireball", "musicentity", "smbtiles", "portaltiles",
	"animatedtiletrigger", "delayer", "title", "menuselect"}
	
	for _, v in ipairs(imagelist) do
		local path = "assets/graphics/DEFAULT/" .. v .. ".png"
		assets:register_image(v, path)
		local img = assets:get_image(v)
		(_G as {string:any})["default" .. (v as string) .. "img"] = img
		(_G as {string:any})[(v as string) .. "img"] = img
	end

	gelgroundimgs = {}
	for gid = 1, GEL_MAX_ID do
		gelgroundimgs[gid] = (_G as {string:any})["gel" .. tostring(gid) .. "groundimg"] as Image
	end
	
	boot_image("mappackback", "mappackback")
	boot_image("mappacknoicon", "mappacknoicon")
	boot_image("mappackoverlay", "mappackoverlay")
	boot_image("mappackhighlight", "mappackhighlight")
	boot_image("mappackscrollbar", "mappackscrollbar")
	
	--tiles
	tilequads = {}
	rgblist = {}
	
	--add smb tiles
	local imgwidth, imgheight = smbtilesimg:getWidth(), smbtilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata = love.image.newImageData("assets/graphics/DEFAULT/smbtiles.png")
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads as {any}, quad:new(smbtilesimg, imgdata, x, y, imgwidth, imgheight) as TileQuad)
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
		end
	end
	smbtilecount = width*height
	
	--add portal tiles
	local imgwidth, imgheight = portaltilesimg:getWidth(), portaltilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata = love.image.newImageData("assets/graphics/DEFAULT/portaltiles.png")
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads as {any}, quad:new(portaltilesimg, imgdata, x, y, imgwidth, imgheight) as TileQuad)
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r / LOVE_COLOR_MAX, g / LOVE_COLOR_MAX, b / LOVE_COLOR_MAX})
		end
	end
	portaltilecount = width*height
	
	--add entities
	boot_image("entities", "entitiesimg")
	entityquads = {}
	local imgwidth, imgheight = entitiesimg:getWidth(), entitiesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local _ = love.image.newImageData("assets/graphics/entities.png")
	
	for y = 1, height do
		for x = 1, width do
			table.insert(entityquads as {any}, entity:new(entitiesimg, x, y, imgwidth, imgheight) as EntityQuad)
			entityquads[#entityquads]:sett(#entityquads)
		end
	end
	entitiescount = width*height
	
	boot_image("smallfont", "fontimage2")
	numberglyphs = "012458"
	font2quads = {}
	for i = 1, 6 do
		font2quads[string.sub(numberglyphs, i, i)] = love.graphics.newQuad((i-1)*4, 0, 4, 8, 24, 8)
	end
	
	boot_image("oneuptext", "oneuptextimage")
	
	boot_image("linktoolpointer", "linktoolpointerimg")
	
	blockdebrisquads = {} as {any:{any:any}}
	for y = 1, 4 do
		(blockdebrisquads as {any:{any:any}})[y] = {} as {any:any}
		for x = 1, 2 do
			(blockdebrisquads as {any:{any:any}})[y][x] = love.graphics.newQuad((x-1)*8, (y-1)*8, 8, 8, 16, 32)
		end
	end
	
	coinblockanimationquads = {}
	for i = 1, 30 do
		coinblockanimationquads[i] = love.graphics.newQuad((i-1)*8, 0, 8, 52, 256, 64)
	end
	
	coinanimationquads = {} as {any:{any:any}}
	for j = 1, 4 do
		coinanimationquads[j] = {} as {any:any}
		for i = 1, 5 do
			coinanimationquads[j][i] = love.graphics.newQuad((i-1)*5, (j-1)*8, 5, 8, 25, 32)
		end
	end
	
	--coinblock
	coinblockquads = {} as {any:{any:any}}
	for j = 1, 4 do
		coinblockquads[j] = {} as {any:any}
		for i = 1, 5 do
			coinblockquads[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*16, 16, 16, 80, 64)
		end
	end
	
	--coin
	coinquads = {} as {any:{any:any}}
	for j = 1, 4 do
		coinquads[j] = {} as {any:any}
		for i = 1, 5 do
			coinquads[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*16, 16, 16, 80, 64)
		end
	end
	
	--axe
	axequads = {} as {any:any}
	for i = 1, 5 do
		axequads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 80, 16)
	end
	
	--spring
	springquads = {} as {any:{any:any}}
	for i = 1, 4 do
		springquads[i] = {} as {any:any}
		for j = 1, 3 do
			springquads[i][j] = love.graphics.newQuad((j-1)*16, (i-1)*31, 16, 31, 48, 124)
		end
	end
	
	seesawquad = {} as {any:any}
	for i = 1, 4 do
		seesawquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end
	
	boot_image("playerselectarrow", "playerselectimg")
	
	starquad = {} as {any:any}
	for i = 1, 4 do
		starquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end
	
	flowerquad = {} as {any:any}
	for i = 1, 4 do
		flowerquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end
	
	fireballquad = {} as {number:any}
	for i = 1, 4 do
		fireballquad[i] = love.graphics.newQuad((i-1)*8, 0, 8, 8, 80, 16)
	end
	
	for i = 5, 7 do
		fireballquad[i] = love.graphics.newQuad((i-5)*16+32, 0, 16, 16, 80, 16)
	end
	
	vinequad = {} as {any:{any:any}}
	for i = 1, 4 do
		vinequad[i] = {} as {any:any}
		for j = 1, 2 do
			vinequad[i][j] = love.graphics.newQuad((j-1)*16, (i-1)*16, 16, 16, 32, 64) 
		end
	end
	
	--enemies
	goombaquad = {} as {any:{any:any}}
	
	for y = 1, 4 do
		goombaquad[y] = {} as {any:any}
		for x = 1, 2 do
			goombaquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*16, 16, 16, 32, 64)
		end
	end
		
	spikeyquad = {} as {any:{any:any}}
	for y = 1, 4 do
		spikeyquad[y] = {} as {any:any}
		for x = 1, 4 do
			spikeyquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*16, 16, 16, 64, 64)
		end
	end
	
	lakitoquad = {}
	for y = 1, 4 do
		lakitoquad[y] = {} as {any:any}
		for x = 1, 2 do
			lakitoquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*24, 16, 24, 32, 96)
		end
	end
	
	koopaquad = {}
	
	for y = 1, 4 do
		koopaquad[y] = {} as {any:any}
		for x = 1, 5 do
			koopaquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*24, 16, 24, 80, 96)
		end
	end
	cheepcheepquad = {}
	
	cheepcheepquad[1] = {} as {any:any}
	cheepcheepquad[1][1] = love.graphics.newQuad(0, 0, 16, 16, 32, 32)
	cheepcheepquad[1][2] = love.graphics.newQuad(16, 0, 16, 16, 32, 32)
	
	cheepcheepquad[2] = {} as {any:any}
	cheepcheepquad[2][1] = love.graphics.newQuad(0, 16, 16, 16, 32, 32)
	cheepcheepquad[2][2] = love.graphics.newQuad(16, 16, 16, 16, 32, 32)
	
	squidquad = {}
	for x = 1, 2 do
		squidquad[x] = love.graphics.newQuad((x-1)*16, 0, 16, 24, 32, 24)
	end
	
	bulletbillquad = {}
	
	for y = 1, 4 do
		bulletbillquad[y] = love.graphics.newQuad(0, (y-1)*16, 16, 16, 16, 64)
	end
	
	hammerbrosquad = {}
	for y = 1, 4 do
		hammerbrosquad[y] = {} as {any:any}
		for x = 1, 4 do
			hammerbrosquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*34, 16, 34, 64, 136)
		end
	end	
	
	hammerquad = {}
	for j = 1, 4 do
		hammerquad[j] = {}
		for i = 1, 4 do
			hammerquad[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*16, 16, 16, 64, 64)
		end
	end
	
	plantquads = {}
	for j = 1, 4 do
		plantquads[j] = {} as {any:any}
		for i = 1, 2 do
			plantquads[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*23, 16, 23, 32, 92)
		end
	end
	
	firequad = {love.graphics.newQuad(0, 0, 24, 8, 48, 8), love.graphics.newQuad(24, 0, 24, 8, 48, 8)}
	
	
	bowserquad = {}
	bowserquad[1] = {love.graphics.newQuad(0, 0, 32, 32, 64, 64), love.graphics.newQuad(32, 0, 32, 32, 64, 64)}
	bowserquad[2] = {love.graphics.newQuad(0, 32, 32, 32, 64, 64), love.graphics.newQuad(32, 32, 32, 32, 64, 64)}
	
	decoysquad = {}
	for y = 1, 7 do
		decoysquad[y] = love.graphics.newQuad(0, (y-1)*32, 32, 32, 64, 256)
	end
	
	boxquad = {love.graphics.newQuad(0, 0, 12, 12, 32, 16), love.graphics.newQuad(16, 0, 12, 12, 32, 16)}
	
	--eh
	boot_image("rainboom", "rainboomimg")
	rainboomquad = {}
	for x = 1, 7 do
		for y = 1, 7 do
			rainboomquad[x+(y-1)*7] = love.graphics.newQuad((x-1)*204, (y-1)*182, 204, 182, 1428, 1274)
		end
	end
	
	--magic!
	boot_image("magic", "magicimg")
	magicquad = {}
	for x = 1, 6 do
		magicquad[x] = love.graphics.newQuad((x-1)*9, 0, 9, 9, 54, 9)
	end
	
	--GUI
	boot_image("checkbox", "checkboximg")
	checkboxquad = {{love.graphics.newQuad(0, 0, 9, 9, 18, 18), love.graphics.newQuad(9, 0, 9, 9, 18, 18)}, {love.graphics.newQuad(0, 9, 9, 9, 18, 18), love.graphics.newQuad(9, 9, 9, 9, 18, 18)}}
	
	boot_image("dropdownarrow", "dropdownarrowimg")
	
	--portals
	portalquad = {}
	for i = 0, 7 do
		portalquad[i] = love.graphics.newQuad(0, i*4, 32, 4, 32, 28)
	end
	
	boot_image("portalparticle", "portalparticleimg")
	boot_image("portalcrosshair", "portalcrosshairimg")
	boot_image("portaldot", "portaldotimg")
	boot_image("portalprojectile", "portalprojectileimg")
	boot_image("portalprojectileparticle", "portalprojectileparticleimg")
	boot_image("portalbackground", "portalbackgroundimg")
	
	--Menu shit
	boot_image("huehuehuebar", "huebarimg")
	boot_image("huebarmarker", "huebarmarkerimg")
	boot_image("volumeslider", "volumesliderimg")
	
	--Portal props	
	buttonquad = {love.graphics.newQuad(0, 0, 32, 5, 64, 5), love.graphics.newQuad(32, 0, 32, 5, 64, 5)}
	
	pushbuttonquad = {love.graphics.newQuad(0, 0, 16, 16, 32, 16), love.graphics.newQuad(16, 0, 16, 16, 32, 16)}
	
	wallindicatorquad = {love.graphics.newQuad(0, 0, 16, 16, 32, 16), love.graphics.newQuad(16, 0, 16, 16, 32, 16)}
	
	walltimerquad = {}
	for i = 1, 10 do
		walltimerquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 160, 16)
	end
	
	boot_image("directions", "directionsimg")
	directionsquad = {}
	for x = 1, 6 do
		directionsquad[x] = love.graphics.newQuad((x-1)*7, 0, 7, 7, 42, 7)
	end
	
	excursionquad = {}
	for x = 1, 8 do
		excursionquad[x] = love.graphics.newQuad((x-1)*8, 0, 8, 32, 64, 32)
	end
	
	faithplatequad = {love.graphics.newQuad(0, 0, 32, 16, 32, 32), love.graphics.newQuad(0, 16, 32, 16, 32, 32)}
	
	gelquad = {love.graphics.newQuad(0, 0, 12, 12, 36, 12), love.graphics.newQuad(12, 0, 12, 12, 36, 12), love.graphics.newQuad(24, 0, 12, 12, 36, 12)}
	
	boot_image("gradient", "gradientimg"); gradientimg:setFilter("linear", "linear")
	
	panelquad = {}
	for x = 1, 2 do
		panelquad[x] = love.graphics.newQuad((x-1)*16, 0, 16, 16, 32, 16)
	end
	
	add("Images, quads")
	
	--AUDIO--
	--sounds
	soundstoload = {"jump", "jumpbig", "stomp", "shot", "blockhit", "blockbreak", "coin", "pipe", "boom", "mushroomappear", "mushroomeat", "shrink", "death", "gameover", "fireball",
					"oneup", "levelend", "castleend", "scorering", "intermission", "fire", "bridgebreak", "bowserfall", "vine", "swim", "rainboom", "konami", "pause", "bulletbill",
					"lowtime", "tailwag", "planemode", "stab", "portal1open", "portal2open", "portalenter", "portalfizzle", "pushbutton"}

	defaultsoundslist = {}
	overwrittensounds = {}	
	soundlist = {}
	
	for _, v in ipairs(soundstoload) do
		assets:register_sound(v, "assets/sounds/" .. v .. ".ogg")
		local src = assets:get_sound(v) as SoundSource
		soundlist[v] = {}
		soundlist[v].source = src
		soundlist[v].lastplayed = 0
		defaultsoundslist[v] = src
	end
	
	soundlist["scorering"].source:setLooping(true)
	soundlist["planemode"].source:setLooping(true)
	soundlist["portal1open"].source:setVolume(0.3)
	soundlist["portal2open"].source:setVolume(0.3)
	soundlist["portalenter"].source:setVolume(0.3)
	soundlist["portalfizzle"].source:setVolume(0.3)
	
	delaylist = {}
	delaylist["blockhit"] = 0.2
	
	musicname = "overworld.ogg"
	
	add("Sounds")

end


local function try_load_http(): HttpLib, boolean
	local req = require as function(string): any
	local ok_http, mod = pcall(req, "socket.http")
	local ok_ssl = pcall(req, "ssl.https")
	if ok_http and ok_ssl then
		return mod as HttpLib, false
	end
	-- LÖVE 12 may not bundle lua-socket/ssl; stub keeps startup alive.
	return {
		PORT = 55555,
		TIMEOUT = 1,
		request = function(_url: string): nil, number
			return nil, 0
		end,
	} as HttpLib, true
end

function Boot.run_load()
	Boot.require_game()
	
	local http_mod: HttpLib
	local stub: boolean
	http_mod, stub = try_load_http()
	http = http_mod
	rawset(_G, "http_is_stub", stub)
	http.PORT = 55555
	http.TIMEOUT = 1
	
	updatenotification = false
	if getupdate() then
		updatenotification = true
	end
	http.TIMEOUT = 4
	
	playertypei = 1
	playertype = playertypelist[playertypei as integer] --portal, gelcannon
	
	if volumesfx == 0 then
		soundenabled = false
	else
		soundenabled = true
	end
	love.filesystem.createDirectory( "mappacks" )
	love.filesystem.createDirectory( "toconvert" )
	editormode = false
	yoffset = 0
	love.graphics.setPointSize(3*scale)
	love.graphics.setLineWidth(2*scale)
	
	uispace = math.floor(width*16*scale/4)
	guielements = {}
	
	--limit hats
	for playerno = 1, players do
		for i = 1, #mariohats[playerno] do
			if (mariohats[playerno][i] as number) > hatcount then
				mariohats[playerno][i] = hatcount
			end
		end
	end
	
	--Backgroundcolors
	backgroundcolor = {
						{92 / 255,	148 / 255,	252 / 255},
						{0 / 255,	0 / 255,	0 / 255},
						{32 / 255,	56 / 255,	236 / 255},
						{158 / 255,	219 / 255,	248 / 255},
						{210 / 255,	159 / 255,	229 / 255},
						{237 / 255,	241 / 255,	243 / 255},
						{244 / 255,	178 / 255,	92 / 255},
						{253 / 255,	246 / 255,	175 / 255},
						{249 / 255,	183 / 255,	206 / 255},
					}
	add("Update Check, variables")
	

	Boot.load_media()
	shaders:init()
	add("Shaders init")
	for _, v in ipairs(dlclist) do
		delete_mappack(v)
	end

	Boot.register_gamestates()
end

function Boot.register_gamestates()
	if not Gamestate then
		return
	end
	-- Menu family shares menu_update/draw
	for _, name in ipairs({"menu", "mappackmenu", "onlinemenu", "options", "lobby"}) do
		(Gamestate.register as function(...: any): any)(name, {update = menu_update, draw = menu_draw})
	end
	for _, name in ipairs({"levelscreen", "gameover", "sublevelscreen", "mappackfinished"}) do
		(Gamestate.register as function(...: any): any)(name, {update = levelscreen_update, draw = levelscreen_draw})
	end
	(Gamestate.register as function(...: any): any)("game", {update = game_update, draw = game_draw})
	(Gamestate.register as function(...: any): any)("intro", {update = intro_update, draw = intro_draw})
	-- Editor draws/updates inside game when editormode; register for future routing
	if editor_update and editor_draw then
		(Gamestate.register as function(...: any): any)("editor", {update = editor_update, draw = editor_draw})
	end
end

_G.Boot = Boot
return Boot
