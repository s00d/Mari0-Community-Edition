--[[ Runtime defaults for globals written during game_load / loadlevel / levelscreen.
     Must run before the post-boot _G write guard snapshots globals.
     Do not assign nil here: in Lua that removes the key from _G, so freeze will
     block later writes (e.g. objects = nil in game_load). Use false or {} instead. ]]

global function init_game_runtime_globals()
	-- game_load
	checkpointx = {}
	checkpointy = {}
	checkpointsub = false
	scrollfactor = 0
	fscrollfactor = 0
	mariocoincount = 0
	marioscore = 0
	globools = {}
	globints = {}
	firstunder100 = true
	mariolivecount = 3
	mariolives = {}
	mariosizes = {}
	autoscroll = true
	autoscrollx = true
	autoscrolly = true
	minimapdragging = false
	jumpitems = { "mushroom", "oneup" }
	marioworld = 1
	mariolevel = 1
	mariosublevel = 0
	respawnsublevel = 0
	local objs, pobjs = fresh_objects()
	objects = objs
	playerobjs = pobjs as {any:mario}
	musicname = ""

	-- loadlevel (misc + class tables)
	everyonedead = false
	levelfinished = false
	coinanimation = 1
	flagx = false
	levelfinishtype = ""
	firestartx = false
	firestarted = false
	firedelay = 4
	flyingfishdelay = 1
	flyingfishstarted = false
	flyingfishstartx = false
	flyingfishendx = false
	flyingfishstarts = {}
	flyingfishends = {}
	flyingfishzones = {}
	bulletbilldelay = 1
	bulletbillstarted = false
	bulletbillstartx = false
	bulletbillendx = false
	bulletbillstarts = {}
	bulletbillends = {}
	bulletbillzones = {}
	firetimer = firedelay
	flyingfishtimer = flyingfishdelay
	bulletbilltimer = bulletbilldelay
	axex = false
	axey = false
	lakitoendx = false
	lakitoend = false
	noupdate = false
	xscroll = 0
	yscroll = 0
	repeatX = 0
	lastrepeat = 0
	ylookmodifier = 0
	displaywarpzonetext = false
	mazestarts = {}
	mazeends = {}
	mazesolved = {}
	mazesolved[0] = true
	mazeinprogress = false
	mazegates = {}
	earthquake = 0
	sunrot = 0
	gelcannontimer = 0
	pausemenuselected = 1
	coinblocktimers = {}
	portaldelay = {}
	for i = 1, players do
		portaldelay[i] = 0
	end
	coinblockanimations = {}
	scrollingscores = {}
	scrollingtexts = {}
	portalparticles = {}
	portalprojectiles = {}
	emancipationgrills = {}
	platformspawners = {}
	rocketlaunchers = {}
	userects = {}
	blockdebristable = {}
	fireworks = {}
	seesaws = {}
	bubbles = {}
	rainbooms = {}
	emancipateanimations = {}
	emancipationfizzles = {}
	textentities = {}
	pedestals = {}
	dialogboxes = {}
	miniblocks = {}
	inventory = {}
	for i = 1, 9 do
		inventory[i] = {}
	end
	mccurrentblock = 1
	itemanimations = {}
	blockbouncetimer = {}
	blockbouncex = {}
	blockbouncey = {}
	blockbouncecontent = {}
	blockbouncecontent2 = {}
	spritebatch_portal_catchup = false
	warpzonenumbers = {}
	portals = {}
	map = {}
	coinmap = {}
	mapwidth = 0
	mapheight = 0
	startx = {3, 3, 3, 3, 3}
	starty = {13, 13, 13, 13, 13}
	rawset(_G, "pipestartx", false)
	rawset(_G, "pipestarty", false)
	enemiesspawned = {}
	intermission = false
	haswarpzone = false
	underwater = false
	bonusstage = false
	custombackground = false
	customforeground = false
	mariotimelimit = 400
	mariotime = 400
	spriteset = 1
	prevsublevel = false
	spawnrestrictions = {}
	portalsavailable = {true, true}
	background = {}

	-- levelscreen / spawn / levelio
	blacktime = 0
	livesleft = false
	levelscreentimer = 0
	sublevelscreen_level = 0
	coinframe = 1
	allowenemy = true
	animatedbooltimers = {}
	animatedtimers = {}
	levelscreenback = false
	levelscreenbackname = false
	rawset(_G, "previewimg", false)
	unstatics = {}
	yadd = 0
end
