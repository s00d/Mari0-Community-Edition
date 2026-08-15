-- Major Mari0 runtime globals for Teal (ambient via love.d.tl → require("game")).
-- Prefer concrete records from entities.d.tl. Narrow `any` only at legacy boundaries.

require("anim8")

-- MapCell before entities: World.map needs it (entities loads before the rest of this file).
global record SpriteBatchViewCell
	foreground: boolean
	tilenumber: number
	batch_id: integer|nil
	slot_id: integer|nil
end
global record MapCell is {any}
	portaloverride: {string:any}
	gels: {string:any}|nil
	gelSides: {number:number}|nil
	portal: any
end

require("entities")
require("records")
require("marioforms")
require("flux")

-- Session instance (`session`): SoT for level world (map/objects/scroll/portals).
-- Teal record name is `World`.
global record World
	map: {number:{number:MapCell}}
	coinmap: {any:{any:any}}
	objects: {any:{any:Entity}}
	playerobjs: {any:mario}
	mapwidth: number
	mapheight: number
	xscroll: number
	yscroll: number
	ylookmodifier: number
	portals: {number:portal}
	enemiesspawned: {integer:boolean}
	smbspritebatch: any
	smbspritebatchfront: any
	portalspritebatch: any
	portalspritebatchfront: any
	new: function(): World
	reset_level: function(World)
end

global record MouseProxy
	getX: function(): number
	getY: function(): number
	getPosition: function(): number, number
	isDown: function(...: any): boolean
end



global record GamestateModule
	current: string
	handlers: {string:{string:function}}
	register: function(string, {string:function})
	set: function(string)
	get: function(): string
	is: function(string): boolean
	in_menu_family: function(): boolean
	update: function(number)
	draw: function()
	call: function(string, ...: any)
end

global record HumpTimerModule
	update: function(number)
	after: function(number, function): any
	every: function(number, function, integer|nil): any
	cancel: function(any)
	clear: function()
end

global record WeaponsModule
	registry: {string:{string:any}}
	gravitygun: {string:any}
	hookshot: {string:any}
	blackhole: {string:any}
	get: function(string): {string:any}
	current: function(any): {string:any}
	icon_image: function(string): any
	default_loadout: function(): {string}
	setup_player: function(any)
	give: function(any, string)
	release: function(any, string)
	switch: function(any, number)
	fire: function(any, any)
	hold: function(any, any, number)
	update: function(any, number)
	update_all: function(number)
	draw: function(any)
	draw_hud: function(any)
end

global record LoveFrameModule
	request_skip_update: function()
	begin_update: function(): boolean
	add_time: function(number)
	try_step: function(number): boolean
	has_pending_step: function(number): boolean
	clear_debt: function()
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

-- map/objects/scroll live on `session` (World), not as bare _G aliases.
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
-- UI input (prefer Ctx.ui later; globals for now)
global ui_input_mode: string
global INPUT_ACTIONS: {string}
global input_bindings_init: function()
global input_bindings_rebuild: function(integer)
global ui_input_update: function(number)
global ui_action_down: function(integer, string): boolean
global ui_action_get: function(integer, string): number
global sys_down: function(string): boolean
global input_player: function(integer): any
global binding_display: function(string): string
global mouseui_x: number
global mouseui_y: number
global screen_to_ui: function(number, number): number, number
global ui_set_input_mode: function(string)
global ui_note_mouse_move: function(number, number, number, number): boolean
global ui_note_kbd: function()
global menu_mousemoved: function(number, number)
global MENU_SCREENS: {string:{string:any}}
global menu_defs_bind: function()
global menu_visible_items: function({string:any}): {any}
global menu_layout_main: function({string:any}): {string:any}
global menu_hit: function({any}, number, number): integer|nil
global menu_hit_spinner: function({string:any}|nil, number, number): string|nil
global menu_mappack_filter_indices: function({any}, string): {integer}
global menu_layout_mappack: function({string:any}|nil): {string:any}
global menu_layout_options_tabs: function(): {any}
global menu_layout_options_rows: function(number): {string:any}
global menu_layout_pause: function(number): {string:any}
global menu_layout_levelscreen: function(number): {string:any}
global menu_mappack_draw: function()
global menu_mappack_setup_filter: function()
global menu_mappack_teardown_filter: function()
global menu_mappack_mousepressed: function(number, number, any): boolean
global menu_mappack_mousemoved: function(number, number)
global menu_mappack_move: function(integer)
global menu_mappack_wheel: function(integer)
global menu_mappack_filtered: function(): {integer}
global menu_mappack_layout: function(): {string:any}
global mappack_skipped_count: number

