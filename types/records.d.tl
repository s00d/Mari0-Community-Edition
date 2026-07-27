-- Ambient class records (Teal handbook). Implementations live in src/**/*.tl.
-- Required from types/game.d.tl so every module sees constructors / self types.

global record actionblock is Entity, Body
	active: boolean
	category: number
	cox: number
	coy: number
	height: number
	mask: {boolean}
	outtable: {{any}}
	speedx: number
	speedy: number
	state: string
	static: boolean
	timer: number
	width: number
	x: number
	y: number
	init: function(actionblock, number, number)
	addoutput: function(actionblock, any, any)
	update: function(actionblock, number): any...
	draw: function(actionblock)
	floorcollide: function(actionblock, any, Entity, any, any): any...
	out: function(actionblock, any)
	new: function(actionblock, number, number): actionblock
end

global record andgate is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	initial: boolean
	inputstate: {any:any}
	outputstate: any
	outtable: {{any}}
	r: {any}
	visible: boolean
	x: number
	y: number
	init: function(andgate, number, number, any)
	link: function(andgate): any|nil
	addoutput: function(andgate, any, any)
	update: function(andgate, number): any...
	draw: function(andgate)
	out: function(andgate, any)
	input: function(andgate, any, any): any
	new: function(andgate, number, number, {any}): andgate
end

global record animatedbooltimer
	boolcheck: any
	delays: {number}
	dir: number
	frametimes: {number}
	length: number
	oldbool: boolean
	quadi: number
	quadobj: TileQuad
	timer: number
	x: number
	y: number
	init: function(animatedbooltimer, number, number, any)
	update: function(animatedbooltimer, number): any...
	input: function(animatedbooltimer, any)
	geti: function(animatedbooltimer): any...
	new: function(animatedbooltimer, number, number, any): animatedbooltimer
end

global record animatedquad
	boolean: any
	boolid: any
	cache: {any}
	delays: {any}
	image: Image
	imagedata: ImageData
	number: any
	portalable: any
	properties: {any}
	props: {any:any}
	quadi: number
	quadlist: {any}
	spikes: {any}
	timer: number
	triggered: any
	init: function(animatedquad, any, any, any): any...
	updateproperties: function(animatedquad): any...
	update: function(animatedquad, number): any...
	quad: function(animatedquad, any, any): any...
	getproperty: function(animatedquad, any, any, any): any...
	new: function(animatedquad, any, any, any): animatedquad
end

global record animatedtiletrigger is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	r: {any}
	regionX: any
	regionY: any
	regionheight: any
	regionwidth: any
	visible: boolean
	x: number
	y: number
	init: function(animatedtiletrigger, number, number, any)
	link: function(animatedtiletrigger): any|nil
	update: function(animatedtiletrigger): any...
	draw: function(animatedtiletrigger)
	input: function(animatedtiletrigger, any, any): any
	new: function(animatedtiletrigger, number, number, {any}): animatedtiletrigger
end

global record animatedtimer
	delays: {number}
	dir: number
	frametimes: {number}
	length: number
	quadi: number
	quadobj: TileQuad
	timer: number
	x: number
	y: number
	init: function(animatedtimer, number, number, any)
	update: function(animatedtimer, number): any...
	input: function(animatedtimer, any)
	geti: function(animatedtimer): any...
	new: function(animatedtimer, number, number, any): animatedtimer
end

global record animation
	actions: {{any}}
	conditions: {{any}}
	currentaction: number
	enabled: boolean
	filepath: string
	firstupdate: boolean
	name: string
	raw: any
	running: boolean
	sleep: number
	timer: number
	triggers: {{any}}
	init: function(animation, any, any)
	decode: function(animation, any)
	addtrigger: function(animation, {any})
	addcondition: function(animation, {any})
	addaction: function(animation, {any})
	update: function(animation, number): any...
	trigger: function(animation)
	draw: function(animation)
	decodenuminput: function(animation, any): number
	new: function(animation, any, any): animation
end

global record animationguielement
	gui: guielement
	width: number
	t: any
	value: any
	default: any
	nicename: any
	length: any
end

global record animationguiline
	deletebutton: guielement
	downbutton: guielement
	elements: {animationguielement}
	t: {any:any}
	type: string
	upbutton: guielement
	init: function(animationguiline, any, any): any...
	update: function(animationguiline, number): any...
	draw: function(animationguiline, number, number)
	click: function(animationguiline, number, number, any): any
	unclick: function(animationguiline, number, number, any): any
	delete: function(animationguiline): any...
	moveup: function(animationguiline): any...
	movedown: function(animationguiline): any...
	keypressed: function(animationguiline, string): any
	textinput: function(animationguiline, string): any
	changemainthing: function(animationguiline, any): any...
	submenuchange: function(animationguiline, any, any): any
	haspriority: function(animationguiline): any
	new: function(animationguiline, any, any): animationguiline
end

global record animationtrigger is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	draw: function(animationtrigger)
	update: function(animationtrigger, number): any...
	cox: number
	coy: number
	id: any
	r: {any}
	x: number
	y: number
	init: function(animationtrigger, number, number, any)
	link: function(animationtrigger): any|nil
	input: function(animationtrigger, any, any): any
	new: function(animationtrigger, number, number, {any}): animationtrigger
end

global record blockdebris is Entity, Body
	width: number
	height: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	frame: number
	speedx: number
	speedy: number
	timer: number
	x: number
	y: number
	init: function(blockdebris, number, number, any, any)
	update: function(blockdebris, number): any...
	draw: function(blockdebris)
	new: function(blockdebris, number, number, any, any): blockdebris
end

global record bowser is Entity, Body
	active: boolean
	animationdirection: string
	animationtimer: number
	backwards: boolean
	category: number
	direction: string
	drawable: boolean
	emancipatecheck: boolean
	fall: boolean
	fireframe: number
	graphic: any
	gravity: number
	gravitydirection: number
	hammers: boolean
	hammertime: number
	hammertimer: number
	height: number
	hp: number
	jump: boolean
	level: number
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	rotation: number
	shot: boolean
	speedx: number
	speedy: number
	startx: number
	starty: number
	static: boolean
	targetx: number
	timer: number
	walkframe: number
	width: number
	x: number
	y: number
	init: function(bowser, number, number, any)
	update: function(bowser, number): any...
	draw: function(bowser)
	newtargetx: function(bowser, any)
	shotted: function(bowser, ...: any): any
	firedeath: function(bowser, ...: any)
	leftcollide: function(bowser, any, Entity): any
	rightcollide: function(bowser, any, Entity): any
	ceilcollide: function(bowser, any, Entity): any
	startfall: function(bowser)
	floorcollide: function(bowser, any, Entity): any
	emancipate: function(bowser, any): any
	new: function(self: bowser, x: number, y: number, a?: any): bowser
end

