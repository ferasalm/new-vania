# PROTOTYPE - NOT FOR PRODUCTION
# The death screen. The picture loses its colour and breaks up, "SYSTEM OFFLINE"
# appears, and there are two choices: RECONSTRUCT (a new Pandora is built at the
# last save room) or QUIT. Works with keys (W/S, then J or K), a pad, the mouse
# and a finger.
extends CanvasLayer

signal chosen(choice: String)

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float amount = 0.0;
uniform float t = 0.0;

float rnd(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	// whole bands of the picture slip sideways for a moment
	float band = floor(uv.y * 36.0);
	float tick = floor(t * 11.0);
	float n = rnd(band + tick * 7.31);
	float slip = n > 0.86 ? (n - 0.86) * 0.5 : 0.0;
	uv.x += slip * amount * (rnd(tick) > 0.5 ? 1.0 : -1.0);
	vec3 c = texture(screen, uv).rgb;
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	// one colour channel hangs behind the others
	float ghost = dot(texture(screen, uv + vec2(0.006 * amount, 0.0)).rgb, vec3(0.333));
	vec3 mono = vec3(mix(grey, ghost, 0.35));
	mono *= 0.82 + 0.18 * sin(uv.y * 216.0 * 3.14159);
	mono += (rnd(uv.y * 91.0 + uv.x * 13.0 + t) - 0.5) * 0.10;
	// now and then a white tear runs across
	float tear = step(0.992, rnd(floor(uv.y * 108.0) + tick * 3.1));
	mono = mix(mono, vec3(0.9), tear * 0.6);
	COLOR = vec4(mix(c, mono * 0.72, amount), 1.0);
}
"""

var active := false
var _mat: ShaderMaterial
var _screen: ColorRect
var _box: Control
var _title: Label
var _sub: Label
var _btns: Array = []
var _pick := 0
var _t := 0.0
var _ready_t := 0.0


func _ready() -> void:
	layer = 35      # above the touch buttons, below the pause menu
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_screen = ColorRect.new()
	_screen.size = Vector2(384, 216)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_screen.material = _mat
	add_child(_screen)
	_box = Control.new()
	_box.size = Vector2(384, 216)
	add_child(_box)
	_title = _label("SYSTEM OFFLINE", 62, 20, Color("#E8F4F4"))
	_sub = _label("unit lost  -  memory cache intact", 90, 8, Color("#9AA8A8"))
	for i in 2:
		var b := Button.new()
		b.text = ["RECONSTRUCT", "QUIT"][i]
		b.custom_minimum_size = Vector2(120, 22)
		b.size = Vector2(120, 22)
		b.position = Vector2(132, 116 + i * 28)
		b.add_theme_font_size_override("font_size", 10)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_choose.bind(i))
		b.mouse_entered.connect(_hover.bind(i))
		_box.add_child(b)
		_btns.append(b)


func _label(text: String, y: float, font: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(384, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	_box.add_child(l)
	return l


func ask() -> String:
	# shows the screen and waits for the choice: "reconstruct" or "quit"
	active = true
	visible = true
	_pick = 0
	_t = 0.0
	_ready_t = 0.9      # a held attack button must not pick at once
	_box.modulate.a = 0.0
	_mat.set_shader_parameter("amount", 0.0)
	var tw := create_tween()
	tw.tween_method(func(v): _mat.set_shader_parameter("amount", v), 0.0, 1.0, 0.6)
	tw.tween_property(_box, "modulate:a", 1.0, 0.3)
	var choice: String = await chosen
	return choice


func close() -> void:
	active = false
	visible = false


func _hover(i: int) -> void:
	_pick = i


func _choose(i: int) -> void:
	if not active or _ready_t > 0.0:
		return
	active = false
	Sfx.play("pickup", 0.8 if i == 0 else 0.5)
	chosen.emit("reconstruct" if i == 0 else "quit")


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_ready_t = maxf(0.0, _ready_t - delta)
	_mat.set_shader_parameter("t", _t)
	# the title itself jumps now and then
	_title.position.x = 0.0 if fmod(_t, 1.7) > 0.12 else randf_range(-3.0, 3.0)
	for i in _btns.size():
		_btns[i].modulate = Color(1, 1, 1, 1) if i == _pick else Color(0.6, 0.6, 0.6, 0.85)
		_btns[i].text = ("> %s <" if i == _pick else "%s") % ["RECONSTRUCT", "QUIT"][i]
	if not active:
		return
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
		_pick = 1 - _pick
		Sfx.play("no_energy", 1.4)
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump"):
		_choose(_pick)
