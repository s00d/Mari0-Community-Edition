--[[ Module upvalue context (Stage 2).
     config/assets/progress/frame are stubs until later phases; level is first. ]]

local Ctx = {
	config = {} as {string: any},
	assets = nil as AssetStore|nil,
	progress = {} as {string: any},
	level = nil as Level|nil,
	frame = { gdt = 1 / 60 },
}

return Ctx