global record box is Entity, Body
	draw: function(box)
	active: boolean
	category: number
	cox: number
	coy: number
	destroying: boolean
	drawable: boolean
	emancipatecheck: boolean
	falling: boolean
	funnel: boolean
	graphic: any
	gravity: number
	gravitydirection: number
	height: number
	infunnel: boolean
	jumping: any
	mask: {boolean}
	offsetX: number
	offsetY: number
	outtable: {{any}}
	parent: Entity|nil
	portaledframe: boolean
	portaloverride: boolean
	pushed: boolean
	quad: any
	quadcenterX: number
	quadcenterY: number
	rotation: number
	speedx: number
	speedy: number
	static: boolean
	userect: any
	width: number
	x: number
	y: number
	init: function(box, number, number)
	update: function(box, number): any...
	globalcollide: function(box, any, Entity, any, any, any): boolean
	ceilcollide: function(box, any, Entity, any, any): boolean
	leftcollide: function(box, any, Entity, any, any): boolean
	rightcollide: function(box, any, Entity, any, any): boolean
	floorcollide: function(box, any, Entity, any, any): boolean
	passivecollide: function(box, any, Entity, any, any): boolean
	startfall: function(box)
	emancipate: function(box, any): any
	destroy: function(box)
	addoutput: function(box, any, any)
	used: function(box, any): any
	dropped: function(box)
	portaled: function(box)
	enteredfunnel: function(box, any)
	faithplate: function(box, any)
	onbutton: function(box, any): any
	new: function(box, number, number): box
end

global record bubble is Entity, Body
	width: number
	height: number
	speedx: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	speedy: number
	x: number
	y: number
	init: function(bubble, number, number)
	update: function(bubble, number): any...
	draw: function(bubble)
	new: function(bubble, number, number): bubble
end

global record bulletbill is Entity, Body
	draw: function(bulletbill)
	active: boolean
	animationdirection: string
	autodelete: boolean
	category: number
	customscissor: any
	direction: string
	drawable: boolean
	graphic: any
	gravity: number
	height: number
	id: any
	killstuff: number
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	rotation: number
	shot: boolean
	speedx: number
	speedy: number
	startx: number
	static: boolean
	time: number
	timer: number
	width: number
	x: number
	y: number
	init: function(bulletbill, number, number, any)
	update: function(bulletbill, number): any...
	stomp: function(Entity, ...: any): any...
	shotted: function(Entity, ...: any): any...
	rightcollide: function(bulletbill, any, Entity): any...
	leftcollide: function(bulletbill, any, Entity): any...
	ceilcollide: function(bulletbill, any, Entity): any...
	floorcollide: function(bulletbill, any, Entity): any...
	globalcollide: function(bulletbill, any, Entity): any...
	portaled: function(bulletbill)
	new: function(bulletbill, number, number, any): bulletbill
end

global record button is Entity, Body
	speedx: number
	speedy: number
	active: boolean
	category: number
	cox: number
	coy: number
	dir: string
	drawable: boolean
	height: number
	input1state: any
	mask: {boolean}
	objtable: {any}
	out: boolean
	outtable: {{any}}
	pressings: {number:Entity}
	r: {any}
	static: boolean
	width: number
	x: number
	y: number
	init: function(button, number, number, any)
	update: function(button, number): any...
	draw: function(button)
	addoutput: function(button, any, any)
	new: function(button, number, number, {any}): button
end

global record camera
	x: number
	y: number
	scale: number
	rot: number
	init: function(self: camera, a?: number, b?: number, c?: number, d?: number)
	new: function(self: camera, a?: number, b?: number, c?: number, d?: number): camera
	lookAt: function(camera, number, number): camera
	move: function(camera, number, number): camera
	pos: function(camera): number, number
	rotate: function(camera, number): camera
	rotateTo: function(camera, number): camera
	zoom: function(camera, number): camera
	zoomTo: function(camera, number): camera
	attach: function(camera)
	detach: function(camera)
	draw: function(camera, function())
	cameraCoords: function(camera, number, number): number, number
	worldCoords: function(camera, number, number): number, number
	mousepos: function(camera): number, number
end

global record castlefire is Entity, Body
	speedx: number
	speedy: number
	draw: function(castlefire)
	active: boolean
	angle: number
	category: number
	child: {Entity}
	delay: number
	dir: string
	drawable: boolean
	graphic: any
	height: number
	kills: boolean
	length: number
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	quadi: number
	r: {any}
	static: boolean
	timer: number
	timer2: number
	width: number
	x: number
	y: number
	init: function(castlefire, number, number, any)
	update: function(castlefire, number): any...
	updatepos: function(castlefire)
	updatequad: function(castlefire)
	new: function(castlefire, number, number, {any}): castlefire
end

global record castlefirefire is Entity, Body
	speedx: number
	speedy: number
	draw: function(castlefirefire)
	update: function(castlefirefire, number): any...
	active: boolean
	angle: number
	category: number
	child: number
	delay: number
	dir: string
	drawable: boolean
	graphic: any
	height: number
	kills: boolean
	length: number
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	quadi: number
	r: {any}
	static: boolean
	timer: number
	timer2: number
	width: number
	x: number
	y: number
	init: function(castlefirefire)
	new: function(castlefirefire): castlefirefire
end

global record ceilblocker is Entity, Body
	speedx: number
	speedy: number
	category: number
	mask: {boolean}
	draw: function(ceilblocker)
	update: function(ceilblocker, number): any...
	active: boolean
	height: number
	static: boolean
	width: number
	x: number
	y: number
	init: function(ceilblocker, any)
	new: function(ceilblocker, any): ceilblocker
end

global record checkpoint is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	draw: function(checkpoint)
	all: boolean
	cox: number
	coy: number
	input1state: any
	p: {boolean}
	r: {any}
	regionX: number
	regionY: number
	regionheight: number
	regionwidth: number
	rest: boolean
	visible: boolean
	x: number
	y: number
	init: function(checkpoint, number, number, any)
	update: function(checkpoint): any...
	link: function(checkpoint): any|nil
	input: function(checkpoint, any, any): any
	trigger: function(checkpoint): any
	new: function(checkpoint, number, number, {any}): checkpoint
end

global record coinblockanimation is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	draw: function(coinblockanimation)
	frame: number
	timer: number
	x: number
	y: number
	init: function(coinblockanimation, number, number)
	update: function(coinblockanimation, number): any...
	new: function(coinblockanimation, number, number): coinblockanimation
end

global record cubedispenser is Entity, Body
	active: boolean
	box: Entity
	boxexists: boolean
	category: number
	cox: number
	coy: number
	height: number
	input1state: any
	inputactive: boolean
	mask: {boolean}
	r: {any}
	spawnondestroy: any
	speedx: number
	speedy: number
	static: boolean
	t: any
	timer: number
	width: number
	x: number
	y: number
	init: function(cubedispenser, number, number, any)
	input: function(cubedispenser, any, any): any
	link: function(cubedispenser): any|nil
	update: function(cubedispenser, number): any...
	draw: function(cubedispenser)
	removebox: function(cubedispenser)
	new: function(cubedispenser, number, number, {any}): cubedispenser
end

global record delayer is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	delay: number
	outtable: {{any}}
	r: {any}
	timers: {{string:any}}
	visible: boolean
	x: number
	y: number
	init: function(delayer, number, number, any)
	link: function(delayer): any|nil
	addoutput: function(delayer, any, any)
	update: function(delayer, number): any...
	draw: function(delayer)
	out: function(delayer, any)
	input: function(delayer, any, any): any
	new: function(delayer, number, number, {any}): delayer
end

global record dialogbox
	chardelay: number
	chartimer: number
	color: {number}
	curchar: number
	hasaprefix: boolean
	lifetime: number
	speaker: string
	text: string
	textcolors: {any}
	textsplit: {any}
	timer: number
	init: function(dialogbox, any, any)
	update: function(dialogbox, number): any...
	draw: function(dialogbox)
	new: function(dialogbox, any, any): dialogbox
