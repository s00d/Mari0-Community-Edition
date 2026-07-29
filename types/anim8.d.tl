global record Anim8Grid
	metamethod __call: function(Anim8Grid, ...: any): any
	getFrames: function(Anim8Grid, ...: any): any
end

global record Anim8Animation
	frames: {any}
	position: integer
	status: string
	timer: number
	totalDuration: number
	flippedH: boolean
	flippedV: boolean

	update: function(Anim8Animation, number)
	draw: function(Anim8Animation, ...: any)
	gotoFrame: function(Anim8Animation, number)
	pause: function(Anim8Animation)
	pauseAtEnd: function(Anim8Animation): Anim8Animation
	pauseAtStart: function(Anim8Animation): Anim8Animation
	resume: function(Anim8Animation)
	flipH: function(Anim8Animation): Anim8Animation
	flipV: function(Anim8Animation): Anim8Animation
	clone: function(Anim8Animation): Anim8Animation
end

local record anim8
	newGrid: function(...: any): Anim8Grid
	newAnimation: function(...: any): Anim8Animation
end

return anim8