global record UITheme
	GRID: number
	PAD: number
	GAP: number
	LINE: number
	SCREEN_W: number
	SCREEN_H: number
	COL: {string:{number}}
	panel_img: Image|nil
	panel_inset_img: Image|nil
	panel_quads: {Quad}|nil
	panel_inset_quads: {Quad}|nil
	debug_assert: boolean
end
global UI: UITheme
global theme_init: function()
global draw_panel: function(number, number, number, number)
global draw_panel_inset: function(number, number, number, number)
global ui_set_color: function(string)
global menu_draw_overlay: function()
global menu_draw_row_bg: function(number, number, number, number, string, number)
global menu_draw_cursor: function(number, number)
global menu_draw_footer: function(number, number, string)
global menu_draw_rule: function(number, number, number)
global menu_draw_tabs: function({any}, any, boolean)
global menu_opt_color: function(boolean)
global menu_draw_yesno: function(string, boolean, string|nil, number|nil)
global menu_layout_selectworld: function(): {string:any}

global record DesktopSize
	width: number
	height: number
end
global desktopsize: DesktopSize
global mappack: string
global mappackendless: boolean
global endlessseed: number
global endless_generate_for_mappack: function(string, number|nil): {any:any}
global endless_parse_room_name: function(string): string, {string:boolean}, string
global endless_copy_cell: function(MapCell): MapCell
global endless_generate: function(number, {{any:any}}, {any:any}|nil): {any:any}
global ENDLESS_ENEMIES: {string:{string:any}}
global endless_populate: function({number:{number:MapCell}}, number, number, number, number, string, number, {any:any}, number|nil): {string}
global endless_room_kind_from_name: function(string): string
global ENEMY_MOVES: {string:function(enemy, number)}
global enemymove_dispatch: function(enemy, number)
global enemymove_drybones_stomp: function(enemy): boolean
global enemymove_turret_topple: function(enemy)
global enemymove_splitter_die: function(enemy): boolean
global enemymove_thwomp_floor: function(enemy)
global enemymove_charger_wall: function(enemy, any, Entity|nil)
global endless_path_connected: function({{number}}): boolean
global endless_no_deadlock: function({{number}}, integer): boolean
global endless_get_templates: function(string): {{any:any}}
global endless_room_from_text: function(string, string): {any:any}|nil
global endless_load_templates_from_dir: function(string, function(string): (string|nil), {string}|nil): {{any:any}}
global endless_load_templates: function(string, function(string): (string|nil), {string}): {{any:any}}
global endless_stitch: function({{{any:any}}}, integer, integer, {any:any}|nil): {number:{number:MapCell}}, {number:{number:boolean}}, number, number
global endless_new_rng: function(number): {any:any}
global endless_assign_rooms: function({{{any:any}}}, {{any:any}}, {number}, {number}, {any:any})
global currentlevel: string|number|{any:any}

-- Typed session / services (World / AssetStore records are already globals)
global session: World
global assets: AssetStore
global Gamestate: GamestateModule
global HumpTimer: HumpTimerModule
global Flux: FluxModule
global scroll_update: function(number)
global world_camera_drawing: boolean
global world_camera_attach: function()
global world_camera_detach: function()
global editor_camera_sync: function()
global wpx: function(number): number
global wpy: function(number): number
global world_batch_offset: function(number): number
global draw_world_tiles: function()
global draw_world_foreground: function()
global world_viewport_w: function(): number
global world_viewport_h: function(): number
global world_screen_x: function(number): number
global world_screen_y: function(number): number
global tile_draw_x: function(number): number
global tile_draw_y: function(number, number): number
global tile_draw_y_raw: function(number): number
global world_draw_scale: function(): number
global world_flip_scale: function(number): number
global entity_draw_x: function(number, number): number
global entity_draw_y: function(number, number): number
global screen_draw_x: function(number): number
global screen_draw_y: function(number): number
global screen_to_tile_x: function(number): number
global screen_to_tile_y: function(number): number
global world_screen_px_x: function(number): number
global world_screen_px_y: function(number): number
global weapon_draw_xy: function(number, number): number, number
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
global portalsavailable: {any:boolean}
global levelweapons: {string}
global Weapons: WeaponsModule
global controls: {any:{any:any}}
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