end

global record door is Entity, Body
	speedx: number
	speedy: number
	active: boolean
	category: number
	cox: number
	coy: number
	dir: string
	drawable: boolean
	firstupdate: boolean
	forceclose: any
	height: number
	input1state: any
	mask: {boolean}
	open: boolean
	r: {any}
	static: boolean
	targetopen: boolean
	timer: number
	width: number
	x: number
	y: number
	init: function(door, number, number, any)
	link: function(door): any|nil
	update: function(door, number): any...
	draw: function(door)
	pushstuff: function(door)
	input: function(door, any, any): any
	closeopen: function(door, any)
	new: function(door, number, number, {any}): door
end

global record emancipateanimation is Entity, Body
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	height: number
	img: Image
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	rotation: number
	rotationspeed: number
	speedx: number
	speedy: number
	timer: number
	timer2: number
	width: number
	x: number
	y: number
	init: function(emancipateanimation, number, number, any, any, any, any, any, any, any, any, any, any, any)
	update: function(emancipateanimation, number): any...
	draw: function(emancipateanimation)
	new: function(emancipateanimation, number, number, any, any, any, any, any, any, any, any, any, any, any): emancipateanimation
end

global record emancipationfizzle is Entity, Body
	width: number
	height: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	r: number
	rotspeed: number
	speedx: number
	speedy: number
	timer: number
	x: number
	y: number
	init: function(emancipationfizzle, number, number, any, any)
	update: function(emancipationfizzle, number): any...
	draw: function(emancipationfizzle)
	new: function(emancipationfizzle, number, number, any, any): emancipationfizzle
end

global record emancipationgrill
	width: number
	height: number
	speedx: number
	speedy: number
	static: boolean
	category: number
	mask: {boolean}
	active: boolean
	destroy: any
	dir: any
	endx: number
	endy: number
	inputstate: any
	involvedtiles: {any:any}
	particles: Dyn
	r: {any}
	range: number
	startx: number
	starty: number
	thickness: number
	x: number
	y: number
	init: function(emancipationgrill, number, number, any)
	link: function(emancipationgrill)
	update: function(emancipationgrill, number): any...
	draw: function(emancipationgrill)
	getTileInvolved: function(emancipationgrill, any, any): any, any
	input: function(emancipationgrill, any, any)
	new: function(emancipationgrill, number, number, {any}): emancipationgrill
end

global record enemy is Entity, Body
	category: number
	draw: function(enemy)
	a: {any}
	active: boolean
	animationdirection: string
	animationframes: number
	animationspeed: number
	animationstart: number
	animationtimer: number
	animationtype: string
	bounceforce: number
	bounces: number
	breakblockside: any
	breaksblocks: number
	chasemarioonwakeup: number
	chasespeed: number
	chasetime: number
	chasetimer: number
	combo: number
	currentcustomtimerstage: number
	customscissor: any
	customtimer: {any}
	customtimertimer: number
	dead: boolean
	deathtimer: number
	direction: any
	distancetime: number
	doesntflyawayonfireball: number
	doesntunrotate: number
	dontactuallytransform: number
	dontmirror: number
	dontpistondist: number
	dontpistonnearplayer: number
	downy: number
	drawable: boolean
	facesplayer: number
	falling: boolean
	fallswhenstomped: number
	firstanimationtype: string
	firstmovement: any
	flyingdistance: number
	flyingtime: number
	flyingtimer: number
	followspace: number
	followspeed: number
	funnel: boolean
	givecoinwhenshot: boolean
	givecoinwhenstomped: number
	graphic: any
	gravity: number
	gravitydirection: number
	health: number
	height: number
	inactiveonretracted: number
	infunnel: boolean
	jumpforce: number
	jumpforcedown: number
	jumping: any
	jumpingy: number
	jumps: number
	jumptime: number
	jumptimer: number
	kickedupsidedown: boolean
	kill: boolean
	killsenemies: boolean
	killsenemiesafterportal: number
	laserresistant: number
	lifetime: number
	lifetimer: number
	mask: {boolean}
	movement: any
	movementrandoms: {any}
	nocollidestops: any
	nofollowspeedup: number
	offsetX: number
	offsetY: number
	offsetx: number
	offsety: number
	outtable: {{any}}
	pistondistx: number
	pistondisty: number
	pistonextendtime: number
	pistonretracttime: number
	pistonspeedx: number
	pistonspeedy: number
	pistonstate: string
	pistontimer: number
	playerneardist: any
	quad: any
	quadcenterX: number
	quadcenterY: number
	quadcenterx: number
	quadcentery: number
	quadgroup: {any:any}
	quadi: number
	reflects: number
	removeonmariocontact: boolean
	resettime: number
	resettimer: number
	resistsfire: number
	resistsspikes: any
	resistsstar: boolean
	rocketdistance: number
	rotatetowardsplayer: number
	rotation: number
	shellanimal: boolean
	shot: boolean
	shothealth: number
	shotjumpforce: number
	shotspeedx: number
	size: number
	small: boolean
	smallmovement: any
	smallquad: any
	smallspeed: number
	spawnallow: boolean
	spawnedenemies: {enemy}
	spawnenemydelay: number
	spawnenemydelays: {number}
	spawnenemyoffsetx: number
	spawnenemyoffsety: number
	spawnenemyspeed: number
	spawnenemyspeedx: number
	spawnenemyspeedxrandomend: number
	spawnenemyspeedxrandomstart: number
	spawnenemyspeedxtowardsplayer: number
	spawnenemyspeedy: number
	spawnenemyspeedyrandomend: number
	spawnenemyspeedyrandomstart: number
	spawnenemytimer: number
	spawnenemytowardsplayer: number
	spawner: any
	spawnmax: any
	spawnoffsetx: number
	spawnoffsety: number
	spawnonlyonextended: boolean
	spawnsenemy: string
	spawnsenemyrandoms: {string}
	spawnsound: string
	speedx: number
	speedxtowardsplayer: number
	speedy: number
	squidacceleration: number
	squiddowndistance: number
	squidfallspeed: number
	squidhordistance: number
	squidstate: string
	squidupspeed: number
	squidxspeed: number
	startgravity: number
	startoffsetY: number
	startquadcenterY: number
	starttowardsplayerhorizontal: boolean
	startx: number
	starty: number
	static: boolean
	staticifnotseen: number
	staticifseen: number
	stompable: boolean
	stompanimation: boolean
	stompedframe: number
	stomphealth: number
	t: string
	targety: number
	targetyspeed: number
	throwanimationstate: number
	throwpreparetime: number
	throwquadoffset: number
	transformpassedparameters: {any}
	transforms: boolean
	transformsinto: string
	transformsintorandoms: {any}
	transformsoffsetx: number
	transformsoffsety: number
	transformtrigger: string
	transformtriggerenemycollide: number
	transformtriggerobjectcollide: number
	transfoutaction: number
	transfoutid: number
	transfoutvalue: number
	truffleshuffleacceleration: number
	truffleshufflespeed: number
	turnaroundoncliff: number
	upsidedown: boolean
	upx: number
	verticalwiggledistance: number
	verticalwigglespeed: number
	wakesup: number
	width: number
	wiggledelay: number
	wiggledistance: number
	wiggleleft: boolean
	wigglespeed: number
	wiggletime: number
	wiggletimer: number
	x: number
	y: number
	init: function(self: enemy, x: number, y: number, t: string, extra?: any)
	update: function(enemy, number): any...
	addoutput: function(enemy, any, any): any...
	shotted: function(self: enemy, a?: any, b?: any, c?: any, d?: any, e?: any): any...
	decodearg: function(enemy, any): any...
	customtimeraction: function(self: enemy, a: any, b?: any): any...
	func: function(enemy, any): number
	globalcollide: function(enemy, any, Entity, any, any, any): any...
	leftcollide: function(enemy, any, Entity, any, any): any...
	rightcollide: function(enemy, any, Entity, any, any): any...
	ceilcollide: function(enemy, any, Entity, any, any): any...
	floorcollide: function(enemy, any, Entity, any, any): any...
	passivecollide: function(enemy, any, Entity, any, any): any...
	startfall: function(enemy): any...
	stomp: function(enemy, any, Entity): any...
	autodeleted: function(enemy): any...
	output: function(enemy): any...
	portaled: function(enemy): any...
	spawnenemy: function(enemy, any): any...
	transform: function(enemy, any): any...
	emancipate: function(enemy): any...
	laser: function(enemy, any, any): any...
	enteredfunnel: function(enemy, any): any...
	getspawnedenemies: function(enemy): any...
	onscreen: function(enemy): any...
	new: function(self: enemy, x: number, y: number, t: string, extra?: any): enemy
