shader_type canvas_item;
// Full-screen post effect: CRT-ish scanlines, vignette, and tearing that
// spikes whenever the owner rewrites something.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 3.0) = 1.1;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;

	// Horizontal tearing in random bands.
	float band = floor(uv.y * 45.0);
	float tear = step(1.0 - glitch * 0.3, rand(vec2(band, floor(t * 14.0))));
	uv.x += tear * (rand(vec2(band, t)) - 0.5) * 0.09 * glitch;

	// Chromatic split.
	float ca = 0.0015 + glitch * 0.012;
	vec3 col;
	col.r = texture(screen_texture, uv + vec2(ca, 0.0)).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - vec2(ca, 0.0)).b;

	// Scanlines and grain.
	col *= 0.9 + 0.1 * sin(SCREEN_UV.y * 360.0 * 3.14159);
	col += (rand(SCREEN_UV + fract(t)) - 0.5) * (0.035 + glitch * 0.18);

	vec2 d = SCREEN_UV - 0.5;
	col *= 1.0 - dot(d, d) * vignette;

	COLOR = vec4(col, 1.0);
}
