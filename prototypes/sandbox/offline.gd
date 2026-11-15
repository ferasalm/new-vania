# PROTOTYPE - NOT FOR PRODUCTION
# THE SYSTEM OFFLINE SCREEN — death as a story, not a fail state.
# Contract (cache-stations-death.md TR-CSD-008/009, system_offline_contract):
#   three rows: SYSTEM OFFLINE / you are destroyed (lowercase) / the cause row
#   three options verbatim: RECONSTRUCT AT THE NEURAL TERMINAL / DRAW THE RESTORE
#   MODULE / QUIT — the module option GREYS, never hides; OFFLINE_HOLD_MS 400 gates
#   selectability; the DEATH state is never time-limited.
# The surface: monochrome + glitch-edged. No camera shake, no red.
extends Control

signal chosen(choice: String)

const OPTIONS := ["reconstruct", "module", "quit"]
const OPTION_TEXT := [
	"RECONSTRUCT AT THE NEURAL TERMINAL",
	"DRAW THE RESTORE MODULE",
	"QUIT",
]

var cause := "FAULT: UNRECORDED"
var has_module := false
var held_ms := 0.0
var sel := 0
var dead := true
var _shader_ok := false

var mono_rect: ColorRect


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 200
	_build_mono()
	if not has_module:
		sel = 0
	queue_redraw()


func _build_mono() -> void:
	mono_rect = ColorRect.new()
	mono_rect.position = Vector2.ZERO
	mono_rect.size = Vector2(960, 540)
	mono_rect.show_behind_parent = true
	mono_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mono_rect.color = Color(0.10, 0.09, 0.08, 0.55)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.88;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 bone_mono = vec3(l) * vec3(0.95, 0.92, 0.86);
	COLOR = vec4(mix(c, bone_mono, amount), 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mono_rect.material = mat
	add_child(mono_rect)
	_shader_ok = true


func _process(delta: float) -> void:
	if dead:
		held_ms += delta * 1000.0
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not dead:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if held_ms < K.OFFLINE_HOLD_MS:
		return
	match event.keycode:
		KEY_W, KEY_UP:
			_move(-1)
		KEY_S, KEY_DOWN:
			_move(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_commit(OPTIONS[sel])
		KEY_1:
			if has_module:
				_commit("module")
		KEY_2:
			_commit("reconstruct")
		KEY_3:
			_commit("quit")
		KEY_ESCAPE:
			_commit("quit")
	get_viewport().set_input_as_handled()


func _move(dir: int) -> void:
	var n := sel
	for i in 3:
		n = (n + dir + 3) % 3
		if OPTIONS[n] != "module" or has_module:
			sel = n
			return


func _commit(choice: String) -> void:
	if choice == "module" and not has_module:
		return
	dead = false
	chosen.emit(choice)


func _draw() -> void:
	# the glitch edges: value-only dark bands + hairlines, no strobing
	draw_rect(Rect2(0, 0, 960, 540), Color(0.04, 0.035, 0.03, 0.80))
	draw_rect(Rect2(0, 0, 26, 540), Color(0, 0, 0, 0.75))
	draw_rect(Rect2(934, 0, 26, 540), Color(0, 0, 0, 0.75))
	for i in 7:
		var y := 40.0 + i * 74.0
		var w := 60.0 + (i % 3) * 90.0
		var x := 0.0 if i % 2 == 0 else 960.0 - w
		draw_rect(Rect2(x, y, w, 1.0), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.10))
	draw_rect(Rect2(0, 268, 960, 1), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.25))

	_center("SYSTEM OFFLINE", 196, 34, K.C_BONE)
	_center("you are destroyed", 236, 19, K.C_BONE)
	_center(cause, 266, 12, K.C_BONE_DIM)

	var unlock := held_ms >= K.OFFLINE_HOLD_MS
	for i in 3:
		var y := 340.0 + i * 40.0
		var is_module: bool = OPTIONS[i] == "module"
		var enabled: bool = unlock and (has_module or not is_module)
		var c := K.C_BONE if enabled else Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.35)
		if enabled and i == sel:
			c = K.C_AMBER
			draw_rect(Rect2(190, y - 17, 580, 28), Color(K.C_AMBER.r, K.C_AMBER.g, K.C_AMBER.b, 0.10))
			draw_rect(Rect2(190, y - 17, 2, 28), K.C_AMBER)
		var txt: String = OPTION_TEXT[i]
		if is_module and not has_module:
			txt += "   (none carried)"
		_center(txt, y, 15, c)

	var foot := "W/S  SELECT      ENTER  CONFIRM" if unlock else "…"
	_center(foot, 496, 11, Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.6))


func _center(txt: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(ThemeDB.fallback_font, Vector2(480.0 - w * 0.5, y), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)