end

global record enemyspawner is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	draw: function(enemyspawner)
	update: function(enemyspawner, number): any...
	cox: number
	coy: number
	enemytospawn: string
	r: {any}
	x: number
	xspeed: number
	y: number
	yspeed: number
	init: function(enemyspawner, number, number, any)
	link: function(enemyspawner): any|nil
	input: function(enemyspawner, any, any): any
	new: function(enemyspawner, number, number, {any}): enemyspawner
end

global record entity
	image: Image
	quad: any
	t: string
	init: function(entity, any, any, any, any, any)
	sett: function(entity, any)
	new: function(entity, any, any, any, any, any): entity
end

global record entitylistitem
	i: number
	t: string
	x: number
	y: number
	init: function(entitylistitem, any, any)
	gethighlight: function(entitylistitem, any, any): boolean
	new: function(entitylistitem, any, any): entitylistitem
end

global record entitytooltip
	ent: any
	x: number
	y: number
	init: function(entitytooltip, any)
	update: function(entitytooltip, number): any...
	draw: function(entitytooltip, any)
	new: function(entitytooltip, any): entitytooltip
end

global record faithplate is Entity, Body
	speedx: number
	speedy: number
	active: boolean
	animationtimer: number
	category: number
	cox: number
	coy: number
	dir: string
	height: number
	includetable: {any}
	input1state: any
	mask: {boolean}
	power: any
	r: {any}
	static: boolean
	width: number
	x: number
	xspeed: number
	y: number
	yspeed: number
	init: function(faithplate, number, number, any)
	input: function(faithplate, any, any): any
	link: function(faithplate): any|nil
	update: function(faithplate, number): any...
	draw: function(faithplate)
	new: function(faithplate, number, number, {any}): faithplate
end

global record fire is Entity, Body
	draw: function(fire)
	active: boolean
	autodelete: boolean
	category: number
	drawable: boolean
	graphic: any
	gravity: number
	height: number
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	quadi: number
	rotation: number
	speedx: number
	speedy: number
	static: boolean
	targety: number
	timer: number
	width: number
	x: number
	y: number
	init: function(fire, number, number)
	update: function(fire, number): any...
	leftcollide: function(fire, any, Entity): any...
	rightcollide: function(fire, any, Entity): any...
	floorcollide: function(fire, any, Entity): any...
	ceilcollide: function(fire, any, Entity): boolean
	new: function(fire, number, number): fire
end

global record fireball is Entity, Body
	draw: function(fireball)
	active: boolean
	category: number
	destroy: boolean
	destroysoon: boolean
	drawable: boolean
	emancipatecheck: boolean
	fireballthrower: Entity
	graphic: any
	gravity: number
	gravitydirection: number
	height: number
	kill: boolean
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	quadi: number
	rotation: number
	speedx: number
	speedy: number
	static: boolean
	timer: number
	width: number
	x: number
	y: number
	init: function(fireball, number, number, any, any)
	update: function(fireball, number): any...
	leftcollide: function(fireball, any, Entity): any
	rightcollide: function(fireball, any, Entity): any
	floorcollide: function(fireball, any, Entity): any
	ceilcollide: function(fireball, any, Entity): any
	passivecollide: function(fireball, any, Entity): any
	hitstuff: function(fireball, any, any)
	explode: function(fireball)
	emancipate: function(fireball): any
	new: function(fireball, number, number, any, any): fireball
end

global record fireworkboom is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	timer: number
	x: number
	y: number
	init: function(fireworkboom, any, any)
	update: function(fireworkboom, number): any...
	draw: function(fireworkboom)
	new: function(fireworkboom, any, any): fireworkboom
end

global record funnel
	lastblock: {any}
	funneltable: {any}
	animationtime: any
	cox: number
	coy: number
	dir: any
	firstupdate: any
	height: number
	input1state: any
	input2state: any
	objtable: {any}
	power: any
	quad: number
	r: {any}
	reverse: any
	speed: number
	speedx: number
	speedy: number
	timer: number
	timer2: number
	width: number
	x: number
	y: number
	init: function(funnel, number, number, any)
	link: function(funnel)
	input: function(funnel, any, any)
	update: function(funnel, number): any...
	draw: function(funnel)
	updaterange: function(funnel)
	new: function(funnel, number, number, {any}): funnel
end

global record gel is Entity, Body
	draw: function(gel)
	active: boolean
	autodelete: boolean
	category: number
	destroy: boolean
	drawable: boolean
	funnel: boolean
	graphic: any
	gravity: number
	height: number
	id: number
	infunnel: boolean
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	rotation: number
	speedx: number
	speedy: number
	static: boolean
	timer: number
	width: number
	x: number
	y: number
	init: function(gel, number, number, any)
	update: function(gel, number): any...
	leftcollide: function(gel, any, Entity): boolean|nil
	rightcollide: function(gel, any, Entity): boolean|nil
	floorcollide: function(gel, any, Entity): boolean|nil
	ceilcollide: function(gel, any, Entity): boolean|nil
	globalcollide: function(gel, any, Entity): boolean|nil
	enteredfunnel: function(gel, any)
	new: function(gel, number, number, any): gel
end

global record geldispenser is Entity, Body
	active: boolean
	category: number
	cox: number
	coy: number
	dir: string
	dropping: boolean
	height: number
	id: number
	input1state: any
	mask: {boolean}
	r: {any}
	speedx: number
	speedy: number
	static: boolean
	timer: number
	width: number
	x: number
	y: number
	init: function(geldispenser, number, number, any)
	link: function(geldispenser): any|nil
	update: function(geldispenser, number): any...
	draw: function(geldispenser)
	input: function(geldispenser, any, any): any
	new: function(geldispenser, number, number, {any}): geldispenser
end

global record groundlight is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	dir: number
	input1state: any
	lighted: boolean
	r: {any}
	timer: number
	x: number
	y: number
	init: function(groundlight, number, number, any, any)
	link: function(groundlight): any|nil
	update: function(groundlight, number): any...
	draw: function(groundlight)
	input: function(groundlight, t: any, input?: any): any
	new: function(groundlight, number, number, any, any): groundlight
