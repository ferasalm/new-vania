# PROTOTYPE - NOT FOR PRODUCTION
# The picture after the reality shift. A full-screen filter that sits between the world and
# the HUD: each room has its own colour (hazard blood red, library inverted and red, church
# sick green, shaft deep blue with a dark rim, vault flickering red and black, time machine
# violet, anywhere else washed out). All of them add film noise, a slight colour split and
# now and then a band of the picture that tears sideways. tear() is the shift itself:
# the picture rips for a couple of seconds and goes white.
extends CanvasLayer

const MODES := {"hazard": 1, "library": 2, "church": 3, "shaft": 4, "vault": 5, "timemachine": 6}
const SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int mode = 0;
uniform float t = 0.0;
uniform float boost = 0.0;
uniform float flash = 0.0;
uniform float noise = 0.12;
uniform float tear_chance = 0.2;

float rnd(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float tick = floor(t * 12.0);
	// now and then a band of the picture slips sideways; during the shift it never stops
	float band = floor(uv.y * 54.0);
	float on = step(1.0 - tear_chance, rnd(floor(t * 1.3) * 3.7)) + boost;
	float n = rnd(band * 1.7 + tick * 5.13);
	float thr = 0.93 - boost * 0.4;
	float slip = n > thr ? (n - thr) * (0.5 + boost * 1.4) : 0.0;
	uv.x += slip * clamp(on, 0.0, 1.0) * (rnd(tick + band) > 0.5 ? 1.0 : -1.0);
	float split = 0.0025 + boost * 0.012;
	vec3 c;
	c.r = texture(screen, uv + vec2(split, 0.0)).r;
	c.g = texture(screen, uv).g;
	c.b = texture(screen, uv - vec2(split, 0.0)).b;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 o;
	float rim = 0.0;
	if (mode == 1) {
		o = mix(vec3(lum) * vec3(1.35, 0.16, 0.1), c * vec3(1.1, 0.3, 0.25), 0.25);
	} else if (mode == 2) {
		vec3 inv = vec3(1.0) - c;
		float il = dot(inv, vec3(0.299, 0.587, 0.114));
		o = mix(inv, vec3(il) * vec3(1.3, 0.2, 0.15), 0.6);
	} else if (mode == 3) {
		o = vec3(lum) * vec3(0.55, 1.1, 0.4) + vec3(0.02, 0.07, 0.0);
	} else if (mode == 4) {
		o = vec3(lum) * vec3(0.3, 0.5, 1.2) + vec3(0.0, 0.01, 0.05);
		rim = 1.0;
	} else if (mode == 5) {
		float fl = 0.55 + 0.45 * step(0.5, rnd(floor(t * 9.0)));
		o = vec3(lum * lum * 1.6) * vec3(1.4, 0.1, 0.08) * fl;
	} else if (mode == 6) {
		o = vec3(lum) * vec3(0.9, 0.4, 1.2) + vec3(0.04, 0.0, 0.07);
	} else {
		o = mix(vec3(lum), c, 0.3) * vec3(0.95, 0.95, 1.0);
	}
	float d = length(SCREEN_UV - vec2(0.5)) * 1.25;
	o *= 1.0 - smoothstep(0.45, 1.0, d) * (rim > 0.5 ? 0.85 : 0.35);
	o += (rnd(uv.y * 91.0 + uv.x * 13.0 + t) - 0.5) * noise;
	float tear = step(0.997 - boost * 0.06, rnd(floor(uv.y * 108.0) + tick * 3.1));
	o = mix(o, vec3(0.9), tear * 0.5 * clamp(on, 0.0, 1.0));
	o = mix(o, vec3(1.0), flash);
	COLOR = vec4(o, 1.0);
}
"""

var _mat: ShaderMaterial
var _rect: ColorRect
var _t := 0.0
var mode := 0
var boost := 0.0       # 0..1: how hard the shift is tearing the picture
var flash := 0.0       # 0..1: white-out


func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_rect = ColorRect.new()
	_rect.size = Vector2(384, 216)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)
	_mat.set_shader_parameter("noise", T.v("shift_noise"))
	_mat.set_shader_parameter("tear_chance", T.v("shift_tear_chance"))


func set_room(room_name: String) -> void:
	# picks the colour of this room; the filter is only on after the shift
	mode = MODES.get(room_name, 0)
	_mat.set_shader_parameter("mode", mode)
	visible = G.shifted or boost > 0.0 or flash > 0.0


func tear(seconds: float) -> void:
	# the shift: the picture rips harder and harder, goes white, and settles into the new colour
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "boost", 1.0, seconds * 0.55)
	tw.parallel().tween_property(self, "flash", 1.0, seconds * 0.55).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "flash", 0.0, seconds * 0.45)
	tw.parallel().tween_property(self, "boost", 0.0, seconds * 0.45)
	tw.tween_callback(func(): visible = G.shifted)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_mat.set_shader_parameter("t", _t)
	_mat.set_shader_parameter("boost", boost)
	_mat.set_shader_parameter("flash", flash)
	_mat.set_shader_parameter("noise", T.v("shift_noise"))
	_mat.set_shader_parameter("tear_chance", T.v("shift_tear_chance"))
