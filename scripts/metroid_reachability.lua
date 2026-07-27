#!/usr/bin/env lua
local pack = arg[1] or "mappacks/metroidfault"
local root="."
local info=debug.getinfo(1,"S").source
if info:sub(1,1)=="@" then root=info:sub(2):match("^(.*)/scripts/") or "." end
package.path=table.concat({root.."/build/?.lua",root.."/build/?/init.lua",root.."/lib/?.lua",root.."/lib/?/init.lua",package.path},";")
globools={}; globints={}
function globoolSH(id,para) local k=tostring(id); if para=="true" then globools[k]=true elseif para=="false" then globools[k]=false end; return globools[k] or false end
function tilekey(x,y) return math.floor(x)*65536+math.floor(y) end
JSON=require("dkjson")
require("world.abilities"); require("world.roomcam"); require("world.reachability")
local base=pack
if not base:match("/") then base="mappacks/"..pack end
local jf=io.open(root.."/"..base.."/rooms.json","r")
if jf then local b=jf:read("*a"); jf:close(); rooms_set(rooms_parse_json(JSON.decode(b))); print("loaded",#ROOMS,"rooms")
else local tf=io.open(root.."/"..base.."/rooms.txt","r"); if not tf then io.stderr:write("no rooms\n"); os.exit(2) end; local b=tf:read("*a"); tf:close(); rooms_set(rooms_parse_txt(b)) end
local errs=world_reachability_check()
if #errs==0 then print("OK reachability"); os.exit(0) end
for _,e in ipairs(errs) do print("ERR",e) end; os.exit(1)