end

global record guielement
	active: boolean
	arguments: {any}
	autorepeat: number
	backgroundcolor: {number}
	bordercolor: {number}
	bordercolorhigh: {number}
	color: {number}
	cursorblink: boolean|number
	cursorpos: number
	cutoff: boolean
	dir: string
	direction: string
	displaynumber: number
	dragging: any
	draggingx: number
	draggingy: number
	entries: {number:any}
	extended: boolean
	fillcolor: {number}
	func: function(...: any): any|nil
	gui: guielement
	height: number
	hidden: boolean
	holding: any
	image: Image
	inputting: boolean
	internvalue: number
	max: number
	maxlength: number
	min: number
	missingy: number
	movex: number
	movey: number
	numerical: number
	offset: number
	priority: boolean
	quad: any
	range: number
	repeatdelay: number
	repeatdelaytimer: number
	repeatwait: number
	repeatwaittimer: number
	scrollbar: guielement
	space: number
	spacing: number
	starty: number
	step: number
	subx: number
	suby: number
	text: any
	textcolor: {number}
	timer: number
	type: string|number
	usemousewheel: any
	value: any
	var: any
	actualvalue: any
	width: number
	width2: number
	x: number
	xrange: number
	y: number
	yrange: number
	category: string
	nicename: string
	name: string
	i: number
	tile: number
	gels: any
	mousepressed: any
	mousereleased: any
	keypressed: any
	elements: {any}
	init: function(guielement, ...: any)
	update: function(guielement, number): any...
	draw: function(self: guielement, a?: number, b?: number, c?: number)
	getheight: function(guielement): number
	click: function(guielement, number, number, any): any...
	haspriority: function(guielement): boolean
	textinput: function(guielement, string): any...
	keypress: function(guielement, string): any...
	unclick: function(guielement, number, number, any): any...
	inhighlight: function(self: guielement, x?: number, y?: number): any...
	new: function(guielement, ...: any): guielement
end

global record itemanimation is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	i: any
	timer: number
	v: EnemyDef
	x: number
	y: number
	init: function(itemanimation, number, number, any)
	update: function(itemanimation, number): any...
	draw: function(itemanimation)
	new: function(itemanimation, number, number, any): itemanimation
end

global record laser
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	blocked: any
	cox: number
	coy: number
	dir: any
	framestart: number
	input1state: any
	lasertable: {any}
	outtable: {Entity}
	power: any
	r: {any}
	init: function(laser, number, number, any)
	link: function(laser)
	input: function(laser, any, any)
	update: function(self: laser, dt?: number): any...
	updateoutputs: function(laser)
	checktile: function(laser, any, any, any)
	draw: function(laser)
	updaterange: function(laser)
	new: function(laser, number, number, {any}): laser
end

global record laserdetector is Entity, Body
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	allowclear: boolean
	cox: number
	coy: number
	dir: any
	drawable: boolean
	out: any
	outtable: {any}
	prevout: any
	r: {any}
	init: function(laserdetector, number, number, any)
	update: function(laserdetector, number): any...
	input: function(laserdetector, any): any
	draw: function(laserdetector)
	addoutput: function(laserdetector, any, any)
	clear: function(laserdetector): any
	new: function(laserdetector, number, number, {any}): laserdetector
end

global record lightbridge
	speedx: number
	speedy: number
	active: boolean
	category: number
	children: number
	childtable: {number:lightbridgebody}
	cox: number
	coy: number
	destroy: any
	dir: string
	gels: Dyn
	glowa: number
	glowtimer: number
	height: number
	i: number
	input1state: any
	mask: {boolean}
	parent: lightbridge
	power: boolean
	r: {any}
	static: boolean
	width: number
	x: number
	y: number
	init: function(lightbridge, number, number, any)
	link: function(lightbridge)
	input: function(lightbridge, any, any)
	update: function(lightbridge, number): any...
	getglowa: function(lightbridge, any): any...
	draw: function(lightbridge)
	updaterange: function(lightbridge)
	addChild: function(lightbridge, lightbridgebody)
	new: function(lightbridge, number, number, {any}): lightbridge
end

global record lightbridgebody is Entity, Body
	speedx: number
	speedy: number
	active: boolean
	category: number
	children: number
	childtable: any
	cox: number
	coy: number
	destroy: boolean
	dir: string
	gels: Dyn
	glowa: number
	glowtimer: number
	height: number
	i: any
	input1state: any
	mask: {boolean}
	parent: lightbridge
	power: any
	r: {any}
	static: boolean
	width: number
	x: number
	y: number
	init: function(lightbridgebody, lightbridge, number, number, string, any)
	pushstuff: function(lightbridgebody)
	update: function(lightbridgebody, number): any...
	draw: function(lightbridgebody)
	new: function(lightbridgebody, lightbridge, number, number, string, any): lightbridgebody
end

global record magic is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	color: {number}
	lifetime: number
	t: number
	x: number
	y: number
	init: function(magic)
	update: function(magic, number): any...
	draw: function(magic)
	new: function(magic): magic
end

