return {
	source_dir = "src",
	build_dir = "build",
	include_dir = { "types" },
	global_env_def = "love",
	gen_target = "5.1",
	gen_compat = "optional",
	feat_arity = "on",
	include = { "**/*.tl" },
	-- Unused at boot (require commented); skip typecheck sink.
	exclude = { "types/**" },
	-- Mari0 uses hundreds of intentional local shadows of game.d.tl globals during
	-- Lua→Teal migration; # on {integer:T} maps is also deliberate legacy.
	disable_warnings = { "redeclaration", "hint" },
}
