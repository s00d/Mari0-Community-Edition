// Gameplay black-hole FX — not a menu post-process filter.
// center: UV 0..1, strength: 0..1, mode: 0=suck/fly, 1=blast, 2=muzzle

extern vec2 center;
extern number strength;
extern number mode;
extern number time;

vec4 effect(vec4 vcolor, Image tex, vec2 texture_coords, vec2 pixel_coords)
{
	vec2 uv = texture_coords;
	vec2 dir = uv - center;
	float dist = length(dir);
	float inv = 1.0 / max(dist, 0.001);
	vec2 ndir = dir * inv;

	float s = clamp(strength, 0.0, 1.5);
	float suck_w = (mode < 0.5) ? 1.0 : (mode < 1.5 ? 0.35 : 0.55);
	float warp = s * suck_w * 0.22 * smoothstep(0.65, 0.0, dist);
	// spiral twist while sucking
	float twist = s * suck_w * 0.9 * smoothstep(0.5, 0.0, dist);
	float ang = twist * sin(time * 8.0 + dist * 20.0);
	float ca = cos(ang);
	float sa = sin(ang);
	vec2 twisted = vec2(dir.x * ca - dir.y * sa, dir.x * sa + dir.y * ca);
	vec2 suv = center + twisted * (1.0 - warp);

	float aberr = s * (0.003 + (mode > 0.5 ? 0.01 : 0.0) + (mode > 1.5 ? 0.008 : 0.0));
	vec2 off = ndir * aberr;

	vec4 r = Texel(tex, clamp(suv + off, 0.0, 1.0));
	vec4 g = Texel(tex, clamp(suv, 0.0, 1.0));
	vec4 b = Texel(tex, clamp(suv - off, 0.0, 1.0));
	vec3 col = vec3(r.r, g.g, b.b);

	// Purple rim / vignette toward singularity
	float rim = s * smoothstep(0.45, 0.0, dist) * 0.55;
	col = mix(col, col * vec3(0.55, 0.25, 1.0), rim);

	// Darken core while sucking
	if (mode < 0.5) {
		float core = s * smoothstep(0.12, 0.0, dist);
		col *= (1.0 - core * 0.85);
		// orbiting shimmer
		float shimmer = sin(atan(dir.y, dir.x) * 6.0 + time * 10.0) * 0.5 + 0.5;
		col += vec3(0.25, 0.05, 0.45) * shimmer * s * smoothstep(0.35, 0.08, dist) * 0.25;
	}

	// Blast flash
	if (mode > 0.5 && mode < 1.5) {
		float flash = s * exp(-dist * 6.0);
		col += vec3(0.85, 0.55, 1.0) * flash * 0.95;
		col += vec3(1.0, 1.0, 1.0) * flash * flash * 0.55;
		// outward shock ring
		float ring = abs(dist - (0.08 + (1.0 - s) * 0.35));
		col += vec3(0.7, 0.3, 1.0) * s * (1.0 - smoothstep(0.0, 0.04, ring)) * 0.8;
	}

	// Muzzle flash (short)
	if (mode > 1.5) {
		float flash = s * exp(-dist * 14.0);
		col += vec3(0.6, 0.2, 1.0) * flash;
		col += vec3(1.0, 0.9, 1.0) * flash * flash * 0.7;
	}

	return vec4(col, 1.0);
}
