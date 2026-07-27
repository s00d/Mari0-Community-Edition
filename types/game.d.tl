-- Major Mari0 runtime globals for Teal (ambient via love.d.tl → require("game")).
-- Prefer concrete records from entities.d.tl. Narrow `any` only at legacy boundaries.

require("entities")
require("records")

global record MouseProxy
	getX: function(): number
	getY: function(): number
	getPosition: function(): number, number
	isDown: function(...: any): boolean
end



global record GamestateModule
	current: string
	handlers: {any:any}
	register: function(...: any): any
	set: function(...: any): any
	get: function(...: any): any
	update: function(...: any): any
	draw: function(...: any): any
end

global record LoggerModule
	level: string
	info: function(...: any)
	debug: function(...: any)
	warn: function(...: any)
	error: function(...: any)
	set_level: function(string)
end

global record BootModule
	setup_core_helpers: function()
	setup_services: function(any, any): LoggerModule, AssetStore, GamestateModule, World, AssetStore, World
	run_early: function(any, any): LoggerModule, AssetStore, GamestateModule, World, AssetStore, World
	require_game: function()
	load_media: function()
	run_load: function()
	register_gamestates: function()
end

-- Runtime JSON is LuaRocks dkjson (see types/dkjson.d.tl); kept as global JSON.
global record JSONModule
	decode: function(s: string, pos?: integer, nullval?: any): any, integer|nil
	encode: function(val: any, state?: {string:any}): string
	null: any
	version: string
end

-- Map / camera / session
-- Keep open-array escape: MapCell is a Teal array-record (numeric tile slots via `#` / [1],[2],… plus named fields).
global record MapCell is {any}
	portaloverride: {string:any}
	gels: {string:any}
	portal: any
end
-- Pure tile parse result from level_parse_tiles_only (no entities / no LÖVE).
global record LevelTilesParse
	v: integer
	mapwidth: number
	mapheight: number
	map: {number:{number:MapCell}}
	coinmap: {number:{number:boolean}}
	categories: {string}
	equalsign: string
end
global record SelectionTile
	x: number
	y: number
end

global map: {number:{number:MapCell}}
global objects: {any:{any:Entity}}
global playerobjs: {any:mario}
global xscroll: number
global yscroll: number
global mapwidth: number
global mapheight: number
global mariotimer: number
global gamestate: string
global editormode: boolean
global paused: any
global players: integer
global scale: number
global width: number
global height: number
global fullscreen: boolean
global fullscreenmode: string
global record DesktopSize
	width: number
	height: number
end
global desktopsize: DesktopSize
global mappack: string
global currentlevel: string|number|{any:any}

-- Typed session / services (World / AssetStore records are already globals)
global session: World
global assets: AssetStore
global Gamestate: GamestateModule
global Logger: LoggerModule
global Boot: BootModule

-- Runtime globals for LuaRocks modules (loaded in main / Boot)
global JSON: JSONModule
global type OsExecuteLib = {string: function(string): boolean|number}
global sha1: function(string): string

