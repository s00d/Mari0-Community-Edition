global type Dyn = {any:Dyn}

global record Font
	getWidth: function(self: Font, text?: string): number
	getHeight: function(Font): number
end

-- Character config bag (assets/characters/*/config.txt + quads from characterloader).
-- Declared before Entity so Entity.char can be Character.
global record Character
	name: string
	smallquadwidth: number
	smallquadheight: number
	bigquadwidth: number
	bigquadheight: number
	smallimgwidth: number
	smallimgheight: number
	bigimgwidth: number
	bigimgheight: number
	runframes: number
	jumpframes: number
	customframes: number
	customscale: number
	smalloffsetX: number
	smalloffsetY: number
	bigoffsetX: number
	bigoffsetY: number
	smallquadcenterX: number
	smallquadcenterY: number
	bigquadcenterX: number
	bigquadcenterY: number
	shrinkquadcenterX: number
	shrinkquadcenterY: number
	shrinkquadcenterY2: number
	growquadcenterX: number
	growquadcenterY: number
	growquadcenterY2: number
	duckquadcenterY: number
	duckoffsetY: number
	rundelay: number
	raccoon: boolean
	nopointing: boolean
	dbljmppls: boolean
	nogunanimations: {any}
	nogunbiganimations: {any}
	animations: {any}
	biganimations: {any}
	flowercolor: {any}
	defaultcolors: {integer:{{number}}}
	defaulthat: any
	colorables: {any}
	hatoffsets: Dyn
	bighatoffsets: Dyn
	idle: {any:any}
	run: {any:{any:any}}
	slide: {any:any}
	jump: {any:{any:any}}
	die: {any:any}
	climb: {any:{any:any}}
	swim: {any:{any:any}}
	grow: {any:any}
	customframe: {any:{any:any}}
	bigidle: {any:any}
	bigrun: {any:{any:any}}
	bigslide: {any:any}
	bigjump: {any:{any:any}}
	bigfire: {any:any}
	bigclimb: {any:{any:any}}
	bigswim: {any:{any:any}}
	bigduck: {any:any}
	bigcustomframe: {any:{any:any}}
end

-- Heterogeneous world objects. Number/boolean fields used in arithmetic or
-- control flow are concrete; polymorphic bags/methods stay `any` so concrete
-- `record … is Entity` may refine them. Prefer `as mario` at call sites.
global interface Body
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}|nil
	cox: number
	coy: number
	gravity: number|nil
	gravitydirection: number|nil
	portalable: boolean|nil
end
-- Keep open-array escape: closing Entity breaks open-field access across hundreds of entity sites (cyan red).
global interface Entity is {any}
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {any:boolean}
	draw: function(Entity)
	update: function(Entity, number): any...
	t: any
	i: any
	cox: number
	coy: number
	dir: any
	timer: number
	frame: number
	rotation: number
	gravity: number
	gravitydirection: number
	portalable: boolean
	drawable: boolean
	dead: boolean
	shot: boolean
	falling: boolean
	flying: boolean
	small: boolean
	emancipatecheck: boolean
	killsenemies: any
	nocollidestops: any
	funnel: any
	lastblock: any
	jumping: any
	upsidedown: boolean
	delete: boolean
	kill: boolean
	open: boolean
	mirror: any
	remote: boolean
	customscissor: any
	invertedscissor: any
	portaloverride: any
	customscale: number
	offsetX: number
	offsetY: number
	quadcenterX: number
	quadcenterY: number
	quad: any
	graphic: any
	biggraphic: any
	colors: {any}
	hats: {any}
	char: Character
	animationdirection: any
	animationstate: any
	animationtimer: number
	runframe: number
	jumpframe: number
	climbframe: number
	swimframe: number
	walkframe: number
	underwater: boolean
	infunnel: boolean
	fireanimationtimer: number
	ducking: boolean
	drawhat: boolean
	pointingangle: number
	controlsenabled: boolean
	portalsavailable: {any:boolean}
	destroy: any
	portalgundisabled: boolean
	disableaiming: boolean
	vine: Entity|boolean
	lastportal: number
	portal: any
	portal1color: any
	portal2color: any
	looktimer: number
	previouslyonground: boolean
	startfall: any
	startx: number
	starty: number
	endx: any
	endy: any
	thickness: number
	mazevar: number
	size: number
	runanimationprogress: number
	starred: boolean
	invincible: boolean
	pickup: any
	payload: any
	gels: {string:any}
	slant: string
	callback: any
	link: function(any, ...: any): any|nil
	backwards: boolean
	notkilledfromblocksbelow: boolean
	jumpsfromblocksbelow: boolean
	jumpforce: number
	shotted: function(Entity, ...: any): any
	rangex: number
	rangey: number
	removeportals: function(Entity, ...: any): any
	jump: any
	leftkey: any
	rightkey: any
	stopjump: any
	die: any
	fall: any
	portaled: function(Entity, any)
	cubeemancipate: function(any, ...: any): any
	-- EnemyDef-ish props accessed via Entity in mario collide paths
	shellanimal: any
	stompable: any
	kills: any
	killsontop: any
	killsonbottom: any
	killsonsides: any
	stompcombosuppressor: any
	makesmariogrow: any
	givesacoin: any
	givescoinamount: any
	givestime: any
	givestimeamount: any
	givesalife: any
	makesmariostar: any
	booloncollect: any
	boolactoncollect: any
	intoncollect: any
	intactoncollect: any
	intactvalue: any
	collectsound: any
	hit: any
	emancipate: function(any, ...: any): any
	limit: any
	destroying: any
	dropped: any
	fire: any
	use: any
	grow: any
	respawn: any
	shootgel: any
	portalpickup: any
	animationwalk: any
	stopanimation: any
	setquad: any
	pickupbox: any
	savereplaydata: any
	updaterange: function(Entity, ...: any): any
	getTileInvolved: function(Entity, ...: any): any, any
	updateangle: any
	input: function(any, ...: any): any
	used: function(any, ...: any): any
	onbutton: function(any, ...: any): any
	passivecollide: function(Entity, any, Entity, any, any): any
	floorcollide: function(Entity, any, Entity, any, any): any
	leftcollide: function(Entity, any, Entity, any, any): any
	rightcollide: function(Entity, any, Entity, any, any): any
	ceilcollide: function(Entity, any, Entity, any, any): any
	addoutput: function(Entity, any, any)
	stomp: function(Entity, ...: any): any
	laser: any
	fireballcallback: any
	ignorefaithplates: any
	faithplate: any
	callbackleft: any
	callbackright: any
	clear: function(any, ...: any): any
	firepoints: any
	autodelete: boolean
	autodeleted: any
	trigger: function(any, ...: any): any
end

-- Minimal LÖVE 11 API surface for Teal (expand as modules need more).
-- Loaded via tlconfig global_env_def = "love"

global record love
	enum ModuleName
		"audio" "data" "event" "filesystem" "font" "graphics"
		"image" "joystick" "keyboard" "math" "mouse" "physics"
		"sound" "system" "thread" "timer" "touch" "video" "window"
	end

	getVersion: function(): number, number, number, string
	_version: string
	_version_minor: number
	_os: string
	handlers: {string:function}
	quit: function()

	record conf
		record Config
			title: string
			identity: string
			console: boolean
			modules: {string:boolean}
			window: {string:any}
		end
	end

	record graphics
		print: function(text: string, x: number, y: number)
		printf: function(...: any)
		newImage: function(...: any): Image
		newQuad: function(x: number, y: number, w: number, h: number, sw: number, sh: number): Quad
		newCanvas: function(...: any): Canvas
		newShader: function(code: string): Shader
		newSpriteBatch: function(image: Image, size?: integer, usage?: string): SpriteBatch
		setColor: function(...: any)
		setBackgroundColor: function(...: any)
		getBackgroundColor: function(): number, number, number, number
		clear: function(...: number)
		draw: function(...: any)
		getWidth: function(): number
		getHeight: function(): number
		setDefaultFilter: function(min: string, mag: string)
		setPointSize: function(s: number)
		setScissor: function(...: any)
		setCanvas: function(...: any)
		setShader: function(shader: Shader|nil)
		origin: function()
		push: function()
		pop: function()
		scale: function(sx: number, sy?: number)
		translate: function(x: number, y: number)
		rotate: function(angle: number)
		rectangle: function(mode: string, x: number, y: number, w: number, h: number)
		stencil: function(...: any)
		isSupported: function(feature: string): boolean
		isCreated: function(): boolean
		reset: function()
		setNewFont: function(...: any): Font
		getRendererInfo: function(): string, string, string, string
		setBlendMode: function(...: any)
		getBlendMode: function(): string
		setColorMask: function(...: any)
		setStencilTest: function(...: any)
		setLineStyle: function(style: string)
		setLineWidth: function(width: number)
		getLineWidth: function(): number
		line: function(...: number)
		polygon: function(...: any)
		circle: function(...: any)
		present: function()
		newScreenshot: function(...: any): any
	end

	record audio
		newSource: function(path: string, source_type: string): Source
		play: function(...: any)
		stop: function(...: any)
		pause: function(...: any): any...
		setVolume: function(v: number)
	end

	record filesystem
		getInfo: function(path: string, filter?: string): {string:any}|nil
		getDirectoryItems: function(path: string): {string}
		read: function(path: string): string|nil, string|nil
		write: function(path: string, data: string): boolean, string|nil
		createDirectory: function(path: string): boolean
		getSaveDirectory: function(): string
		getSource: function(): string
		mount: function(archive: string, mountpoint: string): boolean
		remove: function(path: string): boolean
	end

	record keyboard
		isDown: function(...: string): boolean
		isScancodeDown: function(...: string): boolean
		getScancodeFromKey: function(key: string): string
	end

	record mouse
		isDown: function(...: any): boolean
		getX: function(): number
		getY: function(): number
		getPosition: function(): number, number
		setPosition: function(x: number, y: number)
		setVisible: function(visible: boolean)
		getVisible: function(): boolean
		setGrabbed: function(grabbed: boolean)
		isGrabbed: function(): boolean
	end

	record Joystick
		getHatCount: function(self: Joystick): number
		getAxisCount: function(self: Joystick): number
		getHat: function(self: Joystick, index: number): string
		getAxis: function(self: Joystick, index: number): number
		isDown: function(self: Joystick, ...: any): boolean
		isGamepadDown: function(self: Joystick, ...: any): boolean
		getName: function(self: Joystick): string
		getID: function(self: Joystick): number
		setVibration: function(self: Joystick, ...: any): any
	end

	record joystick
		getJoysticks: function(): {Joystick}
		getJoystickCount: function(): number
	end

	record timer
		getTime: function(): number
		getDelta: function(): number
		getFPS: function(): number
		sleep: function(s: number)
		step: function(): number
	end

	record window
		setMode: function(w: number, h: number, flags?: {string:any}): boolean
		getMode: function(): number, number, {string:any}
		setTitle: function(title: string)
		setIcon: function(data: any)
		getFullscreenModes: function(): {{string:any}}
		isOpen: function(): boolean
	end

	record system
		setClipboardText: function(text: string)
		getClipboardText: function(): string
		getOS: function(): string
		openURL: function(url: string): boolean
	end

	record event
		quit: function(code?: number)
		pump: function()
		-- Love poll iterator yields event name + up to 4 payload values
		poll: function(): function(): string, any, any, any, any
	end

	record math
		random: function(...: number): number
		setRandomSeed: function(seed: number)
		newRandomGenerator: function(...: any): any
	end

	record image
		newImageData: function(...: any): ImageData
	end

	load: function(arg: {string})
	update: function(dt: any)
	draw: function()
	keypressed: function(key: any, scancode: any, isrepeat: any)
	keyreleased: function(key: any, scancode: any)
	textinput: function(text: any)
	mousepressed: function(...: any)
	mousereleased: function(...: any)
	wheelmoved: function(x: any, y: any)
	joystickpressed: function(joystick: any, button: any)
	joystickreleased: function(joystick: any, button: any)
	joystickaxis: function(joystick: any, axis: any, value: any)
	joystickhat: function(joystick: any, hat: any, direction: any)
	focus: function(f: any)
	resize: function(w: number, h: number)
	run: function(): function()|nil
	errhand: function(...: any)
end

global record Joystick
	getHatCount: function(self: Joystick): number
	getAxisCount: function(self: Joystick): number
	getHat: function(self: Joystick, index: number): string
	getAxis: function(self: Joystick, index: number): number
	isDown: function(self: Joystick, ...: any): boolean
	isGamepadDown: function(self: Joystick, ...: any): boolean
	getName: function(self: Joystick): string
	getID: function(self: Joystick): number
end

global record ImageData
	getWidth: function(ImageData): number
	getHeight: function(ImageData): number
	getPixel: function(ImageData, number, number): number, number, number, number
	setPixel: function(ImageData, number, number, number, number, number, number)
	encode: function(self: ImageData, format: string, filename?: string)
end

global record Image
	getWidth: function(self: Image): number
	getHeight: function(self: Image): number
	setFilter: function(self: Image, min: string, mag: string)
end

global record Quad
end

global record Canvas
	renderTo: function(self: Canvas, fn: function())
	clear: function(self: Canvas, ...: number)
	setFilter: function(self: Canvas, min: string, mag: string)
end

global record Shader
	send: function(self: Shader, name: string, ...: any)
end

global record Source
	setPitch: function(Source, number)
	setVolume: function(Source, number)
	play: function(Source)
	stop: function(Source)
	play: function(self: Source)
	stop: function(self: Source)
	setVolume: function(self: Source, v: number)
	setLooping: function(self: Source, loop: boolean)
	seek: function(self: Source, position: number, unit?: string)
	getDuration: function(self: Source, unit: string|nil): number
	isPlaying: function(self: Source): boolean
end

global record SpriteBatch
	add: function(self: SpriteBatch, ...: any): integer
	clear: function(self: SpriteBatch)
	flush: function(self: SpriteBatch)
	setColor: function(self: SpriteBatch, ...: number)
end

-- Game / session globals (see types/game.d.tl)
require("game")
