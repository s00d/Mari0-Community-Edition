rockspec_format = "3.0"
package = "mari0-ce-dependencies"
version = "1-1"
source = {
   url = "https://github.com/Stabyourself/mari0", -- metadata only; game is not a rock
}
description = {
   summary = "Runtime Lua deps for Mari0 CE (Love 11 / LuaJIT)",
   detailed = [[
Pure-Lua rocks vendored into lib/ via scripts/vendor-rocks for .love packaging.
Prefer dkjson over lua-cjson (C modules do not ship inside .love).
]],
   license = "MIT",
}
dependencies = {
   "lua >= 5.1, < 5.5",
   "dkjson == 2.10-1",
   "sha1 == 0.5-1",
}
build = {
   type = "none",
}
