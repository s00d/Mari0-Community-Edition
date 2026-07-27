--[[ Metroidvania F0–F3 headless checks ]]
local root = ... or "."
local failed = 0
local function check(name, cond, detail)
	if cond then print("OK  "..name) else failed=failed+1; print("FAIL "..name..(detail and (": "..detail) or "")) end
end
globools={}; globints={}
function globoolSH(id, para)
	local key=tostring(id)
	if para=="true" then globools[key]=true elseif para=="false" then globools[key]=false elseif para=="flip" then globools[key]=not globools[key] end
	return globools[key] or false
end
function globintSH(id, para, value)
	local key=tostring(id); globints[key]=globints[key] or 0
	if para=="set" then globints[key]=tonumber(value) or 0 elseif para=="add" then globints[key]=globints[key]+(tonumber(value) or 0) end
	return globints[key]
end
function tilekey(x,y) return math.floor(x)*65536+math.floor(y) end
package.path=table.concat({root.."/build/?.lua",root.."/build/?/init.lua",root.."/lib/?.lua",root.."/lib/?/init.lua",package.path},";")
local okj, JSON = pcall(require,"dkjson"); _G.JSON = okj and JSON or nil
local function load_mod(name)
	local ok, mod = pcall(require, name)
	if ok then return mod end
	local chunk = loadfile(root.."/build/"..name:gsub("%.","/")..".lua")
	if not chunk then return nil, tostring(mod) end
	return chunk()
end
check("load abilities", load_mod("world.abilities") ~= nil)
check("load roomcam", load_mod("world.roomcam") ~= nil)
check("load reachability", load_mod("world.reachability") ~= nil)
rooms_set(rooms_parse_txt("0,0,25,15,gate,scroll_h\n25,0,25,15,drain,scroll_h\n"))
check("parse rooms", #ROOMS==2, tostring(#ROOMS))
check("room_at gate", room_at(3,8) and room_at(3,8).id=="gate")
check("room_at drain", room_at(30,8) and room_at(30,8).id=="drain")
check("room_at miss", room_at(100,100)==nil)
local tx,ty=room_camera_target(ROOMS[1],10,8,25,14)
check("camera pin", tx==0 and ty==0)
local pl=fake_player_from_abilities({portal=true})
check("blue pass", door_can_pass("blue",pl,{})==true)
check("red block", door_can_pass("red",pl,{})==false)
check("try open", door_try_open("t1","blue",pl,{}) and door_is_open("t1"))
grant_ability({weapons={},char={}},"morphball")
check("grant morph", has_ability({},"morphball")==true)
local f=io.open(root.."/mappacks/metroidfault/rooms.json","r")
check("rooms.json", f~=nil)
if f and JSON then
	local body=f:read("*a"); f:close()
	rooms_set(rooms_parse_json(JSON.decode(body)))
	check("json rooms", #ROOMS==4, tostring(#ROOMS))
	local errs=world_reachability_check("gate")
	check("reachability", #errs==0, table.concat(errs,"; "))
end
rooms_set(rooms_parse_json({start="a",rooms={{id="a",x=0,y=0,w=10,h=10,doors={{kind="red",to="b"}},items={}},{id="b",x=10,y=0,w=10,h=10,doors={{kind="open",to="a"}},items={}}}}))
check("unreachable detected", #world_reachability_check("a")>=1)
if select("#",...)>0 then return failed end
os.exit(failed>0 and 1 or 0)