global record mario is Entity, Body
	draw: function(mario)
	active: boolean
	alwaysactive: boolean
	animation: any
	animationbridgex: number
	animationdirection: string
	animationmisc: string|any
	animationmisc2: any
	animationmisc3: any
	animationstate: string
	animationtimer: number
	animationtimer2: number
	animationx: any
	animationy: any
	biggraphic: any
	bubbletime: number
	bubbletimer: number
	category: number
	char: Character
	climbframe: number
	colors: {any}
	combo: number
	controlsenabled: boolean
	customscale: number
	customscissor: any
	dbljmping: boolean
	dead: boolean
	drawable: boolean
	drawhat: boolean
	ducking: boolean
	emancipatecheck: boolean
	falling: boolean
	fireanimationtimer: number
	fireballcount: number
	funnel: boolean
	graphic: any
	gravity: number
	gravitydirection: number
	hats: {any}
	height: number
	infunnel: boolean
	invincible: boolean
	jumpanimationprogress: number
	jumpframe: number
	jumping: any
	lastcollision: {any}
	lastground: {number}
	lastportal: number
	looktimer: number
	mask: {boolean}
	mazevar: number
	offsetX: number
	offsetY: number
	passivemoved: boolean
	pickup: any
	platform: any
	playernumber: integer
	pointingangle: number
	portal: any
	portal1color: {number}
	portal2color: {number}
	portalsavailable: {boolean}
	previouslyonground: boolean
	quad: any
	quadcenterX: number
	quadcenterY: number
	raccoonascendtimer: number
	raccoonjump: boolean
	raccoonspinframe: any
	raccoonspintimer: number
	raccoonstarttimer: number
	raccoontimer: number
	rainboomallowed: boolean
	remote: boolean
	rotation: number
	runanimationprogress: number
	runframe: number
	shot: boolean
	size: number
	smallgraphic: any
	speedx: number
	speedy: number
	spring: boolean
	springb: Entity
	springhigh: boolean
	springtimer: number
	springx: number
	springy: number
	starblinktimer: number
	starcolori: number
	starred: boolean
	startimer: number
	static: boolean
	swimanimationprogress: number
	swimframe: number
	t: string
	tailwag: boolean
	tailwagframe: number
	tailwagtimer: number
	underwater: boolean
	upsidedown: boolean
	vine: Entity|boolean
	vineanimationclimb: boolean
	vineanimationdropoff: boolean
	vinemovetimer: number
	vineside: string
	vinex: number
	viney: number
	width: number
	x: number
	y: number
	init: function(mario, number, number, any, any, any, any)
	adddata: function(mario)
	update: function(mario, number): any...
	update_raccoon_effects: function(mario, number)
	update_star: function(mario, number)
	update_animation: function(mario, number): any...
	update_funnels: function(mario, number)
	update_vine: function(mario, number): any...
	update_springs: function(mario, number): any...
	update_world_pickups: function(mario, number)
	update_replay: function(mario, number)
	update_gravity: function(mario, number)
	update_fire_animation: function(mario, number)
	update_zones: function(mario, number)
	update_controls: function(mario, number): any...
	update_drains: function(mario, number)
	updateangle: function(mario): any...
	movement: function(mario, number)
	runanimation: function(mario, number)
	underwatermovement: function(mario, number)
	setquad: function(self: mario, a?: any, b?: any)
	jump: function(self: mario, a?: any): any...
	stopjump: function(self: mario, a?: any)
	rightkey: function(mario)
	leftkey: function(mario)
	grow: function(mario): any...
	shrink: function(mario): any...
	floorcollide: function(mario, any, Entity, any, any): any...
	bluegel: function(mario, any): any...
	stompenemy: function(self: mario, a: any, b: Entity, c: any, d: any, e?: any): any...
	rightcollide: function(mario, any, Entity, any, any): any...
	leftcollide: function(mario, any, Entity, any, any): any...
	ceilcollide: function(mario, any, Entity, any, any): any...
	globalcollide: function(mario, any, Entity, any, any, any): any...
	passivecollide: function(mario, any, Entity, any, any): any...
	starcollide: function(mario, any, Entity, any, any): any...
	hitspring: function(mario, Entity)
	leavespring: function(mario)
	dropvine: function(mario, any)
	grabvine: function(mario, Entity): any...
	goinvincible: function(mario): any...
	faithplate: function(mario, any)
	startfall: function(mario)
	die: function(mario, any): any...
	laser: function(mario, any): any...
	emancipate: function(mario, any): any
	removeportals: function(mario, ...: any): any...
	use: function(self: mario, x?: number, y?: number): any...
	pickupbox: function(mario, Entity)
	dropbox: function(mario)
	cubeemancipate: function(mario): any
	duck: function(mario, any): any...
	pipe: function(mario, number, number, any, any): any...
	savereplaydata: function(mario)
	flag: function(mario): any...
	axe: function(mario): any...
	vineanimation: function(mario)
	star: function(mario)
	fire: function(mario)
	spinhit: function(mario, number, number, any)
	fireballcallback: function(mario)
	portaled: function(mario, any): any...
	shootgel: function(mario, any)
	respawn: function(mario): any...
	dive: function(mario, any)
	enteredfunnel: function(mario, any)
	animationwalk: function(mario, any)
	stopanimation: function(mario)
	portalpickup: function(mario, any): any...
	new: function(mario, number, number, any, any, any, any): mario
end

global record miniblock is Entity, Body
	width: number
	height: number
	speedx: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	i: number
	speedy: number
	timer: number
	x: number
	y: number
	init: function(miniblock, number, number, any)
	update: function(miniblock, number): any...
	draw: function(miniblock)
	new: function(miniblock, number, number, any): miniblock
end

global record musicentity is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	update: function(musicentity, number): any...
	cox: number
	coy: number
	musicname: string
	r: {any}
	single: any
	triggered: boolean
	visible: boolean
	x: number
	y: number
	init: function(musicentity, number, number, any)
	link: function(musicentity): any|nil
	draw: function(musicentity)
	input: function(musicentity, any, any): any
	new: function(musicentity, number, number, {any}): musicentity
end

global record notgate is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	initial: boolean
	input1state: any
	outtable: {{any}}
	power: any
	r: {any}
	visible: boolean
	x: number
	y: number
	init: function(notgate, number, number, any)
	link: function(notgate): any|nil
	addoutput: function(notgate, any, any)
	update: function(notgate, number): any...
	draw: function(notgate)
	out: function(notgate, any)
	input: function(notgate, any, any): any
	new: function(notgate, number, number, {any}): notgate
end

global record orgate is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	initial: boolean
	inputstate: {any:any}
	outputstate: any
	outtable: {{any}}
	r: {any}
	visible: boolean
	x: number
	y: number
	init: function(orgate, number, number, any)
	link: function(orgate): any|nil
	addoutput: function(orgate, any, any)
	update: function(orgate, number): any...
	draw: function(orgate)
	out: function(orgate, any)
	input: function(orgate, any, any): any
	new: function(orgate, number, number, {any}): orgate
end

global record panel is Entity, Body
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	update: function(panel, number): any...
	cox: number
	coy: number
	dir: string
	input1state: any
	out: boolean
	r: number
	t: {any}
	init: function(panel, number, number, any)
	link: function(panel): any|nil
	draw: function(panel)
	input: function(panel, any, any): any
	updatestuff: function(panel)
	new: function(panel, number, number, any): panel
end

global record pedestal is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	blue: boolean
	cox: number
	coy: number
	orange: boolean
	pickedup: boolean
	progress: number
	portals: any
	r: {any}
	x: number
	y: number
	init: function(pedestal, number, number, any)
	update: function(pedestal, number): any...
	draw: function(pedestal)
	new: function(pedestal, number, number, {any}): pedestal
end

global record platform is Entity, Body
	active: boolean
	category: number
	dir: any
	drawable: boolean
	gravity: number
	height: number
	mask: {boolean}
	r: {any}
	rotation: number
	size: number
	speed: number
	speedx: number
	speedy: number
	startx: number
	starty: number
	static: boolean
	time: number
	timer: number
	width: number
	x: number
	xdistance: number
	y: number
	ydistance: number
	init: function(self: platform, x: number, y: number, r: any, diroverride?: any)
	func: function(platform, number): number
	update: function(platform, number): any...
	draw: function(platform)
	rightcollide: function(platform, any, Entity): any
	leftcollide: function(platform, any, Entity): any
	ceilcollide: function(platform, any, Entity): any
	floorcollide: function(platform, any, Entity): any
	passivecollide: function(platform, any, Entity): any
	new: function(self: platform, x: number, y: number, r: {any}, diroverride?: any): platform
end

global record platformspawner is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	draw: function(platformspawner)
	dir: string
	r: {any}
	size: number
	spawndelay: number
	speed: number
	timer: number
	x: number
	y: number
	init: function(platformspawner, number, number, any)
	update: function(platformspawner, number): any...
	new: function(platformspawner, number, number, {any}): platformspawner
end

global record portal
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	animationtimer: number
	facing1: any
	facing2: any
	number: number
	openscale: {number}
	portal1color: {number}
	portal2color: {number}
	portalframe: number
	x1: any
	x2: any
	y1: any
	y2: any
	init: function(portal, any, any, any)
	createportal: function(portal, number, any, any, any, any)
	removeportal: function(portal, number)
	update: function(portal, number): any...
	draw: function(portal)
	new: function(self: portal, id: any, a?: any, b?: any): portal
end

