--[[
	STEAL MY SHIT AND I'LL FUCK YOU UP
	PRETTY MUCH EVERYTHING BY MAURICE GUÉGAN AND IF SOMETHING ISN'T BY ME THEN IT SHOULD BE OBVIOUS OR NOBODY CARES

	Please keep in mind that for obvious reasons, I do not hold the rights to artwork, audio or trademarked elements of the game.
	This license only applies to the code and original other assets. Obviously. Duh.
	Anyway, enjoy.
	
	
	
	DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
              Version 2, December 2004

	Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

	Everyone is permitted to copy and distribute verbatim or modified
	copies of this license document, and changing it is allowed as long
	as the name is changed.

			DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
	TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

	0. You just DO WHAT THE FUCK YOU WANT TO.
]]

-- Thin Love entry: Teal modules live under build/ (see conf.lua package.path).
require "app.love_run"
require "app.main_util"
require "app.errhand"
require "app.love_callbacks"

function love.load(arg)
	local LoveLoad = require "app.love_load"
	LoveLoad.install_mouse()
	LoveLoad.run(arg)
end