-- Entity records live in src/entities/*.tl (global record). Keep ambient helpers.

-- Love 11 color max / disk color space
global LOVE_COLOR_MAX: number
global DISK_COLOR_MAX: number
global MUSIC_SOURCE_TYPE: string

-- Lua 5.1 unpack (gen_target 5.1)
global unpack: function(list: {any}, ...: number): any...

-- Core helpers exported as globals from src/core/*
global tilekey: function(any, any): integer
global bounce_at: {any:any}
global tilekey_xy: function(key: integer): integer, integer
global TILEKEY_STRIDE: integer
global inmap: function(x: number|nil, y: number|nil): boolean
global inrange: function(i: any, a: any, b: any, include?: boolean): boolean
global round: function(num: number, idp?: number): number
global tablecontains: function(t: {any}, entry: any): boolean
global getTile: function(x: number, y: number, portalable?: any, portalcheck?: any, facing?: any, ignoregrates?: any, dir?: any, mirexc?: any): any, any
global getMouseTile: function(any, any): number, number

-- Tiles / enemies / characters
global tilequads: {any:TileQuad}
global enemiesdata: {any:EnemyDef}
global enemies: {string}
global characters: {string:Character}
global mariocharacter: {any:string}

-- Class tables are now Teal `global record`s in src/ (see entities/*, ui/gui, world/*).
-- Do not redeclare them here as `any` ("cannot reassign a type").
global hat: {any:HatDef}
global bighat: {any:HatDef}

-- HUD / progress
global marioworld: number|string
global mariolevel: number
global mariosublevel: number
global mariotime: number
global mariotimelimit: number
global mariolives: {any:number}
global mariolivecount: any
global mariocoincount: number
global mariocolors: {{{number}}}
global mariohats: {any:{any}}
global portalhues: {{number}}
global portalcolor: {{{number}}}
global portalcolor1: {number:number}
global portalcolor2: {number:number}
global portals: {number:portal}
global portalsavailable: {any:boolean}
global controls: {any:{string:{any}}}
global mouse: MouseProxy
global mousex: number
global mousey: number
global mouseowner: integer
global bigmario: boolean

-- Editor / menu UI state
global editorstate: string
global currenttile: any -- tile id or enemy name
global editentities: boolean
global editenemies: boolean
global record EntityListEntry
	t: string
	hidden: boolean
	category: string
	description: string
	iconauthor: string
	output: boolean
	i: number
end
global entitylist: {any:EntityListEntry}
global record entitylistcategory
	t: string
	entries: {entitylistitem}
end
global entitylistitems: {entitylistcategory}
global rightclickmenues: {string:any}
global rightclickm: rightclickmenu|nil
global rightclicka: number
global animationguilines: {string:{animationguiline}}
global animationguiarea: {number}
global objectsguiarea: {number}
global mapbuttons: {string:guielement}
global optionstab: integer
global optionsselection: integer
global skinningplayer: integer
global mappacklist: {string}
global mappackselection: integer
global mappackhorscroll: number
global mappackhorscrollsmooth: number
global onlinemappacklist: {string}
global onlinemappackselection: integer
global helpui: {number}
global hotkeys: {string:{any}}
global selection: number
global selectionlist: {SelectionTile}
global brush: {number}
global record RegionDragging
	x: number
	y: number
	width: number
	height: number
	movex: number
	movey: number
	update: function(RegionDragging, number): boolean|nil
	draw: function(RegionDragging)
	mousepressed: function(RegionDragging, ...: any): any
	mousereleased: function(RegionDragging, ...: any): any
end
global regiondragging: any
global tileselectionclick1x: number
global tileselectionclick1y: number
global minimapscroll: number
global tilesoffset: number
global tileliststart: integer
global middlemode: {any:any} -- [1]=bool dragging, [2]=x, [3]=y
global colorsetedit: integer
global replaychar: {any:Character}
global record PromptState
	joystick: {number:{string:any}}
	joysticks: number
end
global prompt: PromptState
global rgbselection: number
global client_load: function()
global server_load: function()
global server_start: function()

-- Level / world visuals
global spriteset: integer
global custombackground: any
global customforeground: any
global backgroundlevel: any
global background: {any:number}
global coinmap: {any:{any:any}}
global smbtilecount: integer
global portaltilecount: integer
global customtilecount: integer
global modcustomtiles: integer|boolean
global modcustomtilecount: {integer:number}
global music: MusicPlayer
global musicname: string
global record SoundSource
	stop: function(SoundSource)
	seek: function(SoundSource, ...: any)
	play: function(SoundSource)
	pause: function(SoundSource)
	getDuration: function(SoundSource): number
	setVolume: function(SoundSource, number)
	setLooping: function(SoundSource, boolean)
	setPitch: function(SoundSource, number)
	isPlaying: function(SoundSource): boolean
end
global record SoundEntry
	source: SoundSource
	lastplayed: number
end
global soundlist: {any:SoundEntry}
global record ShadersController
	scale: any
	set: function(ShadersController, any, any)
	update: function(ShadersController, any)
	refresh: function(ShadersController, ...: any): any
	predraw: function(ShadersController, ...: any): any
	postdraw: function(ShadersController, ...: any): any
	init: function(ShadersController)
end

global shaders: ShadersController
global shaderlist: {number:string}
global guielements: {any:guielement}
global volumesfx: number
global volumemusic: number
global speed: number
global speedtarget: number
global scrollingscores: {any:scrollingscore}
global flagx: any
global axex: any
global startx: {number}
global starty: {number}
global levelfinished: boolean
global ylookmodifier: number
global gdt: number
global introprogress: number
global currentshaderi1: integer
global currentshaderi2: integer
global globints: {string:number}
global outputs: {any:any}
global CATEGORYDELIMITER: {any:string}
global MAP_SPAWN_HANDLERS: {string:function(number, number, {any})}
global MAP_SPAWN_EARLY_HANDLERS: {string:function(number, number, {any})}

-- Auto-ambient stubs for legacy globals (narrow later)
global record NoticeModule
	new: function(text: any, color?: any, lifetime?: any)
	white: any
	red: any
	yellow: any
	notices: {any}
	duration: number
	fadetime: number
	update: function(number)
	draw: function()
	gety: function(number, number, number, number): number
end
global notice: NoticeModule
global record AnimationDef
	name: string
	nicename: string
	filepath: string
	triggers: {any}
	conditions: {any}
	actions: {any}
end
global animations: {animation}
global currentanimation: integer
global controlstable: {string}
global customtilesimg: Image
global yacceleration: number
global selectionwidth: number
global newmapwidth: number
global newmapheight: number
global characterlist: {string}
global rightclickcellheight: number
global pausemenuselected: number
global custombackgroundimg: {any:{any}}
global axey: any
global noupdate: boolean
global autoscroll: any
global rgblist: {any:any}
global minimapx: number
global minimapy: number
global powerlinedrawtable: {{any}}
global tileselectionclick2x: number
global tileselectionclick2y: number
global pastingtiles: any
global editormenuopen: boolean
global tilelistcount: number
global mappackscroll: number
global mappackscrollsmooth: number
global onlinemappackscroll: number
global onlinemappackscrollsmooth: number
global toconvertmappackscroll: number
global toconvertmappackscrollsmooth: number
global pausemenuselected2: number
global blockbouncetime: number
global record EntityQuad
	sett: function(EntityQuad, number)
	image: Image
	quad: Quad
	i: number
end
global entityquads: {number:EntityQuad}
global levelfinishedmisc: number
global playertype: string
global animatedtimers: {any:{any:animatedtimer}}
global tileselectionclick1: any
global tileselectionclick2: any
global playertypei: number
global record LightDrawPoint
	x: number
	y: number
end
global lightdrawtable: {LightDrawPoint}
global toconvertmappackselection: number
global rightclickcellspacing: number
global smbtilesimg: Image
global portaltilesimg: Image
global coinanimation: number
global intermission: any
global underwater: any
global EQUALSIGN: {any:string}
global seesawtype: {any:{any}}
global pausemenuoptions: {string}
global earthquake: number
global animatedtiles: {animatedquad}
global backgroundcolor: {{number}}
global mazestarts: {number}
global bonusstage: any
global record HttpLib
	request: function(...: any): any, any
	PORT: number
	TIMEOUT: number
end

global http: HttpLib
global custombackgrounds: {any}
global reachedworlds: {string:{number|string:boolean}}
global superfriction: number
global animatedtilelist: any
global toconvertmappacklist: {string}
global result: {string:any}
global yoffset: number
global uispace: number
global blockbouncetimer: {any:number}
global pausemenuopen: boolean
global musiclist: {any}
global animatedtilecount: number
global animatedbooltimers: {any:{any:animatedbooltimer}}
global allowdrag: boolean
global rightclickactive: boolean
global selectionx: number
global selectiony: number
global selectionheight: number
global newmapoffsetx: number
global newmapoffsety: number
global blacktime: number
global ENEMY_SPAWN_HANDLERS: {string:function(number, number, {any}, boolean|nil): boolean}
global record OnlinePlayer
	connected: boolean
	id: string
	ping: number
	colors: {{number}}
	hats: any
	nick: string
end
global record ChatMessage
	id: string
	message: string
end
global playerlist: {OnlinePlayer}
global emancipationgrills: {any:Entity}
global marioscore: number
global flagy: number
global bullettime: boolean
global replaydata: {{string:any}}
global repeatX: any
global haswarpzone: any
global maxwalkspeed: number
global friction: number
global mappackhorscrollrange: number
global currentstate: number
global introduration: number
global introfadetime: number
global rightclickwidth: number
global runanimationtimer: number
global coinframe: integer
global modcustomtilesimg: {number:Image}
global scrollfactor: number
global custombackgroundheight: {any:{number}}
global custombackgroundwidth: {any:{number}}
global testlevel: boolean
global checkpointx: {number:number}
global globools: {string:boolean}
global pipestartx: number
global dirscale: number
global vsync: boolean
global pipeanimationtime: number
global sonicrainboom: boolean
global fireballquad: {number:any}
global arcade: boolean
global multitilesoffset: number
global savestates: {any}
global tileselection: any
global pastecenter: {number}
global changemapwidthmenu: boolean
global lightdrawX: number
global mappacktype: string
global coinblockanimations: {any:coinblockanimation}
global portaldotstimer: number
global tilenumber: number
global customtiles: boolean
global scrollingcomplete: number
global checkpointy: {number:number}
global checkpointsub: number|boolean
global mariosizes: {integer:number}
global mazeends: {number}
global walkaccelerationair: number
global runaccelerationair: number
global funnelmovespeed: number
global loaddelayed: {string:{string}}
global success: boolean
global allowskip: boolean
global fastestplayer: Entity
global regiondragboxwidth: number
global seesawquad: {any:any}
global animationlist: {any:any}
global minimapheight: number
global mtclipboard: {{any}}
global lightdrawY: number
global groundlighttable: {string}
global runanimationframe: number
global usemagic: boolean
global modcustomspritebatch: {number:any}
global blockbouncex: {any:number}
global blockbouncey: {any:number}
global fscrollfactor: number
global infinitetime: boolean
global portaldelay: {number:number}
global gelcannontimer: number
global spritebatchX: {any}
global firestartx: any
global pipestarty: number
global fireanimationtime: number
global soundenabled: boolean
global editordebug: any
global portalknockback: boolean
global s4: {string}
global starcolors: {number:{{number}}}
global firepoints: {any:number}
global mariostarduration: number
global vineframedelay: number
global playercollisions: boolean
global infinitelives: boolean
global fireworkcount: any
global collisionexists: function(any, Entity): any
global mtjustsaved: number
global pastemode: any
global splitxscroll: {number}
global multitileobjects: {any}
global tilescrollbarheight: number
global selectworldcursor: number
global mappackdescription: {any}
global axisDeadZones: {any:any}
global playerconfig: number
global blockdebristable: {any:Entity}
global portalprojectiles: {any:Entity}
global completecanvas: any
global userects: {any:{string:any}}
global adduserect: function(x: number, y: number, width: number, height: number, callback: any): {string:any}
global userect: function(x: number, y: number, width: number, height: number): {any}, any
global menuprompt: boolean
global itemanimations: {any:Entity}
global scalefactor: number
global replayi: {number:number}
global everyonedead: boolean
global blockbouncecontent: {any:any}
global coinblocktimers: {{any}}
global minimapdragging: boolean
global scrollrate: number
global userscrollrange: number
global firetimer: number
global prevsublevel: number|boolean
global spawnrestrictions: {{number}}
global gamefinished: boolean
global frameskip: any
global mkstation: boolean
global SERVER: string|boolean
global BLOCKDELIMITER: {any:string}
global airslidefactor: number
global mariocombo: {any}
global mariogravity: number
global uwmaxairwalkspeed: number
global uwfriction: number
global shotgravity: number
global portalanimation: number
global portalanimationtimer: number
global flagdescendtime: number
global springtime: number
global goombaattack: boolean
global animationtriggerfuncs: {string:{animation}}
global seesawimg: Image
global mapbuttonarea: {number}
global levelscreenbackname: any
global vprev: number
global hprev: number
global multitilegroups: {string:{{any}}}
global existingmaps: {number:number}
global infmarioY: number
global infmarioR: number
global mappackicon: {Image}
global onlinemappackdescription: {any}
global toconvertmappackicon: {Image}
global toconvertmappackdescription: {any}
global axiserror: any
global cheepcheepquad: {any:{any:any}}
global portalparticles: {any:Entity}
global portaldotstime: number
global scenecanvas: any
global desktopprompt: boolean
global suspendprompt: boolean
global smbspritebatch: SpriteBatch
global portalspritebatch: SpriteBatch
global customspritebatch: SpriteBatch
global levelfinishtype: string
global castleflagy: number
global textentities: {any:Entity}
global smbspritebatchfront: SpriteBatch
global portalspritebatchfront: SpriteBatch
global customspritebatchfront: SpriteBatch
global modcustomspritebatchfront: {number:any}
global emancipateanimations: {any:Entity}
global dialogboxes: {any:Entity}
global blockbouncecontent2: {any:any}
global xpantimer: number
global ypantimer: number
global spritebatchY: {any}
global portalparticletimer: number
global firedelay: number
global flyingfishstarted: boolean
global flyingfishtimer: number
global bulletbillstarted: boolean
global bulletbilltimer: number
global flyingfishzones: {{number|boolean}}
global bulletbillzones: {{number|boolean}}
global mazesolved: {any}
global enemiesspawned: {{number}}
global livereplaydelay: {number}
global endpressbutton: boolean
global id: {any}
global keyprompt: boolean
global levelscreens: {any}
global playertypelist: {string}
global maxrunspeed: number
global jumpforce: number
global bubblesspeed: number
global emanceimgwidth: number
global pushbuttontime: number
global pipeanimationdistancedown: number
global growframedelay: number
global flagydistance: number
global konamitable: {string}
global emancipationfizzletime: number
global tooltipimages: {any:Image}
global faithplatequad: {any}
global endimg: Image
global excursionquad: {any:any}
global subtracttimer: number
global vx: number
global vy: number
global tooltipa: number
global clipboardenabled: any
global drawalllinks: any
global skiplevelscreen: any
global multitileobjectnames: {any}
global ctrlpressed: boolean
global selectiondragging: boolean
global outputsi: {number:any}
global linktoolt: string|boolean
global hasHotkey: function(any, any): string|boolean|nil
global levelscreentimer: number
global mappackauthor: {any}
global buttonerror: any
global steptimer: number
global magicdns_timer: number
global magictimer: number
global scrollingscoretime: number
global scrollingtexts: {any:Entity}
global rainbooms: {any:Entity}
global blockbounceheight: number
global coinblockquads: {any:{any:any}}
global coinquads: {any:{any:any}}
global flagimgx: number
global flagimgy: number
global sunrot: number
global replaysystem: boolean
global replaytimer: {number:number}
global scrollingleftcomplete: number
global userscrollspeed: number
global downscrollborder: number
global firestarted: boolean
global flyingfishdelay: number
global bulletbilldelay: number
global respawnsublevel: number
global livereplaydata: {integer:{any}}
global joystickdeadzone: number
global flowercolor: {any}
global MULTIPLYDELIMITER: {any:string}
global joystickaimdeadzone: number
global minspeed: number
global frictionair: number
global uwsuperfriction: number
global bubblesmargin: number
global bubblestime: {number}
global staranimationdelay: number
global bowserfallspeed: number
global seesawfriction: number
global fireballspeed: number
global portalanimationdelay: number
global portalrotationalignmentspeed: number
global portalparticlespeed: number
global portalprojectilesinemul: number
global portalprojectilesinesize: number
global emanceparticlespeedmod: number
global usesquaresize: number
global vinemovespeed: number
global growtime: number
global invicibleblinktime: number
global fireworkdelay: number
global castleanimationmariomove: number
global funnelforce: number
global emancipateanimationtime: number
global bowserquad: {any:{any:any}}
global buttonquad: {any:any}
global emancemaxspeed: number
global parstartup: number
global realaction: any
global faithplateplateimg: Image
global img: {string:any}
global bowserfall: boolean
global portalquad: {any:any}
global vinequad: {any:{any:any}}
global brushmax: number
global minimapscrollspeed: number
global animationlineinset: number
global advanceddrawtool: string|boolean
global linktoolX: number
global linktoolY: number
global blackafterintro: number
global levelscreenback: any
global huechangespeed: number
global continueavailable: boolean
global menuselectimg: Image
global selectworldopen: boolean
global currentfiledownload: number
global mappackname: {any}
global downloaderror: boolean
global onlinemappackicon: {Image}
global onlinemappackauthor: {any}
global toconvertmappackauthor: {any}
global touchfrominsidemissing: number
global runanimationdelay: number
global adjective: string
global noun: string
global actualy: number
global magics: {magic}
global port: number
global portalbouncethreshold: number
global firstpersonview: boolean
global currentscissor: {number}
global coinanimationquads: {any:{any:any}}
global pausemenuoptions2: {any:any}
global volumesliderimg: Image
global scroll_batch_offset: function(scroll: number, sc?: number): number
global displaywarpzonetext: number|boolean
global seesaws: {any:Entity}
global flagscore: number
global levelfinishedmisc2: number
global fireworks: {any:Entity}
global bubbles: {any:Entity}
global emancipationfizzles: {any:Entity}
global pedestals: {any:Entity}
global backgroundstripes: number
global animatedtimerlist: {animatedtimer}
global animatedbooltimerlist: {animatedbooltimer}
global firstunder100: boolean
global autoscrollx: number|boolean
global autoscrolly: number|boolean
global xpan: any
global xpantime: number
global ypan: any
global ypantime: number
global lastrepeat: number
global flyingfishstartx: any
global flyingfishendx: any
global bulletbillstartx: any
global bulletbillendx: any
global lakitoendx: any
global mazeinprogress: boolean
global skipupdate: boolean
global livereplaystored: {integer:{any:any}}
global fontquads: {string:any}
global delaylist: {string:any}
global imagelist: {string}
global marioversion: number
global tablestodo: {any}
global mariostarrunout: number
global runanimationspeed: number
global portalprojectileparticledelay: number
global castlefireangleadd: number
global vineanimationgrowheight: number
global pipeupdelay: number
global gameovertime: number
global sublevelscreentime: number
global castleanimationbridgedisappeardelay: number
global endanimationtextsecondline: number
global rainboomspeed: number
global emancipatefadeouttime: number
global pedestaltime: number
global raccoonstarttime: number
global blockdebrisquads: {any:{any:any}}
global boxquad: {any:any}
global buttonimg: Image
global hatcount: number
global doorpieceimg: Image
global doorcenterimg: Image
global parstartleft: number
global emanceparticleimg: Image
global emancesideimg: Image
global excursionbaseimg: Image
global geldispenserimg: Image
global laserimg: Image
global castleflagmove: boolean
global castleflagtime: number
global bridgedisappear: boolean
global platformimg: Image
global springquads: {any:{any:any}}
global linktoolfadeouttime: number
global tileswitcherpressed: boolean
global entitytooltipobject: entitytooltip|nil
global filecount: number
global mappackback: Image
global mappacknoicon: Image
global mappackoverlay: Image
global mappackhighlight: Image
global mappackscrollbar: Image
global onlinemappackname: {any}
global toconvertmappackname: {any}
global js: string
global ITEM_SPAWN_HANDLERS: {string:function(number, number, any)}
global entitiesimg: Image
global recording: boolean
global skippedframes: number
global recordframe: number
global recordskip: number
global recordtarget: any
global touchfrominsidescaling: number
global chatmessages: {ChatMessage}
global localnick: string
global magicdns_identity: string
global coinblockanimationquads: {integer:any}
global scrollingscoreheight: number
global portaldotsouter: number
global portaldotsinner: number
global firstpersonrotate: boolean
global incognito: boolean
global gel1groundimg: Image
global gel2groundimg: Image
global gel3groundimg: Image
global gel4groundimg: Image
global warpzonenumbers: {any}
global axequads: {any:any}
global miniblocks: {any:Entity}
global rainboomearthquake: number
global tremorx: number
global tremory: number
global gradientimg: Image
global gelcannondelay: number
global rocketlaunchers: {any}
global platformspawners: {any}
global scrollingleftstart: number
global scrollingstart: number
global userscrolltime: number
global upscrollborder: number
global yscrollingrate: number
global xpanstart: number
global ypanstart: number
global portalparticletime: number
global flyingfishstarts: {any}
global flyingfishends: {any}
global bulletbillstarts: {any}
global bulletbillends: {any}
global lakitoend: any
global mazegates: {any}
global testlevelworld: number
global testlevellevel: number
global font2quads: {string:any}
global debugbinds: boolean
global portal_pair_offsets: function(any, any): number, number, number, number
global maxyspeed: number
global overwrittenimages: {string}
global soundstoload: {string}
global defaultsoundslist: {string:any}
global overwrittensounds: {string}
global directionsquad: {number:any}
global starttime: number
global CLIENT: string|boolean
global s1: {string}
global s2: {string}
global s3: {string}
global tableindex: {any:any}
global nexttablestodo: {any:any}
global LAYERDELIMITER: {any:string}
global walkacceleration: number
global runacceleration: number
global jumpforceadd: number
global bounceheight: number
global passivespeed: number
global uwfrictionair: number
global uwairslidefactor: number
global waterdamping: number
global horbouncemul: number
global horbouncespeedy: number
global horbouncemaxspeedx: number
global horbounceminspeedx: number
global mushroomtime: number
global mariostarblinkrate: number
global bowseranimationspeed: number
global bowserspeedforwards: number
global bowserjumpdelay: number
global bowserhammertable: {number}
global platformbonusspeed: number
global platformjustspeed: number
global seesawspeed: number
global seesawgravity: number
global shotspeedx: number
global shotjumpforce: number
global deathanimationjumptime: number
global coinblocktime: number
global coinblockdelay: number
global portalparticleduration: number
global emancelinecolor: {any}
global spacerunroom: number
global doorspeed: number
global geldispensespeed: number
global gelmaxspeed: number
global cubedispensertime: number
global bulletbillrange: number
global fireverspeed: number
global fireanimationdelay: number
global userange: number
global blockdebrisanimationtime: number
global castlefireanimationdelay: number
global vinespeed: number
global vinemovedownspeed: number
global vineframedelaydown: number
global vineanimationstart: number
global vineanimationmariostart: number
global vineanimationstop: number
global vineanimationdropdelay: number
global pipeanimationdelay: number
global pipeanimationdistanceright: number
global shrinktime: number
global invincibletime: number
global blinktime: number
global blacktimesub: number
global flagclimbframedelay: number
global flaganimationdelay: number
global scoresubtractspeed: number
global fireworksoundtime: number
global flagscores: {number}
global flagvalues: {number}
global castleanimationchaindisappear: number
global castleanimationbowserframedelay: number
global castleanimationtextfirstline: number
global castleanimationtextsecondline: number
global endanimationtextfirstline: number
global endanimationtextthirdline: number
global endanimationtextfourthline: number
global endanimationtextfifthline: number
global endanimationend: number
global drainmax: number
global rainboomdelay: number
global gelcannonspeed: number
global excursionbaseanimationtime: number
global funnelbuildupspeed: number
global emancipationfizzledelay: number
global raccoonbuttondelay: number
global raccoontailwagdelay: number
global raccoonspindelay: number
global wallindicatorquad: {any}
global decoysquad: {any:any}
global fireballimg: Image
global emanceaccel: number
global parstartright: number
global parstartdown: number
global firequad: {any:any}
global magicquad: {any}
global firework: number|boolean
global panelquad: {any}
global platformbonusimg: Image
global portalglowimg: Image
global portalimg: Image
global rainboomquad: {integer:any}
global walltimerquad: {integer:any}
global secretcheckboxtext: {string}
global editorloadopen: boolean
global largestworld: number
global line: string
global dropdownarrowimg: Image
global livesleft: number|boolean
global sublevelscreen_level: string|number
global RGBchangespeed: number
global updatenotification: boolean
global playerselectimg: Image
global selectworldexists: {boolean}
global loadingonlinemappacks: boolean
global menu_mappack_title: function(any): string
global menu_mappack_author_line: function(any): string
global menu_mappack_desc_lines: function(any): string, string, string
global huebarimg: Image
global huebarmarkerimg: Image
global DEBUG: boolean
global yadd: number
global goombaquad: {any:{any:any}}
global spikeyquad: {any:{any:any}}
global lakitoquad: {any:{any:any}}
global koopaquad: {any:{any:any}}
global hammerbrosquad: {any:{any:any}}
global hammerquad: {any:{any:any}}
global plantquads: {any:{any:any}}
global versionerror: boolean
global targetdt: number
global screenshotimagedata: any
global magicdns_delay: number
global localnicks: {string}
global magicdelay: number
global ip: string
global magicdns_session: string
global oneuptextimage: Image
global portaldotsdistance: number
global portaldotimg: Image
global portalcrosshairimg: Image
global physicsdebug: any
global portalwalldebug: any
global coinblockimg: Image
global coinimg: Image
global portalbackgroundimg: Image
global seethroughportals: boolean
global superscrollrate: number
global superscroll: number
global xpandiff: number
global ypandiff: number
global inventory: {integer:{any}}
global fontimage2: Image
global portalgundelay: number
global speeddebug: boolean
global facing: string
global xplus: number
global yplus: number
global PHYSICS_LATE_SET: {string:boolean}
global PHYSICS_LATE_LIST: {string}
global directionsimg: Image
global fontquadsback: {string:Quad}
global lastline: number
global totaltime: number
global gellifetime: number
global yaccelerationjumping: number
global headforce: number
global uwjumpforce: number
global uwjumpforceadd: number
global uwyacceleration: number
global uwyaccelerationjumping: number
global waterjumpforce: number
global uwmaxheight: number
global uwpushdownspeed: number
global bubblesmaxy: number
global gelmaxrunspeed: number
global gelmaxwalkspeed: number
global gelrunacceleration: number
global gelwalkacceleration: number
global uwgelmaxrunspeed: number
global uwgelmaxwalkspeed: number
global uwgelrunacceleration: number
global uwgelwalkacceleration: number
global mushroomjumpforce: number
global mariostarblinkrateslow: number
global bowserspeedbackwards: number
global bowserjumpforce: number
global bowsergravity: number
global bowserhammerdrawtime: number
global bowserhealth: number
global platformspawndelay: number
global fireballjumpforce: number
global maxfireballs: number
global deathanimationjumpforce: number
global deathgravity: number
global deathtotaltime: number
global portalanimationcount: number
global portalprojectilespeed: number
global portalprojectiledelay: number
global emanceparticlespeed: number
global boxfriction: number
global boxfrictionair: number
global faithplatetime: number
global bulletbilltimemax: number
global bulletbilltimemin: number
global firespeed: number
global blockdebrisgravity: number
global castlefiredelay: number
global shrinkframedelay: number
global levelscreentime: number
global castleflagstarty: number
global castleflagspeed: number
global castlemintime: number
global endtime: number
global springhighforce: number
global springforce: number
global springytable: {any:number}
global castleanimationnextlevel: number
global castleendmusicstopdelay: number
global endmusicstopdelay: number
global drainspeed: number
global rainboomframes: number
global konamilength: number
global konamihash: string
global maximumbulletbills: number
global funnelspeed: number
global funnelminspeed: number
global funnelmaxspeed: number
global linktoolfadeouttimefast: number
global linktoolfadeouttimeslow: number
global raccoontime: number
global raccoonascendspeed: number
global raccoondescendspeed: number
global defaultvalues: {string:any}
global nobasevalues: {string}
global gelquad: {any:any}
global lightbridgeimg: Image
global lightbridgeglowimg: Image
global magicimg: Image
global blay: number
global portalparticleimg: Image
global portalprojectileimg: Image
global portalprojectileparticleimg: Image
global pushbuttonquad: {any:any}
global rainboomimg: Image
global scaffoldimg: Image
global vineimg: Image
global portal_facing_offset: function(any): number, number
global maxstates: number
global prevtile: entitylistitem|nil
global objectscrollbarheight: number
global linktoolpointerimg: Image
global tx: number
global ty: number
global rightclickelementslist: {any}
global guirepeattimer: number
global editmtobjects: boolean
global entitiescount: number
global regiontoolX: number
global regiontoolY: number
global regiontoolt: string|boolean
global checkboximg: Image
global checkboxquad: {any:{any:any}}
global playedwilhelm: boolean
global logo: Image
global logoblood: Image
global loadingtext: string
global infmarioYspeed: number
global infmarioRspeed: number
global portalcolors: {any}
global firstload: boolean
global currentdownload: number
global downloadcount: number
global savefolderfailed: boolean
global outdated: boolean
global shaderssupported: boolean
global backgroundi: number
global volume: number
global previewimg: ImageData
global numberglyphs: string
global starquad: {any:any}
global flowerquad: {any:any}
global squidquad: {any:any}
global bulletbillquad: {any}
global magicdns_validresponses: {string}

-- Missing globals declared for cyan -u (auto)
global LOVE_MAJOR: number
global actionblockimg: Image
global andgateimg: Image
global animatedtiletriggerimg: Image
global animationstab: function(): any
global arcadeblinkrate: number
global arcadeexittime: number
global arcadeleave: function(any): any
global arcadeplaying: {number:boolean}
global arcadetimeout: number
global axeimg: Image
global blockdebrisimg: Image
global bowserimg: Image
global boximg: Image
global bubbleimg: Image
global bulletbilllifetime: number
global bulletbillspeed: number
global castleanimationcameraaccelerate: number
global castleanimationmariostop: number
global castleflagimg: Image
global coinanimationimg: Image
global coinblockanimationimg: Image
global colors: {any}
global cubedispenserimg: Image
global custommusics: {any}
global debugprints: boolean
global decoysimg: Image
global delayerimg: Image
global dlclist: {string}
global earthquakespeed: number
global editor_mode_labels: function(any, any, any, any): string, string|boolean
global excursionfunnel2img: Image
global excursionfunnelend2img: Image
global excursionfunnelendimg: Image
global excursionfunnelimg: Image
global fireimg: Image
global firstreplayblue: boolean
global fizzleimg: Image
global flagimg: Image
global flyingfishforce: number
global flyingfishgravity: number
global fontimage: Image
global fontimageback: Image
global gameheight: number
global gamewidth: number
global gel1img: Image
global gel2img: Image
global gel3img: Image
global gel4img: Image
global gel5img: Image
global groundlightdelay: number
global guirepeatdelay: number
global hammeranimationspeed: number
global hammerbroanimationspeed: number
global hammerbrojumpforce: number
global hammerbrojumpforcedown: number
global hammerbrojumptime: number
global hammerbropreparetime: number
global hammerbrospeed: number
global hammerbrotime: {any}
global hammergravity: number
global hammerspeed: number
global hammerstarty: number
global jumpitems: {any}
global koopacombo: {any}
global laserdetectorimg: Image
global lasersideimg: Image
global lightbridgesideimg: Image
global livereplaytimer: number
global maintab: function(): any
global mappackbackground: {any}
global mapstab: function(): any
global markbaseimg: Image
global markoverlayimg: Image
global maxscrollrate: number
global mccurrentblock: number
global mtsavehighlighttime: number
global mtsavetimer: number
global mushroomspeed: number
global musicentityimg: Image
global netplayerid: string
global netplayernumber: number
global notgateimg: Image
global objectstab: function(): any
global onlinemappackbackground: {any}
global orgateimg: Image
global panelimg: Image
global peachimg: Image
global pedestalbaseimg: Image
global pedestalgunimg: Image
global pipeanimationrunspeed: number
global plantanimationdelay: number
global plantintime: number
global plantmovedist: number
global plantmovespeed: number
global plantouttime: number
global platformhordistance: number
global platformhortime: number
global platformverdistance: number
global platformvertime: number
global portalbackground: {string:any}
global powerlinestab: function(): any
global pushbuttonimg: Image
global reachedx: function(any)
global realdt: any
global rsflipflopimg: Image
global scoredelay: number
global scrollsmoothrate: number
global spawnarea: {any}
global speedmodifier: number
global springimg: Image
global squarewaveimg: Image
global squidacceleration: number
global squiddowndistance: number
global squidfallspeed: number
global squidupspeed: number
global squidxspeed: number
global starjumpforce: number
global swimanimationspeed: number
global testtimer: number
global tilecount1: number
global tilecount2: number
global tilestab: function(): any
global titleimg: Image
global toadimg: Image
global toconvertmappackbackground: {any}
global toolstab: function(): any
global upfireforce: number
global upfiregravity: number
global userectdebug: boolean
global uwgravity: number
global uwmaxrunspeed: number
global uwmaxwalkspeed: number
global uwrunacceleration: number
global uwwalkacceleration: number
global uwwalkaccelerationair: number
global versionstring: string
global wallindicatorimg: Image
global walltimerimg: Image
global zgbooltriggerimg: Image
global zgbooltriggerquad: {any}

-- Cross-module function stubs (implementations in src/)
global aabb: function(ax: number, ay: number, awidth: number, aheight: number, bx: number, by: number, bwidth: number, bheight: number): boolean
global aabt: function(number, number, number, number, number, number, number, number, any): boolean|nil
global add: function(any)
global addanimationaction: function(): any
global addanimationcondition: function(): any
global addanimationtrigger: function(): any
global addpoints: function(i: any, x?: any, y?: any)
global adjustcollside: function(any, any): any
global animationsystem_draw: function()
global animationsystem_load: function()
global animationsystem_update: function(number)
global build_blockbounce_lookup: function({any:any}, {any:any}): {any:any}
global callcollision: function(any, Entity, any, Entity, any, any): any
global changebackground: function(any): any
global changecharacter: function(any)
global changeforeground: function(any): any
global changelevelscreen: function(any): any
global changeline: function(any, any, any): boolean|nil
global changemapheight: function(number)
global changemapwidth: function(number)
global changemusic: function(any): any
global changenewmapsize: function(any, any): any
global changepastemode: function(any): any
global changeportalgun: function(any): any
global changescale: function(s: number, init?: boolean)
global changespriteset: function(any): any
global checkcollision: function(Entity, Entity, any, any, any, any, number, any): boolean, boolean
global checkforemances: function(dt: number, v: Body, speedx?: number, speedy?: number)
global checkkey: function(any): any
global checkmagic: function(s: string): boolean
global checkportalHOR: function(Entity, number): boolean
global checkportalVER: function(Entity, number): boolean
global checkportalremove: function(any, any)
global checkrect: function(x: number, y: number, width: number, height: number, list: any, statics?: any): {integer:any}
global closerightclickmenu: function()
global collectblock: function(any): any
global collectcoin: function(x: number, y: number, i?: any): any
global collisionscalls: function(any, Entity, any, Entity, any, any): any
global configdecrease: function()
global configincrease: function()
global continuegame: function()
global convertentity: function(any): any
global convertfromstandard: function(Entity, number, number): number, number
global convertmappack: function(any)
global converttostandard: function(Entity, number, number): number, number
global count_spawn_handlers: function({any:any}): number
global createdialogbox: function(any, any)
global creategame: function()
global createmappack: function()
global createnewanimation: function(): any
global decreasetimelimit: function(): any
global defaultbackground: function(any): any
global defaultconfig: function()
global delete_mappack: function(any): any
global deleteanimationguiline: function(string, animationguiline)
global deleteline: function(any, any): boolean|nil
global destroyblock: function(number, number): any
global dispatch_enemy_entity_spawn: function(t: string, x: number, y: number, r: {any}, allowenemy?: boolean): boolean
global dispatch_map_entity_spawn: function(t: string, x: number, y: number, r: {any}, createobjects?: boolean, editormode?: boolean)
global downkey: function(any): any
global downloadfile: function(any, any, any): any
global downloadmappacks: function(): any
global drawforeground: function()
global drawlevel: function()
global drawlevel_tiles: function(any, any)
global drawlinkline: function(any, any, any, any): any
global drawlinkline2: function(any, any, any, any): any
global drawmushrooms: function(): any
global drawplayercard: function(x: number, y: number, colors: {{number}}, hats: any, nick: string, ping?: number, focus?: boolean)
global drawplayer: function(any, any, any, cscale?: any, offsetX?: any, offsetY?: any, rotation?: any, quadcenterX?: any, quadcenterY?: any, animationstate?: any, underwater?: any, ducking?: any, hats?: any, graphic?: any, quad?: any, pointingangle?: any, shot?: any, upsidedown?: any, colors?: any, lastportal?: any, portal1color?: any, portal2color?: any, runframe?: any, swimframe?: any, climbframe?: any, jumpframe?: any, biggraphic?: any, fireanimationtimer?: any, char?: any)
global drawpowerlines: function(): any
global drawrectangle: function(any, any, any, any): any
global drawreplay: function(any, any)
global editor_draw: function(): any
global editor_draw_chrome: function(): any
global editor_draw_linking: function(any, any): any
global editor_draw_menu: function(any, any): any
global editor_draw_menu_animations: function(any, any): any
global editor_draw_menu_changewidth: function(): any
global editor_draw_menu_lightdrawcustomize: function(): any
global editor_draw_menu_main: function(any, any): any
global editor_draw_menu_maps: function(): any
global editor_draw_menu_objects: function(any, any): any
global editor_draw_menu_tiles: function(any, any): any
global editor_draw_menu_tools: function(): any
global editor_draw_overlay: function(any, any): any
global editor_draw_status: function(): any
global editor_keypressed: function(any): any
global editor_load: function(): any
global editor_mousepressed: function(any, any, any): any
global editor_mousepressed_left: function(any, any): any
global editor_mousepressed_right: function(any, any): any
global editor_mousepressed_wheel_down: function(any, any): any
global editor_mousepressed_wheel_up: function(any, any): any
global editor_mousereleased: function(any, any, any): any
global editor_start: function(): any
global editor_textinput: function(any): any
global editor_update: function(number)
global editor_update_closed: function(number)
global editor_update_keyscroll: function(number)
global editor_update_main: function(number)
global editor_update_modifiers: function(): any
global editor_update_objects: function(number)
global editor_update_rightclick: function(number)
global editor_update_tiles: function(number)
global editorclose: function(): any
global editorexit: function(): any
global editoropen: function(): any
global emptySelection: function(): any
global endgame: function()
global enemies_load: function()
global finishlinking: function(any, any): any
global finishregion: function(): any
global fromanimationstab: function(): any
global fromlightdrawcustomizetab: function(): any
global frommapstab: function(): any

global game_update: function(number)
global getquadprops: function(ImageData, number, number): {string:any}
global properprint: function(s: any, x: number, y: number, sc?: number)
global print_r: function(any, any): any
global openSaveFolder: function(string|nil): boolean
global dbprint: function(any, y?: any)
global keypromptenter: function(any, ...: any): any
global loadcustombackgrounds: function()
global loadcustommusics: function()
global loadcustomtiles: function()
global game_draw: function()
global game_draw_debug: function()
global game_draw_fx: function()
global game_draw_hud: function(hidetime?: any): any
global game_draw_objects: function()
global game_draw_pausemenu: function()
global game_draw_player_markers: function()
global game_draw_props: function()
global game_draw_seethrough_portals: function()
global game_joystickaxis: function(any, any, any, any, any)
global game_joystickhat: function(any, any, any)
global game_joystickpressed: function(any, any)
global game_joystickreleased: function(any, any)
global game_keypressed: function(any)
global game_keyreleased: function(any)
global game_load: function(suspended?: any)
global game_mousepressed: function(any, any, any)
global game_mousereleased: function(any, any, any)
global game_textinput: function(any)
global generateanimationgui: function(): any
global generateentitylist: function(): any
global generatespritebatch: function()
global getAngleFrame: function(number, number): any
global getPortal: function(x: number, y: number, dir?: any): number|boolean, number|nil, any, any, any, any, any, any
global getSelectedTiles: function(): {{any}}
global getTiles: function(any, any): {{any}}
global getaveragecolor: function(any, any, any): number, number, number
global getentityhighlight: function(any, any): entitylistitem|nil
global getfilepath: function(any): any
global getmaps: function(): any
global getportalposition: function(any, any, any, any, any, mirexc?: any): number|boolean, number|nil, string|nil
global getupdate: function(): boolean
global givelive: function(any, Entity)
global globintCH: function(id: any, para: any, value: any): boolean
global globintSH: function(id: any, para: any, value?: any): number
global globoolSH: function(id: any, para: any): boolean
global handlegroup: function(i: any, h: any, u: {any:Body}, v: Body, j: any, dt: number, passed: any): boolean, boolean
global hitblock: function(x: number, y: number, t: any, koopa?: any): any
global hitrightside: function()
global horcollision: function(Entity, Entity, any, any, any, any, number): boolean
global increasetimelimit: function(): any
global inportal: function(Entity): boolean
global insideportal: function(number, number, number, number): any, any
global intro_draw: function()
global intro_keypressed: function()
global intro_load: function()
global intro_mousepressed: function()
global intro_update: function(number)
global item: function(i: any, x: number, y: number, size?: any)
global joingame: function()
global keyprompt_update: function()
global keypromptstart: function()
global leftkey: function(any): any
global level_count_tile_entries: function(t: {any}, multipledelimiter: string): number
global level_decode_tile_tokens: function(t: {any}, mapwidth: number, mapheight: number, layerdelimiter: string, multipledelimiter: string): {number:{number:MapCell}}, {number:{number:boolean}}
global level_delimiters: function(v: integer): string, string, string, string, string
global level_detect_format_version: function(string): integer
global level_filename: function(world: number|string, level: number|string, sublevel?: number): string
global level_parse_tiles_only: function(s: string): LevelTilesParse|nil, string|nil
global level_serialize_maptiles: function(map: {number:{number:MapCell}}, coinmap: {number:{number:any}}, mapwidth: number, mapheight: number, v: integer): string
global level_split_file_contents: function(s: string): integer, number, {string}, {string}, string, string, string, string, string
global levelscreen_draw: function()
global levelscreen_load: function(reason: any, levelarg?: any)
global levelscreen_update: function(number)
global livesdecrease: function(): any
global livesincrease: function(): any
global loadHotKeys: function(): any
global loadanimatedtiles: function()
global loadbackground: function(any): any
global loadbackgroundsafe: function(any): any
global loadcharacter: function(string): Character|boolean
global loadconfig: function()
global loadcustomimages: function(string)
global loadcustomsounds: function(string)
global loadenemy: function(string)
global loadhat: function(string)
global loadlevel: function(level: string|number): boolean
global loadlevelscreens: function()
global loadmap: function(filename: string, createobjects?: boolean): boolean
global loadmapold: function(any): any
global loadmappacks: function()
global loadmodcustomtiles: function()
global loadmtgroups: function(): any
global loadmtobjects: function(): any
global loadonlinemappacks: function()
global loadstate: function(s?: any): any
global loadtoconvertmappacks: function()
global lobby_draw: function()
global lobby_load: function()
global lobby_update: function(dt: number)
global magicdns_error: function(result: {string}): boolean
global magicdns_find: function(adjective: string, noun: string): string, string, string
global magicdns_keep: function()
global magicdns_make: function(): string, string
global magicdns_remove: function()
global mapnumberclick: function(any, any, k?: any): any
global mappacks: function()
global mapwidthapply: function(): any
global mapwidthcancel: function(): any
global menu_draw: function()
global menu_draw_mappackmenu: function()
global menu_draw_options: function()
global menu_draw_title: function()
global menu_joystickaxis: function(any, any, any, any, any)
global menu_joystickhat: function(any, any, any)
global menu_joystickpressed: function(any, any)
global menu_joystickreleased: function(any, any)
global menu_keypressed: function(any)
global menu_keyreleased: function(any)
global menu_load: function()
global menu_mousepressed: function(any, any, any)
global menu_mousereleased: function(any, any, any)
global menu_update: function(number)
global modifyportaltiles: function(any, any, any, any, any, any, any)
global modifyportalwalls: function()
global movedownanimationguiline: function(string, animationguiline)
global moveline: function(any, any, any): boolean|nil
global moveoutportal: function(i?: any)
global moveupanimationguiline: function(string, animationguiline)
global newRecoloredImage: function(string, {{number}}, {{number}}): Image|nil
global newlevel: function(): any
global nextcharacter: function()
global nextlevel: function()
global objectclipboardcopy: function(any): any
global onlinemenu_draw: function()
global onlinemenu_load: function()
global onlinemenu_update: function(dt: number)
global onlineupdatescroll: function()
global openchangewidth: function(): any
global passivecollision: function(Entity, Entity, any, any, any, any, number): boolean
global physicsupdate: function(dt: number)
global placetile: function(any, any, t?: any, ent?: any, preventMultiTile?: any): any
global playmusic: function()
global playsound: function(any)
global portalcoords: function(x: number, y: number, speedx: number, speedy: number, width: number, height: number, rotation: number, animationdirection: any, entryportalX: number|boolean, entryportalY: number|boolean, entryportalfacing: any, exitportalX: number|boolean, exitportalY: number|boolean, exitportalfacing: any, self?: Entity, live?: boolean): number, number, number, number, number, any
global prerotatecall: function(any, any): boolean
global previouscharacter: function()
global properprint2: function(any, number, number, ...: any)
global properprintbackground: function(any, any, any, include?: any, color?: any, sc?: any)
global removelink: function(any, any, any): any
global renameline: function(any, any, any): boolean|nil
global renderpreview: function(): ImageData
global reset_mappacks: function()
global resetconfig: function()
global respawnplayers: function()
global reversefscrollfactor: function(): number
global reversescrollfactor: function(): number
global rightkey: function(any): any
global runkey: function(any): any
global saveHotKeys: function(): any
global saveanimation: function(): any
global saveconfig: function()
global savelevel: function()
global savemap: function(filename: string, silent?: boolean)
global savemtobject: function(any, name?: any, file?: any): any
global savesettings: function(): any
global savestate: function()
global scenedraw: function()
global selectanimation: function(any): any
global selectionbutton: function(): any
global selectionend: function(): any
global selectiongettiles: function(any, any, any, any): {SelectionTile}
global selectionstart: function(): any
global selectworld: function()
global sendchat: function()
global serializetable: function(any)
global shootportal: function(any, any, any, any, any, mirrored?: any, bounces?: any)
global spawnenemy: function(x: number, y: number)
global startlevel: function(levelstart?: any)
global startlinking: function(any, any, any): any
global startregion: function(any, any, any): any
global stopmusic: function()
global suspendgame: function()
global test_level: function(): any
global tilesall: function(): any
global tilesanimated: function(): any
global tilescustom: function(): any
global tilesenemies: function(): any
global tilesentities: function(): any
global tilesportal: function(): any
global tilessmb: function(): any
global toconvertupdatescroll: function()
global toggleautoscroll: function(any): any
global togglebonusstage: function(any): any
global toggleclipboardenabled: function(any): any
global togglecustombackground: function(any): any
global togglecustomforeground: function(any): any
global toggledrawalllinks: function(any): any
global toggleeditordebug: function(any): any
global toggleintermission: function(any): any
global togglemagic: function()
global toggleskiplevelscreen: function(any): any
global toggleunderwater: function(any): any
global togglewarpzone: function(any): any
global traceline: function(sourcex: number, sourcey: number, radians: number, reportal?: any): number|boolean, number|boolean, string|boolean, number|boolean, number, number
global trianglepassivecollision: function(Entity, Entity, any, any, any, any, number): any
global trianglevercollision: function(Entity, Entity, any, any, any, any, number): any
global twistdirection: function(any, any): any
global unrotate: function(number, number, number): number
global updateanimationdropdown: function(): any
global updatebackground: function(): any
global updatefscrollfactor: function(): any
global updateranges: function()
global updatescroll: function()
global updatescrollfactor: function(): any
global updatesizes: function()
global upkey: function(any): any
global vercollision: function(Entity, Entity, any, any, any, any, number): boolean
global warpzone: function(any, any)

-- Typed free-function replacement for legacy string:split (see core.stringutil).
global strsplit: function(any, any): {string}
global addzeros: function(any, integer): string
global loadingtexts: {string}
global skipintro: boolean
global fontglyphs: string
global gethatoffset: function(any, any, any, any, any, any, any, any, any, any, any): {number}|nil
global getrainbowcolor: function(number): {number}
global remove_indices_desc: function(any, any)
global addanimationtriggerbutton: guielement
global addanimationconditionbutton: guielement
global addanimationactionbutton: guielement
global allowenemy: boolean
global subtractscore: any
global editor_link_screen_pos: function(any, any): number, number
global gettilelistpos: function(number, number): number|boolean
global changeHotKey: function(any, any, any): any
global closestplayer: integer
global drawui: function(hidetime?: any): any
global drawtools: number
global newx: number
global newy: number

global tileswitcherkey: string
global editorcoinstart: any
global mapsymissing: number
global editor_minimap_xscroll_from_mouse: function(number, number, number, number): number
global editor_minimap_tile_from_click: function(number, number, number, number, number, number, number): number, number
global editor_filter_map_files: function(any): any
global editor_normalize_rect: function(number, number, number, number): number, number, number, number
global editor_hotkeys_parse: function(any): {string:{any}}
global editor_hotkeys_serialize: function(any): any
global getmtbutton: function(any): number
global getlistpos: function(any, any): number|boolean
global formatscrollnumber: function(any): string
global mapsort: function(any, any): boolean
global gradient: function({number}, {number}, number): {number}
global menu_parse_settings_text: function(any): any, any, any
global getclosestplayer: function(x: number): integer
global cameraxpan: function(any, any)
global cameraypan: function(any, any)
global update_and_compact: function(any, any)
global usebase: function(any): Dyn
global buildstartendzones: function(any, any): {{number|boolean}}
global remove_indices_desc_multi: function(any, any)
global enemy_name_ok: function(any): boolean
global normalize_enemy_props: function(any): Dyn
global apply_enemy_defaults: function(any, any): Dyn
global enemy_onscreen: function(any, any, any, any): boolean
global record LoveLoadModule
	install_mouse: function(LoveLoadModule)
	run: function(LoveLoadModule, any)
end
global LoveLoad: LoveLoadModule
global magicdns_session_chars: string
global lkisScancodeDown: function(any): any
global lkisDown: function(any): any
global lmisDown: function(any): any
global joysticks: {Joystick}
global bdrawui: any
global drawreplays: any
global fsaa: any
global iconimg: ImageData


global submode: any

global completewidth: number

global added: number

global slx1: number

global slx2: number

global sly1: number

global sly2: number

global animationstrings: {any:{string}}

global GCA: number

global unstatics: any
global net_quit: function()
global net_sendchat: function(any): any
