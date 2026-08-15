-- Session instance (`session`): SoT for level world state.
-- Teal record name is `World`. Methods via __index; fields on the table itself.

rawset(_G, "World", rawget(_G, "World") or {})

function World.new(): World
	local objects, playerobjs = fresh_objects()
	local self = {
		map = {} as {number:{number:MapCell}},
		coinmap = {} as {any:{any:any}},
		objects = objects,
		playerobjs = playerobjs,
		mapwidth = 0,
		mapheight = 0,
		xscroll = 0,
		yscroll = 0,
		ylookmodifier = 0,
		portals = {} as {number:portal},
		enemiesspawned = {} as {integer:boolean},
		smbspritebatch = nil,
		smbspritebatchfront = nil,
		portalspritebatch = nil,
		portalspritebatchfront = nil,
	}
	return setmetatable(self, { __index = World }) as World
end

function World:reset_level()
	local objects, playerobjs = fresh_objects()
	self.objects = objects
	self.playerobjs = playerobjs as {any:mario}
	self.map = {}
	self.coinmap = {}
	self.mapwidth = 0
	self.mapheight = 0
	self.xscroll = 0
	self.yscroll = 0
	self.ylookmodifier = 0
	self.portals = {}
	self.enemiesspawned = {}
	self.smbspritebatch = nil
	self.smbspritebatchfront = nil
	self.portalspritebatch = nil
	self.portalspritebatchfront = nil
	if physics_world_reset then
		physics_world_reset()
	end
end

return World