-- Level / world visuals
global spriteset: integer
global custombackground: any
global customforeground: any
global backgroundlevel: any
global background: {any:number}
global smbtilecount: integer
global portaltilecount: integer
global customtilecount: integer
global modcustomtiles: integer|boolean
global modcustomtilecount: {integer:number}
global music: MusicPlayer
global musicname: string

global record RippleInstance
	pitch: number
	loop: boolean
	volume: number
	isStopped: function(RippleInstance): boolean
	pause: function(RippleInstance, ...: any)
	resume: function(RippleInstance, ...: any)
	stop: function(RippleInstance, ...: any)
end

global record RippleSound
	volume: number
	loop: boolean
	play: function(RippleSound, ...: any): RippleInstance
	pause: function(RippleSound, ...: any)
	resume: function(RippleSound, ...: any)
	stop: function(RippleSound, ...: any)
	update: function(RippleSound, number)
	tag: function(RippleSound, ...: any)
	untag: function(RippleSound, ...: any)
end

global record RippleTag
	volume: number
	pause: function(RippleTag, ...: any)
	resume: function(RippleTag, ...: any)
	stop: function(RippleTag, ...: any)
	tag: function(RippleTag, ...: any)
	untag: function(RippleTag, ...: any)
end

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
	sound: RippleSound
	lastplayed: number
	duration: number
end
global soundlist: {any:SoundEntry}
global record ShadersController
	scale: any
	set: function(ShadersController, any, any)
	setParameter: function(ShadersController, string, string, ...: any): boolean, string
	update: function(ShadersController, any)
	refresh: function(ShadersController, ...: any): any
	predraw: function(ShadersController, ...: any): any
	postdraw: function(ShadersController, ...: any): any
	init: function(ShadersController, integer|nil)
end

global shaders: ShadersController
global shaderlist: {number:string}
global guielements: {any:guielement}
global volumesfx: number
global volumemusic: number
global audio_tag_music: RippleTag
global audio_tag_sfx: RippleTag
global audio_apply_volumes: function()
global audio_bind_sfx: function(string, Source|nil, {string:any}|nil)
global audio_set_pitch: function(number)
global audio_ripple_set_pitch: function(RippleSound, number)
global sound_playing: function(string): boolean
global stopsound: function(string)
global sound_duration: function(string): number
global speed: number
global speedtarget: number
global scrollingscores: {any:scrollingscore}
global flagx: any
global axex: any
global startx: {number}
global starty: {number}
global levelfinished: boolean
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
global level_mapmode: boolean
global mapmode_zoom: number
global mapmode_pad_x: number
global mapmode_pad_y: number
global mapmode_tile_y_off: function(): number
global mapmode_update_view: function(mario)
global mapmode_player_cell: function(mario): integer, integer
global mapmode_cell_center: function(integer, integer, mario): number, number
global mapmode_snap_to_start: function(mario)
global mapmode_try_enter_level: function(mario): boolean
global mapmode_cell_walkable: function(integer, integer): boolean
global mapmode_snap_player: function(mario)
global mapmode_apply_movement: function(mario, number)
global EQUALSIGN: {any:string}
global seesawtype: {any:{any}}
global pausemenuoptions: {string}
global screenshake: function(number)
global screenshake_amp: function(): number
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
global http_is_stub: boolean
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
	slot: integer|nil
	host: boolean|nil
end
global record ChatMessage
	id: string
	message: string
end
global playerlist: {OnlinePlayer}
global chatmessages: {ChatMessage}