global record portalent is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	dir: string
	id: number
	input1state: any
	portal: number
	power: any
	r: {any}
	x: number
	y: number
	init: function(portalent, number, number, any, any)
	link: function(portalent): any|nil
	update: function(portalent, number): any...
	draw: function(portalent)
	input: function(portalent, any, any): any
	trigger: function(portalent): any
	rem: function(portalent)
	new: function(portalent, number, number, any, any): portalent
end

global record portalparticle is Entity, Body
	width: number
	height: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	color: {number}
	direction: string
	speedx: number
	speedy: number
	timer: number
	x: number
	y: number
	init: function(portalparticle, number, number, any, any)
	update: function(portalparticle, number): any...
	draw: function(portalparticle)
	new: function(portalparticle, number, number, any, any): portalparticle
end

global record portalprojectile is Entity, Body
	width: number
	height: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	alpha: number
	angle: number
	bounces: any
	color: {number}
	endx: any
	endy: any
	hit: any
	lastparticle: number
	length: number
	mirror: any
	particles: {number:Entity}
	payload: any
	payloaddelivered: any
	portal: any
	sinestart: number
	speedx: number
	speedy: number
	startx: number
	starty: number
	time: number
	timer: number
	x: number
	y: number
	init: function(portalprojectile, number, number, any, any, any, any, any, any, any, any)
	update: function(portalprojectile, number): any...
	draw: function(portalprojectile)
	createportal: function(portalprojectile)
	new: function(portalprojectile, number, number, any, any, any, any, any, any, any, any): portalprojectile
end

global record portalprojectileparticle is Entity, Body
	width: number
	height: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	alpha: number
	angle: number
	bounces: number
	color: {number}
	endx: number
	endy: number
	hit: number
	lastparticle: number
	length: number
	mirror: boolean
	particles: {any}
	payload: number
	payloaddelivered: number
	sinestart: number
	speedx: number
	speedy: number
	startx: number
	starty: number
	time: number
	timer: number
	x: number
	y: number
	init: function(portalprojectileparticle, number, number, any, any, any, any)
	update: function(portalprojectileparticle, number): any...
	draw: function(portalprojectileparticle)
	new: function(self: portalprojectileparticle, x: number, y: number, color: any, a?: any, b?: any, c?: any): portalprojectileparticle
end

global record portalwall is Entity, Body
	speedx: number
	speedy: number
	update: function(portalwall, number): any...
	active: boolean
	category: number
	height: number
	mask: {boolean}
	static: boolean
	width: number
	x: number
	y: number
	init: function(self: portalwall, x: number, y: number, a: any, b: any, c?: any)
	draw: function(portalwall)
	new: function(portalwall, number, number, any, any, any): portalwall
end

global record pushbutton is Entity, Body
	x: number
	y: number
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	base: any
	cox: number
	coy: number
	dir: any
	out: any
	outtable: {any}
	pusheddown: boolean
	r: {any}
	timer: number
	init: function(pushbutton, number, number, any)
	update: function(pushbutton, number): any...
	draw: function(pushbutton)
	addoutput: function(pushbutton, any, any)
	used: function(pushbutton): any
	new: function(pushbutton, number, number, {any}): pushbutton
end

global record quad
	breakable: number
	bridge: number
	coin: number
	coinblock: number
	collision: number
	foreground: number
	grate: number
	image: Image
	invisible: boolean
	mirror: boolean
	platform: number
	portalable: boolean
	props: any
	quadobj: Quad
	slantupleft: number
	slantupright: number
	water: number
	init: function(quad, any, any, any, any, any, any)
	getproperty: function(quad, any): any...
	quad: function(quad): Quad
	new: function(quad, any, any, any, any, any, any): quad
end

global record rainboom is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	dir: string
	frame: number
	r: any
	timer: number
	x: number
	y: number
	init: function(rainboom, number, number, any)
	update: function(rainboom, number): any...
	draw: function(rainboom)
	new: function(rainboom, number, number, any): rainboom
end

global record regiondrag
	grabbed: number
	height: number
	movestartx: number
	movestarty: number
	movex: number
	movey: number
	width: number
	x: number
	y: number
	init: function(regiondrag, number, number, any, any)
	update: function(regiondrag, number): any...
	draw: function(regiondrag)
	mousepressed: function(regiondrag, any, any, any): any
	mousereleased: function(regiondrag, any, any, any)
	inhighlight: function(regiondrag, any, any, any): boolean
	new: function(regiondrag, number, number, any, any): regiondrag
end

global record regiontrigger is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	checktable: any
	cox: number
	coy: number
	out: any
	outtable: {{any}}
	r: {any}
	regionX: number
	regionY: number
	regionheight: number
	regionwidth: number
	x: number
	y: number
	init: function(regiontrigger, number, number, any)
	update: function(regiontrigger, number): any...
	draw: function(regiontrigger)
	addoutput: function(regiontrigger, any, any)
	new: function(regiontrigger, number, number, {any}): regiontrigger
end

global record RightClickVar
	value: any
	t: any
	link: any
	entries: {any}
	max: any
	min: any
	step: any
	actualvalue: any
	width: any
	region: any
	default: any
	text: any
end

global record rightclickmenu
	elements: {any}
	t: {any}
	tx: any
	ty: any
	variables: {RightClickVar}
	x: number
	y: number
	init: function(rightclickmenu, number, number, any, any, any)
	update: function(rightclickmenu, number): any...
	draw: function(rightclickmenu)
	mousepressed: function(rightclickmenu, any, any, any): boolean
	mousereleased: function(rightclickmenu, any, any, any)
	keypressed: function(rightclickmenu, any)
	textinput: function(rightclickmenu, any)
	linkcallback: function(rightclickmenu, rightclickmenu, any, any)
	regioncallback: function(rightclickmenu, rightclickmenu, any)
	directioncallback: function(rightclickmenu, rightclickmenu, any, any)
	new: function(rightclickmenu, number, number, any, any, any): rightclickmenu
end

global record rocketlauncher is Entity, Body
	draw: function(rocketlauncher)
	active: boolean
	animationdirection: string
	autodelete: boolean
	category: number
	customscissor: any
	direction: string
	drawable: boolean
	graphic: any
	gravity: number
	height: number
	id: any
	killstuff: number
	mask: {boolean}
	offsetX: number
	offsetY: number
	quad: any
	quadcenterX: number
	quadcenterY: number
	rotation: number
	shot: boolean
	speedx: number
	speedy: number
	startx: number
	static: boolean
	time: number
	timer: number
	width: number
	x: number
	y: number
	init: function(rocketlauncher, number, number)
	update: function(rocketlauncher, number): any...
	fire: function(rocketlauncher): any...
	randomtime: function(rocketlauncher)
	new: function(rocketlauncher, number, number): rocketlauncher
end

global record rsflipflop is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	update: function(rsflipflop, number): any...
	cox: number
	coy: number
	output: boolean
	outtable: {{any}}
	r: {any}
	visible: boolean
	x: number
	y: number
	init: function(rsflipflop, number, number, any)
	link: function(rsflipflop): any|nil
	addoutput: function(rsflipflop, any, any)
	draw: function(rsflipflop)
	out: function(rsflipflop, any)
	input: function(rsflipflop, any, any): any
	new: function(rsflipflop, number, number, {any}): rsflipflop
end

