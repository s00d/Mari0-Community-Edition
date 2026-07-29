--[[ Optional STI load path for .tmx assets (v1 N-M levels unchanged). ]]

local sti_ok, sti_mod = pcall(require, "sti")

global function sti_available(): boolean
	return sti_ok
end

global function sti_try_load_map(path: string): any|nil
	if not sti_ok then
		return nil
	end
	if not string.match(path, "%.tmx$") then
		return nil
	end
	if not love.filesystem.getInfo(path) then
		return nil
	end
	return (sti_mod as function(string): any)(path)
end