global record NetModule
	host: function(port: number, nick: string): boolean
	join: function(addr: string, port: number, nick: string): boolean
	update: function(dt: number)
	quit: function()
	start_match: function()
	chat: function(text: string)
	status: function(): string
	in_match: function(): boolean
	is_online: function(): boolean
	role: function(): string
	local_slot: function(): integer
	held_for: function(slot: integer, action: string): boolean|nil
	peers: function(): {{string:any}}
	chats: function(): {{string:any}}
end
global Net: NetModule

global record SockClient
	getIndex: function(SockClient): integer
	send: function(SockClient, string, any)
	disconnectLater: function(SockClient)
	disconnectNow: function(SockClient, integer|nil)
	disconnect: function(SockClient, integer|nil)
	setSerialization: function(SockClient, ...: any)
	setSendMode: function(SockClient, string)
	resetSendSettings: function(SockClient)
	connect: function(SockClient)
	update: function(SockClient)
	on: function(SockClient, string, function(any))
end

global record SockServer
	update: function(SockServer)
	on: function(SockServer, string, function(any, SockClient))
	sendToAll: function(SockServer, string, any)
	sendToAllBut: function(SockServer, SockClient, string, any)
	setSerialization: function(SockServer, ...: any)
	setSendMode: function(SockServer, string)
	resetSendSettings: function(SockServer)
	destroy: function(SockServer)
end

global record SockModule
	newServer: function(string, number, integer|nil): SockServer
	newClient: function(string, number): SockClient
end

global record BitserModule
	dumps: function(any): string
	loads: function(string): any