global record scaffold is Entity, Body
	active: boolean
	category: number
	dir: string
	distance: number
	drawable: boolean
	gravity: number
	height: number
	input1state: any
	mask: {boolean}
	power: any
	r: {any}
	rotation: number
	size: number
	speed: number
	speedx: number
	speedy: number
	startx: number
	starty: number
	state: string
	static: boolean
	time1: number
	time2: number
	timer: number
	width: number
	x: number
	y: number
	init: function(scaffold, number, number, any)
	link: function(scaffold): any|nil
	input: function(scaffold, any, any): any
	update: function(scaffold, number): any...
	draw: function(scaffold)
	rightcollide: function(scaffold, any, Entity): boolean
	leftcollide: function(scaffold, any, Entity): boolean
	ceilcollide: function(scaffold, any, Entity): boolean
	floorcollide: function(scaffold, any, Entity): boolean
	passivecollide: function(scaffold, any, Entity): boolean
	new: function(scaffold, number, number, {any}): scaffold
end

global record screenboundary is Entity, Body
	speedx: number
	speedy: number
	draw: function(screenboundary)
	update: function(screenboundary, number): any...
	active: boolean
	category: number
	height: number
	mask: {boolean}
	static: boolean
	width: number
	x: number
	y: number
	init: function(screenboundary, any)
	new: function(screenboundary, any): screenboundary
end

global record scrollingscore is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	draw: function(scrollingscore)
	i: any
	timer: number
	x: number
	y: number
	init: function(scrollingscore, any, any, any)
	update: function(scrollingscore, number): any...
	new: function(scrollingscore, any, any, any): scrollingscore
end

global record scrollingtext is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	s: any
	timer: number
	x: number
	y: number
	init: function(scrollingtext, any, any, any)
	update: function(scrollingtext, number): any...
	draw: function(scrollingtext)
	new: function(scrollingtext, any, any, any): scrollingtext
end

global record seesaw
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	dist1: number
	dist2: number
	falloff: any
	falloffside: any
	lcount: any
	leftplatform: any
	r: {any}
	range: number
	rcount: any
	rightplatform: any
	width: number
	x: number
	y: number
	init: function(seesaw, number, number, any)
	update: function(seesaw, number): any...
	fallingoff: function(seesaw, any)
	draw: function(seesaw)
	callbackleft: function(seesaw, any)
	callbackright: function(seesaw, any)
	new: function(seesaw, number, number, {any}): seesaw
end

global record seesawplatform is Body
	active: boolean
	callback: any
	category: number
	dir: string
	drawable: boolean
	gravity: number
	height: number
	mask: {boolean}
	rotation: number
	side: any
	size: any
	speedx: number
	speedy: number
	startx: number
	starty: number
	static: boolean
	width: number
	x: number
	y: number
	init: function(seesawplatform, number, number, any, any, any)
	update: function(seesawplatform, number): any...
	draw: function(seesawplatform)
	rightcollide: function(seesawplatform, any, Entity): any
	leftcollide: function(seesawplatform, any, Entity): any
	ceilcollide: function(seesawplatform, any, Entity): any
	floorcollide: function(seesawplatform, any, Entity): any
	callbackleft: any
	callbackright: any
	new: function(seesawplatform, number, number, any, any, any): seesawplatform
end

global record spring is Entity, Body
	speedx: number
	speedy: number
	active: boolean
	category: number
	cox: number
	coy: number
	drawable: boolean
	frame: number
	height: number
	mask: {boolean}
	static: boolean
	timer: number
	width: number
	x: number
	y: number
	init: function(spring, number, number)
	update: function(spring, number): any...
	draw: function(spring)
	hit: function(spring)
	new: function(spring, number, number): spring
end

global record squarewave is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	initial: boolean
	input1state: any
	outtable: {{any}}
	r: {any}
	time1: number
	time2: number
	timer: number
	visible: boolean
	x: number
	y: number
	init: function(squarewave, number, number, any)
	addoutput: function(squarewave, any, any)
	update: function(squarewave, number): any...
	draw: function(squarewave)
	out: function(squarewave, any)
	new: function(squarewave, number, number, {any}): squarewave
end

global record textentity is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	blue: number
	boolbincache: {any:{any}}
	boolcache: {any:{any}}
	builtincache: {any:{any}}
	glintcache: {any:{any}}
	green: number
	hasaprefix: boolean
	input1state: any
	pass: boolean
	power: any
	r: {any}
	red: number
	text: string
	textsplit: {number:any}
	x: number
	y: number
	init: function(textentity, number, number, any)
	link: function(textentity): any|nil
	input: function(textentity, any, any): any
	update: function(textentity, number): any...
	draw: function(textentity)
	new: function(textentity, number, number, {any}): textentity
end

global record tile is Entity, Body
	active: boolean
	category: number
	cox: number
	coy: number
	height: number
	mask: {boolean}
	speedx: number
	speedy: number
	static: boolean
	width: number
	x: number
	y: number
	init: function(tile, number, number, any)
	new: function(tile, ...: any): tile
end

global record vine is Entity, Body
	speedx: number
	speedy: number
	active: boolean
	category: number
	cox: number
	coy: number
	drawable: boolean
	height: number
	hidetop: any
	limit: number
	mask: {boolean}
	static: boolean
	t: string
	timer: number
	width: number
	x: number
	y: number
	init: function(vine, number, number, any)
	update: function(vine, number): any...
	draw: function(vine)
	new: function(self: vine, x: number, y: number, a?: any): vine
end

global record wallindicator is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	input1state: any
	lighted: boolean
	r: {any}
	x: number
	y: number
	init: function(wallindicator, number, number, any)
	link: function(wallindicator): any|nil
	update: function(wallindicator): any...
	draw: function(wallindicator)
	input: function(wallindicator, any, any): any
	new: function(wallindicator, number, number, {any}): wallindicator
end

global record walltimer is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	cox: number
	coy: number
	input1state: any
	lighted: boolean
	outtable: {{any}}
	quad: number
	r: {any}
	time: number
	timer: number
	x: number
	y: number
	init: function(walltimer, number, number, any)
	link: function(walltimer): any|nil
	addoutput: function(walltimer, any, any)
	update: function(walltimer, number): any...
	draw: function(walltimer)
	out: function(walltimer, any)
	input: function(walltimer, any, any): any
	new: function(walltimer, number, number, {any}): walltimer
end

global record zgbooltrigger is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	checktable: any
	cox: number
	coy: number
	id: any
	inverted: any
	invisible: boolean
	out: any
	outtable: {any}
	r: {any}
	x: number
	y: number
	init: function(zgbooltrigger, number, number, any)
	update: function(zgbooltrigger, number): any...
	draw: function(zgbooltrigger)
	addoutput: function(zgbooltrigger, any, any)
	new: function(zgbooltrigger, number, number, {any}): zgbooltrigger
end

global record zginttrigger is Entity, Body
	width: number
	height: number
	speedx: number
	speedy: number
	active: boolean
	static: boolean
	category: number
	mask: {boolean}
	checktable: any
	condition: any
	conditions: {any}
	cox: number
	coy: number
	id: any
	out: any
	outtable: {any}
	r: {any}
	value: any
	x: number
	y: number
	init: function(zginttrigger, number, number, any)
	update: function(zginttrigger, number): any...
	draw: function(zginttrigger)
	addoutput: function(zginttrigger, any, any)
	new: function(zginttrigger, number, number, {any}): zginttrigger
end


global record upfire is Entity, Body
	new: function(any, number, number, any): upfire
end
