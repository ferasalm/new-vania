shader_type canvas_item;
// The weapon appearing and breaking up, pixel by pixel (user, 2026-11-19: "the weapon
// materializes with the attack, and then dematerializes fashionably").
// mode 0: drawn as it is. mode 1: pixels arrive as t goes 0 -> 1, the newest ones glow.
// mode 2: pixels leave as t goes 0 -> 1, the edge that is about to go glows.
uniform int mode = 0;
uniform float t = 1.0;
uniform vec4 glow : source_color = vec4(0.75, 1.0, 1.0, 1.0);
uniform vec2 px = vec2(82.0, 18.0);   // the texture's pixel size, so each pixel gets one value

float noise(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float n = noise(floor(UV * px));
	if (mode == 1) {
		if (n >= t) {
			c.a = 0.0;
		} else if (n > t - 0.2) {
			c.rgb = glow.rgb;
		}
	} else if (mode == 2) {
		if (n < t) {
			c.a = 0.0;
		} else if (n < t + 0.12) {
			c.rgb = glow.rgb;
		}
	}
	COLOR = c;
}
