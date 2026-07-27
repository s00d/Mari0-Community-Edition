-- Ambient records for cross-module game objects (Teal handbook: records + .d.tl).
-- Loaded via require from types/game.d.tl (global_env_def chain).

-- Enemy JSON / enemiesdata values (assets/enemies/*.json).
global record EnemyDef
	quadcount: integer
	quadno: integer
	width: number
	height: number
	category: integer
	mask: {boolean}
	static: boolean
	active: boolean
	autodelete: boolean
	emancipatecheck: boolean
	animationtype: string
	animationspeed: number
	animationframes: integer
	animationstart: integer
	movement: string
	gravity: number
	speedx: number
	offsetX: number
	offsetY: number
	quadcenterX: number
	quadcenterY: number
	nospritesets: boolean
	kills: boolean
	killsonsides: boolean
	killsonbottom: boolean
	stompable: boolean
	stompanimation: boolean
	stompanimationtime: number
	stompedframe: integer
	truffleshufflespeed: number
	truffleshuffleacceleration: number
	ignorefaithplates: boolean
	notkilledfromblocksbelow: boolean
	description: string
	portalable: boolean
	removeonmariocontact: boolean
	spawnoffsetx: number
	spawnoffsety: number
	transforms: boolean
	transformsinto: string
	transformtrigger: string
	resistsstar: boolean
	shellanimal: boolean
	movementrandoms: {string}
	spawnsound: string
	spawnsenemy: string
	directfromblock: boolean
	graphic: any
	quad: any
	quadbase: any
	quadgroup: any
	drawable: boolean
end

-- Character record lives in types/love.d.tl (needed before Entity.char).

-- Tile atlas entry (world.quad / tilequads[i]).
global record TileQuad
	image: Image
	triggered: any
	boolean: any
	cache: any
	number: any
	boolid: any
	delays: {number}
	properties: {any:Dyn}
	portalable: any
	getproperty: function(TileQuad, ...: any): any
	quad: function(TileQuad, ...: any): any
end

-- Portal pair owned by a player (entities.portal).
-- Loose portal bag (runtime fields vary); prefer records.portal class for methods.
global record Portal
	number: integer
	portal1color: {number}
	portal2color: {number}
	animationtimer: number
	portalframe: integer
	openscale: {any}
	x1: any
	y1: any
	facing1: any
	x2: any
	y2: any
	facing2: any
	timer: number
	i: integer
	cox: number
	coy: number
	side: string
	tend: any
	x: number
	y: number
	createportal: function(Portal, any, any, any, any, any)
	removeportal: function(Portal, any)
	update: function(Portal, any)
	draw: function(Portal)
end

-- Player class record is `mario` in types/records.d.tl (source: entities.mario).

-- Enemy instance (entities.enemy); def fields are copied onto the instance at init.
global record Enemy
	t: string
	a: {any}
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	rotation: number
	active: boolean
	static: boolean
	mask: {boolean}
	gravitydirection: number
	combo: integer
	falling: boolean
	shot: boolean
	outtable: {{Entity, any}}
	animationtype: string
	animationtimer: number
	animationdirection: string
	quadi: integer
	quad: Quad
	quadgroup: {Quad}
	movement: string
	customtimer: {any}
	spawnoffsetx: number
	spawnoffsety: number
	update: function(Enemy, number)
	draw: function(Enemy)
end

-- Session / world bag (world.session).
global record World
	map: {number:{number:{any}}}
	objects: {string:{number:Entity}}
	mapwidth: integer
	mapheight: integer
	xscroll: number
	yscroll: number
	mariotimer: number
	gamestate: string
	mappack: string|nil
	currentlevel: any
	editormode: boolean
	paused: boolean
	new: function(): World
	sync_session_from_globals: function(World)
	set_scroll: function(World, number, number)
	set_map_size: function(World, integer, integer)
	set_gamestate: function(World, string)
end

-- Per-level state bag (world.level); Ctx.level owns map/objects/scroll for a load.
global record Level
	map: {number:{number:{any}}}
	coinmap: {number:{number:boolean}}
	objects: {string:{any:Entity}}
	mapwidth: integer
	mapheight: integer
	xscroll: number
	yscroll: number
	ylookmodifier: number
	playerobjs: {Entity}
	portals: {any}
	teardown: {function}
	smbspritebatch: SpriteBatch|nil
	smbspritebatchfront: SpriteBatch|nil
	portalspritebatch: SpriteBatch|nil
	portalspritebatchfront: SpriteBatch|nil
	new: function(): Level
	destroy: function(Level)
	on_destroy: function(Level, function)
	push_globals: function(Level)
	pull_globals: function(Level)
end

-- Asset store (assets.store).
global record AssetStoreEntry
	path: string
	kind: string
	object: any
	default_path: string
end

global record AssetStore
	images: {string:AssetStoreEntry}
	sounds: {string:AssetStoreEntry}
	music_type: string
	ROOT: string
	GRAPHICS: string
	SOUNDS: string
	SHADERS: string
	CHARACTERS: string
	ENEMIES: string
	__index: AssetStore
	new: function(string|nil): AssetStore
	register_image: function(AssetStore, string, string)
	register_sound: function(AssetStore, string, string)
	get_image: function(AssetStore, string): Image
	get_sound: function(AssetStore, string): Source
	override_image: function(AssetStore, string, string)
	override_sound: function(AssetStore, string, string)
	restore_image_defaults: function(AssetStore)
	restore_sound_defaults: function(AssetStore)
	restore_defaults: function(AssetStore)
	export_image_globals: function(AssetStore, {string})
	load_image: function(string): Image|nil
	load_image_data: function(ImageData): Image|nil
	load_sound: function(string, string): Source|nil
end

global record HatDef
	graphic: Image|nil
	x: number
	y: number
	height: number
	width: number
end

global record MusicPlayer
	loaded: {string:Source}
	pitch: number
	list: {string}
	list_fast: {string}
	load: function(MusicPlayer, any): boolean
	play: function(self: MusicPlayer, name: any, fade?: any)
	stop: function(self: MusicPlayer, name: any, fade?: any)
	update: function(MusicPlayer)
	setVolume: function(MusicPlayer, any)
end
