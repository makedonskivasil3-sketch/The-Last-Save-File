shader_type canvas_item;
render_mode unshaded;
// The screen of an old CRT that someone else owns.
//
// One full-screen pass over everything below it (world + HUD): barrel
// curvature, scanlines, an aperture grille, radial chromatic aberration,
// animated grain, vignette, and every way the owner can corrupt the picture.
//
// Nothing here should be set by hand: scripts/fx/screen_fx.gd drives every
// uniform each frame and applies the player's Settings. The settings map to:
//   intensity  = Settings.glitch_intensity  (0 = clean-ish CRT, 1 = full corruption)
//   flash      = Settings.flash_scale()     (1 = normal, 0.3 = reduce flashing)
//   curvature  = Settings.crt_curvature     (0 = flat glass)
// Only 3 texture reads per pixel, so it stays cheap on the web build.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// --- player settings ---------------------------------------------------------
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float flash : hint_range(0.0, 1.0) = 1.0;
uniform float curvature : hint_range(0.0, 0.4) = 0.14;

// --- slow state ---------------------------------------------------------------
// Owner awareness, 0..1, smoothed. Drives the whole "the screen is getting sick" look.
uniform float awareness : hint_range(0.0, 1.0) = 0.0;
// The Edge: cold, desaturated, crawling with unloaded-data noise.
uniform float edge_mode : hint_range(0.0, 1.0) = 0.0;

// --- events (decay back to 0 in screen_fx.gd) ----------------------------------
uniform float glitch : hint_range(0.0, 1.0) = 0.0;      // tearing + displaced blocks
uniform float noise_burst : hint_range(0.0, 1.0) = 0.0; // the cursor arriving: static and whine lines
uniform float roll : hint_range(0.0, 1.0) = 0.0;        // vertical hold slipping
uniform float squeeze : hint_range(0.0, 1.0) = 0.0;     // power-off: collapse to a line, then a dot
uniform vec4 wash : source_color = vec4(0.0);           // full-screen colour flash, alpha = strength
uniform float void_amount : hint_range(0.0, 1.0) = 0.0; // erased: the screen gets eaten in blocks
uniform float smear : hint_range(0.0, 1.0) = 0.0;       // overwritten: rows dragged sideways
uniform float invert : hint_range(0.0, 1.0) = 0.0;      // selected: negative flash