end

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
global coinframe: integer
global modcustomtilesimg: {number:Image}
global scrollfactor: number
global custombackgroundheight: {any:{number}}
global custombackgroundwidth: {any:{number}}
global testlevel: boolean
global checkpointx: {number:number}
global globools: {string:boolean}
global pipestartx: number
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
global usemagic: boolean
global modcustomspritebatch: {number:any}
global blockbouncex: {any:number}
global blockbouncey: {any:number}
global fscrollfactor: number
global infinitetime: boolean
global portaldelay: {number:number}
global gelcannontimer: number
global spritebatchX: {any}
global spritebatchY: {any}
global spritebatch_cols: integer
global spritebatch_rows: integer
global spritebatch_floor_x: integer
global spritebatch_floor_y: integer
global spritebatch_view: {number:{number:SpriteBatchViewCell|nil}}
global spritebatch_orphan_slots: integer
global spritebatch_portal_catchup: boolean
global spritebatch_dirty: boolean
global invalidate_spritebatch_after_portal_teleport: function()
global firestartx: any
global pipestarty: number
global fireanimationtime: number
global soundenabled: boolean
global editordebug: any
global portalknockback: boolean
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
global spawnrestrictions: {integer:boolean}
global add_spawn_restriction: function(sx: number, sy: number)
global gamefinished: boolean
global frameskip: any
global mkstation: boolean
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
global portalparticletimer: number
global firedelay: number
global flyingfishstarted: boolean
global flyingfishtimer: number
global bulletbillstarted: boolean
global bulletbilltimer: number
global flyingfishzones: {{number|boolean}}
global bulletbillzones: {{number|boolean}}
global mazesolved: {any}
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
global selectworldopen: boolean
global currentfiledownload: number
global mappackname: {any}
global downloaderror: boolean
global onlinemappackicon: {Image}
global onlinemappackauthor: {any}
global toconvertmappackauthor: {any}
global touchfrominsidemissing: number
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
global ypan: any
global lastrepeat: number
global flyingfishstartx: any
global flyingfishendx: any
global bulletbillstartx: any
global bulletbillendx: any
global lakitoendx: any
global mazeinprogress: boolean
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
global flyinguptime: number
global flytime: number
global maxspeedfly: number
global maxspeeds: {number}
global flyingascension: number
global flyacceleration: number
global frictionflysmall: number
global frictionflybig: number
global frictionskidfly: number
global floatascension: number
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
global gelgroundimgs: {Image}
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
global enable_debugbinds: function()
global portal_pair_offsets: function(any, any): number, number, number, number
global maxyspeed: number
global overwrittenimages: {string}
global soundstoload: {string}
global defaultsoundslist: {string:any}
global overwrittensounds: {string}
global directionsquad: {number:any}
global starttime: number
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
global menu_mappack_title: function(any, any): string
global menu_mappack_author_line: function(any, any): string
global menu_mappack_desc_lines: function(any, any): string, string, string, string
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
global PHYSICS_GROUP_ORDER: {string}
global physics_group_keys_sorted: function({any: any}): {any}
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
global gelspeedmul: number
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
global netstatus: string
global magicdns_available: function(): boolean
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
global rsflipflopimg: Image
global scoredelay: number
global scrollsmoothrate: number
global spawnarea: {any}
global speedmodifier: number
global springimg: Image
global donutimg: Image
global powblockimg: Image
global flipblockimg: Image
global beltimg: Image
global longfireimg: Image
global smallspringimg: Image
global collectableimg: Image
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
global draw_tile_gel_overlays: function({number}, number, number, number, number)
global draw_entity_gel_overlays: function({string:any}, number, number, number, number)
global entity_set_gel: function(any, integer, number)
global entity_gel_id: function(any, integer): number|nil
global map_cell_set_gel: function(MapCell, integer, number)
global map_cell_gel_id: function(MapCell, integer): number|nil
global init_map_cell_gels: function(MapCell)
global GEL_SIDE_TOP: integer
global GEL_SIDE_RIGHT: integer
global GEL_SIDE_BOTTOM: integer
global GEL_SIDE_LEFT: integer
global GEL_SIDE_BY_NAME: {string:integer}
global GEL_BOUNCE: integer
global GEL_SPEED: integer
global GEL_CLEANSE: integer
global GEL_ADHERE: integer
global GEL_MAX_ID: integer
global GEL_POOL_MAX: integer
global gel_has: function(number|nil, string): boolean
global gel_react_floor: function({string:any}, number|nil): boolean
global gel_react_side: function({string:any}, number|nil, integer): boolean
global gel_clamp_id: function(any): integer
global gel_pool_prepare: function()
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
global checkmagic: function(s: string): boolean
global checkportalHOR: function(Entity, number): boolean
global checkportalVER: function(Entity, number): boolean
global checkportalremove: function(any, any)
global checkrect: function(x: number, y: number, width: number, height: number, list: any, statics?: any): {integer:any}
global physics_world_reset: function()
global physics_world_refresh: function()
global physics_world_prune: function()
global physics_world_upsert: function(item: any, group: string, key: any)
global physics_world_remove: function(item: any)
global physics_world_query: function(x: number, y: number, w: number, h: number, filter?: any): {integer: any}, number
global physics_world_meta: function(item: any): string|nil, any
global physics_world_upsert_slot: function(group: string, key: any, body: any)
global physics_world_remove_slot: function(group: string, key: any)
global physics_world_set_tile: function(key: any, body: any|nil)
global physics_world_set_portalwall: function(key: string, body: any|nil)
global physics_world_insert_platform: function(body: any)
global closerightclickmenu: function()
global collectblock: function(any): any
global collectcoin: function(x: number, y: number, i?: any): any
global collisionscalls: function(any, Entity, any, Entity, any, any): any
global configdecrease: function()
global configincrease: function()
global continuegame: function()
global convertentity: function(any, {string:any}|nil): {any}, string|nil
global convert_level_text: function(string, {string:any}|nil): string|nil, string|nil
global convert_mappack_fs: function(string, string, {string:any}, {string:any}|nil): {string:any}|nil, string|nil
global convertfromstandard: function(Entity, number, number): number, number
global convertmappack: function(any)
global converttostandard: function(Entity, number, number): number, number
global validate_remap: function({string:any}|nil): {string}
global remap_kind: function(number): string
global normalize_legacy_map_entity: function({any})
global ENEMY_REMAP: {number:string}
global VARIANT_REMAP: {number:{string:any}}
global PASS_THROUGH: {number:boolean}
global OLD_ENTITY_NAMES: {string}
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
global with_mask: function(function(), function(), ?boolean)
global begin_mask: function(function(), ?boolean)
global end_mask: function()
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
global init_game_runtime_globals: function()
global game_load: function(suspended?: any)
global game_mousepressed: function(any, any, any)
global game_mousereleased: function(any, any, any)
global game_textinput: function(any)
global generateanimationgui: function(): any
global generateentitylist: function(): any
global generatespritebatch: function(integer, integer)
global updatespritebatch: function()
global tile_spritebatch_rebuild: function()
global tile_spritebatch_update_tile: function(number, number)
global tile_spritebatch_draw_bg: function()
global tile_spritebatch_draw_fg: function()
global create_tile_spritebatches: function(number|nil)
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
global mappack_path: function(name: string): string
global mappack_level_path: function(mappack_name: string, world: number|string, level: number|string, sublevel?: number): string
global level_name: function(world: number|string, level: number|string, sublevel?: number): string
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
global reset_level_state: function()
global fresh_objects: function(): {string:{any:Entity}}, {Entity}
global obj_group: function(string): {any:Entity}
global obj_insert: function(string, Entity)
global obj_each_group: function(string, function(Entity))
global obj_draw_group: function(string)
global logicgate_init_xy: function(any, number, number, {any})
global logicgate_link: function(any): any|nil
global logicgate_addoutput: function(any, any, any)
global logicgate_out: function(any, any)
global logicgate_draw_img: function(any, Image)
global OBJECT_GROUP_KEYS: {string}
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
global punt_hit: function({string:any}, string, {string:any}): boolean
global punt_kill: function({string:any}): boolean
global punt_kill_entity: function({string:any}): boolean
global punt_tick: function({string:any}, number)
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
global warpzone: function(any, any, any)

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
global camera_pan_stop: function()
global camera_pan_apply: function()
global update_and_compact: function(any, any)
global usebase: function(any): Dyn
global buildstartendzones: function(any, any): {{number|boolean}}
global remove_indices_desc_multi: function(any, any)
global enemy_name_ok: function(any): boolean
global normalize_enemy_props: function(any): Dyn
global apply_enemy_defaults: function(any, any): Dyn
global enemy_onscreen: function(any, any, any, any): boolean
global onscreen: function(number, number, number|nil, number|nil): boolean
global prof_push: function(string)
global prof_pop: function(string|nil)
global gcpace_configure: function()
global gcpace_step: function()
global gcpace_after_load: function()
global keepalive_pump: function()
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


