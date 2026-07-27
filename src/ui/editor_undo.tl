--[[ Cell-diff undo/redo ring buffer (max 64 strokes). ]]

global record UndoCell
	x: integer
	y: integer
	tile: any
	entity: any
	extras: {any}
	coin: boolean|nil
end

global record UndoStroke
	cells: {UndoCell}
end

local UNDO_MAX = 64
global editor_undo_stack: {UndoStroke} = {}
global editor_redo_stack: {UndoStroke} = {}
local stroke: UndoStroke|nil = nil
local stroke_seen: {string:boolean} = {}

local function cell_key(x: number, y: number): string
	return tostring(x) .. "," .. tostring(y)
end

local function snapshot_cell(x: number, y: number): UndoCell|nil
	if not inmap(x, y) then
		return nil
	end
	local c = map[x][y]
	local extras: {any} = {}
	for i = 3, #c do
		extras[#extras + 1] = c[i]
	end
	return {
		x = math.floor(x) as integer,
		y = math.floor(y) as integer,
		tile = c[1],
		entity = c[2],
		extras = extras,
		coin = coinmap[x][y] as boolean|nil,
	}
end

local function apply_cell(u: UndoCell)
	if not inmap(u.x, u.y) then
		return
	end
	local c = map[u.x][u.y]
	for i = #c, 3, -1 do
		c[i] = nil
	end
	c[1] = u.tile
	c[2] = u.entity
	for i = 1, #u.extras do
		c[2 + i] = u.extras[i]
	end
	if u.coin ~= nil then
		coinmap[u.x][u.y] = u.coin as boolean
	end
	init_map_cell_gels(c)
end

global function editor_undo_begin()
	stroke = { cells = {} }
	stroke_seen = {}
end

global function editor_undo_record(x: number, y: number)
	if not stroke then
		editor_undo_begin()
	end
	local st = stroke as UndoStroke
	local k = cell_key(x, y)
	if stroke_seen[k] then
		return
	end
	stroke_seen[k] = true
	local snap = snapshot_cell(x, y)
	if snap then
		st.cells[#st.cells + 1] = snap
	end
end

global function editor_undo_commit()
	if stroke == nil then
		stroke_seen = {}
		return
	end
	local st = stroke as UndoStroke
	if #st.cells == 0 then
		stroke = nil
		stroke_seen = {}
		return
	end
	editor_undo_stack[#editor_undo_stack + 1] = st
	while #editor_undo_stack > UNDO_MAX do
		table.remove(editor_undo_stack, 1)
	end
	editor_redo_stack = {}
	stroke = nil
	stroke_seen = {}
end

local function invert_stroke(s: UndoStroke): UndoStroke
	local inv: UndoStroke = { cells = {} }
	for i = 1, #s.cells do
		local u = s.cells[i]
		local cur = snapshot_cell(u.x, u.y)
		if cur then
			inv.cells[#inv.cells + 1] = cur
		end
	end
	for i = 1, #s.cells do
		apply_cell(s.cells[i])
	end
	return inv
end

global function editor_undo(): boolean
	if stroke then
		editor_undo_commit()
	end
	if #editor_undo_stack == 0 then
		return false
	end
	local s = table.remove(editor_undo_stack) as UndoStroke
	editor_redo_stack[#editor_redo_stack + 1] = invert_stroke(s)
	generatespritebatch(0 as integer, 0 as integer)
	return true
end

global function editor_redo(): boolean
	if #editor_redo_stack == 0 then
		return false
	end
	local s = table.remove(editor_redo_stack) as UndoStroke
	editor_undo_stack[#editor_undo_stack + 1] = invert_stroke(s)
	while #editor_undo_stack > UNDO_MAX do
		table.remove(editor_undo_stack, 1)
	end
	generatespritebatch(0 as integer, 0 as integer)
	return true
end

global function editor_undo_clear()
	editor_undo_stack = {}
	editor_redo_stack = {}
	stroke = nil
	stroke_seen = {}
end
