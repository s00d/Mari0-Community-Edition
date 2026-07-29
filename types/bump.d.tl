global record BumpWorld
	add: function(BumpWorld, ...: any)
	remove: function(BumpWorld, any)
	update: function(BumpWorld, ...: any)
	move: function(BumpWorld, ...: any): number, number, {any}, number
	queryRect: function(BumpWorld, ...: any): {any}, number
	hasItem: function(BumpWorld, any): boolean
	getRect: function(BumpWorld, any): number, number, number, number
end

local record bump
	newWorld: function(...: any): BumpWorld
end

return bump