global record GelDef
	id: integer
	name: string
	bounce: boolean|nil
	speed: boolean|nil
	cleanse: boolean|nil
	adhere: boolean|nil
end
global GEL_DEFS: {integer:GelDef}

-- Editor docks / palettes / autotile / cell-undo (ui.editor_*)
global record EditorRect
	x: number
	y: number
	w: number
	h: number
end

global record EditorLayoutState
	toolbar: EditorRect
	palette: EditorRect
	canvas: EditorRect
	props: EditorRect
	minimap: EditorRect
	hint: EditorRect
	palette_collapsed: boolean
	props_collapsed: boolean
	palette_w: number
	props_w: number
	tile_ox: number
	tile_oy: number
	tile_cols: number
	dock_mode: boolean
end

global EDITOR_LAYOUT: EditorLayoutState
global tilelist_ox: number
global tilelist_oy: number
global tilelist_cols: number

global record AutotileGroup
	name: string
	mode: integer
	tiles: {integer}
	set: {integer:boolean}
end

global AUTOTILE_GROUPS: {string:AutotileGroup}
global AUTOTILE_BY_TILE: {integer:string}
global autotile_enabled: boolean

global editor_test_restore: {string:any}|nil

-- Function bindings (implemented in ui.* modules)
global layout_recalc: function(string|nil, boolean|nil)
global layout_toggle_palette: function()
global layout_toggle_props: function()
global layout_hit: function(EditorRect, number, number): boolean
global layout_over_canvas: function(number, number): boolean
global layout_rects_on_grid: function(): boolean

global build_palettes: function({string:any}|nil): any

global autotile_parse: function(string): {string:AutotileGroup}
global autotile_load_text: function(string)
global autotile_load_mappack: function(string|nil)
global autotile_mask: function(number, number, AutotileGroup): integer
global autotile_pick: function(AutotileGroup, integer): integer
global autotile_refresh_cell: function(number, number)
global autotile_around: function(number, number)
global autotile_region: function(number, number, number, number)
global autotile_paint: function(number, number, integer, boolean): boolean
global autotile_group_for_tile: function(integer): AutotileGroup|nil