uniform vec2 game_size = vec2(640.0, 360.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	float t = mod(TIME, 1000.0);
	float a = awareness * intensity;
	float sick = a * a;

	// 1. Glass. Barrel curvature, normalised so the corners land exactly on
	//    the screen corners: nothing is cropped, the middle just bulges.
	vec2 cc = SCREEN_UV - 0.5;
	float k = curvature * (1.0 + sick * 0.35);
	vec2 uv = 0.5 + cc * (1.0 + k * dot(cc, cc)) / (1.0 + k * 0.5);

	// Power-off squeeze: vertical collapse to a line, then the line to a dot.
	float sy = clamp(squeeze / 0.75, 0.0, 1.0);
	float sx = clamp((squeeze - 0.75) / 0.25, 0.0, 1.0);
	uv.y = 0.5 + (uv.y - 0.5) / max(1.0 - sy * 0.985, 0.015);
	uv.x = 0.5 + (uv.x - 0.5) / max(1.0 - sx * 0.985, 0.015);
	// Anything squeezed off the glass is black.
	float on_glass = step(0.0, uv.y) * step(uv.y, 1.0) * step(0.0, uv.x) * step(uv.x, 1.0);

	// 2. Vertical hold slipping.
	uv.y = fract(uv.y + roll);

	// 3. Sickness: the image breathes and wobbles, row by row.
	uv.x += (sin(uv.y * 38.0 + t * 3.1) * 0.0012 + sin(uv.y * 6.0 - t * 1.3) * 0.0018) * sick;
	uv.y += sin(uv.x * 9.0 + t * 0.7) * 0.0008 * sick;

	// 4. Tearing: random bands snap sideways. Awareness adds a background rate.
	float tick = floor(t * 14.0);
	float tear_amt = clamp(glitch + max(a - 0.35, 0.0) * 0.22 * flash, 0.0, 1.0) * intensity;
	float band = floor(uv.y * 45.0);
	float tear = step(1.0 - tear_amt * 0.35, hash(vec2(band, tick)));
	uv.x += tear * (hash(vec2(band, tick + 7.0)) - 0.5) * 0.12 * tear_amt;
	// One thin tear line slowly sweeping down the screen once the owner is suspicious.
	float sweep = fract(t * 0.11);
	uv.x += smoothstep(0.012, 0.0, abs(uv.y - sweep)) * 0.012 * max(a - 0.3, 0.0) * flash;

	// 5. Displaced blocks: chunks of the picture copied from the wrong place.
	vec2 blk = floor(uv * vec2(24.0, 14.0));
	float bh = hash(blk + tick);
	if (bh < glitch * 0.18 * intensity) {
		uv += (vec2(hash(blk + 3.1), hash(blk + 8.7)) - 0.5) * 0.09;
	}

	// 6. Overwritten: rows dragged sideways, as if something is being written over them.
	uv.x -= smear * hash(vec2(floor(uv.y * 90.0), floor(t * 24.0))) * 0.25;

	// 7. Chromatic aberration, stronger toward the edges of the glass.
	float ca = (0.0012 + a * 0.0045 + glitch * 0.012 + noise_burst * 0.012 + edge_mode * 0.002) * max(intensity, 0.25);
	vec2 dir = (uv - 0.5) * 2.0;
	vec3 col;
	col.r = texture(screen_texture, uv + dir * ca + vec2(ca * 0.6, 0.0)).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - dir * ca - vec2(ca * 0.6, 0.0)).b;

	// 8. Colour: drains, then turns red/magenta as the owner closes in.
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), a * 0.55);
	col *= mix(vec3(1.0), vec3(1.28, 0.72, 0.92), a * 0.75);
	// The Edge: cold and colourless.
	col = mix(col, vec3(lum) * vec3(0.75, 0.95, 1.2), edge_mode * 0.55);

	// 9. Scanlines (one per game pixel row) and an aperture grille.
	float scan = 0.5 + 0.5 * cos(uv.y * game_size.y * 6.28318);
	col *= mix(1.0, 0.68 + 0.32 * scan, 0.55);
	float triad = mod(FRAGCOORD.x, 3.0);
	vec3 mask = triad < 1.0 ? vec3(1.0, 0.82, 0.82) : (triad < 2.0 ? vec3(0.82, 1.0, 0.82) : vec3(0.82, 0.82, 1.0));
	col *= mix(vec3(1.0), mask, 0.22);
	// A faint bright band rolling through: the refresh you can almost see.
	col *= 1.0 + 0.05 * smoothstep(0.06, 0.0, abs(fract(uv.y - t * 0.07) - 0.5));

	// 10. Grain, alive, heavier as things get worse.
	float g = hash(FRAGCOORD.xy * 0.71 + fract(t * 7.13) * 431.0) - 0.5;
	col += g * (0.035 + a * 0.06 + glitch * 0.15 + noise_burst * 0.3 + edge_mode * 0.04) * max(intensity, 0.35);

	// 11. Cursor arrival: thin bright vertical lines and a sweeping static band.
	if (noise_burst > 0.0) {
		float lines = step(0.996 - noise_burst * 0.025, hash(vec2(floor(FRAGCOORD.x * 0.5), floor(t * 30.0))));
		float bandn = smoothstep(0.08, 0.0, abs(uv.y - fract(t * 1.7)));
		col = mix(col, vec3(0.9, 0.95, 1.0), (lines * 0.6 + bandn * 0.35 * hash(FRAGCOORD.xy + t)) * noise_burst * flash);
	}
	// The Edge: rows of unloaded data flickering through.
	if (edge_mode > 0.0) {
		float row = step(0.985, hash(vec2(floor(uv.y * 120.0), floor(t * 8.0))));
		col += vec3(0.1, 0.35, 0.45) * row * edge_mode * hash(vec2(floor(FRAGCOORD.x / 6.0), t)) * flash;
	}

	// 12. Erased: blocks of screen go to void, red at the bite edge.
	if (void_amount > 0.0) {
		vec2 vb = floor(SCREEN_UV * vec2(32.0, 18.0));
		float h = hash(vb);
		float eaten = step(h, void_amount);
		float rim = step(h, void_amount + 0.08) - eaten;
		col = mix(col, vec3(0.0), eaten);
		col = mix(col, vec3(0.9, 0.12, 0.1), rim * 0.7 * (0.6 + 0.4 * flash));
	}

	// 13. Negative flash (selected) and colour wash.
	col = mix(col, 1.0 - col, invert * flash);
	col = mix(col, wash.rgb, wash.a * flash);

	// 14. Brightness flicker that gets worse with awareness.
	col *= 1.0 - hash(vec2(floor(t * 24.0), 3.0)) * 0.07 * a * flash;

	// 15. Vignette: darker corners closing in as the owner gets closer.
	// Capped so the HUD in the corners always stays readable (min ~30%).
	float v = dot(cc, cc);
	col *= 1.0 - smoothstep(0.08, 0.6, v) * (0.45 + 0.27 * a);
	// Rounded glass edge: a soft black bezel at the very corners.
	vec2 edge = smoothstep(vec2(0.0), vec2(0.012 + curvature * 0.03), 0.5 - abs(cc));
	col *= edge.x * edge.y * on_glass;
	// Power-off: the collapsing line glows white-hot.
	col += vec3(0.8, 0.95, 1.0) * sy * (1.0 - sx) * smoothstep(0.01, 0.0, abs(SCREEN_UV.y - 0.5)) * flash;

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
