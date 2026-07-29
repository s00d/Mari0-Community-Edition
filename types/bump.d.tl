global record BumpWorld
	add: function(BumpWorld, item: any, x: number, y: number, w: number, h: number): any
	remove: function(BumpWorld, item: any)
	update: function(BumpWorld, item: any, x: number, y: number, w?: number, h?: number)
	move: function(BumpWorld, item: any, goalX: number, goalY: number, filter?: function): number, number, {any}, number
	check: function(BumpWorld, item: any, goalX: number, goalY: number, filter?: function): number, number, {any}, number
	queryRect: function(BumpWorld, x: number, y: number, w: number, h: number, filter?: function): {integer: any}, number
	hasItem: function(BumpWorld, item: any): boolean
	getRect: function(BumpWorld, item: any): number, number, number, number
	getItems: function(BumpWorld): {integer: any}, number
	countItems: function(BumpWorld): number
end

local record bump
	newWorld: function(cellSize?: number): BumpWorld
end

return bump