global editor_undo_begin: function()
global editor_undo_record: function(number, number)
global editor_undo_commit: function()
global editor_undo: function(): boolean
global editor_redo: function(): boolean
global editor_undo_clear: function()

global EDITOR_RECENT_TILES: {integer}
global EDITOR_PALETTE_CATEGORY: string
global editor_recent_push: function(integer)
global editor_recent_list: function(): {integer}
global palette_entity_categories: function(any): {string}
global palette_entities_filtered: function(any, string|nil): {any}
global editor_cycle_palette_category: function(any): string

global editor_cheats_used: boolean
global editor_clear_cheats: function()
global editor_mark_cheats: function()
global editor_pass_clearcheck: function(): boolean
global editor_has_clearcheck: function(any, any, any): boolean
global editor_clear_check: function(): boolean, string
global editor_run_clearcheck_ui: function()

global editor_draw_live_preview: function()

global record EditorDragState
	kind: string
	ox: number
	oy: number
	from_x: number
	from_y: number
	to_x: number
	to_y: number
	started: boolean
	handle: string|nil
	ent_t: string|nil
end
global EDITOR_DRAG: EditorDragState|nil
global editor_drag_begin: function(number, number, boolean)
global editor_drag_move: function(number, number): boolean
global editor_drag_end: function(number, number)
global editor_drag_active: function(): boolean

global ENEMY_MODIFIERS: {string:{string:any}}
global ENEMY_MODIFIER_ORDER: {string}
global apply_enemy_modifiers: function(any, {any}|nil)
global enemy_modifier_ids_from_args: function({any}|nil): {string}
global enemy_drop_modifier: function(string, number, number): boolean

global editor_capture_test_restore: function({string:any}|nil)
global editor_apply_test_restore: function(boolean|nil)
global test_level_from_cursor: function()

global record MetroidRoom
	id: string
	x: number
	y: number
	w: number
	h: number
	scroll_h: boolean
	scroll_v: boolean
	flags: string
	doors: {{string:any}}
	items: {{string:any}}
	spawns: {{string:any}}
end

global ROOMS: {MetroidRoom}
global ROOMS_BY_ID: {string:MetroidRoom}
global START_ROOM: string
global currentroom: MetroidRoom|nil
global metroidmode: boolean
global roomtransition: number
global metroidmapopen: boolean
global metroid_playtime: number
global ABILITIES: {string:{string:string}}
global ABILITY_TEXT: {string:string}
global DOOR_TYPES: {string:function(any, any): boolean}
global DOOR_COLOR: {string:{number}}
global room_at: function(number, number): MetroidRoom|nil
global roomcam_update: function(number)
global rooms_parse_txt: function(string): {MetroidRoom}
global rooms_parse_json: function({string:any}): {MetroidRoom}
global rooms_set: function({MetroidRoom})
global rooms_clear: function()
global room_enter: function(MetroidRoom, MetroidRoom|nil)
global map_reveal: function(string)
global spawn_room: function(MetroidRoom)
global despawn_room: function(MetroidRoom)
global metroid_try_load_mappack: function(string): boolean
global metroid_try_load_level: function(string, string|nil): boolean
global metroid_bootstrap_from_player: function()
global metroid_mark_killed: function(number, number)
global metroid_load_rooms_from_strings: function(string|nil, string|nil): boolean
global room_camera_target: function(MetroidRoom, number, number, number, number): number, number
global has_ability: function(any, string): boolean
global grant_ability: function(any, string)
global metroid_reapply_abilities: function(any)
global has_weapon: function(any, string): boolean
global door_can_pass: function(string, any, any): boolean
global door_try_open: function(string, string, any, any): boolean
global door_uid: function(number, number): string
global door_is_open: function(string): boolean
global door_set_open: function(string, boolean)
global fake_player_from_abilities: function({string:boolean}): {string:any}
global world_reachability_check: function(string|nil): {string}
global metroidmap_toggle: function()
global metroidmap_close: function()
global metroidmap_draw: function()
global metroid_save: function(integer): boolean
global metroid_load: function(integer): {string:any}|nil
global metroid_autosave: function()
global metroid_use_hp: function(): boolean
global metroid_hurt: function(any, number): boolean
global metroid_apply_hp_to_player: function(any)
